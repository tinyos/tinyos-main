/*
 * "Copyright (c) 2006 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 */
 
/**
 * This application is used to test the basic functionality of the printf service.  
 * It is initiated by calling the start() command of the SplitControl interface 
 * provided by the PrintfC component.  After starting the printf service, calls to 
 * the standard c-style printf command are made to print various strings of text 
 * over the serial line.  Only upon calling PrintfFlush.flush() does the data 
 * actually get sent out over the serial line.
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.6 $
 * @date $Date: 2008-06-12 12:55:33 $
 */
 
#include "printf.h"

configuration TestPrintfAppC{
}
implementation {
  components MainC, TestPrintfC;

  TestPrintfC.Boot -> MainC;
}

