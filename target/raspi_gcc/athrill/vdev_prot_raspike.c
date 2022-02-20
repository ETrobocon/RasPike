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

static char previous_sent_buffer[VDEV_TX_DATA_SIZE];

int vdevProtRaspikeInit(const VdevIfComMethod *com)
{
  Std_ReturnType err;

  cur_com = com;

  // 0 を設定された時に動作するように-1を設定する
  memset((char*)VDEV_TX_DATA_BASE,-1,VDEV_TX_DATA_BODY_SIZE);
  memset(previous_sent_buffer,-1,VDEV_TX_DATA_BODY_SIZE);
  
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

static void disable_interrupt(sigset_t *old)
{
  sigset_t sigset;
  sigemptyset(&sigset);

  sigaddset(&sigset,SIGUSR2);
  sigaddset(&sigset,SIGALRM);
  sigaddset(&sigset,SIGPOLL);
  sigprocmask(SIG_BLOCK, &sigset, old);
  return;
}

static void enable_interrupt(sigset_t *to_set)
{
  sigprocmask(SIG_SETMASK,to_set,NULL);
}

char *makeCommand(int cmd_id, int value, char *buf)
{
  int k = 0;
  /* Message Byte. First Bit is On */
  buf[k] = (0x80|(cmd_id&0x7f));
  /* following bytes do not use First Bit */
  /* data : 14bit. 1bit(signed) + 6bit[higer] + 7bit[lower] */
  k++;
  buf[k] = (((value)>>7) & 0x1f);
  if ( value < 0 ) {
    buf[k] |= 0x20; /* Minus Bit */
  }
  k++;
  buf[k] = (0x7f & value);
	
  return buf;
}

/* コンフィグ系のものを先に送るため、送信順を制御する*/
static int send_order[VDEV_TX_DATA_SIZE/4] =
  {56,57,58,59,60,61,62,63,64,65,66,67,0,1,2,3,4,5,6,7,8,9,10,11,12,13};

#define numof(table) (sizeof(table)/sizeof(table[0]))

/* IOメモリへの書き込み */
Std_ReturnType vdevProtRaspikeSilCb(int size, uint32 addr, void *data)
{
  int len;

  if ( size != 1 ) return STD_E_OK;

  if (addr == VDEV_TX_FLAG(0)) {
    sigset_t old_set;
    disable_interrupt(&old_set);
    


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
    char buf[3*256];
    int k = 0;
    struct timespec wait = {0,0.5*1000000}; // 0.5msec wait
    for ( i = 0; i < numof(send_order); i++ ) {
      int send_idx = send_order[i];
      curMem = (unsigned int *)(VDEV_TX_DATA_BASE) + send_idx;
      prevMem =  (unsigned int *)previous_sent_buffer + send_idx;
      if ( *curMem != *prevMem ) {
	int cmd = 1; /* cmd 1 (command) */
	int value = abs(*(int*)curMem);
	
	/* Message Byte. First Bit is On */
	buf[0] = (0x80|(send_idx&0x7f));
	/* following bytes do not use First Bit */
	/* data : 14bit. 1bit(signed) + 6bit[higer] + 7bit[lower] */
	k++;
	buf[1] = (((value)>>7) & 0x1f);
	if ( *(int*)curMem < 0 ) {
	  buf[k] |= 0x20; /* Minus Bit */
	}
	k++;
	buf[2] = (0x7f & value);
	
	len = cur_com->send(buf,3);
	nanosleep(&wait,0);
	*prevMem = *curMem;
	k++;
      }
      curMem++;
      prevMem++;

    }
    if ( k != 0 ) {
      //      len = cur_com->send(buf,k);
    } else {
      len = cur_com->send(makeCommand(127,0,buf),3);
    }
      // SPIKE側を起動させるために、10msecおきにコマンドは送る
      
      
    enable_interrupt(&old_set);      
	

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
  disable_interrupt(NULL);
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
	    } else {
	      printf("@=%x\n",buf[0]);
	    }
	  }
	  memset(buf,0,RASPIKE_RX_SIZE);
	  err = cur_com->receive(buf,RASPIKE_RX_SIZE);	  

	  
	  if (err != STD_E_OK) {
	    printf("Error!");
	    
	    continue;
	  }

	  //	   printf("Not=%s\n",buf);
	  sscanf(buf,"%d:%d",&cmd_id,&val);
	  //	  printf("cmd=%d val=%d\n",cmd_id,val);

	  if ( cmd_id < 0 || cmd_id >= (VDEV_RX_DATA_SIZE-VDEV_RX_DATA_BODY_OFF )) {
	    printf("cmd value error\n!");
	    continue;
	  }

	  char *p = VDEV_RX_DATA_BASE + cmd_id*4;

	  *(unsigned int*)p = *(unsigned int*)&val;
	  
	}

	return STD_E_OK;

}
