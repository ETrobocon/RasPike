#include "app.h"
#include "LineTracer.h"
#include <stdio.h>

#include "spike/pup/motor.h"
#include "spike/pup/colorsensor.h"

/* 関数プロトタイプ宣言 */
static int16_t steering_amount_calculation(void);
static void motor_drive_control(int16_t);

static pup_motor_t *fg_left_motor;
static pup_motor_t *fg_right_motor;
static pup_device_t *fg_color_sensor;

void LineTracer_Configure(pbio_port_id_t left_motor_port, pbio_port_id_t right_motor_port, pbio_port_id_t color_sensor_port)
{

  /* センサー入力ポートの設定 */
  fg_color_sensor = pup_color_sensor_get_device(color_sensor_port);
  fg_left_motor   = pup_motor_get_device(left_motor_port);
  fg_right_motor   = pup_motor_get_device(right_motor_port);  

  pup_motor_setup(fg_left_motor,PUP_DIRECTION_COUNTERCLOCKWISE,true);
  pup_motor_setup(fg_right_motor,PUP_DIRECTION_CLOCKWISE,true);  

}


/* ライントレースタスク(100msec周期で関数コールされる) */
void tracer_task(intptr_t unused) {

    int16_t steering_amount; /* ステアリング操舵量の計算 */
    
    /* ステアリング操舵量の計算 */
    steering_amount = steering_amount_calculation();

    /* 走行モータ制御 */
    motor_drive_control(steering_amount);

    /* タスク終了 */
    ext_tsk();
}

/* ステアリング操舵量の計算 */
static int16_t steering_amount_calculation(void){

    uint16_t  target_brightness; /* 目標輝度値 */
    float32_t diff_brightness;   /* 目標輝度との差分値 */
    int16_t   steering_amount;   /* ステアリング操舵量 */
    pup_color_rgb_t rgb_val;

    /* 目標輝度値の計算 */
    target_brightness = (WHITE_BRIGHTNESS + BLACK_BRIGHTNESS) / 2;

    /* カラーセンサ値の取得 */
    rgb_val = pup_color_sensor_rgb(fg_color_sensor);

    /* 目標輝度値とカラーセンサ値の差分を計算 */
    diff_brightness = (float32_t)(target_brightness - rgb_val.g);

    /* ステアリング操舵量を計算 */
    steering_amount = (int16_t)(diff_brightness * STEERING_COEF);

    return steering_amount;
}

/* 走行モータ制御 */
static void motor_drive_control(int16_t steering_amount){

    int left_motor_power, right_motor_power; /*左右モータ設定パワー*/

    /* 左右モータ駆動パワーの計算(走行エッジを右にする場合はRIGHT_EDGEに書き換えること) */
    left_motor_power  = (int)(BASE_SPEED + (steering_amount * LEFT_EDGE));
    right_motor_power = (int)(BASE_SPEED - (steering_amount * LEFT_EDGE));

    /* 左右モータ駆動パワーの設定 */
    pup_motor_set_power(fg_left_motor, left_motor_power);
    pup_motor_set_power(fg_right_motor, right_motor_power);

    return;
}
