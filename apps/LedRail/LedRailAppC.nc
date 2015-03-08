/*
 * LedRailAppC
 *
 * Test the PowerRail interface and Regulator module implementation
 */

configuration LedRailAppC {
}
implementation {
  components MainC, LedRailC, Pwr3V3C, LedsC;
  components new TimerMilliC() as Timer0;

  LedRailC.Boot -> MainC.Boot;
  LedRailC.Timer0 -> Timer0;
  LedRailC.PwrReg -> Pwr3V3C;
  LedRailC.Leds -> LedsC;
}
