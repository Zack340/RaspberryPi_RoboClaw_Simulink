#include "roboclaw.h"
#include "roboclaw_wrapper.h"

struct roboclaw *rc;
struct roboclaw_Settings *rc_sets;
pthread_t rc_thread;
struct roboclaw_Data *rc_pdata;

#ifdef __cplusplus
extern "C" {
#endif

void roboclaw_initialize(struct roboclaw_Settings *settings)
{
    rc_sets = settings;
    
    rc = roboclaw_init_ext(rc_sets->tty,
                           rc_sets->baudrate,
                           rc_sets->timeout_ms,
                           rc_sets->retries,
                           rc_sets->strict_0xFF_ACK);
    if (rc == NULL)
    {
        printf("\nFailed to init RoboClaw.\n");
        exit(1);
    }
    
    rc_pdata = (struct roboclaw_Data *)malloc(sizeof(struct roboclaw_Data));
    rc_pdata->m1Duty = 0;
    rc_pdata->m2Duty = 0;
    rc_pdata->m1Speed = 0;
    rc_pdata->m2Speed = 0;
    rc_pdata->accel = 0;
    rc_pdata->m1Counts = 0;
    rc_pdata->m2Counts = 0;
    rc_pdata->voltage = 0;
}

void roboclaw_step(struct roboclaw_Data *data)
{
    pthread_join(rc_thread, NULL);
    
    rc_pdata->m1Duty = data->m1Duty;
    rc_pdata->m2Duty = data->m2Duty;
    rc_pdata->m1Speed = data->m1Speed;
    rc_pdata->m2Speed = data->m2Speed;
    rc_pdata->accel = data->accel;
    data->m1Counts = rc_pdata->m1Counts;
    data->m2Counts = rc_pdata->m2Counts;
    data->voltage = rc_pdata->voltage;
    
    pthread_create(&rc_thread, NULL, (void *)roboclaw_tic, (void *)rc_pdata);
}

void roboclaw_terminate()
{
    pthread_join(rc_thread, NULL);
    
    roboclaw_duty_m1m2(rc, rc_sets->address, 0, 0);
    roboclaw_close(rc);
}

void *roboclaw_tic(void *pdata)
{
    struct roboclaw_Data *data = (struct roboclaw_Data *)pdata;
    int8_T ret = 0;
    
    switch (rc_sets->mode)
    {
        case 0:
            ret = roboclaw_duty_m1m2(rc, rc_sets->address, data->m1Duty, data->m2Duty);
            break;
        case 1:
            ret = roboclaw_speed_m1m2(rc, rc_sets->address, data->m1Speed, data->m2Speed);
            break;
        case 2:
            ret = roboclaw_speed_accel_m1m2(rc, rc_sets->address, data->m1Speed, data->m2Speed, data->accel);
            break;
        default:
            break;
    }
    
    ret = roboclaw_encoders(rc, rc_sets->address, &data->m1Counts, &data->m2Counts);
    
    int16_T voltage = 0;
    ret = roboclaw_main_battery_voltage(rc, rc_sets->address, &voltage);
    data->voltage = (real32_T)voltage / 10.0f;
}

void roboclaw_errorDetector(int8_T ret)
{
    if (ret == -1)
    {
        fprintf(stderr, "\nIO Error: %s\n", strerror(errno));
    }
    if (ret == -2)
    {
        printf("\nExceeded retries.\n");
    }
    
    roboclaw_terminate();    
    exit(1);
}

#ifdef __cplusplus
}
#endif