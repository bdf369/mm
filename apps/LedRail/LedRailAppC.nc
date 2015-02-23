/*
 * LedRailAppC
 *
 * Test the PowerRail interface and Regulator module implementation
 */

configuration LedRailAppC
{
}

implementation
{
  components MainC, LedRailC, RegulatorC, LedsC;
  components new TimerMilliC() as Timer0;

  LedRailC.Boot -> MainC.Boot;
  LedRailC.Timer0 -> Timer0;
  LedRailC.PowerRail -> RegulatorC;
  LedRailC.Leds -> LedsC;
}
