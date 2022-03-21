/*
 * Sensor.c
 *
 *  Created on: Oct 17, 2013
 *      Author: liyixiao
 */

#include "ev3api.h"

#include <t_stddef.h>
#include <t_syslog.h>
#include <string.h>
#include "platform_interface_layer.h"
#include "api_common.h"
#include "uart_dri.h"

static uint8_t get_sensor_index(sensor_port_t port, sensor_type_t type);

/**
 * Check whether a port number is valid
 */
#define CHECK_PORT(port) CHECK_COND((port) >= EV3_PORT_1 && (port) <= EV3_PORT_4, E_ID)

/*
 * Device type of sensors
 * NONE_SENSOR = not connected
 */
static sensor_type_t sensors[TNUM_SENSOR_PORT];
static uint8_t sensor_modes[TNUM_SENSOR_PORT] = {-1,-1,-1,-1};


static const analog_data_t *pAnalogSensorData = NULL;

/**
 * Functions to get data from analog sensor
 */

static inline
int16_t analog_sensor_get_pin1(sensor_port_t port) {
	return pAnalogSensorData[port].pin1[*pAnalogSensorData[port].actual];
}


/**
 * Fetch data from a UART sensor. If size is 0, switch mode only.
 */
static
void uart_sensor_fetch_data(sensor_port_t port, uint8_t mode, void *dest, SIZE size)
{
	sensor_type_t type = ev3_sensor_get_type(port);
	switch (type) {
		case ULTRASONIC_SENSOR:
		  uart_dri_get_data_ultrasonic(port, mode, dest, size);
			break;
		case GYRO_SENSOR:
		  uart_dri_get_data_gyro(port,mode, dest, size);
			break;
		case TOUCH_SENSOR:
			{
			  uint8_t index = get_sensor_index(port, type);
			  if (index != -1) {
			    uart_dri_get_data_touch(port, index, mode, dest, size);
			  }
			}
			break;
		case COLOR_SENSOR:
			{
				uint8_t index = get_sensor_index(port, type);
				if (index != -1) {
				  uart_dri_get_data_color(port,index, mode, dest, size);
				}
			}
			break;
		case INFRARED_SENSOR:
			uart_dri_get_data_ir(mode, dest, size);
			break;
		case HT_NXT_ACCEL_SENSOR:
			uart_dri_get_data_accel(mode, dest, size);
			break;
		case NXT_TEMP_SENSOR:
			uart_dri_get_data_temp(mode, dest, size);
			break;
		default:
			break;
	}
	//TODO
	return;
}

static uint8_t get_sensor_index(sensor_port_t port, sensor_type_t type)
{
	sensor_port_t i;
	uint8_t index = 0;
	for (i = 0; i < TNUM_SENSOR_PORT; i++) {
		if (sensors[i] == type) {
			if (port == i) {
				return index;
			}
			index++;
		}
	}
	/*
	 * not found.
	 */
	return -1;
}

static void set_sensor_mode(sensor_port_t port, uint8_t mode)
{
  if (sensor_modes[port] != mode) {
    //    uart_dri_set_sensor_mode(port,mode);
    sensor_modes[port] = mode;
  }
}
  

void _initialize_ev3api_sensor() {
	// TODO: Thread safe
	sensors[EV3_PORT_1]   = NONE_SENSOR;
	sensors[EV3_PORT_2]   = NONE_SENSOR;
	sensors[EV3_PORT_3]   = NONE_SENSOR;
	sensors[EV3_PORT_4]   = NONE_SENSOR;
	brickinfo_t brickinfo;
	ER ercd = fetch_brick_info(&brickinfo);
	assert(ercd == E_OK);
	//pAnalogSensorData = brickinfo.analog_sensors;
	//assert(pAnalogSensorData != NULL);
}

ER ev3_sensor_config(sensor_port_t port, sensor_type_t type)
{
	ER ercd;
	CHECK_PORT(port);


	/* RaSpike: send config when config is changed */
	if ( sensors[port] != type ) {
	  uart_dri_config_sensor(port,type);
	  uart_dri_set_sensor_mode(port,-1);
	}
	
	sensors[port] = type;
	ercd = E_OK;

error_exit:
	return ercd;
}

