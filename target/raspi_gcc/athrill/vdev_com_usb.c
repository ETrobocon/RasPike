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
#include "vdev_if.h"

#include "devconfig.h"
#include "vdev_private.h"
#include "raspike_com.h"

static char serial_device[50];
static RPComDescriptor *fgDesc;

Std_ReturnType vdevUSBlInit(void *obj)
{
  char *dev_name = "/dev/ttyACM0";
  VdevIfComMethod *this = (VdevIfComMethod*)obj;
  
  Std_ReturnType err = cpuemu_get_devcfg_string("VDEV_SERIAL_DEV_NAME",&dev_name);
  if ( err != STD_E_OK ) {
    printf("VDEV_SERIAL_DEV_NAME not found. Use default device name\n");

  }
  strcpy(serial_device,dev_name);
  printf("VDEV USB name=%s\n",serial_device);
    
  this->info = (void*)raspike_open_usb_communication(serial_device);

  if ( this->info ) {
    fgDesc = this->info;
    return STD_E_OK;
  } else {
    return -1;
  }
  
}
  
Std_ReturnType vdevUSBSend(const unsigned char *buf, int len)
{
  // This function should not be used
  Std_ReturnType err = STD_E_OK;

  int ret = raspike_com_send(fgDesc,buf,len);

  if ( ret > 0 ) {
    return err;
  } else {
    return -1;
  }
}

Std_ReturnType vdevUSBReceive(unsigned char *buf, int len)
{
  // This function should not be used
  Std_ReturnType err = STD_E_OK;

  int ret = raspike_com_receive(fgDesc,buf,len);

  if ( ret > 0 ) {
    return err;
  } else {
    return -1;
  }
  
}
