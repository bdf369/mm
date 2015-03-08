/*
 * LedRailC
 *
 * Drives the PowerRail interface using a timer.
 */


module LedRailC {
  uses interface Boot;
  uses interface Timer<TMilli> as Timer0;
  uses interface PwrReg;
  uses interface Leds;
}
implementation {
  uint32_t task_counter;

  event void Boot.booted() {
    nop();
    /* Start timer used to toggle power request */
    call Timer0.startOneShot(2000);
  }

  event void Timer0.fired() {
    nop();
    /* toggle the power request */
    call PwrReg.pwrReq();
  }

  task void doStuff() {
    uint32_t i;

    nop();

    /* here we light up Led1 after getting this notification */
    /* if we add 2 timers we can light Led2 using the second timer */
    call Leds.led1On();

    /* Pretend to do stuff for a while */
    for (i=0; i < 5000; i++) {
      task_counter++;
    }

    if (task_counter < 100000) {
      post doStuff();
      return;
    }

    call Leds.led2Off();

    /* release demand for power */
    call PwrReg.pwrRel();

    /* start a timer for next time */
    call Timer0.startOneShot(2000);
  }

  event void PwrReg.pwrAvail() {
    nop();
    /* do something and then release power */
    task_counter = 0;
    post doStuff();
  }
}
