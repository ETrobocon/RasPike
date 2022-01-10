#include <stdio.h>
#include <unistd.h>
#include "vdev_private.h"
#include "athrill_mpthread.h"
#include "cpuemu_ops.h"

static Std_ReturnType vdev_ev3proxy_get_data8(MpuAddressRegionType *region, CoreIdType core_id, uint32 addr, uint8 *data);
static Std_ReturnType vdev_ev3proxy_get_data16(MpuAddressRegionType *region, CoreIdType core_id, uint32 addr, uint16 *data);
static Std_ReturnType vdev_ev3proxy_get_data32(MpuAddressRegionType *region, CoreIdType core_id, uint32 addr, uint32 *data);
static Std_ReturnType vdev_ev3proxy_put_data8(MpuAddressRegionType *region, CoreIdType core_id, uint32 addr, uint8 data);
static Std_ReturnType vdev_ev3proxy_put_data16(MpuAddressRegionType *region, CoreIdType core_id, uint32 addr, uint16 data);
static Std_ReturnType vdev_ev3proxy_put_data32(MpuAddressRegionType *region, CoreIdType core_id, uint32 addr, uint32 data);
static Std_ReturnType vdev_ev3proxy_get_pointer(MpuAddressRegionType *region, CoreIdType core_id, uint32 addr, uint8 **data);

MpuAddressRegionOperationType	vdev_ev3proxy_memory_operation = {
		.get_data8 		= 	vdev_ev3proxy_get_data8,
		.get_data16		=	vdev_ev3proxy_get_data16,
		.get_data32		=	vdev_ev3proxy_get_data32,

		.put_data8 		= 	vdev_ev3proxy_put_data8,
		.put_data16		=	vdev_ev3proxy_put_data16,
		.put_data32		=	vdev_ev3proxy_put_data32,

		.get_pointer	= vdev_ev3proxy_get_pointer,
};


static MpthrIdType vdev_thrid;
static MpthrIdType vdev_send_thrid;

Std_ReturnType mpthread_init(void);
extern Std_ReturnType mpthread_register(MpthrIdType *id, MpthrOperationType *op);

static Std_ReturnType vdev_thread_do_init(MpthrIdType id);
static Std_ReturnType vdev_thread_do_proc(MpthrIdType id);
static Std_ReturnType vdev_send_thread_do_init(MpthrIdType id);
static Std_ReturnType vdev_send_thread_do_proc(MpthrIdType id);
static uint32 enable_complemental_send = 0; // defaule false
static uint32 reset_area_off = 0;
static uint32 reset_area_size  = 0; 

static MpthrOperationType vdev_op = {
	.do_init = vdev_thread_do_init,
	.do_proc = vdev_thread_do_proc,
};

// Complemental TX Communication
static MpthrOperationType vdev_send_op = {
	.do_init = vdev_send_thread_do_init,
	.do_proc = vdev_send_thread_do_proc,
};
static struct timespec previous_sent = {0};

static void save_sent_time(void)
{
	clock_gettime(CLOCK_MONOTONIC,&previous_sent);
}

static long get_time_from_previous_sending(void)
{
	struct timespec cur;
	clock_gettime(CLOCK_MONOTONIC,&cur);
	return (cur.tv_sec-previous_sent.tv_sec)*1000000000 + cur.tv_nsec-previous_sent.tv_nsec;
}


static void lock_send_mutex(void)
{
	if ( enable_complemental_send ) {
		mpthread_lock(vdev_send_thrid);
	}
}
static void unlock_send_mutex(void)
{
	if ( enable_complemental_send ) {
		mpthread_unlock(vdev_send_thrid);
	}
}

static void bt_init(void)
{
	char buf[255];
	char *btprefix;

	(void)cpuemu_get_devcfg_string("DEVICE_CONFIG_BT_BASENAME", &btprefix);

	printf("bt_init() start \n");
	// for receive
	sprintf(buf,"%s_out",btprefix);
	printf("bt_init() open =%s \n",buf);
	vdev_control.rx_fp = fopen(buf,"r");
	printf("bt_init() opened =%p \n",vdev_control.rx_fp);

	if ( vdev_control.rx_fp == 0 ) {
		printf("ERROR: can not open bt name=%s\n",buf);
		ASSERT(0);
	}

	// for send
	sprintf(buf,"%s_in",btprefix);
	vdev_control.tx_fp = fopen(buf,"w");
	if ( vdev_control.tx_fp == 0 ) {
		printf("ERROR: can not open bt name=%s\n",buf);
		ASSERT(0);
	}

	printf("bt_init() Finished \n");

}

