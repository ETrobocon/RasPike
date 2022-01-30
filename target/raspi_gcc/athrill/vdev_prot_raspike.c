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

  
#if 0  
  mpthread_init();

  err = mpthread_register(&vdev_thrid, &vdev_op);
  ASSERT(err == STD_E_OK);

  err = mpthread_start_proc(vdev_thrid);
  ASSERT(err == STD_E_OK);
#endif  
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
    static char previous_sent_buffer[VDEV_TX_DATA_SIZE/4];

    if ( previous_sent.tv_sec == 0 ) {
      save_sent_time();
    }
    printf("Time:%d\n",get_time_from_previous_sending());
    
    // Check Difference
    int i;
    int num = 0;
    // unsigned int access
    unsigned int *curMem = (unsigned int *)(VDEV_TX_DATA_BASE);
    unsigned int *prevMem = (unsigned int *)previous_sent_buffer;
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
    // Clear reset area
    if ( reset_area_off && reset_area_size ) {
      memset((char*)(VDEV_TX_DATA_BASE+reset_area_off),0,reset_area_size);
    }

    
    if ( num == 0 ) return STD_E_OK;
    send_command.com_header.cmd = 1;
    send_command.num = num;
    len = cur_com->send(&send_command,sizeof(RaspikeHeader)+sizeof(uint32_t)+sizeof(RaspikeBodyElement)*num);
    printf("Sent\n");

    
  }
  return STD_E_OK;
#if 0  
  if ( addr < VDEV_TX_DATA_BASE || addr >= VDEV_TX_DATA_BASE + VDEV_TX_DATA_BODY_SIZE) {
    return STD_E_OK;
  }
  if ( size != 4 ) return STD_E_OK;
  memcpy(&header,&common_header,sizeof(common_header));
  header.com_header.cmd = 1;
  header.elem_num = 1;

  lock_task();
  len = cur_com->send(&header,sizeof(header));
 
  if ( len != STD_E_OK ) {
    printf("Write Header Error errno=%d\n",errno);
    exit(-1);
  }

  RaspikeBodyElement body;

  int cmd_id = addr - VDEV_TX_DATA_BASE;
  body.cmd_id = cmd_id;
  memcpy(body.buf,data,size);
  int send_size = sizeof(body.cmd_id)+size;
  
  len = cur_com->send(&body,send_size);

  unlock_task();
  if ( len != STD_E_OK ) {
    printf("Write Command Body Error ret=%d sendsize=%d errno=%d",len,send_size,errno);
    exit(-1);
  }
  //printf("Command Write Success cmd_id=%d size=%d val=%d\n",cmd_id,size,*(int*)data);
#endif
  return STD_E_OK;
}
