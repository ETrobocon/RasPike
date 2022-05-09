#ifndef _UART_DRI_H_
#define _UART_DRI_H_

#include "platform_interface_layer.h"

typedef void (*uart_wait_mode_change_func)(uint8_t port,uint8_t mode, uint32_t *check_addr);
void uart_set_wait_mode_change_func(uart_wait_mode_change_func func);

extern void uart_dri_get_data_ultrasonic(uint8_t port, uint8_t mode, void *dest, SIZE size);
extern void uart_dri_get_data_gyro(uint8_t port,uint8_t mode, void *dest, SIZE size);
extern void uart_dri_get_data_touch(uint8_t port,uint8_t index, uint8_t mode, void *dest, SIZE size);
extern void uart_dri_get_data_color(uint8_t port,uint8_t index, uint8_t mode, void *dest, SIZE size);
extern void uart_dri_get_data_ir(uint8_t mode, void *dest, SIZE size);
extern void uart_dri_get_data_accel(uint8_t mode, void *dest, SIZE size);
extern void uart_dri_get_data_temp(uint8_t mode, void *dest, SIZE size);
extern void uart_dri_get_data_battery(uint8_t mode, void *dest, SIZE size);

extern void uart_dri_config_sensor(uint8_t port, uint8_t config);
extern void uart_dri_set_sensort_mode(uint8_t port, uint8_t mode);

#endif /* _UART_DRI_H_ */
