/*
 * Motor.c
 *
 *  Created on: Oct 17, 2013
 *      Author: liyixiao
 */

#include "ev3api.h"
#include "platform_interface_layer.h"
#include "api_common.h"
#include "motor_dri.h"

/**
 * Check whether a port number is valid
 */
#define CHECK_PORT(port) CHECK_COND((port) >= EV3_PORT_A && (port) <= EV3_PORT_D, E_ID)

/**
 * Check whether a port is connected (or initialized)
 */
#define CHECK_PORT_CONN(port) CHECK_COND(getDevType(mts[(port)]) != TYPE_NONE, E_OBJ)
#define CHECK_MOTOR_TYPE(type) CHECK_COND(type >= NONE_MOTOR && type <= (NONE_MOTOR + TNUM_MOTOR_TYPE - 1), E_PAR)


/**
 * Type of motors
 */
static motor_type_t mts[TNUM_MOTOR_PORT];

static inline
int getDevType(motor_type_t type) {
	switch(type) {
	case NONE_MOTOR:
		return TYPE_NONE;
		break;

	case MEDIUM_MOTOR:
		return TYPE_MINITACHO;
		break;

	case LARGE_MOTOR:
	case UNREGULATED_MOTOR: // TODO: check this
		return TYPE_TACHO;
		break;

	default:
		API_ERROR("Invalid motor type %d", type);
		return TYPE_NONE;
	}
}

void _initialize_ev3api_motor()
{
	mts[EV3_PORT_A]   = NONE_MOTOR;
	mts[EV3_PORT_B]   = NONE_MOTOR;
	mts[EV3_PORT_C]   = NONE_MOTOR;
	mts[EV3_PORT_D]   = NONE_MOTOR;
	return;
}

ER ev3_motor_config(motor_port_t port, motor_type_t type) {
	ER ercd;
	int i;

	CHECK_PORT(port);
	CHECK_MOTOR_TYPE(type);

	mts[port] = type;

    /*
     * Set Motor Type
     */
    char buf[TNUM_MOTOR_PORT + 1];
    buf[0] = opOUTPUT_SET_TYPE;
    for (i = EV3_PORT_A; i < TNUM_MOTOR_PORT; ++i) {
        buf[i + 1] = getDevType(mts[i]);
    }
    motor_command(buf, sizeof(buf));

    /*
     * Set initial state to IDLE
     */
    buf[0] = opOUTPUT_STOP;
    buf[1] = port;
    buf[2] = 0;
    motor_command(buf, sizeof(buf));

    ercd = E_OK;

error_exit:
    return ercd;
}

ER_UINT ev3_motor_get_type(motor_port_t port) {
	ER ercd;

	CHECK_PORT(port);

	return mts[port];

error_exit:
	return ercd;
}

int32_t ev3_motor_get_counts(motor_port_t port)
{
	ER ercd;

	CHECK_PORT(port);
	CHECK_PORT_CONN(port);

    char buf[8];
	int32_t *counts = (int32_t*)&buf[4];

    buf[0] = opOUTPUT_GET_COUNT;
    buf[1] = port;
    motor_command(buf, sizeof(buf));


	return *counts;

error_exit:
	assert(ercd != E_OK);
	syslog(LOG_ERROR, "%s(): Failed to get motor counts, ercd: %d", __FUNCTION__, ercd);
	return 0;
}

static int motor_power[TNUM_MOTOR_PORT];

int ev3_motor_get_power(motor_port_t port)
{
	ER ercd;

	CHECK_PORT(port);
	CHECK_PORT_CONN(port);

	return motor_power[port];

error_exit:
	assert(ercd != E_OK);
	syslog(LOG_ERROR, "%s(): Failed to get motor power, ercd: %d", __FUNCTION__, ercd);
	return 0;
}

ER ev3_motor_reset_counts(motor_port_t port)
{
	ER ercd;

	CHECK_PORT(port);
	CHECK_PORT_CONN(port);

    char buf[2];

    buf[0] = opOUTPUT_CLR_COUNT;
    buf[1] = port;
    motor_command(buf, sizeof(buf));

    ercd = E_OK;

error_exit:
    return ercd;
}

ER ev3_motor_set_power(motor_port_t port, int power)
{
	ER ercd;

	CHECK_PORT(port);
	CHECK_PORT_CONN(port);

	motor_type_t mt = mts[port];

	if (power < -100 || power > 100) {
		int old_power = power;
		if (old_power > 0) {
			power = 100;
		} else {
			power = -100;
		}
		syslog(LOG_WARNING, "%s(): power %d is out-of-range, %d is used instead.", __FUNCTION__, old_power, power);
	}

	char buf[3];

	if (mt == UNREGULATED_MOTOR) {
	    // Set unregulated power
	    buf[0] = opOUTPUT_POWER;
	} else {
		// Set regulated speed
	    buf[0] = opOUTPUT_SPEED;
	}
    buf[1] = port;
    buf[2] = power;
	motor_command(buf, sizeof(buf));

    /**
     * Start the motor
     */
    motor_command(buf, sizeof(buf));
    buf[0] = opOUTPUT_START;
    buf[1] = port;
    motor_command(buf, sizeof(buf));

    motor_power[port] = power;

    ercd = E_OK;

error_exit:
    return ercd;
}

ER ev3_motor_stop(motor_port_t port, bool_t brake)
{
	ER ercd;


	CHECK_PORT(port);
	CHECK_PORT_CONN(port);

	ev3_motor_set_power(port,0);

    char buf[3];
    buf[0] = opOUTPUT_STOP;
    buf[1] = port;
    buf[2] = brake;
    motor_command(buf, sizeof(buf));

    ercd = E_OK;

error_exit:
    return ercd;
}

ER ev3_motor_rotate(motor_port_t port, int degrees, uint32_t speed_abs, bool_t blocking)
{
	//not supported
	return E_OK;
}

ER ev3_motor_steer(motor_port_t left_motor, motor_port_t right_motor, int power, int turn_ratio)
{
	ER ercd;
	int left_power;
	int right_power;
	int abs_turn_ratio = (turn_ratio < 0) ? -turn_ratio : turn_ratio;
	int abs_power = (power < 0) ? -power : power;

	CHECK_PORT(left_motor);
	CHECK_PORT_CONN(left_motor);
	CHECK_PORT(right_motor);
	CHECK_PORT_CONN(right_motor);

	if (abs_turn_ratio > 100) {
		abs_turn_ratio = 100;
	}
	if (abs_power > 100) {
		abs_power = 100;
	}
	left_power = abs_power;
	right_power = abs_power;
#if 0
	if (right_motor > left_motor) {
		turn_ratio = turn_ratio * (-1);
	}
#endif
	if (turn_ratio > 0) {
		right_power = (abs_power * (100 - abs_turn_ratio))  / 100 ;
	}
	else {
		left_power = (abs_power * (100 - abs_turn_ratio))  / 100 ;
	}
	if (power < 0) {
		left_power = left_power * (-1);
		right_power = right_power * (-1);
	}

	(void)ev3_motor_set_power(left_motor, left_power);
	(void)ev3_motor_set_power(right_motor, right_power);
	return E_OK;

error_exit:
    return ercd;
}

