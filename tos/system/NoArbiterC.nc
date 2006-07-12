/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * A do-nothing arbiter for non-shared resources which need to pretend to
 * have arbitration. Just grants all requests, without any error
 * checking. Does still call ResourceConfigure at the right time.
 *
 * @author David Gay
 */

generic module NoArbiterC() {
  provides interface Resource;
  uses interface ResourceConfigure;
}
implementation {
  task void granted() {
    call ResourceConfigure.configure();
    signal Resource.granted();
  }

  async command error_t Resource.request() {
    post granted();
    return SUCCESS;
  }

  async command error_t Resource.immediateRequest() {
    call ResourceConfigure.configure();
    return SUCCESS;
  }  

  async command void Resource.release() {
    call ResourceConfigure.unconfigure();
  } 

  async command uint8_t Resource.isOwner() {
    return TRUE;
  }

  default async command void ResourceConfigure.configure() { }
  default async command void ResourceConfigure.unconfigure() { }
}
