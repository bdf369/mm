/*
 * BattP.nc: implementation for Battery Monitor
 * Copyright 2008 Eric B. Decker
 * All rights reserved.
 */


/**
 *  Battery Monitor Sensor Driver
 *  @author: Eric B. Decker
 */

#include "sensors.h"
#include "batt.h"

module BattP {
  provides {
    interface StdControl;
    interface Init;
    interface AdcConfigure<const mm3_sensor_config_t*>;
  }

  uses {
    interface Regime as RegimeCtrl;
    interface Timer<TMilli> as PeriodTimer;
    interface Adc;
    interface Collect;
    interface HplMM3Adc as HW;
    interface mm3Control;
    interface mm3CommData;
    interface Panic;
    interface Docked;
  }
}

implementation {
  uint32_t period;
  uint8_t  batt_state;
  uint32_t err_overruns;
  uint32_t err_eaves_drops;


  command error_t Init.init() {
    period = 0;
    batt_state = BATT_STATE_OFF;
    err_overruns = 0;
    return SUCCESS;
  }


  command error_t StdControl.start() {
    call HW.batt_on();
    return SUCCESS;
  }


  /*
   * Done checking the battery.  If we are docked, leave the
   * battery on so we continue to charge it.  batt_on happened
   * on the start.
   */
  command error_t StdControl.stop() {
    /*
     * For the time being we attach the battery to the ext charge
     * pin to fake it.  So for the time being don't turn the Batt
     * FET on just to be safe.
     */
//    if (call Docked.isDocked() == FALSE)
    call HW.batt_off();
    return SUCCESS;
  }


  event void PeriodTimer.fired() {
    if (batt_state != BATT_STATE_IDLE) {
      err_overruns++;
      return;
    }
    batt_state = BATT_STATE_READ;
    call Adc.reqConfigure();
  }


  event void Adc.configured() {
    uint8_t batt_data[BATT_BLOCK_SIZE];
    dt_sensor_data_nt *bdp;

    bdp = (dt_sensor_data_nt *) batt_data;
    bdp->data[0] = call Adc.readAdc();
    batt_state = BATT_STATE_IDLE;
    call Adc.release();
    bdp->len = BATT_BLOCK_SIZE;
    bdp->dtype = DT_SENSOR_DATA;
    bdp->sns_id = SNS_ID_BATT;
    bdp->sched_mis = call PeriodTimer.gett0();
    bdp->stamp_mis = call PeriodTimer.getNow();
    if (call mm3Control.eavesdrop()) {
      if (call mm3CommData.send_data(bdp, BATT_BLOCK_SIZE))
	err_eaves_drops++;
    }
    call Collect.collect(batt_data, BATT_BLOCK_SIZE);
  }

  event void mm3CommData.send_data_done(error_t rtn) {
  }

  event void RegimeCtrl.regimeChange() {
    uint32_t new_period;

    call PeriodTimer.stop();
    if (call Adc.isOwner())
      call Adc.release();
    new_period = call RegimeCtrl.sensorPeriod(SNS_ID_BATT);
    if (new_period == 0)
      batt_state = BATT_STATE_OFF;
    else if (new_period != period) {
      batt_state = BATT_STATE_IDLE;
      period = new_period;
      call PeriodTimer.startPeriodic(period);
    }
  }

  event void Docked.docked() {}
  event void Docked.undocked() {}

  async command const mm3_sensor_config_t* AdcConfigure.getConfiguration() {
    return &batt_config;
  }
}
