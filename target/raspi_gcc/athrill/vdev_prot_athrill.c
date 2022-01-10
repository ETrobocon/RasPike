#include <assert.h>
#include <time.h>
#include <string.h>
#include <stdio.h>
#include "vdev.h"
#include "target_sil.h"
#include "vdev_prot_athrill.h"
#include "athrill_mpthread.h"
#include "devconfig.h"
#include "vdev_private.h"

#define ASSERT(val) 

static const VdevIfComMethod *cur_com = 0;

struct timespec previous_sent = {0};
static MpthrIdType vdev_thrid;

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



static Std_ReturnType vdevProtAthrillSilCb(int size, uint32 addr, uint8_t data);

static Std_ReturnType vdev_thread_do_init(MpthrIdType id);
static Std_ReturnType vdev_thread_do_proc(MpthrIdType id);

static uint32 reset_area_off = 0;
static uint32 reset_area_size  = 0; 

static MpthrOperationType vdev_op = {
	.do_init = vdev_thread_do_init,
	.do_proc = vdev_thread_do_proc,
};


int vdevProtAthrillInit(const VdevIfComMethod *com)
{
  Std_ReturnType err;

  cur_com = com;
  /* デバイスIOに書き込んだ際に呼ばれるコールバック関数 */
  SilSetWriteHook(vdevProtAthrillSilCb);

  // Reset Area
  err = cpuemu_get_devcfg_value("DEVICE_CONFIG_RESET_AREA_OFFSET", &reset_area_off);
  printf("DEVICE_CONFIG_RESET_AREA_OFFSET=%d\n",reset_area_off);
  
  err = cpuemu_get_devcfg_value("DEVICE_CONFIG_RESET_AREA_SIZE", &reset_area_size);
  printf("DEVICE_CONFIG_RESET_AREA_SIZE=%d\n",reset_area_size);

  
  /* 受信用スレッドの作成 */
  mpthread_init();

  err = mpthread_register(&vdev_thrid, &vdev_op);
  ASSERT(err == STD_E_OK);

  err = mpthread_start_proc(vdev_thrid);
  ASSERT(err == STD_E_OK);
  
  return 0;

}

/* IOメモリへの書き込み */
Std_ReturnType vdevProtAthrillSilCb(int size, uint32 addr, uint8_t data)
{
  if ( size != 1 ) return STD_E_OK;
  
  //  uint32 off = ((uint32)addr - VDEV_BASE) + VDEV_TX_DATA_BODY_OFF;

  if (addr == VDEV_TX_FLAG(0)) {

    //    uint32 tx_off = VDEV_TX_DATA_BASE - VDEV_BASE;
    Std_ReturnType err;
	
    memcpy(&vdev_control.comm.write_data.buffer[VDEV_TX_DATA_BODY_OFF], (char*)(VDEV_TX_DATA_BASE + VDEV_TX_DATA_BODY_OFF), VDEV_TX_DATA_BODY_SIZE);
    memcpy(&vdev_control.comm.write_data.buffer[VDEV_TX_SIM_TIME(VDEV_SIM_INX_ME)],  (void*)&vdev_control.vdev_sim_time[VDEV_SIM_INX_ME], 8U);
    memcpy(&vdev_control.comm.write_data.buffer[VDEV_TX_SIM_TIME(VDEV_SIM_INX_YOU)], (void*)&vdev_control.vdev_sim_time[VDEV_SIM_INX_YOU], 8U);
		//printf("sim_time=%llu\n", vdev_udp_control.vdev_sim_time[VDEV_SIM_INX_ME]);
    err = udp_comm_remote_write(&vdev_control.comm, vdev_control.remote_ipaddr);

    // Clear reset area
    if ( reset_area_off && reset_area_size ) {
      memset(&vdev_control.comm.write_data.buffer[reset_area_off],0,reset_area_size);
      memset((char*)(VDEV_TX_DATA_BASE+reset_area_off),0,reset_area_size);
    }

    if (err != STD_E_OK) {
      printf("WARNING: vdevput_data8: udp send error=%d\n", err);
    }

  }
  else {
  }

  return STD_E_OK;

}


/* 受信スレッド */
static Std_ReturnType vdev_thread_do_init(MpthrIdType id)
{
	//nothing to do
	return STD_E_OK;
}

static Std_ReturnType vdev_udp_packet_check(const char *p)
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
	Std_ReturnType err;
	//	uint32 off = VDEV_RX_DATA_BASE - VDEV_BASE;
	uint64 curr_stime;

	while (1) {
		err = udp_comm_read(&vdev_control.comm);
		
		if (err != STD_E_OK) {
			continue;
		} else if (vdev_udp_packet_check((const char*)&vdev_control.comm.read_data.buffer[0]) != STD_E_OK) {
			continue;
		}
		//gettimeofday(&unity_notify_time, NULL);
		memcpy((char*)VDEV_RX_DATA_BASE, &vdev_control.comm.read_data.buffer[0], vdev_control.comm.read_data.len);
		memcpy((void*)&curr_stime, &vdev_control.comm.read_data.buffer[VDEV_RX_SIM_TIME(VDEV_SIM_INX_ME)], 8U);

		//unity_interval_vtime = curr_stime - vdev_udp_control.vdev_sim_time[VDEV_SIM_INX_YOU];
		//vdev_calc_predicted_virtual_time(vdev_udp_control.vdev_sim_time[VDEV_SIM_INX_YOU], curr_stime);
		vdev_control.vdev_sim_time[VDEV_SIM_INX_YOU] = curr_stime;
#if 0
		{
			uint32 count = 0;
			if ((count % 1000) == 0) {
				printf("%llu, %llu\n", vdev_control.vdev_sim_time[VDEV_SIM_INX_YOU], vdev_control.vdev_sim_time[VDEV_SIM_INX_ME]);
			}
			count++;
		}
#endif
	}
	return STD_E_OK;


}
