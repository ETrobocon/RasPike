#include <stdio.h>
#include <time.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "athrill_mpthread.h"
#include "std_types.h"
#include "std_errno.h"
#include "vdev.h"
#include "udp_comm.h"
#include "vdev_com_udp.h"
#include "devconfig.h"
#include "vdev_private.h"


#define ASSERT(val) assert(val)




Std_ReturnType vdevUdpInit(void *obj)
{
  Std_ReturnType err;
  uint32 portno;

  vdev_control.config.is_wait = TRUE;
  
  vdev_control.remote_ipaddr = "127.0.0.1";
  (void)cpuemu_get_devcfg_string("DEBUG_FUNC_VDEV_TX_IPADDR", &vdev_control.remote_ipaddr);
  printf("VDEV:TX IPADDR=%s\n", vdev_control.remote_ipaddr);
  err = cpuemu_get_devcfg_value("DEBUG_FUNC_VDEV_TX_PORTNO", &portno);
  if (err != STD_E_OK) {
    printf("ERROR: can not load param DEBUG_FUNC_VDEV_TX_PORTNO\n");
    ASSERT(err == STD_E_OK);
  }
  printf("VDEV:TX PORTNO=%d\n", portno);
  vdev_control.local_ipaddr = "127.0.0.1";
  (void)cpuemu_get_devcfg_string("DEBUG_FUNC_VDEV_RX_IPADDR", &vdev_control.local_ipaddr);
  printf("VDEV:RX IPADDR=%s\n", vdev_control.local_ipaddr);
  vdev_control.config.client_port = (uint16)portno;
  err = cpuemu_get_devcfg_value("DEBUG_FUNC_VDEV_RX_PORTNO", &portno);
  if (err != STD_E_OK) {
    printf("ERROR: can not load param DEBUG_FUNC_VDEV_RX_PORTNO\n");
    ASSERT(err == STD_E_OK);
  }
  vdev_control.config.server_port = (uint16)portno;
  printf("VDEV:RX PORTNO=%d\n", portno);
  
  err = udp_comm_create_ipaddr(&vdev_control.config, &vdev_control.comm, vdev_control.local_ipaddr);
  ASSERT(err == STD_E_OK);

  return err;
}


Std_ReturnType vdevUdpSend(const unsigned char *buf, int len)
{
  Std_ReturnType err;
  memcpy(vdev_control.comm.write_data.buffer,buf,len);
  vdev_control.comm.write_data.len = len;
  err = udp_comm_remote_write(&vdev_control.comm, vdev_control.remote_ipaddr);
  return err;
}
  
Std_ReturnType vdevUdpReceive(unsigned char *buf, int len)
{
  Std_ReturnType err;  
  err = udp_comm_read(&vdev_control.comm);
  if ( err == STD_E_OK ) {
    memcpy(buf, &vdev_control.comm.read_data.buffer[0], vdev_control.comm.read_data.len);
  }
  return err;
}
  
