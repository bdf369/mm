/*
 * Copyright (c) 2008 Stanford University.
 * Copyright (c) 2008 Eric B. Decker
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
 
/**
 * @author Kevin Klues (klueska@cs.stanford.edu)
 * @author Eric B. Decker (cire831@gmail.com)
 */

configuration GPSByteCollectC {
  provides interface StdControl as GPSByteControl;
}

implementation {
  components MainC, GPSByteCollectP;
  MainC.SoftwareInit -> GPSByteCollectP;
  GPSByteControl = GPSByteCollectP;

  components new Msp430GpioC() as GPSBitC;
  components HplMsp430GeneralIOC as GeneralIOC;
  GPSBitC -> GeneralIOC.Port13;
  GPSByteCollectP.gpsRx -> GPSBitC;

  components new Msp430InterruptC() as InterruptGPSBitC;
  components HplMsp430InterruptC as InterruptC;
  InterruptGPSBitC.HplInterrupt -> InterruptC.Port13;
  GPSByteCollectP.gspRxInt -> InterruptGPSBitC;

  components HplMM3AdcC;
  GPSByteCollectP.HW -> HplMM3AdcC;

  components PanicC;
  GPSByteCollectP.Panic -> PanicC;

  components new TimerMilliC() as BitTimer;
  GPSByteCollectP.BitTimer -> BitTimer;
}