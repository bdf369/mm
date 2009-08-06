/*
 * Copyright (c) 2008-2009, Eric B. Decker
 * All rights reserved.
 *
 * Provides multiplexing a single newPak packet stream out to
 * multiple possible outputs depending on the value of a switch.
 *
 * Packets are variable encapsulated newPaks and include all
 * encapsulation information in the packet.  This includes any AM
 * or port information.  In other words packets are almost ready to
 * go out what ever hardware interface they are slated for.  The only
 * thing missing is any low level h/w encapsulation.  This can't be
 * added until we are ready to do the actual send and know which h/w
 * port we want to go out.
 *
 * @author Eric B. Decker
 * @date   Apr 3 2008, June 30, 2009
 */ 

#include "Serial.h"
#include "sensors.h"
#include "panic.h"

typedef enum {
  COMM_STATE_OFF         = 0,
  COMM_STATE_SERIAL_REQUEST,
  COMM_STATE_SERIAL_INIT,
  COMM_STATE_SERIAL,
  COMM_STATE_SERIAL_RELEASED,
  COMM_STATE_RADIO_REQUEST,
  COMM_STATE_RADIO_INIT,
  COMM_STATE_RADIO,
} comm_state_t;


module mm3CommSwP {
  provides {
    interface mm3CommSw;
    interface pakSend;
//  interface Receive;
  }
  uses {
    interface Panic;
  
    interface SplitControl as SerialControl;
    interface pakSend      as SerialSend;
//  interface pakReceive   as SerialReceive;

    interface SplitControl as RadioControl;
    interface pakSend      as RadioSend;
//  interface pakReceive   as RadioReceive;
  }
}

implementation {

  comm_state_t comm_state;


  //********************* Use SERIAL *******************************//

  command error_t mm3CommSw.useSerial() {
    if (comm_state == COMM_STATE_SERIAL)
      return EALREADY;
    if (comm_state == COMM_STATE_OFF || comm_state == COMM_STATE_RADIO) {
      comm_state = COMM_STATE_SERIAL_INIT;
      call SerialControl.start();
      return SUCCESS;
    } 
    return EBUSY;
  }

  event void SerialControl.startDone(error_t error) {
    if (error == SUCCESS) {
      comm_state = COMM_STATE_SERIAL; 
      signal mm3CommSw.serialOn();
    } else {
      call Panic.panic(PANIC_COMM, 20, error, 0, 0, 0);
      call SerialControl.start();
    }
  }
  
  //********************* Use RADIO *******************************//

  command error_t mm3CommSw.useRadio() {
    if(comm_state == COMM_STATE_RADIO)
      return EALREADY;
    if(comm_state == COMM_STATE_OFF || comm_state == COMM_STATE_SERIAL) {
      comm_state = COMM_STATE_RADIO_INIT;
      call RadioControl.start();
      return SUCCESS;
    } 
    return EBUSY;
  }

  event void RadioControl.startDone(error_t error) {
    if(error == SUCCESS) {
      comm_state = COMM_STATE_RADIO; 
      signal mm3CommSw.radioOn();
    } else {
      call Panic.panic(PANIC_COMM, 21, error, 0, 0, 0);
      call RadioControl.start();
    }
  }
  
  //********************* Use NONE *******************************//

  command error_t mm3CommSw.useNone() {
    if(comm_state == COMM_STATE_OFF)
      return EALREADY;
    if(comm_state == COMM_STATE_SERIAL) {
      comm_state = COMM_STATE_SERIAL_INIT;
      call SerialControl.stop();
      return SUCCESS;
    } 
    if(comm_state == COMM_STATE_RADIO) {
      comm_state = COMM_STATE_RADIO_INIT;
      call RadioControl.stop();
      return SUCCESS;
    } else
      return EBUSY;
  }

  event void SerialControl.stopDone(error_t error) {
    if(error == SUCCESS) {
      comm_state = COMM_STATE_OFF; 
      signal mm3CommSw.commOff();
    } else {
      call Panic.panic(PANIC_COMM, 22, error, 0, 0, 0);
      call SerialControl.stop();
    }
  }

  event void RadioControl.stopDone(error_t error) {
    if(error == SUCCESS) {
      comm_state = COMM_STATE_OFF; 
      signal mm3CommSw.commOff();
    } else {
      call Panic.panic(PANIC_COMM, 23, error, 0, 0, 0);
      call RadioControl.stop();
    }
  }

  //********************* Receiving *******************************//

#ifdef notdef
  event message_t* SerialReceive.receive[uint8_t cid](message_t* msg, void* payload, uint8_t len) {
    return signal Receive.receive[id](msg, payload, len);
  }

  event message_t* RadioReceive.receive[uint8_t cid](message_t* msg, void* payload, uint8_t len) {
    return signal Receive.receive[id](msg, payload, len);
  }
#endif



  void bad_comm_state(uint8_t where) {
    call Panic.panic(PANIC_COMM, where, comm_state, 0, 0, 0);
  }

  //********************* Sending *******************************//

  command error_t pakSend.send(message_t* msg) {
    switch (comm_state) {
      case COMM_STATE_SERIAL:
	return call SerialSend.send(msg);
      case COMM_STATE_RADIO:
	return call RadioSend.send(msg);

      default:
      case COMM_STATE_OFF:
      case COMM_STATE_SERIAL_INIT:
      case COMM_STATE_RADIO_INIT:
	bad_comm_state(37);
	return FAIL;
    }
  }

  command error_t pakSend.cancel(message_t* msg) {
    switch (comm_state) {
      case COMM_STATE_OFF:
	return EOFF;  
      case COMM_STATE_SERIAL_INIT:
      case COMM_STATE_RADIO_INIT:
	return EBUSY;
      case COMM_STATE_SERIAL:
	return call SerialSend.cancel(msg);
      case COMM_STATE_RADIO:
	return call RadioSend.cancel(msg);
      default:
	bad_comm_state(38);
	return FAIL;
    }  
  }

  event void SerialSend.sendDone(message_t* msg, error_t error) {
    signal pakSend.sendDone(msg, error);
  }
  
  event void RadioSend.sendDone(message_t* msg, error_t error) {
    signal pakSend.sendDone(msg, error);
  }

#ifdef notdef
  default event void pakSend.sendDone(message_t* msg, error_t error) {
    bad_comm_state(0);
  }
#endif
}
