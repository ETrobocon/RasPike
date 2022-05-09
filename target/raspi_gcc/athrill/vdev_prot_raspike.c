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
#include <pthread.h>
#include "uart_dri.h"
#include "sil.h"
#include "ev3_vdev.h"

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

static pthread_cond_t cond = PTHREAD_COND_INITIALIZER;
static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;


static char previous_sent_buffer[VDEV_TX_DATA_SIZE];

#define RASPIKE_NOT_USED (999999)
static void raspike_uart_wait_mode_change(uint8_t port,uint8_t mode, uint32_t *check_addr)
{

  /* まずvalueを通信上使われない999999に変更する */
  sil_wrw_mem(check_addr,RASPIKE_NOT_USED);

  /* モードチェンジのコマンドを送出する*/
  sil_wrw_mem((uint32_t *)EV3_SENSOR_MODE_INX(port),mode);
  volatile uint32_t *addr = check_addr;
    
  /* Ackは受け取ったが、実際に値としてRASPIKE_NOT_USED 以外の値が設定されることを待つ */
  struct timespec t = {0,10*1000000};
    
  do {
    uint32_t data = sil_rew_mem(addr);
    //printf("port=%d val=%d\n",port,data);
    if ( data != RASPIKE_NOT_USED ) {
      break;
    }
    nanosleep(&t,0);
  } while(1);
}