ER_UINT ev3_sensor_get_type(sensor_port_t port) {
	ER ercd;

//	lazy_initialize();
	CHECK_PORT(port);

	return sensors[port];

error_exit:
	return ercd;
}

typedef enum {
	COL_AMBIENT = 1,
	COL_COLOR   = 2,
	COL_REFLECT = 3,
	COL_RGBRAW  = 4,
} COLOR_SENSOR_MODES;

colorid_t ev3_color_sensor_get_color(sensor_port_t port) {
	ER ercd;

//	lazy_initialize();
	CHECK_PORT(port);
	CHECK_COND(ev3_sensor_get_type(port) == COLOR_SENSOR, E_OBJ);

	colorid_t val = COLOR_NONE;
	/* RaSpike */
	set_sensor_mode(port,COL_COLOR);
	
	uart_sensor_fetch_data(port, COL_COLOR, &val, sizeof(val));
	assert(val >= COLOR_NONE && val < TNUM_COLOR);
    return val;

error_exit:
	syslog(LOG_WARNING, "%s(): ercd %d", __FUNCTION__, ercd);
    return COLOR_NONE;
}

uint8_t ev3_color_sensor_get_reflect(sensor_port_t port) {
	ER ercd;

//	lazy_initialize();
	CHECK_PORT(port);
	CHECK_COND(ev3_sensor_get_type(port) == COLOR_SENSOR, E_OBJ);

	uint8_t val;
	/* RaSpike */
	set_sensor_mode(port,COL_REFLECT);
	uart_sensor_fetch_data(port, COL_REFLECT, &val, sizeof(val));
    return val;

error_exit:
    syslog(LOG_WARNING, "%s(): ercd %d", __FUNCTION__, ercd);
    return 0;
}

uint8_t ev3_color_sensor_get_ambient(sensor_port_t port) {
	ER ercd;

//	lazy_initialize();
	CHECK_PORT(port);
	CHECK_COND(ev3_sensor_get_type(port) == COLOR_SENSOR, E_OBJ);

	uint8_t val;
	/* RaSpike */
	set_sensor_mode(port,COL_AMBIENT);

	uart_sensor_fetch_data(port, COL_AMBIENT, &val, sizeof(val));
    return val;

error_exit:
    syslog(LOG_WARNING, "%s(): ercd %d", __FUNCTION__, ercd);
    return 0;
}

void ev3_color_sensor_get_rgb_raw(sensor_port_t port, rgb_raw_t *val) {
	ER ercd;

//	lazy_initialize();
	CHECK_PORT(port);
	CHECK_COND(ev3_sensor_get_type(port) == COLOR_SENSOR, E_OBJ);

	/* RaSpike */
	set_sensor_mode(port,COL_RGBRAW);

	uart_sensor_fetch_data(port, COL_RGBRAW, val, sizeof(rgb_raw_t));

    return;

error_exit:
    syslog(LOG_WARNING, "%s(): ercd %d", __FUNCTION__, ercd);
}

typedef enum {
	GYRO_ANG  = 1,
	GYRO_RATE = 2,
	GYRO_GnA  = 3,
	GYRO_CAL  = 4,
} GYRO_SENSOR_MODES;

int16_t ev3_gyro_sensor_get_angle(sensor_port_t port) {
	ER ercd;

//	lazy_initialize();
	CHECK_PORT(port);
	CHECK_COND(ev3_sensor_get_type(port) == GYRO_SENSOR, E_OBJ);

	int16_t val;
	/* RaSpike */
	set_sensor_mode(port,GYRO_ANG);

	uart_sensor_fetch_data(port, GYRO_ANG, &val, sizeof(val));
    return val;

error_exit:
    syslog(LOG_WARNING, "%s(): ercd %d", __FUNCTION__, ercd);
    return 0;
}

