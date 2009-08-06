/**
 * Copyright @ 2008-2009 Eric B. Decker
 * @author Eric B. Decker
 */

#include "mm3_comm.h"

configuration mm3CommDataC {
  provides interface mm3CommData[uint8_t sns_id];
}

implementation {
  components mm3CommDataP;
  mm3CommData = mm3CommDataP;

  components PanicC;
  mm3CommDataP.Panic -> PanicC;

  components new nPakQueueSenderP(MM3_NUM_SENSORS);
  mm3CommDataP.pakSend  -> nPakQueueSenderP;
  mm3CommDataP.SendBusy -> nPakQueueSenderP;

  components mm3CommDispatchC;
  nPakQueueSenderP.pakBotSend     -> mm3CommDispatchC.pakSend[MM3_COMM_DATA];

  components nPakC, AMEncapC;
  mm3CommDataP.nPak-> nPakC;
  mm3CommDataP.AMEncap  -> AMEncapC;
  
  components LedsC;
  mm3CommDataP.Leds -> LedsC;
}