int vdevProtRaspikeInit(const VdevIfComMethod *com)
{
  Std_ReturnType err;

  cur_com = com;

  // 0 を設定された時に動作するように-1を設定する
  memset((char*)VDEV_TX_DATA_BASE,0,VDEV_TX_DATA_BODY_SIZE);
  memset(previous_sent_buffer,0,VDEV_TX_DATA_BODY_SIZE);
  
  /* デバイスIOに書き込んだ際に呼ばれるコールバック関数 */
  SilSetWriteHook(vdevProtRaspikeSilCb);
  
  // Uart Driverへのコールバック
  uart_set_wait_mode_change_func(raspike_uart_wait_mode_change);
  
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

static uint32 get_msec_from_previous_time(const struct timespec *now,const struct timespec *before)
{
	return (uint32)((uint64)(now->tv_sec-before->tv_sec)*1000000000 + (uint64)now->tv_nsec-(uint64)before->tv_nsec)/1000000;
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
typedef struct {
  uint32_t cmd_id;
  int      do_wait_ack;
} RasPikeCommand;

#define WAIT_ACK_COMMAND(cmd) {cmd,1}
#define ONE_WAY_COMMAND(cmd) {cmd,0}

static volatile int ack_received[256] = {0};

static RasPikeCommand send_order[] = {
  ONE_WAY_COMMAND(56), /* SENSOR_1 Config */
  ONE_WAY_COMMAND(57), /* SENSOR_2 Config */
  ONE_WAY_COMMAND(58), /* SENSOR_3 Config */
  ONE_WAY_COMMAND(59), /* SENSOR_4 Config */
  WAIT_ACK_COMMAND(60), /* SENSOR_1 Mode */
  WAIT_ACK_COMMAND(61), /* SENSOR_2 Mode */
  WAIT_ACK_COMMAND(62), /* SENSOR_3 Mode */
  WAIT_ACK_COMMAND(63), /* SENSOR_4 Mode */
  ONE_WAY_COMMAND(64), /* MOTOR_A Config */
  ONE_WAY_COMMAND(65), /* MOTOR_B Config */
  ONE_WAY_COMMAND(66), /* MOTOR_C Config */
  ONE_WAY_COMMAND(67), /* MOTOR_D Config */
  WAIT_ACK_COMMAND(5), /* MOTOR_A Stop */
  WAIT_ACK_COMMAND(6), /* MOTOR_B Stop */
  WAIT_ACK_COMMAND(7), /* MOTOR_C Stop */
  WAIT_ACK_COMMAND(8), /* MOTOR_D Stop */
  WAIT_ACK_COMMAND(9), /* MOTOR_A Reset */
  WAIT_ACK_COMMAND(10), /* MOTOR_B Reset */
  WAIT_ACK_COMMAND(11), /* MOTOR_C Reset */
  WAIT_ACK_COMMAND(12), /* MOTOR_D Reset */
  WAIT_ACK_COMMAND(13), /* GYRO Reset */
  ONE_WAY_COMMAND(1),   /* MOTOR_A Power */
  ONE_WAY_COMMAND(2),   /* MOTOR_B Power */
  ONE_WAY_COMMAND(3),   /* MOTOR_C Power */
  ONE_WAY_COMMAND(4),   /* MOTOR_D Power */
  ONE_WAY_COMMAND(0), /* Panel LED */  
};

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
      int send_idx = send_order[i].cmd_id;
      curMem = (unsigned int *)(VDEV_TX_DATA_BASE) + send_idx;
      prevMem =  (unsigned int *)previous_sent_buffer + send_idx;
      if ( *curMem != *prevMem ) {
	int cmd = 1; /* cmd 1 (command) */
	int value = abs(*(int*)curMem);

	
	/* Message Byte. First Bit is On */
	buf[0] = (0x80|(send_idx&0x7f));
	/* following bytes do not use First Bit */
	/* data : 14bit. 1bit(signed) + 6bit[higer] + 7bit[lower] */
	buf[1] = (((value)>>7) & 0x1f);
	if ( *(int*)curMem < 0 ) {
	  buf[1] |= 0x20; /* Minus Bit */
	}
	k++;
	buf[2] = (0x7f & value);

	struct timespec next,now;
	int can_exit = 0;
	ack_received[send_idx] = 0;
	do {
	  len = cur_com->send(buf,3);
	  nanosleep(&wait,0);

	  if ( !send_order[i].do_wait_ack ) {
	    break;
	  }
	  timespec_get(&now, TIME_UTC);
	  /* Wait Ack */
	  volatile uint32_t *p = (ack_received+send_idx); 
	  /* Retry time = 500msec */
	  next.tv_nsec = now.tv_nsec + 500*1000000;
	  next.tv_sec  = now.tv_sec;
	  if ( next.tv_nsec >= 1000000000 ) {
	    next.tv_nsec = next.tv_nsec - 1000000000;
	    next.tv_sec++;
	  }
	  pthread_mutex_lock(&mutex);

	  while (1) {
	    if ( *p ) {
	      can_exit = 1;
	      break;
	    }
	    int ret = pthread_cond_timedwait(&cond,&mutex,&next);
	    if ( ret == ETIMEDOUT ) {
	      /* Retry */
	      timespec_get(&now, TIME_UTC);	      
	      //printf("Resend %d %d.%d\n",send_idx,now.tv_sec,now.tv_nsec/1000000);
	      break;
	    }
	  }
	  pthread_mutex_unlock(&mutex);	  

	  if ( can_exit ) {
	    struct timespec cur;
	    timespec_get(&cur, TIME_UTC);	      
	    //	    printf("Cmd=%d spends %d msec\n",send_idx,get_msec_from_previous_time(&cur,&now));
	    break;
	  }
	} while(1);

	*prevMem = *curMem;
	k++;
      }
    }
    if ( k != 0 ) {
      //      len = cur_com->send(buf,k);
    } else {
      len = cur_com->send(makeCommand(127,0,buf),3);
    }
      // SPIKE側を起動させるために、10msecおきにコマンドは送る
      
      
    enable_interrupt(&old_set);      
	

    // Clear reset area
    if ( reset_area_off && reset_area_size ) {
      memset((char*)(VDEV_TX_DATA_BASE+reset_area_off),0,reset_area_size);
    }

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
	int type;
	int cmd_id;
	int val;
	
	memset(buf,0,sizeof(buf));
	
	while (1) {

	  /* Find header @ */
	  while (1) {
	    err = cur_com->receive(buf,1);

	    if ( buf[0] == '@' || buf[0] == '<') {
	      /* type 0 is status, 1 is ack */
	      type = (buf[0]=='@'?0:1);
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
	  //	  printf("type=%d cmd=%d val=%d\n",type,cmd_id,val);

	  if ( cmd_id < 0 || cmd_id >= (VDEV_RX_DATA_SIZE-VDEV_RX_DATA_BODY_OFF )) {
	    printf("cmd value error\n!");
	    continue;
	  }

	  if ( type == 0 ) {
	    /* status */
	    char *p = VDEV_RX_DATA_BASE + cmd_id*4;

	    *(unsigned int*)p = *(unsigned int*)&val;
	    //	    printf("OFFSET=%d value=%d\n",cmd_id*4,val);
	  } else {
	    if ( cmd_id != 127 ) {
	      /* ack */
	      pthread_mutex_lock(&mutex);  
	      ack_received[cmd_id] = 1;
	      pthread_cond_broadcast(&cond);
	      pthread_mutex_unlock(&mutex);
	    }
	  }
	}

	return STD_E_OK;

}
