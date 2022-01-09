/**
 * This sample program balances a two-wheeled Segway type robot such as Gyroboy in EV3 core set.
 *
 * References:
 * http://www.hitechnic.com/blog/gyro-sensor/htway/
 * http://www.cs.bgu.ac.il/~ami/teaching/Lejos-2013/classes/src/lejos/robotics/navigation/Segoway.java
 */

#include "ev3api.h"
#include "app.h"

//#define DEBUG

#ifdef DEBUG
#define _debug(x) (x)
#else
#define _debug(x)
#endif

static const int left_motor = EV3_PORT_A;
static const int right_motor = EV3_PORT_B;
static const int arm_motor = EV3_PORT_C;

static const int color_sensor = EV3_PORT_1;
static const int ultrasonic_sensor = EV3_PORT_2;
static const int touch_sensor0 = EV3_PORT_3;
static const int touch_sensor1 = EV3_PORT_4;

#define ERR_CHECK(err)  \
do {    \
    if ((err) != 0) {   \
        syslog(LOG_NOTICE, "ERROR: %s %d err=%d", __FUNCTION__, __LINE__, (err));   \
    }   \
} while (0)

/*
 * 1.1 走る(前進操作)
 */
static void do_foward(int power)
{
    ER err = ev3_motor_steer(left_motor, right_motor, power, 0);
    ERR_CHECK(err);
    return;
}
/*
 * 1.5 カラーセンサの値を見る
 */
colorid_t color = COLOR_NONE;
static void check_color_sensor(void)
{
    color = ev3_color_sensor_get_color(color_sensor);
    uint8_t value = ev3_color_sensor_get_reflect(color_sensor);
    char *color_str = "NULL";
    switch (color) {
        case COLOR_NONE:
            color_str = "NONE";
            break;
        case COLOR_BLACK:
            color_str = "BLACK";
            break;
        case COLOR_BLUE:
            color_str = "BLUE";
            break;
        case COLOR_GREEN:
            color_str = "GREEN";
            break;
        case COLOR_YELLOW:
            color_str = "YELLOW";
            break;
        case COLOR_RED:
            color_str = "RED";
            break;
        case COLOR_WHITE:
            color_str = "WHITE";
            break;
        case COLOR_BROWN:
            color_str = "BROWN";
            break;
        default:
            break;
    }
    _debug(syslog(LOG_NOTICE, "color=%s reflect_value=%d", color_str, value));
    return;
}
/*
 * 1.6 超音波センサの値を見る
 */
int16_t ultrasonic_value = 0;
static void check_ultrasonic_sensor(void)
{
    ultrasonic_value = ev3_ultrasonic_sensor_get_distance(ultrasonic_sensor);
    _debug(syslog(LOG_NOTICE, "ultrasonic_value=%d", ultrasonic_value));
    return;
}
/*
 * 1.7 タッチセンサの値を見る
 */
bool_t is_pressed[2] = { false, false };
static void check_touch_sensor(int id)
{
    int inx = (id == touch_sensor0) ? 0 : 1;
    is_pressed[inx] = ev3_touch_sensor_is_pressed(id);
    _debug(syslog(LOG_NOTICE, "is_pressed[%d]=%d", inx, is_pressed[inx]));
    return;
}

/*
 * 1.3 止まる(停止操作)
 */
static void do_stop(void)
{
    ER err = ev3_motor_stop(left_motor, true);
    ERR_CHECK(err);
    err = ev3_motor_stop(right_motor, true);
    ERR_CHECK(err);
    do_foward(0);
}
/*
 * 1.4 アームを動かす
 */
static void do_arm_move(bool_t up)
{
    if (up) {
        ER err = ev3_motor_set_power(arm_motor, 5);
        ERR_CHECK(err);
    }
    else {
        ER err = ev3_motor_set_power(arm_motor, -5);
        ERR_CHECK(err);
    }
    return;
}
/*
 * 1.2 曲がる(ステアリング操作)
 */
static void do_turn(int turn_speed)
{
    if (turn_speed > 0) {
        ER err = ev3_motor_set_power(left_motor, turn_speed);
        ERR_CHECK(err);
        err = ev3_motor_set_power(right_motor, 0);
        ERR_CHECK(err);
    }
    else {
        ER err = ev3_motor_set_power(left_motor, 0);
        ERR_CHECK(err);
        err = ev3_motor_set_power(right_motor, -turn_speed);
        ERR_CHECK(err);
    }
    return;
}

static void do_practice_1(void)
{
    do_foward(5);
    do_arm_move(false);
    check_color_sensor();
    //check_ultrasonic_sensor();
    //check_touch_sensor(touch_sensor0);
    //do_turn(5); //turn right
    //do_turn(-5); //turn left
    return;
}

typedef enum {
    Practice2_Phase_First = 0,
    Practice2_Phase_Second,
    Practice2_Phase_Third,
    Practice2_Phase_Fourth,
    Practice2_Phase_Fifth,
    Practice2_Phase_Sixth,
} Practice2_PhaseType;
static Practice2_PhaseType Practice2_Phase;

