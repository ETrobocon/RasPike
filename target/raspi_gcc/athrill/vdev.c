#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "main.h"
#include "vdev.h"
#include "vdev_if.h"
#include "devconfig.h"

#include "vdev_com_udp.h"
#include "vdev_private.h"

/* assume this area is cleared by C runtime */
unsigned char athrill_vdev_mem[VDEV_RX_DATA_SIZE+VDEV_TX_FLAG_SIZE+VDEV_TX_FLAG_SIZE];

VdevControlType vdev_control;

static const VdevIfComMethod *current_com = 0;

static const VdevIfComMethod VdevComUDP = {
  .init = vdevUdpInit,
  .send = vdevUdpSend,
  .receive = vdevUdpReceive
};


#include "vdev_prot_athrill.h"
static const VdevProtocolHandler *current_prot = 0;

/* Athrillと同じ形式のハンドラ*/
static const VdevProtocolHandler vdevProtAthrill = {
  .init = vdevProtAthrillInit

};


int initialize_vdev(void)
{
  printf("initialize vdev\n");
  memset(athrill_vdev_mem,0,sizeof(athrill_vdev_mem));


  /* Get Communication  Handler */
  /*
    UDP / SERIAL
  */
  char *comMethod;
  /* default */
  current_com = &VdevComUDP;

  if (cpuemu_get_devcfg_string("DEVICE_CONFIG_VDEV_COM", &comMethod) == STD_E_OK) {
    if ( !strcmp(comMethod,"UDP") ) {
      current_com = &VdevComUDP;
    } else {
    }
  }

  current_com->init();
  
  /* Protocol Type */
  /* ATHRILL / PROXY */
  /* default */
  current_prot = &vdevProtAthrill;
 
  if (cpuemu_get_devcfg_string("DEVICE_CONFIG_VDEV_PROTOCOL", &comMethod) == STD_E_OK) {
    if ( !strcmp(comMethod,"ATHRILL") ) {
      current_prot = &vdevProtAthrill;
    } else {
    }
  }

  current_prot->init(current_com);
  
  return 0;
}
  




__attribute__((constructor)) void vdev_initializer(void) 
{
  printf("vdev initializer called\n");
  deviceStartupCb = initialize_vdev;
}
