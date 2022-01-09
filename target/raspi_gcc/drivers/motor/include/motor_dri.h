#ifndef _MOTOR_DRI_H_
#define _MOTOR_DRI_H_


#include "driver_common.h"


typedef   enum
{
  opOUTPUT_GET_TYPE           = 0,
  opOUTPUT_SET_TYPE,
  opOUTPUT_RESET,
  opOUTPUT_STOP,
  opOUTPUT_POWER,
  opOUTPUT_SPEED,
  opOUTPUT_START,
  opOUTPUT_POLARITY,
  opOUTPUT_READ,
  opOUTPUT_TEST,
  opOUTPUT_READY,
  opOUTPUT_POSITION,
  opOUTPUT_STEP_POWER,
  opOUTPUT_TIME_POWER,
  opOUTPUT_STEP_SPEED,
  opOUTPUT_TIME_SPEED,
  opOUTPUT_STEP_SYNC,
  opOUTPUT_TIME_SYNC,
  opOUTPUT_CLR_COUNT,
  opOUTPUT_GET_COUNT,
  opOUTPUT_PRG_STOP,
} OP;


typedef   enum
{
//  TYPE_KEEP                     =   0,  //!< Type value that won't change type in byte codes
  TYPE_NXT_TOUCH                =   1,  //!< Device is NXT touch sensor
  TYPE_NXT_LIGHT                =   2,  //!< Device is NXT light sensor
  TYPE_NXT_SOUND                =   3,  //!< Device is NXT sound sensor
  TYPE_NXT_COLOR                =   4,  //!< Device is NXT color sensor

  TYPE_TACHO                    =   7,  //!< Device is a tacho motor
  TYPE_MINITACHO                =   8,  //!< Device is a mini tacho motor
  TYPE_NEWTACHO                 =   9,  //!< Device is a new tacho motor

  TYPE_THIRD_PARTY_START        =  50,
  TYPE_THIRD_PARTY_END          =  99,

  TYPE_IIC_UNKNOWN              = 100,

  TYPE_NXT_TEST                 = 101,  //!< Device is a NXT ADC test sensor

  TYPE_NXT_IIC                  = 123,  //!< Device is NXT IIC sensor
  TYPE_TERMINAL                 = 124,  //!< Port is connected to a terminal
  TYPE_UNKNOWN                  = 125,  //!< Port not empty but type has not been determined
  TYPE_NONE                     = 126,  //!< Port empty or not available
  TYPE_ERROR                    = 127,  //!< Port not empty and type is invalid
} TYPE;
extern void initialize_motor_dri(intptr_t);
ER_UINT extsvc_motor_command(intptr_t cmd, intptr_t size, intptr_t par3, intptr_t par4, intptr_t par5, ID cdmid);

#endif /* _MOTOR_DRI_H_ */
