#include <assert.h>
#include <time.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
#include "vdev.h"
#include "target_sil.h"
#include "vdev_prot_raspike.h"
#include "athrill_mpthread.h"
#include "devconfig.h"
#include "vdev_private.h"
#include "target_kernel_impl.h"

static uint32 reset_area_off = 0;
static uint32 reset_area_size  = 0; 



static sigset_t prev_sigset;
static void lock_task(void)
{
  sigset_t sigset;
  sigemptyset(&sigset);
  sigaddset(&sigset,SIGUSR2);
  sigaddset(&sigset,SIGALRM);
  sigprocmask(SIG_BLOCK, &sigset, &prev_sigset);
}

static void unlock_task(void)
{
  sigprocmask(SIG_SETMASK,&prev_sigset,0);
}


typedef struct {
  char header[4];
  uint32_t cmd;

} RaspikeHeader;

typedef struct {
  uint32_t cmd_id;
  uint32_t data;
} RaspikeBodyElement;


typedef struct {
  RaspikeHeader com_header;
  uint32_t num;
  RaspikeBodyElement elements[1024/4];
} RaspikeCommand;

static RaspikeCommand send_command;

static RaspikeHeader common_header;

static const VdevIfComMethod *cur_com = 0;
static MpthrIdType vdev_thrid;

static Std_ReturnType vdevProtRaspikeSilCb(int size, uint32 addr, void* data);

static Std_ReturnType vdev_thread_do_init(MpthrIdType id);
static Std_ReturnType vdev_thread_do_proc(MpthrIdType id);

static MpthrOperationType vdev_op = {
	.do_init = vdev_thread_do_init,
	.do_proc = vdev_thread_do_proc,
};

int vdevProtRaspikeInit(const VdevIfComMethod *com)
{
  Std_ReturnType err;

  cur_com = com;
  
  memset(&send_command.com_header,0,sizeof(send_command.com_header));
  memcpy(&send_command.com_header.header,"RSTX",4);
  
  
  /* デバイスIOに書き込んだ際に呼ばれるコールバック関数 */
  SilSetWriteHook(vdevProtRaspikeSilCb);

  // Reset Area
  err = cpuemu_get_devcfg_value("DEVICE_CONFIG_RESET_AREA_OFFSET", &reset_area_off);
  printf("DEVICE_CONFIG_RESET_AREA_OFFSET=%d\n",reset_area_off);
  
  err = cpuemu_get_devcfg_value("DEVICE_CONFIG_RESET_AREA_SIZE", &reset_area_size);
  printf("DEVICE_CONFIG_RESET_AREA_SIZE=%d\n",reset_area_size);

  
  mpthread_init();

  err = mpthread_register(&vdev_thrid, &vdev_op);

  err = mpthread_start_proc(vdev_thrid);

  return 0;
}  

static struct timespec previous_sent = {0};

static void save_sent_time(void)
{
	clock_gettime(CLOCK_MONOTONIC,&previous_sent);
}

static uint32 get_time_from_previous_sending(void)
{
	struct timespec cur;
	clock_gettime(CLOCK_MONOTONIC,&cur);
	return (uint32)((uint64)(cur.tv_sec-previous_sent.tv_sec)*1000000000 + (uint64)cur.tv_nsec-(uint64)previous_sent.tv_nsec)/1000000;
}


