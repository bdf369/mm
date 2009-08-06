// $Id$
/*
 * Copyright (c) 2009 Eric B. Decker
 * All rights reserved.
 */

#ifdef CC2420_STACK

configuration RadioPakDirectC {
  provides {
    interface SplitControl;
    interface pakSend;
    interface pakReceive;
    interface pakReceive as Snoop[am_id_t id];
  }
}
implementation {
  components CC2420PakDirectC as RadioPak;

  SplitControl = RadioPak;
  pakSend      = RadioPak;
  pakReceive   = RadioPak.pakReceive;
  Snoop        = RadioPak.Snoop;
}

#else

module RadioPakDirectC {
  provides {
    interface SplitControl;
    interface pakSend;
    interface pakReceive;
    interface pakReceive as Snoop;
  }
}

implementation {

  command error_t SplitControl.start() {
    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    return SUCCESS;
  }

  command error_t pakSend.send(message_t* msg) {
    return SUCCESS;
  }

  command error_t pakSend.cancel(message_t* msg) {
    return SUCCESS;
  }
}

#endif
