/**
 * Copyright (c) 2009 Eric B. Decker
 * @author Eric B. Decker, <cire831@gmail.com>
 * @date June 30, 2009
 */

#include "mm3_comm.h"

configuration mm3CommDispatchC {
  provides interface pakSend[uint8_t cid];
}

implementation {
  components new nPakQueueSenderP(MM3_COMM_NUM_CLIENTS);
  pakSend  = nPakQueueSenderP;

  components mm3CommSwC;
  nPakQueueSenderP.pakBotSend -> mm3CommSwC;
}
