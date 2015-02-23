/*
 * RegulatorC
 *
 * Module to control when to enable a voltage regulator, according to
 * requests via the PowerRail interface.
 */

/*
 * TODO(barry): Currently this is a singleton. Make generic to support
 * multiple regulators and also maybe multiple regulator types
 * (eg. tps78233, mic9416x, ...)
 */


configuration RegulatorC
{
  provides interface PowerRail;
}

implementation
{
  components RegulatorP;
  components new TimerMilliC() as VoutTimer;
  components LedsC as Enable;

  PowerRail = RegulatorP;

  RegulatorP.VoutTimer -> VoutTimer;
  RegulatorP.Enable -> Enable;
}
