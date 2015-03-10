/*
 * Control 3V3 power regulator
 * Use Led0 to simulate enabling the pwr_3v3_ena pin
 */

/* For this test, use 3000 msec delay between turning on Led0
 * and signalling pwrAvail
 */
#define PWR3V3_VOUT_RISETIME 3000

configuration Pwr3V3C {
  provides interface PwrReg;
}
implementation {
  components Pwr3V3P;
  PwrReg = Pwr3V3P;

  components new TimerMilliC() as VoutTimer;
  Pwr3V3P.VoutTimer -> VoutTimer;

  components PlatformLedC, LedIOP;
  LedIOP.Led -> PlatformLedC.Led[0];
  Pwr3V3P.Pwr3V3Enable -> LedIOP;
}