static int send_message(const unsigned char *buf, int len) 
{
	int ret = -1;
	if ( vdev_control.tx_fp != 0 ) {
		ret =  fwrite(buf,1,len,vdev_control.tx_fp);
		fflush(vdev_control.tx_fp);
	}
	//printf("fwrite ret=%d \n",ret);

	return ret;
}
static int receive_message(unsigned char *buf, int len)
{
	int ret = -1;
//	printf("fread len=%d \n",len);

	if ( vdev_control.rx_fp != 0 ) {
		ret = fread(buf,1,len,vdev_control.rx_fp);
	}
#if 0
	int i;
	for ( i = 0; i < ret; i++ ){
		printf("%d ",buf[i]);
	}

	printf("\nfread ret=%d \n",ret);
#endif
	return ret;
}

// Message Definitions

typedef uint16_t CmdID;
typedef struct message_common {
	CmdID cmd;
	uint16_t len;
} MessageCommon;

typedef struct athrill_update_element {
	unsigned int offset;
	unsigned int data;
} AthrillUpdateElement;

typedef struct message_target_update {
	uint64_t ev3time;
	unsigned int num;
} MessageTargetUpdate;

#define ATHRILL_MSG_HELLO (0x01)
#define ATHRILL_MSG_INITIALIZE (0x02)
#define ATHRILL_MSG_ATHRILL_UPDATE (0x03)

#define TARGET_MSG_WELCOME (0x81)
#define TARGET_MSG_INITIALIZE_ACK (0x82)
#define TARGET_MSG_TARGET_UPDATE (0x83)


static void handshake_proxy(void)
{
	int ret;
	// send hello
	MessageCommon msg;
	msg.cmd = ATHRILL_MSG_HELLO;
	msg.len = 0;

	ret = send_message((unsigned char*)&msg,sizeof(msg));

	// wait welcome
	ret = receive_message((unsigned char*)&msg,sizeof(msg));
	if ( msg.cmd != TARGET_MSG_WELCOME ) {
		printf("ERROR: Expected WELCOME but it was %d\n",msg.cmd);
		ASSERT(0);
	}

	// send Initialize
	msg.cmd = ATHRILL_MSG_INITIALIZE;
	msg.len = VDEV_TX_DATA_COMM_SIZE;
	ret = send_message((unsigned char*)&msg,sizeof(msg));
	ret = send_message((unsigned char*)vdev_control.comm.write_data.buffer,VDEV_TX_DATA_COMM_SIZE);

	// wait InitializeAck

	ret = receive_message((unsigned char*)&msg,sizeof(msg));
	if ( msg.cmd != TARGET_MSG_INITIALIZE_ACK ) {
		printf("ERROR: Expected WELCOME but it was %d\n",msg.cmd);
		ASSERT(0);
	}
	ret = receive_message((unsigned char*)vdev_control.comm.read_data.buffer,vdev_control.comm.read_data.len);

}

