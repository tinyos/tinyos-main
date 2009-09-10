/*
 * Copyright (c) 2009 Johns Hopkins University.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the (updated) modification history and the author appear in
 * all copies of this source code.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
 * OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 */

configuration BlockingConfigStorageP {
  provides {
    interface BlockingConfig[uint8_t id];
    interface BlockingMount[uint8_t id];
  }
  
  uses {
    interface ConfigStorage[uint8_t id];
    interface Mount as ConfigMount[uint8_t id];
  }
}

implementation {
  components MainC,
             SystemCallC,
             SystemCallQueueC,
             BlockingConfigStorageImplP;
             
  MainC.SoftwareInit -> BlockingConfigStorageImplP;
  
  BlockingConfig = BlockingConfigStorageImplP;
  BlockingMount = BlockingConfigStorageImplP;
  ConfigStorage = BlockingConfigStorageImplP;
  ConfigMount = BlockingConfigStorageImplP;
  
  BlockingConfigStorageImplP.SystemCall -> SystemCallC;
  BlockingConfigStorageImplP.SystemCallQueue -> SystemCallQueueC;
}
