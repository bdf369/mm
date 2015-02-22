/*
 * Power Rail Interface
 *
 * command: powerRequest() to request power on rail
 *
 * event: powerAvailable() to indicate power is available on rail
 *
 * command: powerRelease() to release demand for power on rail
 */

/*
 * Looking at tps78233 datasheet, it looks like there's a about a 3ms delay
 * for Vout to reach say 3.3V when EN is driven about 1.2V. If the regulator is
 * on already there is no delay.
 *
 * Since there could be a delay needed if we need to enable the regulator
 * there needs to be an event to indicate when power is available.
 *
 */

interface PowerRail {
  command void powerRequest();

  event void powerAvailable();

  command void powerRelease();
}
