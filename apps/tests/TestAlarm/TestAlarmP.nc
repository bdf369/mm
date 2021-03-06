/*
 * Copyright (c) 2008 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
 
/*
 * @author: Kevin Klues (klueska@cs.stanford.edu)
 * @author: Eric B. Decker <cire831@gmail.com>
 */


#include "Timer.h"

module TestAlarmP {
  uses interface Alarm<T32khz, uint16_t> as Alarm0;
  uses interface Alarm<T32khz, uint16_t> as Alarm1;
  uses interface Alarm<T32khz, uint16_t> as Alarm2;
  uses interface Leds;
  uses interface Boot;
}

implementation {
  event void Boot.booted() {
    call Alarm0.start( 2500 );
    call Alarm1.start( 5000 );
    call Alarm2.start( 10000 );
  }

  async event void Alarm0.fired() {
    call Leds.led0Toggle();
    call Alarm0.start( 2500 );
  }

  async event void Alarm1.fired() {
    call Leds.led1Toggle();
    call Alarm1.start( 5000 );
  }

  async event void Alarm2.fired() {
    call Leds.led2Toggle();
    call Alarm2.start( 10000 );
  }
}
