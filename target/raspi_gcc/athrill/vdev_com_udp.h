#ifndef _VDEV_COM_UDP_H_
#define _VDEV_COM_UDP_H_

extern Std_ReturnType vdevUdpInit(void *obj);
extern Std_ReturnType vdevUdpSend(const unsigned char *buf, int len);
extern Std_ReturnType vdevUdpReceive(unsigned char *buf, int len);

#endif /*_VDEV_COM_UDP_H_*/
