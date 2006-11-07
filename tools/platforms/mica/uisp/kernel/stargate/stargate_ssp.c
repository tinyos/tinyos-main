/*
 * sg_ssp.c -- Stargate SSP Driver for mote programming
 *
 * Portions Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.

 * Portions Copyright (C) 2001 Alessandro Rubini and Jonathan Corbet
 * Copyright (C) 2001 O'Reilly & Associates
 *
 * The source code in this file can be freely used, adapted,
 * and redistributed in source or binary form, so long as an
 * acknowledgment appears in derived source files.  The citation
 * should list that the code comes from the book "Linux Device
 * Drivers" by Alessandro Rubini and Jonathan Corbet, published
 * by O'Reilly & Associates.   No warranty is attached;
 * we cannot take responsibility for errors or fitness for use.
 *
 * $Id: stargate_ssp.c,v 1.3 2006-11-07 19:30:42 scipio Exp $
 */

#ifndef __KERNEL__
#  define __KERNEL__
#endif
#ifndef MODULE
#  define MODULE
#endif

#include <linux/config.h>

#ifdef CONFIG_MODVERSIONS
#define MODVERSIONS
#include <linux/modversions.h>
#endif

#include <linux/kernel.h> /* printk() */
#include <linux/module.h>
#include <linux/sched.h>

#include <linux/fs.h>     /* everything... */
#include <linux/errno.h>  /* error codes */
#include <linux/delay.h>  /* udelay */
#include <linux/slab.h>
#include <linux/mm.h>
#include <linux/ioport.h>
#include <linux/interrupt.h>
#include <linux/tqueue.h>
#include <linux/poll.h>
#include <linux/init.h>

#include <asm/io.h>
#include <asm/system.h>
#include <asm/hardware.h>
#include <asm/irq.h>

#define SG_SSP_PHYSBASE (__PREG(SSCR0))
#define SG_SSP_SIZE	(5*4) /* 5 Registers, 4 Bytes each */

#define SG_GPIOCNTL_PHYSBASE (__PREG(GPLR0))
#define SG_GPIOCNTL_SIZE (27*4) /* 27 Registers, 4 Bytes each */

#define SSPS_TNF		(1 << 2)
#define SSPS_RNE		(1 << 3)
#define SSPS_BSY		(1 << 4)
#define SSPS_TFS		(1 << 5)
#define SSPS_RFS		(1 << 6)
#define SSPS_ROR		(1 << 7)

#define SSPC_SSE		(1 << 7)
/*
 * all of the parameters have no "sg_ssp_" prefix, to save typing when
 * specifying them at load time
 */
static int major = 0; /* dynamic by default */
MODULE_PARM(major, "i");

/* Since sg_ssp_base is vremapped in case use_mem==1, remember the phys addr. */
unsigned long sg_ssp_vbase;

MODULE_AUTHOR ("Phil Buonadonna");
MODULE_DESCRIPTION ("Stargate SSP Driver v 0.91");
/*
 * The devices with low minor numbers write/read burst of data to/from
 * specific I/O ports (by default the parallel ones).
 * 
 * The device with 128 as minor number returns ascii strings telling
 * when interrupts have been received. Writing to the device toggles
 * 00/FF on the parallel data lines. If there is a loopback wire, this
 * generates interrupts.  
 */

int sg_ssp_open (struct inode *inode, struct file *filp)
{
  MOD_INC_USE_COUNT;


  GPCR(22) = GPIO_bit(22); // MUX -> Programming mode
  
  SSCR0 = ((10 << 8) | SSPC_SSE | 7);  /* SRC=3, SSE, DSS = 8-bit data */
  
  /* Put attached mote into reset */
  GPCR(77) = GPIO_bit(77); // RSTN -> 0
  
  return 0;
}


int sg_ssp_release (struct inode *inode, struct file *filp)
{
  SSCR0 = 0;

  GPSR(22) = GPIO_bit(22); // MUX -> Serial Comm mode

  /* Clear the reset */
  GPSR(77) = GPIO_bit(77); // RSTN -> 1

  MOD_DEC_USE_COUNT;
  return 0;
}


ssize_t sg_ssp_read(struct file *filp, char *buf, size_t count, loff_t *f_pos)
{
  int retval = count, lcnt = count;
  unsigned char *kbuf=kmalloc(count, GFP_KERNEL), *ptr;
  unsigned int value;

  if (!kbuf) {
    return -ENOMEM;
  }

  ptr = kbuf;

  while (lcnt > 0) {
    while (!(SSSR & SSPS_RNE)) {
      cpu_relax();
    }
    value = SSDR;
    *(ptr++) = value;
    //printk(KERN_INFO "sg_ssp: read 0x%lx from ssp\n",value);
    lcnt--;
  }

  if ( (retval > 0) && copy_to_user(buf, kbuf, retval))
    retval = -EFAULT;
  kfree(kbuf);

  return retval;
}

ssize_t sg_ssp_write(struct file *filp, const char *buf, size_t count,
		     loff_t *f_pos)
{
  int retval = count, lcnt = count;
  unsigned char *kbuf=kmalloc((count+1), GFP_KERNEL), *ptr;
  unsigned int value;

  if (!kbuf) {
    return -ENOMEM;
  }
  if (copy_from_user(kbuf, buf, count)) {
    return -EFAULT;
  }
  ptr = kbuf;

  while (lcnt > 0) {
    while (!(SSSR & SSPS_TNF)) {
      cpu_relax();
    }
    value = *(ptr++);
    SSDR = value;
    //printk(KERN_INFO "sg_ssp: wrote 0x%lx to ssp\n",value);
    lcnt--;
  }
  kfree(kbuf);
  return retval;

}



