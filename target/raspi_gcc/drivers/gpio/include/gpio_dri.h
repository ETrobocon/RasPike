/*
 * gpio_dri.h
 *
 *  Created on: Sep 20, 2013
 *      Author: liyixiao
 */

#pragma once

#include <kernel.h>

typedef enum {
	/*
	 * LED
	 */
	EV3_GPIO_0 = 0,		//LED
	EV3_GPIO_1,			//LED
	EV3_GPIO_2,			//LED
	EV3_GPIO_3,			//LED
	EV3_GPIO_4,			//LED
	EV3_GPIO_5,			//LED
	EV3_GPIO_6,			//LED
	EV3_GPIO_7,			//LED
	/*
	 * Button
	 */
	EV3_GPIO_8,			//BTN
	EV3_GPIO_9,			//BTN
	EV3_GPIO_10,		//BTN
	EV3_GPIO_11,		//BTN
	EV3_GPIO_12,		//BTN
	EV3_GPIO_13,		//BTN
	EV3_GPIO_14,		//BTN
	EV3_GPIO_15,		//BTN
} Ev3GpioPinType;
#define EV3_GPIO_PIN_BASE_SIZE	8U

bool_t gpio_get_value(uint32_t pin);
void gpio_set_value(uint32_t pin, bool_t value);
void gpio_out_flush(void);