void device_init_vdev_ev3proxy(MpuAddressRegionType *region)
{
	Std_ReturnType err;


	bt_init();

	//initialize  write & read buffer header
	{
		VdevTxDataHeadType *tx_headp = (VdevTxDataHeadType*)&vdev_control.comm.write_data.buffer[0];
		memset((void*)tx_headp, 0, VDEV_TX_DATA_HEAD_SIZE);
		memcpy((void*)tx_headp->header, VDEV_TX_DATA_HEAD_HEADER, strlen(VDEV_TX_DATA_HEAD_HEADER));
		tx_headp->version = VDEV_TX_DATA_HEAD_VERSION;
		tx_headp->ext_off = VDEV_TX_DATA_HEAD_EXT_OFF;
		tx_headp->ext_size = VDEV_TX_DATA_HEAD_EXT_SIZE;
		vdev_control.comm.write_data.len = VDEV_TX_DATA_COMM_SIZE;
	}
	{
		VdevRxDataHeadType *rx_headp = (VdevRxDataHeadType*)&vdev_control.comm.read_data.buffer[0];
		vdev_control.comm.read_data.len = 1024;
		memset((void*)rx_headp, 0, 1024);
	}

	handshake_proxy();


	mpthread_init();

	err = mpthread_register(&vdev_thrid, &vdev_op);
	ASSERT(err == STD_E_OK);

	err = mpthread_start_proc(vdev_thrid);
	ASSERT(err == STD_E_OK);

	// Reset Area
	err = cpuemu_get_devcfg_value("DEVICE_CONFIG_RESET_AREA_OFFSET", &reset_area_off);
	printf("DEVICE_CONFIG_RESET_AREA_OFFSET=%d\n",reset_area_off);

	err = cpuemu_get_devcfg_value("DEVICE_CONFIG_RESET_AREA_SIZE", &reset_area_size);
	printf("DEVICE_CONFIG_RESET_AREA_SIZE=%d\n",reset_area_size);

	return;
}
void device_supply_clock_vdev_ev3proxy(DeviceClockType *dev_clock)
{
	uint64 interval;
	uint64 unity_sim_time;

#if 1
	unity_sim_time = vdev_control.vdev_sim_time[VDEV_SIM_INX_YOU] * ((uint64)vdev_control.cpu_freq);
#else
	unity_sim_time = vdev_get_unity_sim_time(dev_clock);
#endif

	vdev_control.vdev_sim_time[VDEV_SIM_INX_ME] = ( dev_clock->clock / ((uint64)vdev_control.cpu_freq) );

	if ((unity_sim_time != 0) && (dev_clock->min_intr_interval != DEVICE_CLOCK_MAX_INTERVAL)) {
		if ((unity_sim_time <= dev_clock->clock)) {
			interval = 2U;
			//printf("UNITY <= MICON:%llu %llu\n", vdev_control.vdev_sim_time[VDEV_SIM_INX_YOU], vdev_control.vdev_sim_time[VDEV_SIM_INX_ME]);
		}
		else {
			//interval = (unity_sim_time - dev_clock->clock) + ((unity_interval_vtime  * ((uint64)vdev_ev3proxy_control.cpu_freq)) / 2);
			interval = (unity_sim_time - dev_clock->clock);
			//printf("UNITY > MICON:%llu %llu\n", vdev_control.vdev_sim_time[VDEV_SIM_INX_YOU], vdev_control.vdev_sim_time[VDEV_SIM_INX_ME]);
		}
		if (interval < dev_clock->min_intr_interval) {
			dev_clock->min_intr_interval = interval;
		}
	}
	return;
}

static Std_ReturnType vdev_thread_do_init(MpthrIdType id)
{
	//nothing to do
	return STD_E_OK;
}

static Std_ReturnType vdev_ev3proxy_packet_check(const char *p)
{
	const uint32 *p_int = (const uint32 *)&vdev_control.comm.read_data.buffer[0];
#if 0
	printf("HEADER:%c%c%c%c\n", p[0], p[1], p[2], p[3]);
	printf("version:0x%x\n", p_int[1]);
	printf("reserve[0]:0x%x\n", p_int[2]);
	printf("reserve[1]:0x%x\n", p_int[3]);
	printf("unity_time[0]:0x%x\n", p_int[4]);
	printf("unity_time[1]:0x%x\n", p_int[5]);
	printf("ext_off:0x%x\n", p_int[6]);
	printf("ext_size:0x%x\n", p_int[7]);
#endif
	if (strncmp(p, VDEV_RX_DATA_HEAD_HEADER, 4) != 0) {
		printf("ERROR: INVALID HEADER:%c%c%c%c\n", p[0], p[1], p[2], p[3]);
		return STD_E_INVALID;
	}
	if (p_int[1] != VDEV_RX_DATA_HEAD_VERSION) {
		printf("ERROR: INVALID VERSION:0x%x\n", p_int[1]);
		return STD_E_INVALID;
	}
	if (p_int[6] != VDEV_RX_DATA_HEAD_EXT_OFF) {
		printf("ERROR: INVALID EXT_OFF:0x%x\n", p_int[6]);
		return STD_E_INVALID;
	}
	if (p_int[7] != VDEV_RX_DATA_HEAD_EXT_SIZE) {
		printf("ERROR: INVALID EXT_SIZE:0x%x\n", p_int[7]);
		return STD_E_INVALID;
	}
	return STD_E_OK;
}

