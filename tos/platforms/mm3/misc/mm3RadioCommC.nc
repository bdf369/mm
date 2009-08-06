/**
 * Copyright @ 2008 Eric B. Decker
 * @author Eric B. Decker
 */
 
configuration mm3RadioCommC {
  provides {
    interface pakSend;
    interface SplitControl;
  }
}

implementation {
  components RadioPakDirectC as RadioSender;
  pakSend = RadioSender;
  SplitControl = RadioSender;
}