unsigned int sg_ssp_poll(struct file *filp, poll_table *wait)
{
  return POLLIN | POLLRDNORM | POLLOUT | POLLWRNORM;
}


struct file_operations sg_ssp_fops = {
  read: sg_ssp_read,
  write: sg_ssp_write,
  poll: sg_ssp_poll,
  open: sg_ssp_open,
  release: sg_ssp_release,
};


void sg_ssp_interrupt(int irq, void *dev_id, struct pt_regs *regs)
{

  unsigned int status = SSSR;

  if (status & SSPS_ROR) {
    printk(KERN_WARNING "sg_ssp: receiver overrun 0x%lx",status);
    SSSR = SSPS_ROR;
  }

}



/* Two wrappers, to use non-page-aligned ioremap() on 2.0 */

/* Remap a not (necessarily) aligned port region */
void *sg_ssp_remap(unsigned long phys_addr, unsigned long phys_size)
{
  /* The code comes mainly from arch/any/mm/ioremap.c */
  unsigned long offset, last_addr, size;

  last_addr = phys_addr + phys_size - 1;
  offset = phys_addr & ~PAGE_MASK;
    
    /* Adjust the begin and end to remap a full page */
  phys_addr &= PAGE_MASK;
  size = PAGE_ALIGN(last_addr) - phys_addr;
  return ioremap(phys_addr, size) + offset;
}

/* Unmap a region obtained with sg_ssp_remap */
void sg_ssp_unmap(void *virt_add)
{
  iounmap((void *)((unsigned long)virt_add & PAGE_MASK));
}

/* Finally, init and cleanup */

int sg_ssp_init(void)
{
  int result;
  
  /* Set up owner pointers.*/
  SET_MODULE_OWNER(&sg_ssp_fops);
  
  /* Get our needed resources. */
  result = check_mem_region(SG_SSP_PHYSBASE, SG_SSP_SIZE);
  if (result) {
    printk(KERN_INFO "sg_ssp: can't get I/O mem address 0x%lx\n",
	   SG_SSP_PHYSBASE);
    return result;
  }
  request_mem_region(SG_SSP_PHYSBASE, SG_SSP_SIZE, "SSP");
  
  result = check_mem_region(SG_GPIOCNTL_PHYSBASE, SG_GPIOCNTL_SIZE);
  if (result) {
    printk(KERN_INFO "sg_ssp: can't get GPIO I/O mem address 0x%lx\n",
	   SG_GPIOCNTL_PHYSBASE);
    return result;
  }
  request_mem_region(SG_GPIOCNTL_PHYSBASE, SG_GPIOCNTL_SIZE, "SSPGPIO");

  /* also, ioremap it */
  sg_ssp_vbase = (unsigned long)sg_ssp_remap(SG_SSP_PHYSBASE,SG_SSP_SIZE);
  /* Hmm... we should check the return value */
  
  result = register_chrdev(major, "ssp", &sg_ssp_fops);
  if (result < 0) {
    printk(KERN_INFO "sg_ssp: can't get major number\n");
    sg_ssp_unmap((void *)sg_ssp_vbase);
    release_mem_region(SG_SSP_PHYSBASE,SG_SSP_SIZE);
    return result;
  }
  if (major == 0) major = result; /* dynamic */
  
  result = request_irq(IRQ_SSP, sg_ssp_interrupt,
		       SA_INTERRUPT, "ssp", NULL);
  if (result) {
    printk(KERN_INFO "sg_ssp: can't get assigned irq %i\n",
	   IRQ_SSP);
    sg_ssp_unmap((void *)sg_ssp_vbase);
    release_mem_region(SG_SSP_PHYSBASE,SG_SSP_SIZE);
    return result;
  }

  SSSR = SSPS_ROR;
  SSCR1 = 0;

  // Enable the SSP alternate functions
  set_GPIO_mode(GPIO23_SCLK_md);
  set_GPIO_mode(GPIO25_STXD_MD); // Enable the SSP TX/RX lines
  set_GPIO_mode(GPIO26_SRXD_MD);

  set_GPIO_mode((GPIO27_SEXTCLK | GPIO_IN));    // Avoid driving the RED LED
  set_GPIO_mode((22 | GPIO_OUT));		// MUX Selector
  set_GPIO_mode((77 | GPIO_OUT));		// RSTN 

  /* Set the state of the reset pin */
  GPSR(77) = GPIO_bit(77);  // RSTN -> 1
 
  return 0;
}

void sg_ssp_cleanup(void)
{

  free_irq(IRQ_SSP,NULL);
  unregister_chrdev(major, "ssp");
  sg_ssp_unmap((void *)sg_ssp_vbase);
  release_mem_region(SG_SSP_PHYSBASE,SG_SSP_SIZE);
  release_mem_region(SG_GPIOCNTL_PHYSBASE,SG_GPIOCNTL_SIZE);
}

module_init(sg_ssp_init);
module_exit(sg_ssp_cleanup);








