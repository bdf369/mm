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

/**
 * @author Kevin Klues <klueska@cs.stanford.edu>
 * @date March 3rd, 2008
 */

import net.tinyos.message.*;
import net.tinyos.util.*;
import java.io.*;
/**
*/

public class Mm3SerialCollectApp implements MessageListener {
  MoteIF mote;

  /* Main entry point */
  void run() {
    mote = new MoteIF(PrintStreamMessenger.err);
    mote.registerListener(new CollectMsg(), this);
  }
  
  void printSensorData(CollectMsg msg, int offset, int len) {
    for(int i=offset; i<len; i++)
      System.out.println("  [data["+(i-offset)+"]=0x"+ Integer.toHexString(msg.getElement_buffer(i))+"]");
  }

  synchronized public void messageReceived(int dest_addr, Message msg) {
    if (msg instanceof CollectMsg) {
      //DtIgnoreMsg ignoreMsg = new DtIgnoreMsg(msg, 0);
      //System.out.print(ignoreMsg.toString());
      DtSensorDataMsg sensorDataMsg = new DtSensorDataMsg(msg, 0);
      System.out.print(sensorDataMsg.toString());
      printSensorData((CollectMsg)msg, sensorDataMsg.offset_data(0), sensorDataMsg.get_len());
    }
  }

  public static void main(String[] args) {
    Mm3SerialCollectApp me = new Mm3SerialCollectApp();
    me.run();
  }
}