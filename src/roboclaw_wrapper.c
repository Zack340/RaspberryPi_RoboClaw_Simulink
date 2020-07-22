#include "roboclaw.h"
#include "roboclaw_wrapper.h"

struct roboclaw *rc;
struct Settings *sets;

#ifdef __cplusplus
extern "C" {
#endif

void initialize(struct Settings *settings)
{
    sets = settings;
    
    rc = roboclaw_init_ext(sets->tty,
                           sets->baudrate,
                           sets->timeout_ms,
                           sets->retries,
                           sets->strict_0xFF_ACK);
    if (rc == NULL)
    {
        printf("\nFailed to init RoboClaw.\n");
        exit(1);
    }
}

void step(struct Data *data)
{
    int8_T ret = 0;
    
    switch (sets->mode)
    {
        case 0:
            ret = roboclaw_duty_m1m2(rc, sets->address, data->m1Duty, data->m2Duty);
            break;
        case 1:
            ret = roboclaw_speed_m1m2(rc, sets->address, data->m1Speed, data->m2Speed);
            break;
        case 2:
            ret = roboclaw_speed_accel_m1m2(rc, sets->address, data->m1Speed, data->m2Speed, data->accel);
            break;
        default:
            break;
    }
    errorDetector(ret);
    
    ret = roboclaw_encoders(rc, sets->address, &data->m1Counts, &data->m2Counts);
    errorDetector(ret);

    int16_T voltage = 0;
    ret = roboclaw_main_battery_voltage(rc, sets->address, &voltage);
    errorDetector(ret);
    data->voltage = (real32_T)voltage / 10.0f;
}

void terminate()
{
    roboclaw_close(rc);
}

void errorDetector(int8_T ret)
{
    if (ret == -1)
    {
        fprintf(stderr, "\nIO Error: %s\n", strerror(errno));
        exit(1);
    }
    if (ret == -2)
    {
        printf("\nExceeded retries.\n");
        exit(1);
    }
}

#ifdef __cplusplus
}
#endif