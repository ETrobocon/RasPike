#include "app.h"
#include <stdio.h>
#include "LineTracer.h"

/* センサーポートの定義 */
static const pbio_port_id_t
  color_sensor_port    = PBIO_PORT_ID_A,
  left_motor_port      = PBIO_PORT_ID_C,
  right_motor_port     = PBIO_PORT_ID_D; 

/* メインタスク(起動時にのみ関数コールされる) */
void main_task(intptr_t unused) {

  /* センサー入力ポートの設定 */
  pup_device_t *color_sensor = pup_color_sensor_get_device(color_sensor_port);
  pup_motor_t  *left_motor   = pup_motor_get_device(left_motor_port);
  pup_motor_t  *right_motor   = pup_motor_get_device(right_motor_port);  

  pup_motor_setup(left_motor,PUP_DIRECTION_CLOCKWISE,true);
  pup_motor_setup(right_motor,PUP_DIRECTION_COUNTERCLOCKWISE,true);  

  /* LineTracerに構成を渡す */
  LineTracer_Configure(left_motor,right_motor,color_sensor);
  printf("Start Line Trace!!\n");
    
  /* ライントレースタスクの起動 */
  sta_cyc(LINE_TRACER_TASK_CYC);

  /* タスク終了 */
  ext_tsk();
}
