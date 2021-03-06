/*
 * Copyright (c) 2008, 2010, Eric B. Decker
 * All rights reserved.
 */

/**
 * mmComm provides a single interface that can be switched between
 * the radio or the dock serial.
 *
 * Each channel (control, debug, or data) contends for the comm line.
 * Data packets contend with each other before contending for the
 * comm line with control and debug traffic.
 *
 * DockComm provides the interface to the dock serial port.
 * DockCommArbiter assumes that the dock serial port is shared
 * and is arbitrated.  DockComm assumes the port is dedicated.
 *
 * @author Eric B. Decker
 * @date   Apr 3 2008
 * @date   Feb 24 2010
 */ 

#include "AM.h"
#include "sensors.h"

uint16_t mmSerial_busy;

module DockCommP {
  provides {
    interface Init;
    interface AMSend[uint8_t id];
  }
  uses {
    interface Resource;
    interface ResourceRequested;
    interface AMSend as SubAMSend[uint8_t client_id];
    interface Leds;
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

  command error_t AMSend.send[uint8_t id](am_addr_t addr, message_t *msg, uint8_t len) {
    error_t e;
    if(busy == FALSE) {
      if(call Resource.isOwner() == TRUE) {
        atomic busy = TRUE;
        if( (e = call SubAMSend.send[id](addr, msg, len)) != SUCCESS )
          atomic busy = FALSE;
        return e;
      }
      return FAIL;
    }
    return EBUSY;
  }

  event void Resource.granted() {}

  event void SubAMSend.sendDone[uint8_t id](message_t* msg, error_t err) {
    atomic busy = FALSE;
    signal AMSend.sendDone[id](msg, err);
  }
  
  command error_t AMSend.cancel[uint8_t id](message_t* msg) {
    error_t e = call SubAMSend.cancel[id](msg);
    if(e == SUCCESS) busy = FALSE;
    return e;
  }
  
  void requested() {
    if(!busy) {
      if(call Resource.isOwner() == TRUE) {
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

  command error_t AMSend.send[uint8_t id](am_addr_t addr, message_t *msg, uint8_t len) {
    if(busy == FALSE) {
      if(call Resource.request() == SUCCESS) {
        busy = TRUE;
        my_addr = addr;
        my_msg = msg;
        my_len = len;
        my_id = id;
        return SUCCESS;
      }
    }
    mmSerial_busy++;
    return EBUSY;
  }

  event void Resource.granted() {
    error_t e;
    if( (e = call SubAMSend.send[my_id](my_addr, my_msg, my_len)) != SUCCESS ) {
      release();
      signal AMSend.sendDone[my_id](my_msg, e);
    }
  }

  event void SubAMSend.sendDone[uint8_t id](message_t* msg, error_t err) {
    release();
    signal AMSend.sendDone[id](msg, err);
  }
  
  command error_t AMSend.cancel[uint8_t id](message_t* msg) {
    error_t e = call SubAMSend.cancel[id](msg);
    if(e == SUCCESS) release();
    return e;
  }

  async event void ResourceRequested.requested() { }

  async event void ResourceRequested.immediateRequested() { }

#endif

  command uint8_t AMSend.maxPayloadLength[uint8_t id]() {
    return call SubAMSend.maxPayloadLength[id]();
  }

  command void* AMSend.getPayload[uint8_t id](message_t* msg, uint8_t len) {
    return call SubAMSend.getPayload[id](msg, len);
  }

  default event void AMSend.sendDone[uint8_t id](message_t* msg, error_t err) {
  }

  default command error_t SubAMSend.send[uint8_t id](am_addr_t addr, message_t *msg, uint8_t len) {
    return FAIL;
  }
}
