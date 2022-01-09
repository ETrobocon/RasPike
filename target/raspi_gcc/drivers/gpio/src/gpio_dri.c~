#include <kernel.h>
#include <t_syslog.h>
#include <t_stdlib.h>
#include "syssvc/serial.h"
#include "syssvc/syslog.h"
#include "kernel_cfg.h"
#include "gpio_dri.h"
#include "ev3_vdev.h"
#include "sil.h"

#include "driver_common.h"
#include "ev3_vdev.h"
#include "prc_config.h"

bool_t gpio_get_value(uint32_t pin) {
	bool_t ret = FALSE;
	uint32_t base = pin / EV3_GPIO_PIN_BASE_SIZE;
	uint32_t index = pin % EV3_GPIO_PIN_BASE_SIZE;
	uint8_t data;

	switch (base) {
	case 1: //BUTTON
		data = sil_reb_mem((const uint8_t *)EV3_GPIO_BTN_ADDR);
		if ((data & (1U << index)) != 0U) {
			ret = TRUE;
		}
		break;
	default:
		break;
	}
	return ret;
}

void gpio_set_value(uint32_t pin, bool_t value) {
	uint32_t base = pin / EV3_GPIO_PIN_BASE_SIZE;
	uint32_t index = pin % EV3_GPIO_PIN_BASE_SIZE;
	uint8_t * addr;
	uint8_t data;

	switch (base) {
	case 0: //LED
		addr = (uint8_t *)EV3_GPIO_LED_ADDR;
		break;
	default:
		return;
	}
	data = sil_reb_mem(addr);


	if(value == TRUE) {
		data |= (1U << index);
    }
    else {
		data &= ~(1U << index);
    }
	sil_wrb_mem(addr, data);
	return;
}
void gpio_out_flush(void)
{
	disable_int_all();
	lock_cpu();
	sil_wrb_mem((void*)VDEV_TX_FLAG_BASE, 1);

#if 1
	//TODO clear reset angle
	if (sil_rew_mem((uint32_t*)EV3_MOTOR_ADDR_INX(EV3_MOTOR_INX_RESET_ANGLE_A)) != 0) {
		sil_wrw_mem((uint32_t*)EV3_MOTOR_ADDR_INX(EV3_MOTOR_INX_RESET_ANGLE_A), 0U);
	}
	if (sil_rew_mem((uint32_t*)EV3_MOTOR_ADDR_INX(EV3_MOTOR_INX_RESET_ANGLE_B)) != 0) {
		sil_wrw_mem((uint32_t*)EV3_MOTOR_ADDR_INX(EV3_MOTOR_INX_RESET_ANGLE_B), 0U);
	}
	if (sil_rew_mem((uint32_t*)EV3_MOTOR_ADDR_INX(EV3_MOTOR_INX_RESET_ANGLE_C)) != 0) {
		sil_wrw_mem((uint32_t*)EV3_MOTOR_ADDR_INX(EV3_MOTOR_INX_RESET_ANGLE_C), 0U);
	}
	if (sil_rew_mem((uint32_t*)EV3_MOTOR_ADDR_INX(EV3_MOTOR_INX_RESET_ANGLE_D)) != 0) {
		sil_wrw_mem((uint32_t*)EV3_MOTOR_ADDR_INX(EV3_MOTOR_INX_RESET_ANGLE_D), 0U);
	}
	if (sil_rew_mem((uint32_t *)EV3_GYRO_ADDR_RESET) != 0 ) {
		sil_wrw_mem( (uint32_t *)EV3_GYRO_ADDR_RESET, 0U);
	}
#endif
	unlock_cpu();
	enable_int_all();
}
