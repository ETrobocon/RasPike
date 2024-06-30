#ifndef _VDEV_COM_SERIAL_H_
#define _VDEV_COM_SERIAL_H_

extern Std_ReturnType vdevSerialInit(void *obj);
extern Std_ReturnType vdevSerialSend(const unsigned char *buf, int len);
extern Std_ReturnType vdevSerialReceive(unsigned char *buf, int len);


#endif /* _VDEV_COM_SERIAL_H_ */
