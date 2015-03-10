/*
 * Control 3V3 power regulator
 */

/* tps78233 output rise delay in msec */
#define PWR3V3_VOUT_RISETIME 5

configuration Pwr3V3C {
  provides interface PwrReg;
}
implementation {
  components Pwr3V3P;

  PwrReg = Pwr3V3P;

  components new TimerMilliC() as VoutTimer;
  Pwr3V3P.VoutTimer -> VoutTimer;

  components HplMsp430GeneralIOC as GeneralIOC;
  components new Msp430GpioC() as Pwr3V3Enable;
  Pwr3V3Enable -> GeneralIOC.Port62;
  Pwr3V3P.Pwr3V3Enable -> Pwr3V3Enable;
}