static Std_ReturnType vdev_thread_do_proc(MpthrIdType id)
{
	int ret;
	uint32 off = VDEV_RX_DATA_BASE - VDEV_BASE;
	uint64 curr_stime;

	while (1) {
		MessageCommon msg;

		//ret = receive_message((unsigned char*)&msg,sizeof(msg));

		while (1) {
			unsigned char c;
			ret = receive_message((unsigned char*)&c,1);
			if ( c == TARGET_MSG_TARGET_UPDATE ) {
				//dummy read
				receive_message((unsigned char*)&c,1);
				receive_message((unsigned char*)&msg.len,2);
				msg.cmd = TARGET_MSG_TARGET_UPDATE;
				break;
			} 
		}

		if ( msg.cmd == TARGET_MSG_TARGET_UPDATE ) {
			MessageTargetUpdate updateMsg;
			//			ret = receive_message((unsigned char*)&updateMsg,sizeof(updateMsg));
			ret = receive_message((unsigned char*)&updateMsg.ev3time,sizeof(updateMsg.ev3time));
			ret = receive_message((unsigned char*)&updateMsg.num,sizeof(updateMsg.num));
			AthrillUpdateElement elements[1024/4];
			if ( updateMsg.num > 0 ) {
				ret = receive_message((unsigned char*)elements,sizeof(AthrillUpdateElement)*updateMsg.num);
			}
			// Update Receive Buffer
			int i;
			for (i = 0; i < updateMsg.num; i++ ) {
				const AthrillUpdateElement *p = elements+i;
				if ( p->offset >=0  && p->offset < (1024) ) {
					unsigned int *toModify = (unsigned int *)(vdev_control.comm.read_data.buffer+p->offset);
					*toModify = p->data;
//					printf("Update offset=%d data=%d mod=%p\n",p->offset,p->data,toModify);
				} else {
					printf("Update offset=%d data=%d\n",p->offset,p->data);

				}

			}

			// copy sim time
			memcpy(&vdev_control.comm.read_data.buffer[VDEV_RX_SIM_TIME(VDEV_SIM_INX_ME)],&updateMsg.ev3time,8);
//			printf("simtime=%lld\n",updateMsg.ev3time);
		} else {
			// TODO:Fix me
			unsigned short tmp;
			printf("Not Update=%d\n",msg.cmd);
			ret = receive_message((unsigned char*)tmp,2);
			printf("Not Update=%d next=%d\n",msg.cmd,tmp);
			ASSERT(0);

			return STD_E_OK;
		}

#if 0 // Skip Error Check		
		if (err != STD_E_OK) {
			continue;
		} else if (vdev_ev3proxy_packet_check((const char*)&vdev_control.comm.read_data.buffer[0]) != STD_E_OK) {
			continue;
		}
#endif
		//gettimeofday(&unity_notify_time, NULL);
		memcpy(&vdev_control.region->data[off], &vdev_control.comm.read_data.buffer[0], 1024);
		memcpy((void*)&curr_stime, &vdev_control.comm.read_data.buffer[VDEV_RX_SIM_TIME(VDEV_SIM_INX_ME)], 8U);

		//unity_interval_vtime = curr_stime - vdev_ev3proxy_control.vdev_sim_time[VDEV_SIM_INX_YOU];
		//vdev_calc_predicted_virtual_time(vdev_ev3proxy_control.vdev_sim_time[VDEV_SIM_INX_YOU], curr_stime);
		vdev_control.vdev_sim_time[VDEV_SIM_INX_YOU] = curr_stime;
	}
	return STD_E_OK;


}


