#include "motor_dri.h"
#include "ev3_vdev.h"
#include "ev3api_motor.h"
#include "sil.h"

int motor_power[TNUM_MOTOR_TYPE];

void initialize_motor_dri(intptr_t arg)
{
	return;
}
static void motor_get_angle(int port, int *angle)
{
	*angle = sil_rew_mem( (const uint32_t *)EV3_SENSOR_MOTOR_ADDR_INX(port));
	return;
}
static void motor_clr_angle(int port)
{
	int index = port + EV3_MOTOR_INX_RESET_ANGLE_TOP;
	sil_wrw_mem((uint32_t*)EV3_MOTOR_ADDR_INX(index), 1U);
	return;
}
static void motor_set_power(int port, int power)
{
	motor_power[port] = power;
	return;
}
static void motor_start(int port)
{
	int index = port + EV3_MOTOR_INX_POWER_TOP;
	sil_wrw_mem((uint32_t*)EV3_MOTOR_ADDR_INX(index), motor_power[index]);
	return;
}

static void motor_brake(int port, bool_t brake)
{
	int index = port + EV3_MOTOR_INX_POWER_TOP;
	sil_wrw_mem((uint32_t*)EV3_MOTOR_ADDR_INX(index), 0);

	index = port + EV3_MOTOR_INX_STOP_TOP;
	sil_wrw_mem((uint32_t*)EV3_MOTOR_ADDR_INX(index), brake);
	return;
}

ER_UINT extsvc_motor_command(intptr_t cmd, intptr_t size, intptr_t par3, intptr_t par4, intptr_t par5, ID cdmid)
{
	char *cmdp = (char*)cmd;
	int cmd_value = cmdp[0];

	switch (cmd_value) {
	case opOUTPUT_SET_TYPE:
		/* nothing to do */
		break;
	case opOUTPUT_STOP:
		motor_brake(cmdp[1], cmdp[2]);
		break;
	case opOUTPUT_POWER:
	case opOUTPUT_SPEED:
		motor_set_power(cmdp[1], cmdp[2]);
		break;
	case opOUTPUT_START:
		motor_start(cmdp[1]);
		break;
	case opOUTPUT_GET_COUNT:
		motor_get_angle(cmdp[1], (int*)&cmdp[4]);
		break;
	case opOUTPUT_CLR_COUNT:
		motor_clr_angle(cmdp[1]);
		break;
	default:
		return E_PAR;
	}

	return E_OK;
}
