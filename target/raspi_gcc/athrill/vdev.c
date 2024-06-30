#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "main.h"
#include "vdev.h"
#include "vdev_if.h"
#include "devconfig.h"

#include "vdev_private.h"
#include "vdev_com_udp.h"
#include "vdev_com_serial.h"



/* assume this area is cleared by C runtime */
unsigned char athrill_vdev_mem[VDEV_RX_DATA_SIZE+VDEV_TX_FLAG_SIZE+VDEV_TX_FLAG_SIZE];

VdevControlType vdev_control;

static const VdevIfComMethod *current_com = 0;

static VdevIfComMethod VdevComUDP = {
  .init = vdevUdpInit,
  .send = vdevUdpSend,
  .receive = vdevUdpReceive,
  .info = 0
};

static VdevIfComMethod VdevComSerial = {
  .init = vdevSerialInit,
  .send = vdevSerialSend,
  .receive = vdevSerialReceive,
  .info = 0
};

#include "vdev_prot_athrill.h"
#include "vdev_prot_raspike.h"

static const VdevProtocolHandler *current_prot = 0;

/* Athrillと同じ形式のハンドラ*/
static const VdevProtocolHandler vdevProtAthrill = {
  .init = vdevProtAthrillInit

};

/* RasPi / SPIKE用コマンド*/
static const VdevProtocolHandler vdevProtRaspike = {
  .init = vdevProtRaspikeInit

};

#ifdef USE_RASPIKE_ART
#include "vdev_com_usb.h"
#include "vdev_prot_raspike_art.h"
/* RasPi-ART / SPIKE用コマンド*/

static VdevIfComMethod VdevComUSB = {
  .init = vdevUSBlInit,
  .send = vdevUSBSend,
  .receive = vdevUSBReceive,
  .info = 0
};


static const VdevProtocolHandler vdevProtRaspikeART = {
  .init = vdevProtRaspikeARTInit
};

#endif 




int initialize_vdev(void)
{
  printf("initialize vdev\n");
  memset(athrill_vdev_mem,0,sizeof(athrill_vdev_mem));

  /* Get Communication  Handler */
  /*
    UDP / SERIAL / USB
    USB is for RasPike-ART. RasPike-ART doesn't use VdevProtocolHandler 
  */
  char *comMethod;
  /* default */
  current_com = &VdevComUDP;

  if (cpuemu_get_devcfg_string("DEVICE_CONFIG_VDEV_COM", &comMethod) == STD_E_OK) {
    if ( !strcmp(comMethod,"UDP") ) {
      current_com = &VdevComUDP;
    } else if ( !strcmp(comMethod,"SERIAL")) {
      current_com = &VdevComSerial;
    }

#ifdef USE_RASPIKE_ART
    else if ( !strcmp(comMethod,"USB")) {
      current_com = &VdevComUSB;
    }
#endif    
  }

  if ( current_com )
    current_com->init((void*)current_com);
  
  /* Protocol Type */
  /* ATHRILL / PROXY */
  /* default */
  current_prot = &vdevProtAthrill;
 
  if (cpuemu_get_devcfg_string("DEVICE_CONFIG_VDEV_PROTOCOL", &comMethod) == STD_E_OK) {
    if ( !strcmp(comMethod,"ATHRILL") ) {
      current_prot = &vdevProtAthrill;
    } else if ( !strcmp(comMethod,"RASPIKE") ) {
      current_prot = &vdevProtRaspike;
    }

#ifdef USE_RASPIKE_ART    
    else if ( !strcmp(comMethod,"RASPIKE-ART") ) {
      current_prot = &vdevProtRaspikeART;
    }
#endif    
       
  }

  current_prot->init(current_com);
  
  return 0;
}
  




__attribute__((constructor)) void vdev_initializer(void) 
{
  printf("vdev initializer called\n");
  deviceStartupCb = initialize_vdev;
}
