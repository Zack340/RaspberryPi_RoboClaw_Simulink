#ifndef _ROBOCLAW_WRAPPER_H_
#define _ROBOCLAW_WRAPPER_H_
#include "rtwtypes.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#ifdef __cplusplus
extern "C" {
#endif
    
struct Settings
{
    uint8_T tty[256];
    uint8_T address;
    int32_T baudrate;
    int16_T timeout_ms;
    int16_T retries;
    int16_T strict_0xFF_ACK;
    uint8_T mode;
};

struct Data
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
    
void initialize(struct Settings *settings);
void step(struct Data *data);
void terminate();
void errorDetector(int8_T ret);

#ifdef __cplusplus
}
#endif
#endif // _ROBOCLAW_WRAPPER_H_