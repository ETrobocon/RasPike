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
// For RasPike-ART
#include "raspike_protocol_api.h"

static MpthrIdType vdev_thrid;

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


static Std_ReturnType vdevProtRaspikeSilCb(unsigned int size, unsigned int addr, const void* data);

static Std_ReturnType vdev_thread_do_init(MpthrIdType id);
static Std_ReturnType vdev_thread_do_proc(MpthrIdType id);

static MpthrOperationType vdev_op = {
	.do_init = vdev_thread_do_init,
	.do_proc = vdev_thread_do_proc,
};

int vdevProtRaspikeARTInit(const VdevIfComMethod *com)
{
  Std_ReturnType err;
  
  RPComDescriptor *desc = (RPComDescriptor*)com->info;
  
  /* デバイスIOに書き込んだ際に呼ばれるコールバック関数 */
  SilSetWriteHook((const SilWriteHook)vdevProtRaspikeSilCb);

  raspike_prot_init(desc);
  
  mpthread_init();

  err = mpthread_register(&vdev_thrid, &vdev_op);
  err = mpthread_start_proc(vdev_thrid);

  err; // for avoid warning
  return 0;
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

/* IOメモリへの書き込み */
Std_ReturnType vdevProtRaspikeSilCb(unsigned int size, unsigned int  addr, const void *data)
{
  if (addr != VDEV_TX_FLAG(0)) {
    // Called EV3 API. But RasPike-ART does not support it.
  
    printf("[WARN] RasPike-ART does not support EV3 API(addr = %x)\n",addr);

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

static Std_ReturnType vdev_thread_do_proc(MpthrIdType id)
{
  while(1) {
    raspike_prot_receive();
  }

  enable_interrupt(NULL);

  return STD_E_OK;

}
