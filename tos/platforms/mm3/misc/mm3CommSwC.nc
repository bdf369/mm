/**
 * Copyright @ 2008-2009 Eric B. Decker
 * @author Eric B. Decker <cire831@gmail.com>
 */
 
#include "sensors.h"

configuration mm3CommSwC {
  provides {
    interface mm3CommSw;
    interface pakSend;
  }
}

implementation {
  components mm3CommSwP;
  
  mm3CommSw  = mm3CommSwP;
  pakSend    = mm3CommSwP;

  components mm3SerialCommC;
  mm3CommSwP.SerialSend    -> mm3SerialCommC;
  mm3CommSwP.SerialControl -> mm3SerialCommC;

  components mm3RadioCommC;
  mm3CommSwP.RadioSend    -> mm3RadioCommC;
  mm3CommSwP.RadioControl -> mm3RadioCommC;

  components PanicC;
  mm3CommSwP.Panic -> PanicC;
}
