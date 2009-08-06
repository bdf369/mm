/*
 * Copyright (c) 2008-2009, Eric B. Decker
 * All rights reserved.
 */

/**
 * mm3Comm provides a single interface that can be switched between
 * the radio or the direct connect serial line.
 *
 * This is the serial interface.  It includes arbitration around access
 * to the serial hardware and any associated hardware.
 *
 * @author Eric B. Decker, <cire831@gmail.com>
 * @date   Apr 3 2008, June 30, 2009
 */ 

#include "sensors.h"

uint16_t mm3Serial_busy;

module mm3SerialCommP {
  provides {
    interface Init;
    interface pakSend;
  }
  uses {
    interface Resource;
    interface ResourceRequested;
    interface pakSend as SubSend;
  }
}

implementation {
  error_t busy = FALSE;

#ifndef SERIAL_DEFAULT_OWNER
  am_addr_t my_addr;
  message_t* my_msg;
  uint8_t my_len;
  uint8_t my_id;

  void release() {
    busy = FALSE;
    call Resource.release();
  }

#endif

  
#ifdef SERIAL_DEFAULT_OWNER
  command error_t Init.init() {
    return call Resource.immediateRequest();
  }

  command error_t pakSend.send(message_t *msg) {
    error_t e;
    if (busy == FALSE) {
      if (call Resource.isOwner() == TRUE) {
        atomic busy = TRUE;
        if ((e = call SubSend.send(msg)) != SUCCESS)
          atomic busy = FALSE;
        return e;
      }
      return FAIL;
    }
    return EBUSY;
  }

  event void Resource.granted() {}

  event void SubSend.sendDone(message_t* msg, error_t err) {
    atomic busy = FALSE;
    signal pakSend.sendDone(msg, err);
  }
  
  command error_t pakSend.cancel(message_t* msg) {
    error_t e = call SubSend.cancel(msg);
    if (e == SUCCESS) busy = FALSE;
    return e;
  }
  
  void requested() {
    if (!busy) {
      if (call Resource.isOwner() == TRUE) {
        call Resource.release();
        call Resource.request();
      } 
    }
  }
  
  async event void ResourceRequested.requested() {
    requested();
  }

  async event void ResourceRequested.immediateRequested() {
    requested();
  }

#else

  command error_t Init.init() {
    return SUCCESS;
  }

  command error_t pakSend.send(message_t *msg) {
    if (busy == FALSE) {
      if (call Resource.request() == SUCCESS) {
        busy = TRUE;
        my_msg = msg;
        return SUCCESS;
      }
    }
    mm3Serial_busy++;
    return EBUSY;
  }

  event void Resource.granted() {
    error_t e;
    if ((e = call SubSend.send(my_msg)) != SUCCESS ) {
      release();
      signal pakSend.sendDone(my_msg, e);
    }
  }

  event void SubSend.sendDone(message_t* msg, error_t err) {
    release();
    signal pakSend.sendDone(msg, err);
  }
  
  command error_t pakSend.cancel(message_t* msg) {
    error_t e = call SubSend.cancel(msg);
    if (e == SUCCESS) release();
    return e;
  }

  async event void ResourceRequested.requested() { }

  async event void ResourceRequested.immediateRequested() { }

#endif

}
