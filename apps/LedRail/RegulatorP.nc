/*
 * RegulatorP
 *
 * Controls enable pin on voltage regulator or load switch.
 */

module RegulatorP
{
  provides interface PowerRail;

  /* TODO(barry): Do we need to provide Init? */

  /* For now this wiggles Led0 instead of driving the regulator enable */
  uses interface Leds as Enable;

  /* Timer to wait for Vout rise delay */
  uses interface Timer<TMilli> as VoutTimer;
}

implementation
{
  /* provision for up to 255 clients */
  uint8_t refcount;

  void notifyAvail()
  {
    signal PowerRail.powerAvailable();
  }

  task void notifyImmediate()
  {
    notifyAvail();
  }

  event void VoutTimer.fired()
  {
    nop();
    notifyAvail();
  }
  
  command void PowerRail.powerRequest()
  {
    nop();
    if (refcount == 0) {
      /* turn led0 on to simulate enabling regulator */
      call Enable.led0On();

      /* start a timer equal to Vout rise time delay */
      call VoutTimer.startOneShot(3000);
    } else {
      /* immediate signal of powerAvailable */
      post notifyImmediate();
    }
    refcount++;
  }

  command void PowerRail.powerRelease()
  {
    /* TODO(barry): assert(refcount) ?? */
    if (refcount)
      refcount--;

    if (refcount == 0) {
      call Enable.led1Off();
    }
  }
}
