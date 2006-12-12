/* Copyright (c) 2002-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Mount a volume.
 *
 * @author David Gay
 * @version $Revision: 1.4 $ $Date: 2006-12-12 18:23:14 $
 */

interface Mount {
  /**
   * Mount a particular volume. This must be done before the volume's
   * first use. <code>mountDone</code> will be signaled if SUCCESS is
   * returned.
   * @return SUCCESS if mount request is accepted, FAIL if mount has
   *   already been attempted.
   */
  command error_t mount();

  /**
   * Report success or failure of mount operation. If the mount failed,
   * no operation should be perfomed on the volume. Note that success
   * should not be used to indicate that the volume contains valid data,
   * rather failure indicates some major internal problem that prevents
   * the volume from being used.
   *
   * @param error SUCCESS if the mount succeeded, FAIL otherwise.
   */
  event void mountDone(error_t error);
}
