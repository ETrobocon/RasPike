#include <stdio.h>
#include <time.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <sys/time.h>
#include "athrill_mpthread.h"
#include "std_types.h"
#include "std_errno.h"
#include "vdev.h"
#include "devconfig.h"
#include "vdev_private.h"
#include "vdev_com_serial.h"

static char serial_device[50];
static int  device_fd = 0;




Std_ReturnType vdevSerialInit(void *obj)
{
  Std_ReturnType err;
  char *dev_name = "/dev/ttyAMA1";

  struct termios tio;                 // シリアル通信設定
  
  err = cpuemu_get_devcfg_string("VDEV_SERIAL_DEV_NAME",&dev_name);
  if ( err != STD_E_OK ) {
    printf("VDEV_SERIAL_DEV_NAME not found. Use default device name\n");

  }
  strcpy(serial_device,dev_name);
  printf("VDEV serial name=%s\n",serial_device);
  
  device_fd = open(serial_device,O_RDWR);

  if ( device_fd < 0 ) {
    printf("Device not found errno = %d\n",errno);
    exit(-1);
  }

  printf("Serial Opened fd=%d\n",device_fd);

  bzero(&tio, sizeof(tio));
  tcgetattr(&tio,0);
  tio.c_cflag =  (B115200 | CS8 | CLOCAL | CREAD);
  tio.c_cc[VMIN] = 0;
  tio.c_cc[VTIME] = 0;
  tcflush(device_fd, TCIFLUSH);
  tcsetattr(device_fd,TCSANOW,&tio);

#if 0
  while(1) {
    struct timespec req = {0, 10 * 1000000};
    const char *test = "test\n";
    write(device_fd,test,6);
    nanosleep(&req,0);
    
  }
#endif  
  return STD_E_OK;
}
  
Std_ReturnType vdevSerialSend(const unsigned char *buf, int len)
{
  Std_ReturnType err;

  struct timespec ns = { 0, 1 * 500000 }; // 0.5msec
  
  err = write(device_fd,buf,len);
  if ( err != len ) {
    printf("Write Error err=%d\n",errno);
    return -1;
  }
  nanosleep(&ns,0);
  
  return STD_E_OK;
}

Std_ReturnType vdevSerialReceive(unsigned char *buf, int len)
{

  Std_ReturnType err;

  unsigned char *p = buf;
  int left = len;

  struct timespec ns = { 0, 1 * 1000000 }; // 1msec
  
  while (1) {
    while(1) {
      err = read(device_fd,p,left);
      if ( err != 0 ) {
	break;
      }
      nanosleep(&ns,0);
    } 
    if ( err < 0 ) {
      printf("read error errno=%d\n",errno);
      return -1;
    }

    left = left - err;
    p+=err;
    if ( left == 0 ) {
      break;
    }

  }
  *p = 0;
  return STD_E_OK;
}