static void do_practice_2_first(void)
{
    check_color_sensor();
    switch (color) {
    case COLOR_BLACK:
        do_foward(5);
        break;
    case COLOR_WHITE:
        do_turn(5);
        break;
    case COLOR_RED:
        do_stop();
        Practice2_Phase = Practice2_Phase_Second;
        break;
    default:
        do_turn(-5);
        break;
    }
    return;
}
static void do_practice_2_second(void)
{
    check_ultrasonic_sensor();
    check_color_sensor();
    if (ultrasonic_value > 5) {
        do_foward(5);
        return;
    }

    switch (color) {
    case COLOR_BLACK:
        do_stop();
        Practice2_Phase = Practice2_Phase_Third;
        break;
    default:
        break;
    }
    return;
}
static void do_practice_2_third(void)
{
    check_ultrasonic_sensor();
    if (ultrasonic_value < 12) {
        do_turn(5);
        return;
    }
    Practice2_Phase = Practice2_Phase_Fourth;
    return;
}
static void do_practice_2_Fourth(void)
{
    check_color_sensor();
    switch (color) {
    case COLOR_BLACK:
        do_foward(5);
        break;
    case COLOR_WHITE:
        do_turn(-5);
        break;
    case COLOR_BLUE:
        do_stop();
        Practice2_Phase = Practice2_Phase_Fifth;
        break;
    default:
        do_turn(5);
        break;
    }
    return;
}
static void do_practice_2_Fifh(void)
{
    check_ultrasonic_sensor();
    if (ultrasonic_value < 5) {
        do_stop();
        syslog(LOG_NOTICE, "GOAL!!");
        Practice2_Phase = Practice2_Phase_Sixth;
    }
    else {
        do_foward(5);
    }
    return;
}
#define BLINK_CYCLE 20
#define BLINK_CYCLE_HALF ( BLINK_CYCLE / 2 )

static void blink_led(ledcolor_t b_color)
{
    static int count = 0;
    check_touch_sensor(touch_sensor1);
    if (is_pressed[1] == true) {
        ev3_led_set_color(b_color);
        return;
    }

    if (count <= BLINK_CYCLE_HALF) {
        ev3_led_set_color(b_color);
    }
    else if (count > BLINK_CYCLE_HALF) {
        ev3_led_set_color(LED_OFF);
    }
    count++;
    if (count >= BLINK_CYCLE) {
        count = 0;
    }
    return;
}
static void do_practice_2(void)
{
    switch (Practice2_Phase) {
    case Practice2_Phase_First:
        blink_led(LED_GREEN);
        do_practice_2_first();
        break;
    case Practice2_Phase_Second:
        blink_led(LED_ORANGE);
        do_practice_2_second();
        break;
    case Practice2_Phase_Third:
        blink_led(LED_RED);
        do_practice_2_third();
        break;
    case Practice2_Phase_Fourth:
        blink_led(LED_RED);
        do_practice_2_Fourth();
        break;
    case Practice2_Phase_Fifth:
        blink_led(LED_GREEN);
        do_practice_2_Fifh();
        break;
    default:
        ev3_led_set_color(LED_OFF);
        do_stop();
        break;
    }
    return;
}

void main_task(intptr_t unused) {
    ev3_sensor_config(color_sensor, COLOR_SENSOR);
    ev3_sensor_config(ultrasonic_sensor, ULTRASONIC_SENSOR);
    ev3_sensor_config(touch_sensor0, TOUCH_SENSOR);
    ev3_sensor_config(touch_sensor1, TOUCH_SENSOR);
    ev3_motor_config(left_motor, LARGE_MOTOR);
    ev3_motor_config(right_motor, LARGE_MOTOR);
    ev3_motor_config(arm_motor, LARGE_MOTOR);
  
    syslog(LOG_NOTICE, "#### motor control start");
    int count = 0;
    ev3_motor_stop(left_motor, true);
    ev3_motor_stop(right_motor, true);
    while(1) {
#if 0
        /*
         * ここに制御プログラムを入れてください
         */
        if (count <= 100) {
           ev3_motor_set_power(left_motor, 3);
           ev3_motor_set_power(right_motor, 3);
        }
        else if ((count > 100) && (count <= 200)) {
           ev3_motor_set_power(left_motor, -3);
           ev3_motor_set_power(right_motor, -3);
        }
        else if ((count > 200) && (count <= 300)) {
           ev3_motor_set_power(left_motor, 0);
           ev3_motor_set_power(right_motor, 0);
           ev3_motor_set_power(arm_motor, 1);
        }
        else if ((count > 300) && (count <= 400)) {
           ev3_motor_set_power(left_motor, 0);
           ev3_motor_set_power(right_motor, 0);
           ev3_motor_set_power(arm_motor, -1);
        }
        else {
            /* nothing to do */
        }
        count++;
#else
    //check_ultrasonic_sensor();
    do_arm_move(false);
    do_practice_2();
#endif
        tslp_tsk(100000); /* 100msec */
    }
}
