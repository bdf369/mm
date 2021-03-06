/*
 * Copyright (c) 2008, 2010, Eric B. Decker
 * All rights reserved.
 */

#ifndef SAL_H
#define SAL_H

#include "sensors.h"

#define SURFACE_THRESHOLD 65000UL
#define SAL_OFF_SAMPLE_RATE 1024UL

/*
 * Sensor States (used to observe changes)
 */
enum {
    SAL_STATE_OFF		= 0,
    SAL_STATE_IDLE		= 1,
    SAL_STATE_READ_1		= 2,
    SAL_STATE_READ_2		= 3,
};

const mm_sensor_config_t sal_config_1 = {
  .sns_id = SNS_ID_SAL,
  .mux  = SMUX_SALINITY,
  .t_settle = 164,		/* ~ 5mS */
  .gmux = 0,
};

const mm_sensor_config_t sal_config_2 = {
  .sns_id = SNS_ID_SAL,
  .mux  = SMUX_SALINITY,
  .t_settle = 4,		/* ~120uS */
  .gmux = 0,
};

#endif