/* IOメモリへの書き込み */
Std_ReturnType vdevProtRaspikeSilCb(int size, uint32 addr, void *data)
{
  int len;

  if ( size != 1 ) return STD_E_OK;

  if (addr == VDEV_TX_FLAG(0)) {

    unsigned char buf[4];
    


    static char previous_sent_buffer[VDEV_TX_DATA_SIZE/4];

    if ( previous_sent.tv_sec == 0 ) {
      save_sent_time();
    }
    //    printf("Time:%d\n",get_time_from_previous_sending());
    
    // Check Difference
    int i;
    int num = 0;
    // unsigned int access
    unsigned int *curMem = (unsigned int *)(VDEV_TX_DATA_BASE);
    unsigned int *prevMem = (unsigned int *)previous_sent_buffer;

    for ( i = 0; i < VDEV_TX_DATA_BODY_SIZE/4; i++ ) {
      if ( *curMem != *prevMem ) {
	int cmd = 1; /* cmd 1 (command)
	/* Message Byte. First Bit is On */
	buf[0] = (0x80|(i&0x7f));
	/* following bytes do not use First Bit */
	/* data : 14bit. 1bit(signed) + 6bit[higer] + 7bit[lower] */
	
	buf[1] = (((*curMem)>>7) & 0x3f);
	if ( *(int*)curMem < 0 ) {
	  buf[1] |= 0x40; /* Minus Bit */
	}
	buf[2] = (0x7f & *curMem);
	len = cur_com->send(buf,sizeof(buf));
	*prevMem = *curMem;
      }
      curMem++;
      prevMem++;

    }
	

#if 0 /* Old Version */
    for ( i = 0; i < VDEV_TX_DATA_BODY_SIZE/4; i++ ) {
      if ( *curMem != *prevMem ) {
	send_command.elements[num].cmd_id = i * 4;
	send_command.elements[num].data = *curMem;
	*prevMem = *curMem;
	num++;
      }
      curMem++;
      prevMem++;
    }
#endif
    
    // Clear reset area
    if ( reset_area_off && reset_area_size ) {
      memset((char*)(VDEV_TX_DATA_BASE+reset_area_off),0,reset_area_size);
    }

#if 0    
    if ( num == 0 ) return STD_E_OK;
    send_command.com_header.cmd = 1;
    send_command.num = num;
    len = cur_com->send(&send_command,sizeof(RaspikeHeader)+sizeof(uint32_t)+sizeof(RaspikeBodyElement)*num);
#endif
    //    printf("Sent\n");

    
  }
  return STD_E_OK;

}

/* 受信スレッド */
static Std_ReturnType vdev_thread_do_init(MpthrIdType id)
{
  /* 受信用スレッドでsignalを受けると、ON_STACKの判定が効かなくなるため、受信プロセスではsignalを受け取らないようにする*/
  sigset_t sigset;
  sigemptyset(&sigset);
  sigaddset(&sigset,SIGUSR2);
  sigaddset(&sigset,SIGALRM);
  sigprocmask(SIG_BLOCK, &sigset, NULL);

  return STD_E_OK;
}

#define RASPIKE_RX_SIZE (11)
static Std_ReturnType vdev_thread_do_proc(MpthrIdType id)
{
	Std_ReturnType err;
	//	uint32 off = VDEV_RX_DATA_BASE - VDEV_BASE;
	uint64 curr_stime;
	char buf[256];
	int cmd_id;
	int val;

	memset(buf,0,sizeof(buf));
	
	while (1) {

	  /* Find header @ */
	  while (1) {
	    err = cur_com->receive(buf,1);
	    if ( buf[0] == '@' ) {
	      break;
	    }
	  }
	  err = cur_com->receive(buf,RASPIKE_RX_SIZE);	  

	  
	  if (err != STD_E_OK) {
	    continue;
	  }
	  //	  printf("Not=%s",buf);
	  sscanf(buf,"%d:%d",&cmd_id,&val);
	  //	  printf("cmd=%d val=%d\n",cmd_id,val);
	  if ( cmd_id < 0 || cmd_id >= (VDEV_RX_DATA_SIZE-VDEV_RX_DATA_BODY_OFF )) {
	    printf("cmd value error\n!");
	    continue;
	  }

	  char *p = VDEV_RX_DATA_BASE + cmd_id;

	  *(unsigned int*)p = *(unsigned int*)&val;
	  
	}

	return STD_E_OK;

}
