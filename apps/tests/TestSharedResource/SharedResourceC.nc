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
 * SharedResourceC is used to provide a generic configuration around 
 * the SharedResourceP component so that new instantiations of 
 * it provide a single set of interfaces that are all properly associated 
 * with one another rather than requiring the user to deal with the complexity
 * of doing this themselves.
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.4 $
 * @date $Date: 2006-12-12 18:22:51 $
 */
 
#define TEST_SHARED_RESOURCE   "Test.Shared.Resource"
generic configuration SharedResourceC() {
	provides interface Resource;
	provides interface ResourceRequested;
	provides interface ResourceOperations;
    uses interface ResourceConfigure;
}
implementation {
  components SharedResourceP;
  
  enum {
    RESOURCE_ID = unique(TEST_SHARED_RESOURCE)
  };

  Resource = SharedResourceP.Resource[RESOURCE_ID];
  ResourceRequested = SharedResourceP.ResourceRequested[RESOURCE_ID];
  ResourceOperations = SharedResourceP.ResourceOperations[RESOURCE_ID];
  ResourceConfigure = SharedResourceP.ResourceConfigure[RESOURCE_ID];
}