static Std_ReturnType vdev_send_thread_do_init(MpthrIdType id)
{
	//nothing to do
	return STD_E_OK;
}
static Std_ReturnType vdev_ev3proxy_get_data8(MpuAddressRegionType *region, CoreIdType core_id, uint32 addr, uint8 *data)
{
	uint32 off = (addr - region->start) + VDEV_RX_DATA_BODY_OFF;
	*data = *((uint8*)(&region->data[off]));
	return STD_E_OK;
}
static Std_ReturnType vdev_ev3proxy_get_data16(MpuAddressRegionType *region, CoreIdType core_id, uint32 addr, uint16 *data)
{
	uint32 off = (addr - region->start) + VDEV_RX_DATA_BODY_OFF;
	*data = *((uint16*)(&region->data[off]));
	return STD_E_OK;
}
static Std_ReturnType vdev_ev3proxy_get_data32(MpuAddressRegionType *region, CoreIdType core_id, uint32 addr, uint32 *data)
{
	uint32 off = (addr - region->start) + VDEV_RX_DATA_BODY_OFF;
	*data = *((uint32*)(&region->data[off]));
	return STD_E_OK;
}
static Std_ReturnType vdev_ev3proxy_put_data8(MpuAddressRegionType *region, CoreIdType core_id, uint32 addr, uint8 data)
{
	uint32 off = (addr - region->start) + VDEV_TX_DATA_BODY_OFF;
	*((uint8*)(&region->data[off])) = data;

	if (addr == VDEV_TX_FLAG(0)) {
		static char previous_sent_buffer[VDEV_TX_DATA_SIZE/4];

		AthrillUpdateElement elements[VDEV_TX_DATA_SIZE/4];

		uint32 tx_off = VDEV_TX_DATA_BASE - region->start;
		Std_ReturnType err;
	
		lock_send_mutex();

		// Check Difference
		int i;
		int num = 0;
		// unsigned int access
		unsigned int *curMem = (unsigned int *)&region->data[tx_off];
		unsigned int *prevMem = (unsigned int *)previous_sent_buffer;
		for ( i = 0; i < 1024/4; i++ ) {
			if ( *curMem != *prevMem ) {
				elements[num].offset = i * 4;
				elements[num].data = *curMem;
				*prevMem = *curMem;
				num++;
			}
			curMem++;
			prevMem++;
		}

		MessageCommon msg;
		msg.cmd = ATHRILL_MSG_ATHRILL_UPDATE;
		msg.len = 4 + sizeof(AthrillUpdateElement)*num;
		send_message((unsigned char*)&msg,sizeof(msg));
		send_message((unsigned char*)&num,4);
		send_message((unsigned char*)elements,sizeof(AthrillUpdateElement)*num);

		// Clear reset area
		if ( reset_area_off && reset_area_size ) {
				memset(&vdev_control.comm.write_data.buffer[reset_area_off],0,reset_area_size);
				memset(&region->data[tx_off+reset_area_off],0,reset_area_size);
		}
		save_sent_time();
		unlock_send_mutex();

		if (err != STD_E_OK) {
			printf("WARNING: vdevput_data8: udp send error=%d\n", err);
		}

	}
	else {
	}

	return STD_E_OK;
}
static Std_ReturnType vdev_ev3proxy_put_data16(MpuAddressRegionType *region, CoreIdType core_id, uint32 addr, uint16 data)
{
	uint32 off = (addr - region->start) + VDEV_TX_DATA_BODY_OFF;
	*((uint16*)(&region->data[off])) = data;
	return STD_E_OK;
}
static Std_ReturnType vdev_ev3proxy_put_data32(MpuAddressRegionType *region, CoreIdType core_id, uint32 addr, uint32 data)
{
	uint32 off = (addr - region->start) + VDEV_TX_DATA_BODY_OFF;
	*((uint32*)(&region->data[off])) = data;
	return STD_E_OK;
}
static Std_ReturnType vdev_ev3proxy_get_pointer(MpuAddressRegionType *region, CoreIdType core_id, uint32 addr, uint8 **data)
{
	uint32 off = (addr - region->start) + VDEV_TX_DATA_BODY_OFF;
	*data = &region->data[off];
	return STD_E_OK;
}
