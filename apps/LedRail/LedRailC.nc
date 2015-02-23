/*
 * LedRailC
 *
 * Drives the PowerRail interface using a timer.
 */


module LedRailC
{
  uses interface Boot;
  uses interface Timer<TMilli> as Timer0;
  uses interface PowerRail;
  uses interface Leds;
}

implementation
{
  event void Boot.booted()
  {
    nop();
    /* Start timer used to toggle power request */
    call Timer0.startOneShot(2000);
  }

  event void Timer0.fired()
  {
    nop();
    /* toggle the power request */
    call PowerRail.powerRequest();
  }

  task void doStuff()
  {
    uint32_t i;

    nop();
    /* here we light up Led1 after getting this notification */
    /* if we add 2 timers we can light Led2 using the second timer */
    call Leds.led1On();

    /* Pretend to do stuff for a while */
    for (i=0; i < 500000; i++)
      ;

    call Leds.led2Off();

    /* release demand for power */
    call PowerRail.powerRelease();

    /* start a timer for next time */
    call Timer0.startOneShot(2000);
  }

  event void PowerRail.powerAvailable()
  {
    nop();
    /* do something and then release power */
    post doStuff();
  }
}
