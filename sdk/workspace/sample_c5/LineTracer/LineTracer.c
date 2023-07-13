#include "app.h"
#include "LineTracer.h"
#include <stdio.h>

/* 関数プロトタイプ宣言 */
static int16_t steering_amount_calculation(void);
static void motor_drive_control(int16_t);

/* ライントレースタスク(100msec周期で関数コールされる) */
void tracer_task(intptr_t unused) {
    //
    //ev3_motor_set_power(arm_motor, 100);
   
    printf("tracer_task\n");
    int16_t steering_amount;
    /* ステアリング操舵量の計算 */

    /* ステアリング操舵量の計算 */
    steering_amount = steering_amount_calculation();
    printf("steering_amount: %d\n", steering_amount);
    /* 走行モータ制御 */
    motor_drive_control(steering_amount);

    /* タスク終了 */
    ext_tsk();
}

/* ステアリング操舵量の計算 */
static int16_t steering_amount_calculation(void){

    printf("steering_amount_calculation\n");

    uint16_t  target_brightness; /* 目標輝度値 */
    float32_t diff_brightness;   /* 目標輝度との差分値 */
    int16_t   steering_amount;   /* ステアリング操舵量 */
    rgb_raw_t rgb_val;           /* カラーセンサ取得値 */
    
    printf("calculation brightness \n");
    /* 目標輝度値の計算 */
    target_brightness = (WHITE_BRIGHTNESS - BLACK_BRIGHTNESS) / 2;

    printf("get color sensor \n");
    /* カラーセンサ値の取得 */
    ev3_color_sensor_get_rgb_raw(color_sensor, &rgb_val);
    printf("r: %u, g: %u, b: %u\n", rgb_val.r, rgb_val.g, rgb_val.b);
    printf("diff brightness \n");
    /* 目標輝度値とカラーセンサ値の差分を計算 */
    diff_brightness = (float32_t)(target_brightness - rgb_val.g);

    printf("teering amount\n");
    /* ステアリング操舵量を計算 */
    steering_amount = (int16_t)(diff_brightness * STEERING_COEF);

    return steering_amount;
}

/* 走行モータ制御 */
static void motor_drive_control(int16_t steering_amount){

    printf("motor_drive_control\n");

    int left_motor_power, right_motor_power; /*左右モータ設定パワー*/

    /* 左右モータ駆動パワーの計算(走行エッジを右にする場合はRIGHT_EDGEに書き換えること) */
    left_motor_power  = (int)(BASE_SPEED + (steering_amount * LEFT_EDGE));
    right_motor_power = (int)(BASE_SPEED - (steering_amount * LEFT_EDGE));

    /* 左右モータ駆動パワーの設定 */
    ev3_motor_set_power(left_motor, left_motor_power);
    ev3_motor_set_power(right_motor, right_motor_power);

    return;
}
