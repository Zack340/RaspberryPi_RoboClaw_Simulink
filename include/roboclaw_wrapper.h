/* 
 *  	Author : Eisuke Matsuzaki
 *  	Created on : 7/21/2020
 *  	Copyright (c) 2020 d’Arbeloff Lab, MIT Department of Mechanical Engineering
 *      Released under the MIT license
 * 
 *      RoboClaw Driver for Raspberry Pi
 */

#ifndef _ROBOCLAW_WRAPPER_H_
#define _ROBOCLAW_WRAPPER_H_
#include "rtwtypes.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <pthread.h>

#ifdef __cplusplus
extern "C" {
#endif
    
struct roboclaw_Settings
{
    uint8_T tty[256];
    uint8_T address;
    int32_T baudrate;
    int16_T timeout_ms;
    int16_T retries;
    int16_T strict_0xFF_ACK;
    uint8_T mode;
};

struct roboclaw_Data
{
    int16_T m1Duty;
    int16_T m2Duty;
    int32_T m1Speed;
    int32_T m2Speed;
    int32_T accel;
    int32_T m1Counts;
    int32_T m2Counts;
    real32_T voltage;
};
    
void roboclaw_initialize(struct roboclaw_Settings *settings);
void roboclaw_step(struct roboclaw_Data *data);
void roboclaw_terminate();
void *roboclaw_tic(void *pdata);
void roboclaw_errorDetector(int8_T ret);

#ifdef __cplusplus
}
#endif
#endif // _ROBOCLAW_WRAPPER_H_