int16_t ev3_gyro_sensor_get_rate(sensor_port_t port) {
	ER ercd;

//	lazy_initialize();
	CHECK_PORT(port);
	CHECK_COND(ev3_sensor_get_type(port) == GYRO_SENSOR, E_OBJ);

	int16_t val;
	/* RaSpike */
	set_sensor_mode(port,GYRO_RATE);

	uart_sensor_fetch_data(port, GYRO_RATE, &val, sizeof(val));
    return val;

error_exit:
    syslog(LOG_WARNING, "%s(): ercd %d", __FUNCTION__, ercd);
    return 0;
}

ER ev3_gyro_sensor_reset(sensor_port_t port) {
	ER ercd;

//	lazy_initialize();
	CHECK_PORT(port);
	CHECK_COND(ev3_sensor_get_type(port) == GYRO_SENSOR, E_OBJ);

	//uart_sensor_switch_mode(port, GYRO_CAL);
	uart_sensor_fetch_data(port, GYRO_CAL, NULL, 0);

	return E_OK;

error_exit:
    syslog(LOG_WARNING, "%s(): ercd %d", __FUNCTION__, ercd);
    return ercd;
}

typedef enum {
	US_DIST_CM = 1,
	//	US_DIST_IN = 1,
	US_LISTEN  = 2,
} ULTRASONIC_SENSOR_MODES;

int16_t ev3_ultrasonic_sensor_get_distance(sensor_port_t port) {
	ER ercd;

//	lazy_initialize();
	CHECK_PORT(port);
	CHECK_COND(ev3_sensor_get_type(port) == ULTRASONIC_SENSOR, E_OBJ);

#if 0
    return ev3_uart_sensor_get_short(port) / 10;
#endif
	int16_t val = COLOR_NONE;

	/* RaSpike */
	set_sensor_mode(port,US_DIST_CM);

	uart_sensor_fetch_data(port, US_DIST_CM, &val, sizeof(val));

	/* RasPile Use original value */
	return val;

error_exit:
    syslog(LOG_WARNING, "%s(): ercd %d", __FUNCTION__, ercd);
    return 0;
}

bool_t ev3_ultrasonic_sensor_listen(sensor_port_t port) {
	ER ercd;

//	lazy_initialize();
	CHECK_PORT(port);
	CHECK_COND(ev3_sensor_get_type(port) == ULTRASONIC_SENSOR, E_OBJ);

	/* RaSpike */
	set_sensor_mode(port,US_LISTEN);
	
	// TODO: TEST THIS API!
	bool_t val;
	uart_sensor_fetch_data(port, US_LISTEN, &val, sizeof(val));
    return val;

error_exit:
    syslog(LOG_WARNING, "%s(): ercd %d", __FUNCTION__, ercd);
    return false;
}

typedef enum {
	IR_DIST   = 0,
	IR_SEEK   = 1,
	IR_REMOTE = 2,
} INFRARED_SENSOR_SENSOR_MODES;

int8_t ev3_infrared_sensor_get_distance(sensor_port_t port) {
	ER ercd;

//	lazy_initialize();
	CHECK_PORT(port);
	CHECK_COND(ev3_sensor_get_type(port) == INFRARED_SENSOR, E_OBJ);

	int8_t val;
	uart_sensor_fetch_data(port, IR_DIST, &val, sizeof(val));
	return val;

error_exit:
	syslog(LOG_WARNING, "%s(): ercd %d", __FUNCTION__, ercd);
	return 0;
}

ir_seek_t ev3_infrared_sensor_seek(sensor_port_t port) {
	ir_seek_t result;
	ER ercd;
	int i;

//	lazy_initialize();
	CHECK_PORT(port);
	CHECK_COND(ev3_sensor_get_type(port) == INFRARED_SENSOR, E_OBJ);

	int8_t val[8];
	uart_sensor_fetch_data(port, IR_SEEK, &val, 8 * sizeof(int8_t));
	for (i = 0; i < 4; i++) {
		result.heading [i] = val[2 * i];
		result.distance[i] = val[2 * i + 1];
	}
	return result;

error_exit:
	syslog(LOG_WARNING, "%s(): ercd %d", __FUNCTION__, ercd);
	for (i = 0; i < 4; i++) {
		result.heading [i] = 0;
		result.distance[i] = -128;
	}
	return result;
}

