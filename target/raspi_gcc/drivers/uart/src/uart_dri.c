#include "uart_dri.h"
#include "ev3_vdev.h"
#include "sil.h"
#include <string.h>

void uart_dri_get_data_ultrasonic(uint8_t mode, void *dest, SIZE size)
{
	uint32_t data;
	const uint32_t *addr;
	switch (mode) {
	case 0:
		addr = (const uint32_t *)EV3_SENSOR_ADDR_ULTRASONIC;
		break;
	case 2:
		addr = (const uint32_t *)EV3_SENSOR_ADDR_ULTRASONIC_LISTEN;
		break;
	default:
		return;
	}
	data = sil_rew_mem(addr);

	switch (mode) {
	case 0:
		// get_distance uses int16_t
		*(int16_t*)dest = (int16_t)data;
		break;
	case 2:
		*(bool_t*)dest = (bool_t)(!(data == 0));
		break;
	}
	//memcpy(dest, (void*)&data, sizeof(data));
	return;
}
void uart_dri_get_data_gyro(uint8_t mode, void *dest, SIZE size)
{
	uint16_t data;
	const uint32_t *addr;
	switch (mode) {
	case 0:
		addr = (const uint32_t *)EV3_SENSOR_ADDR_ANGLE;
		break;
	case 1:
		addr = (const uint32_t *)EV3_SENSOR_ADDR_RATE;
		break;
	case 4:
	    {
			// Gyro Reset sends reset (write command)
			uint32_t *waddr = (uint32_t *)EV3_GYRO_ADDR_RESET;
			sil_wrw_mem(waddr,1);
			sil_wrw_mem((uint32_t *)EV3_SENSOR_ADDR_ANGLE,0);
			sil_wrw_mem((uint32_t *)EV3_SENSOR_ADDR_RATE,0);
			return;
		}
	default:
		return;
	}
	data = sil_rew_mem(addr);
	memcpy(dest, (void*)&data, sizeof(data));
	return;
}
void uart_dri_get_data_touch(uint8_t index, uint8_t mode, void *dest, SIZE size)
{
	uint16_t data ;
	uint32_t *addr;

	if (index == 0) {
		addr = (uint32_t *)EV3_SENSOR_ADDR_TOUCH_0;
	}
	else {
		addr = (uint32_t *)EV3_SENSOR_ADDR_TOUCH_1;
	}
	data = (uint16_t)sil_rew_mem(addr);
	memcpy(dest, (void*)&data, sizeof(data));
	return;
}
typedef enum {
	DRI_COL_REFLECT = 0,
	DRI_COL_AMBIENT = 1,
	DRI_COL_COLOR   = 2,
	DRI_COL_RGBRAW  = 4,
} DRI_COLOR_SENSOR_MODES;

void uart_dri_get_data_color(uint8_t index, uint8_t mode, void *dest, SIZE size)
{
	uint8_t *data8 = (uint8_t*)dest;
	uint16_t *array = (uint16_t*)dest;
	DRI_COLOR_SENSOR_MODES dri_mode = mode;
	if (dri_mode == DRI_COL_REFLECT) {
		*data8 = (uint8_t)sil_rew_mem( (const uint32_t *)EV3_SENSOR_ADDR_REFLECT(index));
	}
	else if (dri_mode == DRI_COL_AMBIENT) {
		*data8 = (uint8_t)sil_rew_mem( (const uint32_t *)EV3_SENSOR_ADDR_AMBIENT(index));
	} else if ( dri_mode == DRI_COL_COLOR ) {
		*data8 = (uint8_t)sil_rew_mem( (const uint32_t *)EV3_SENSOR_ADDR_COLOR(index));
	} else {
		array[0] = (uint16_t)sil_rew_mem( (const uint32_t *)EV3_SENSOR_ADDR_RGB_R(index));
		array[1] = (uint16_t)sil_rew_mem( (const uint32_t *)EV3_SENSOR_ADDR_RGB_G(index));
		array[2] = (uint16_t)sil_rew_mem( (const uint32_t *)EV3_SENSOR_ADDR_RGB_B(index));
	}
	return;
}
void uart_dri_get_data_ir(uint8_t mode, void *dest, SIZE size)
{
	int8_t *array = (int8_t*)dest;
	switch (mode) {
	case 0:
		array[0] = (int8_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_IR_D);
		break;
	case 1:
		array[0] = (int8_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_IR_0_H);
		array[1] = (int8_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_IR_0_D);
		array[2] = (int8_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_IR_1_H);
		array[3] = (int8_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_IR_1_D);
		array[4] = (int8_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_IR_2_H);
		array[5] = (int8_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_IR_2_D);
		array[6] = (int8_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_IR_3_H);
		array[7] = (int8_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_IR_3_D);
		break;
	case 2:
		array[0] = (int8_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_IR_0);
		array[1] = (int8_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_IR_1);
		array[2] = (int8_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_IR_2);
		array[3] = (int8_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_IR_3);
		break;
	default:
		return;
	}
	return;
}
void uart_dri_get_data_accel(uint8_t mode, void *dest, SIZE size)
{
	int16_t *array = (int16_t*)dest;
	array[0] = (uint16_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_AXES_X);
	array[1] = (uint16_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_AXES_Y);
	array[2] = (uint16_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_AXES_Z);
	return;
}
void uart_dri_get_data_temp(uint8_t mode, void *dest, SIZE size)
{
	int16_t *array = (int16_t*)dest;
	array[0] = (uint16_t)sil_rew_mem((const uint32_t *)EV3_SENSOR_ADDR_TMP);
	return;
}

void uart_dri_get_data_battery(uint8_t mode, void *dest, SIZE size)
{
	// mode 0 : current / mode 1: voltage
	int32_t *p = (int32_t*)dest;
	int32_t data;
	const uint32_t *addr = ((mode == 0 ) ? (const uint32_t *)EV3_BATTERY_ADDR_CURRENT:  (const uint32_t *)EV3_BATTERY_ADDR_VOLTAGE);
	data = (uint32_t)sil_rew_mem(addr);
	*p = data;
	return;

}
