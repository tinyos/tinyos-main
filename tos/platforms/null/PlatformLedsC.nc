// $Id: PlatformLedsC.nc,v 1.5 2007-05-23 22:17:49 idgay Exp $
/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Dummy implementation to support the null platform.
 */

module PlatformLedsC
{
  provides interface GeneralIO as Led0;
  provides interface GeneralIO as Led1;
  provides interface GeneralIO as Led2;
  uses interface Init;
}
implementation
{

  async command void Led0.set() {
  }

  async command void Led0.clr() {
  }

  async command void Led0.toggle() {
  }

  async command bool Led0.get() {
    return FALSE;
  }

  async command void Led0.makeInput() {
  }

  async command void Led0.makeOutput() {
    call Init.init();
  }

  async command void Led1.set() {
  }

  async command void Led1.clr() {
  }

  async command void Led1.toggle() {
  }

  async command bool Led1.get() {
    return FALSE;
  }

  async command void Led1.makeInput() {
  }

  async command void Led1.makeOutput() {
    call Init.init();
  }

  async command void Led2.set() {
  }

  async command void Led2.clr() {
  }

  async command void Led2.toggle() {
  }

  async command bool Led2.get() {
    return FALSE;
  }

  async command void Led2.makeInput() {
  }

  async command void Led2.makeOutput() {
    call Init.init();
  }

  async command bool Led0.isInput() { 
    return FALSE;
  }

  async command bool Led0.isOutput() { 
    return FALSE;
  }

  async command bool Led1.isInput() { 
    return FALSE;
  }

  async command bool Led1.isOutput() { 
    return FALSE;
  }

  async command bool Led2.isInput() { 
    return FALSE;
  }

  async command bool Led2.isOutput() { 
    return FALSE;
  }

}
