#ifndef _VDEV_COM_USB_H_
#define _VDEV_COM_USB_H_

extern Std_ReturnType vdevUSBlInit(void *obj);
extern Std_ReturnType vdevUSBSend(const unsigned char *buf, int len);
extern Std_ReturnType vdevUSBReceive(unsigned char *buf, int len);


#endif /* _VDEV_COM_USB_H_ */