ir_remote_t ev3_infrared_sensor_get_remote(sensor_port_t port) {
	ir_remote_t result;
	ER ercd;
	int i;

//	lazy_initialize();
	CHECK_PORT(port);
	CHECK_COND(ev3_sensor_get_type(port) == INFRARED_SENSOR, E_OBJ);

	uint8_t val[4];
	uart_sensor_fetch_data(port, IR_REMOTE, &val, 4 * sizeof(uint8_t));
	for (i = 0; i < 4; i++) {
		switch(val[i])
		{
		case 0:  // no buttons pressed
			result.channel[i] = 0;
			continue;
		case 1:  // red up
			result.channel[i] = IR_RED_UP_BUTTON;
			continue;
		case 2:  // red down
			result.channel[i] = IR_RED_DOWN_BUTTON;
			continue;
		case 3:  // blue up
			result.channel[i] = IR_BLUE_UP_BUTTON;
			continue;
		case 4:  // blue down
			result.channel[i] = IR_BLUE_DOWN_BUTTON;
			continue;
		case 5:  // red up and blue up
			result.channel[i] = IR_RED_UP_BUTTON + IR_BLUE_UP_BUTTON;
			continue;
		case 6:  // red up and blue down
			result.channel[i] = IR_RED_UP_BUTTON + IR_BLUE_DOWN_BUTTON;
			continue;
		case 7:  // red down and blue up
			result.channel[i] = IR_RED_DOWN_BUTTON + IR_BLUE_UP_BUTTON;
			continue;
		case 8:  // red down and blue down
			result.channel[i] = IR_RED_DOWN_BUTTON + IR_BLUE_DOWN_BUTTON;
			continue;
		case 9:  // beacon mode on
			result.channel[i] = IR_BEACON_BUTTON;
			continue;
		case 10: // red up and red down
			result.channel[i] = IR_RED_UP_BUTTON + IR_RED_DOWN_BUTTON;
			continue;
		case 11: // blue up and blue down
			result.channel[i] = IR_BLUE_UP_BUTTON + IR_BLUE_DOWN_BUTTON;
		}
	}
	return result;

error_exit:
	syslog(LOG_WARNING, "%s(): ercd %d", __FUNCTION__, ercd);
	for (i = 0; i < 4; i++) {
		result.channel[i] = 0;
	}
	return result;
}

bool_t ev3_touch_sensor_is_pressed(sensor_port_t port) {
	ER ercd;

//	lazy_initialize();
	CHECK_PORT(port);
	CHECK_COND(ev3_sensor_get_type(port) == TOUCH_SENSOR, E_OBJ);

	int16_t val;
	uart_sensor_fetch_data(port, 0U, &val, sizeof(val));

    return val > (ADC_RES / 2);

error_exit:
    syslog(LOG_WARNING, "%s(): ercd %d", __FUNCTION__, ercd);
    return false;
}

bool_t ht_nxt_accel_sensor_measure(sensor_port_t port, int16_t axes[3]) {
	ER ercd;

	CHECK_PORT(port);
	CHECK_COND(ev3_sensor_get_type(port) == HT_NXT_ACCEL_SENSOR, E_OBJ);

	uart_sensor_fetch_data(port, 0U, axes, sizeof(int16_t) * 3);

	return true;

error_exit:
	syslog(LOG_WARNING, "%s(): ercd %d", __FUNCTION__, ercd);
	return false;
}

bool_t nxt_temp_sensor_measure(sensor_port_t port, float *temp) {
	ER ercd;
	int16_t raw;

	CHECK_PORT(port);
	CHECK_COND(ev3_sensor_get_type(port) == NXT_TEMP_SENSOR, E_OBJ);

	uart_sensor_fetch_data(port, 0U, &raw, sizeof(raw));
    *temp = raw * 0.0625f;
	return true;

error_exit:
	syslog(LOG_WARNING, "%s(): ercd %d", __FUNCTION__, ercd);
	return false;
}

