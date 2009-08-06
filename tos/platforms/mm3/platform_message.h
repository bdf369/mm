/* $Id: platform_message.h,v 1.5 2008/02/19 22:03:45 scipio Exp $
 * Copyright (c) 2008-2009 Eric B. Decker
 * "Copyright (c) 2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Defining the platform independently named packet structures for the MM3
 * platform.  Currently this is defined for serial, cc2420 radio, and AM
 * headers.  The AM header is a place holder until a determination is made
 * for how to send the packet out is made.  What actual interface is determined
 * later on the way out.  At that time the header is written for the interface
 * as appropriate.
 *
 * @author Eric B. Decker <cire831@gmail.com>
 * @author Philip Levis
 * @version $Revision: 1.5 $ $Date: 2008/02/19 22:03:45 $
 */


#ifndef PLATFORM_MESSAGE_H
#define PLATFORM_MESSAGE_H

#include <CC2420.h>
#include <Serial.h>
#include <AM.h>

typedef union message_header {
  cc2420_header_t cc2420;
  serial_header_t serial;
  am_header_t     am;
} message_header_t;

#define ENCAP_RX_RADIO_START  0
#define ENCAP_RX_SERIAL_START (sizeof(cc2420_header_t) - sizeof(serial_header_t))

typedef union TOSRadioFooter {
  cc2420_footer_t cc2420;
} message_footer_t;

typedef union TOSRadioMetadata {
  cc2420_metadata_t cc2420;
  serial_metadata_t serial;
} message_metadata_t;

#endif
