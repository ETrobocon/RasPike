#ifdef __cplusplus
extern "C" {
#endif

/* 下記の項目は各ロボットに合わせて変えること */

/* カラーセンサの輝度設定 */
#define WHITE_BRIGHTNESS  (180)
#define BLACK_BRIGHTNESS  (10) 

/* ステアリング操舵量の係数 */
#define STEERING_COEF     (0.2F) 

/* 走行基準スピード */
#define BASE_SPEED        (40) 

/* ライントレースエッジ切り替え */
#define LEFT_EDGE         (-1) 
#define RIGHT_EDGE        (1) 

#include "spike/pup/motor.h"
#include "spike/pup/colorsensor.h"

  
  extern void LineTracer_Configure(pup_motor_t *left_motor,pup_motor_t *right_motor,pup_device_t *color_sensor);

  
#ifdef __cplusplus
}
#endif
