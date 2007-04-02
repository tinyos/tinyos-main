/*                                                                      tab:2
 *
 * "Copyright (c) 2000-2007 The Regents of the University of
 * California.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */


/**
 * A generic interface to read from and write to the internal flash of
 * a microcontroller.
 *
 * @author Jonathan Hui <jwhui@cs.berkeley.edu>
 * @author Prabal Dutta <prabal@cs.berkeley.edu> (Port to T2)
 */
interface InternalFlash {

  /**
   * Read <code>size</code> bytes starting from <code>addr</code> and
   * return them in <code>buf</code>.
   *
   * @param   addr A pointer to the starting address from which to read.
   * @param   buf  A pointer to the buffer into which read bytes are
   *               placed.
   * @param   size The number of bytes to read.
   * @return  SUCCESS if the bytes were successfully read.
   *          FAIL if the call could not be completed.
   */
  command error_t read(void* addr, void* buf, uint16_t size);

  /**
   * Write <code>size</code> bytes from <code>buf</code> into internal
   * flash starting at <code>addr</code>.
   *
   * @param   addr A pointer to the starting address to which to write.
   * @param   buf  A pointer to the buffer from which bytes are read.
   * @param   size The number of bytes to write.
   * @return  SUCCESS if the bytes were successfully written.
   *          FAIL if the call could not be completed.
   */
  command error_t write(void* addr, void* buf, uint16_t size);
}
