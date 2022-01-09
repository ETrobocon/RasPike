#ifndef _UART_DRI_H_
#define _UART_DRI_H_

#include "platform_interface_layer.h"

extern void uart_dri_get_data_ultrasonic(uint8_t mode, void *dest, SIZE size);
extern void uart_dri_get_data_gyro(uint8_t mode, void *dest, SIZE size);
extern void uart_dri_get_data_touch(uint8_t index, uint8_t mode, void *dest, SIZE size);
extern void uart_dri_get_data_color(uint8_t index, uint8_t mode, void *dest, SIZE size);
extern void uart_dri_get_data_ir(uint8_t mode, void *dest, SIZE size);
extern void uart_dri_get_data_accel(uint8_t mode, void *dest, SIZE size);
extern void uart_dri_get_data_temp(uint8_t mode, void *dest, SIZE size);
extern void uart_dri_get_data_battery(uint8_t mode, void *dest, SIZE size);

#endif /* _UART_DRI_H_ */
