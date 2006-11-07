// $Id: pxa27x_registers.h,v 1.3 2006-11-07 19:31:10 scipio Exp $ 

/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2002 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */
/*
 *
 * Authors:		Phil Buonadonna
 *
 * Edits:	Josh Herbach, Konrad Lorincz
 * Revised: 09/19/2005
 */

#ifndef _PXA27X_REGISTER_H
#define _PXA27X_REGISTER_H


#define _PXAREG(_addr)	(*((volatile uint32_t *)(_addr)))
#define _PXAREG_OFFSET(_addr,_off) (_PXAREG((uint32_t)(_addr) + (uint32_t)(_off)))

					
/******************************************************************************/
/* Memory Controller */
/******************************************************************************/
#define MDCNFG	_PXAREG(0x48000000) /* SDRAM Configuration register 6-43 */
#define MDREFR	_PXAREG(0x48000004) /* SDRAM Refresh Control register 6-53 */
#define MSC0	_PXAREG(0x48000008) /* Static Memory Control register 0 6-63 */
#define MSC1	_PXAREG(0x4800000C) /* Static Memory Control register 1 6-63 */
#define MSC2	_PXAREG(0x48000010) /* Static Memory Control register 2 6-63 */
#define MECR	_PXAREG(0x48000014) /* Expansion Memory (PC Card/CompactFlash) Bus Configuration register 6-79 */
#define SXCNFG	_PXAREG(0x4800001C) /* Synchronous Static Memory Configuration register 6-58 */
#define FLYCNFG	_PXAREG(0x48000020) /* Fly-by DMA DVAL<1:0> polarities 5-39 */
#define MCMEM0	_PXAREG(0x48000028) /* PC Card Interface Common Memory Space Socket 0 Timing Configuration register 6-77 */
#define MCMEM1	_PXAREG(0x4800002C) /* PC Card Interface Common Memory Space Socket 1 Timing Configuration register 6-77 */
#define MCATT0	_PXAREG(0x48000030) /* PC Card Interface Attribute Space Socket 0 Timing Configuration register 6-77 */
#define MCATT1	_PXAREG(0x48000034) /* PC Card Interface Attribute Space Socket 1 Timing Configuration register 6-77 */
#define MCIO0	_PXAREG(0x48000038) /* PC Card Interface I/o Space Socket 0 Timing Configuration register 6-78 */
#define MCIO1	_PXAREG(0x4800003C) /* PC Card Interface I/o Space Socket 1 Timing Configuration register 6-78 */
#define MDMRS	_PXAREG(0x48000040) /* SDRAM Mode Register Set Configuration register 6-49 */
#define BOOT_DEF	_PXAREG(0x48000044) /* Boot Time Default Configuration register 6-75 */
#define ARB_CNTL	_PXAREG(0x48000048) /* Arbiter Control register 29-2 */
#define BSCNTR0	_PXAREG(0x4800004C) /* System Memory Buffer Strength Control register 0 6-81 */
#define BSCNTR1	_PXAREG(0x48000050) /* System Memory Buffer Strength Control register 1 6-82 */
#define LCDBSCNTR	_PXAREG(0x48000054) /* LCD Buffer Strength Control register 7-102 */
#define MDMRSLP	_PXAREG(0x48000058) /* Special Low Power SDRAM Mode Register Set Configuration register 6-51 */
#define BSCNTR2	_PXAREG(0x4800005C) /* System Memory Buffer Strength Control register 2 6-83 */
#define BSCNTR3	_PXAREG(0x48000060) /* System Memory Buffer Strength Control register 3 6-84 */
#define SA1110	_PXAREG(0x48000064) /* SA-1110 Compatibility Mode for Static Memory register 6-70 */

/* MDCNFG Bit Defs */
#define MDCNFG_MDENX		(1 << 31)
#define MDCNFG_DCACX2		(1 << 30)
#define MDCNFG_DSA1110_2	(1 << 28)
#define MDCNFG_DADDR2		(1 << 26)
#define MDCNFG_DTC2(_x)		(((_x) & 0x3) << 24)
#define MDCNFG_DNB2		(1 << 23)
#define MDCNFG_DRAC2(_x)	(((_x) & 0x3) << 21)
#define MDCNFG_DCAC2(_x)	(((_x) & 0x3) << 19)
#define MDCNFG_DWID2		(1 << 18)
#define MDCNFG_DE3		(1 << 17)
#define MDCNFG_DE2		(1 << 16)
#define MDCNFG_STACK1		(1 << 15)
#define MDCNFG_DCACX0		(1 << 14)
#define MDCNFG_STACK0		(1 << 13)
#define MDCNFG_DSA1110_0	(1 << 12)
#define MDCNFG_DADDR0		(1 << 10)
#define MDCNFG_DTC0(_x)		(((_x) & 0x3) << 8)
#define MDCNFG_DNB0		(1 << 7)
#define MDCNFG_DRAC0(_x)	(((_x) & 0x3) << 5)
#define MDCNFG_DCAC0(_x)	(((_x) & 0x3) << 3)
#define MDCNFG_DWID0		(1 << 2)
#define MDCNFG_DE1		(1 << 1)
#define MDCNFG_DE0		(1 << 0)
#define MDCNFG_SETALWAYS	((1 << 27) | (1 << 11))

/* MDREFR Bit Defs */
#define MDREFR_ALTREFA	(1 << 31)	/* */
#define MDREFR_ALTREFB	(1 << 30)	/* */
#define MDREFR_K0DB4	(1 << 29)	/* */
#define MDREFR_K2FREE	(1 << 25)	/* */
#define MDREFR_K1FREE	(1 << 24)	/* */
#define MDREFR_K0FREE	(1 << 23)	/* */
#define MDREFR_SLFRSH	(1 << 22)	/* */
#define MDREFR_APD	(1 << 20)	/* */
#define MDREFR_K2DB2	(1 << 19)	/* */
#define MDREFR_K2RUN	(1 << 18)	/* */
#define MDREFR_K1DB2	(1 << 17)	/* */
#define MDREFR_K1RUN	(1 << 16)	/* */
#define MDREFR_E1PIN	(1 << 15)	/* */
#define MDREFR_K0DB2	(1 << 14)	/* */
#define MDREFR_K0RUN	(1 << 13)	/* */
#define MDREFR_DRI(_x)  ((_x) & 0xfff) /* */

/* MSCx Bit Defs */
#define MSC_RBUFF135	(1 << 31)		 /* Return Data Buff vs. Streaming  nCS 1,3 or 5 */
#define MSC_RRR135(_x)	(((_x) & (0x7)) << 28)	/* ROM/SRAM Recovery Time  nCS 1,3 or 5 */
#define MSC_RDN135(_x)	(((_x) & (0x7)) << 24)	/* ROM Delay Next Access nCS 1,3 or 5 */
#define MSC_RDF135(_x)	(((_x) & (0x7)) << 20)	/* ROM Delay First Access nCS 1,3 or 5 */
#define MSC_RBW135	(1 << 19)		/* ROM Bus Width nCS 1,3 or 5 */
#define MSC_RT135(_x)	(((_x) & (0x7)) << 16)	/* ROM Type  nCS 1,3 or 5 */
#define MSC_RBUFF024	(1 << 15)		/* Return Data Buff vs. Streaming  nCS 0,2 or 4 */
#define MSC_RRR024(_x)	(((_x) & (0x7)) << 12)	/* ROM/SRAM Recover Time  nCS 0,2 or 4 */
#define MSC_RDN024(_x)	(((_x) & (0x7)) << 8)	/* ROM Delay Next Access  nCS 0,2 or 4 */
#define MSC_RDF024(_x)	(((_x) & (0x7)) << 4)	/* ROM Delay First Access  nCS 0,2 or 4 */
#define MSC_RBW024	(1 << 3)		/* ROM Bus Width  nCS 0,2 or 4 */
#define MSC_RT024(_x)	(((_x) & (0x7)) << 0)	/* ROM Type  nCS 0,2 or 4 */

/* SXCNFG Bit defs */
#define SXCNFG_SXEN0 (1)
#define SXCNFG_SXEN1 (1<<1)
#define SXCNFG_SXCL0(_x) (((_x) & 0x7) << 2)
#define SXCNFG_SXTP0(_x) (((_x) & 0x3) << 12)
#define SXCNFG_SXCLEXT0 (1<<15)

/* ARB_CNTL Bit defs */
#define ARB_CNTL_DMA_SLV_PARK (1 << 31) 
#define ARB_CNTL_CI_PARK (1 << 30) 
#define ARB_CNTL_EX_MEM_PARK (1 << 29) 
#define ARB_CNTL_INT_MEM_PARK (1 << 28) 
#define ARB_CNTL_USB_PARK (1 << 27) 
#define ARB_CNTL_LCD_PARK (1 << 26) 
#define ARB_CNTL_DMA_PARK (1 << 25) 
#define ARB_CNTL_CORE_PARK (1 << 24) 
#define ARB_CNTL_LOCK_FLAG (1 << 23) 
#define ARB_CNTL_LCD_WT(_wt) (((_wt) & 0xF) << 8)
#define ARB_CNTL_DMA_WT(_wt) (((_wt) & 0xF) << 4)
#define ARB_CNTL_CORE_WT(_wt) (((_wt) & 0xF) << 0)

/* SA1110 Bit defs */
#define SA1110_SXSTACK(_x) (((_x) & 0x3) << 12)
/******************************************************************************/
/* LCD Controller */
/******************************************************************************/
#define LCCR0	_PXAREG(0x44000000) /* LCD Controller Control register 0 7-56 */
#define LCCR1	_PXAREG(0x44000004) /* LCD Controller Control register 1 7-64 */
#define LCCR2	_PXAREG(0x44000008) /* LCD Controller Control register 2 7-66 */
#define LCCR3	_PXAREG(0x4400000C) /* LCD Controller Control register 3 7-69 */
#define LCCR4	_PXAREG(0x44000010) /* LCD Controller Control register 4 7-74 */
#define LCCR5	_PXAREG(0x44000014) /* LCD Controller Control register 5 7-77 */
#define FBR0	_PXAREG(0x44000020) /* DMA Channel 0 Frame Branch register 7-101 */
#define FBR1	_PXAREG(0x44000024) /* DMA Channel 1 Frame Branch register 7-101 */
#define FBR2	_PXAREG(0x44000028) /* DMA Channel 2 Frame Branch register 7-101 */
#define FBR3	_PXAREG(0x4400002C) /* DMA Channel 3 Frame Branch register 7-101 */
#define FBR4	_PXAREG(0x44000030) /* DMA Channel 4 Frame Branch register 7-101 */
#define LCSR1	_PXAREG(0x44000034) /* LCD Controller Status register 1 7-109 */
#define LCSR0	_PXAREG(0x44000038) /* LCD Controller Status register 0 7-104 */
#define LIIDR	_PXAREG(0x4400003C) /* LCD Controller Interrupt ID register 7-116 */
#define TRGBR	_PXAREG(0x44000040) /* TMED RGB Seed register 7-97 */
#define TCR	_PXAREG(0x44000044) /* TMED Control register 7-98 */
#define OVL1C1	_PXAREG(0x44000050) /* Overlay 1 Control register 1 7-90 */
#define OVL1C2	_PXAREG(0x44000060) /* Overlay 1 Control register 2 7-91 */
#define OVL2C1	_PXAREG(0x44000070) /* Overlay 2 Control register 1 7-92 */
#define OVL2C2	_PXAREG(0x44000080) /* Overlay 2 Control register 2 7-94 */
#define CCR	_PXAREG(0x44000090) /* Cursor Control register 7-95 */
#define CMDCR	_PXAREG(0x44000100) /* Command Control register 7-96 */
#define PRSR	_PXAREG(0x44000104) /* Panel Read Status register 7-103 */
#define FBR5	_PXAREG(0x44000110) /* DMA Channel 5 Frame Branch register 7-101 */
#define FBR6	_PXAREG(0x44000114) /* DMA Channel 6 Frame Branch register 7-101 */
#define FDADR0	_PXAREG(0x44000200) /* DMA Channel 0 Frame Descriptor Address register 7-100 */
#define FSADR0	_PXAREG(0x44000204) /* DMA Channel 0 Frame Source Address register 7-117 */
#define FIDR0	_PXAREG(0x44000208) /* DMA Channel 0 Frame ID register 7-117 */
#define LDCMD0	_PXAREG(0x4400020C) /* LCD DMA Channel 0 Command register 7-118 */
#define FDADR1	_PXAREG(0x44000210) /* DMA Channel 1 Frame Descriptor Address register 7-100 */
#define FSADR1	_PXAREG(0x44000214) /* DMA Channel 1 Frame Source Address register 7-117 */
#define FIDR1	_PXAREG(0x44000218) /* DMA Channel 1 Frame ID register 7-117 */
#define LDCMD1	_PXAREG(0x4400021C) /* LCD DMA Channel 1 Command register 7-118 */
#define FDADR2	_PXAREG(0x44000220) /* DMA Channel 2 Frame Descriptor Address register 7-100 */
#define FSADR2	_PXAREG(0x44000224) /* DMA Channel 2 Frame Source Address register 7-117 */
#define FIDR2	_PXAREG(0x44000228) /* DMA Channel 2 Frame ID register 7-117 */
#define LDCMD2	_PXAREG(0x4400022C) /* LCD DMA Channel 2 Command register 7-118 */
#define FDADR3	_PXAREG(0x44000230) /* DMA Channel 3 Frame Descriptor Address register 7-100 */
#define FSADR3	_PXAREG(0x44000234) /* DMA Channel 3 Frame Source Address register 7-117 */
#define FIDR3	_PXAREG(0x44000238) /* DMA Channel 3 Frame ID register 7-117 */
#define LDCMD3	_PXAREG(0x4400023C) /* LCD DMA Channel 3 Command register 7-118 */
#define FDADR4	_PXAREG(0x44000240) /* DMA Channel 4 Frame Descriptor Address register 7-100 */
#define FSADR4	_PXAREG(0x44000244) /* DMA Channel 4 Frame Source Address register 7-117 */
#define FIDR4	_PXAREG(0x44000248) /* DMA Channel 4 Frame ID register 7-117 */
#define LDCMD4	_PXAREG(0x4400024C) /* LCD DMA Channel 4 Command register 7-118 */
#define FDADR5	_PXAREG(0x44000250) /* DMA Channel 5 Frame Descriptor Address register 7-100 */
#define FSADR5	_PXAREG(0x44000254) /* DMA Channel 5 Frame Source Address register 7-117 */
#define FIDR5	_PXAREG(0x44000258) /* DMA Channel 5 Frame ID register 7-117 */
#define LDCMD5	_PXAREG(0x4400025C) /* LCD DMA Channel 5 Command register 7-118 */
#define FDADR6	_PXAREG(0x44000260) /* DMA Channel 6 Frame Descriptor Address register 7-100 */
#define FSADR6	_PXAREG(0x44000264) /* DMA Channel 6 Frame Source Address register 7-117 */
#define FIDR6	_PXAREG(0x44000268) /* DMA Channel 6 Frame ID register 7-117 */
#define LDCMD6	_PXAREG(0x4400026C) /* LCD DMA Channel 6 Command register 7-118 */
#define LCDBSCNTR	_PXAREG(0x48000054) /* LCD Buffer Strength Control register 7-102 */


/******************************************************************************/
/* USB Host Controller */
/******************************************************************************/
#define UHCREV	_PXAREG(0x4C000000) /* UHC HCI Spec Revision register 20-10 */
#define UHCHCON	_PXAREG(0x4C000004) /* UHC Host Control register 20-10 */
#define UHCCOMS	_PXAREG(0x4C000008) /* UHC Command Status register 20-14 */
#define UHCINTS	_PXAREG(0x4C00000C) /* UHC Interrupt Status register 20-16 */
#define UHCINTE	_PXAREG(0x4C000010) /* UHC Interrupt Enable register 20-18 */
#define UHCINTD	_PXAREG(0x4C000014) /* UHC Interrupt Disable register 20-20 */
#define UHCHCCA	_PXAREG(0x4C000018) /* UHC Host Controller Communication Area register 20-21 */
#define UHCPCED	_PXAREG(0x4C00001C) /* UHC Period Current Endpoint Descriptor register 20-21 */
#define UHCCHED	_PXAREG(0x4C000020) /* UHC Control Head Endpoint Descriptor register 20-22 */
#define UHCCCED	_PXAREG(0x4C000024) /* UHC Control Current Endpoint Descriptor register 20-22 */
#define UHCBHED	_PXAREG(0x4C000028) /* UHC Bulk Head Endpoint Descriptor register 20-23 */
#define UHCBCED	_PXAREG(0x4C00002C) /* UHC Bulk Current Endpoint Descriptor register 20-24 */
#define UHCDHEAD	_PXAREG(0x4C000030) /* UHC Done Head register 20-25 */
#define UHCFMI	_PXAREG(0x4C000034) /* UHC Frame Interval register 20-26 */
#define UHCFMR	_PXAREG(0x4C000038) /* UHC Frame Remaining register 20-27 */
#define UHCFMN	_PXAREG(0x4C00003C) /* UHC Frame Number register 20-28 */
#define UHCPERS	_PXAREG(0x4C000040) /* UHC Periodic Start register 20-29 */
#define UHCLST	_PXAREG(0x4C000044) /* UHC Low-Speed Threshold register 20-30 */
#define UHCRHDA	_PXAREG(0x4C000048) /* UHC Root Hub Descriptor A register 20-31 */
#define UHCRHDB	_PXAREG(0x4C00004C) /* UHC Root Hub Descriptor B register 20-33 */
#define UHCRHS	_PXAREG(0x4C000050) /* UHC Root Hub Status register 20-34 */
#define UHCRHPS1	_PXAREG(0x4C000054) /* UHC Root Hub Port 1 Status register 20-35 */
#define UHCRHPS2	_PXAREG(0x4C000058) /* UHC Root Hub Port 2 Status register 20-35 */
#define UHCRHPS3	_PXAREG(0x4C00005C) /* UHC Root Hub Port 3 Status register 20-35 */
#define UHCSTAT	_PXAREG(0x4C000060) /* UHC Status register 20-39 */
#define UHCHR	_PXAREG(0x4C000064) /* UHC Reset register 20-41 */
#define UHCHIE	_PXAREG(0x4C000068) /* UHC Interrupt Enable register 20-44 */
#define UHCHIT	_PXAREG(0x4C00006C) /* UHC Interrupt Test register 20-45 */


/******************************************************************************/
/* Quick Capture Interface */
/******************************************************************************/
#define CICR0	_PXAREG(0x50000000) /* Quick Capture Interface Control register 0 27-24 */
#define CICR1	_PXAREG(0x50000004) /* Quick Capture Interface Control register 1 27-28 */
#define CICR2	_PXAREG(0x50000008) /* Quick Capture Interface Control register 2 27-32 */
#define CICR3	_PXAREG(0x5000000C) /* Quick Capture Interface Control register 3 27-33 */
#define CICR4	_PXAREG(0x50000010) /* Quick Capture Interface Control register 4 27-34 */
#define CISR	_PXAREG(0x50000014) /* Quick Capture Interface Status register 27-37 */
#define CIFR	_PXAREG(0x50000018) /* Quick Capture Interface FIFO Control register 27-40 */
#define CITOR	_PXAREG(0x5000001C) /* Quick Capture Interface Time-Out register 27-37 */
#define CIBR0	_PXAREG(0x50000028) /* Quick Capture Interface Receive Buffer register 0 (Channel 0) 27-42 */
#define CIBR1	_PXAREG(0x50000030) /* Quick Capture Interface Receive Buffer register 1 (Channel 1) 27-42 */
#define CIBR2	_PXAREG(0x50000038) /* Quick Capture Interface Receive Buffer register 2 (Channel 2) 27-42 */


/* Quick Capture Interface - Control Register 0 */
#define CICR0_DMA_EN    (1 << 31)	/* DMA Request Enable */
#define CICR0_EN        (1 << 28)	/* Quick Capture Interface Enable (and Quick Disable) */
#define CICR0_TOM       (1 << 9)	/* Time-Out Interrupt Mask */
#define CICR0_RDAVM     (1 << 8)	/* Receive-Data-Available Interrupt Mask */
#define CICR0_FEM       (1 << 7)	/* FIFO-Empty Interrupt Mask */
#define CICR0_EOLM      (1 << 6)	/* End-of-Line Interrupt Mask */
#define CICR0_SOFM      (1 << 2)	/* Start-of-Frame Interrupt Mask */
#define CICR0_EOFM      (1 << 1)	/* End-of-Frame Interrupt Mask */
#define CICR0_FOM       (1 << 0)	/* FIFO Overrun Interrupt Mask */


/* Quick Capture Interface - Control Register 1 */
#define CICR1_TBIT      (1 << 31)   /* Transparency Bit */
#define CICR1_RGBT_CONV(_data,_x)   ((_data & ~(0x7 << 29)) | (_x << 29))       /* RGBT Conversion */
#define CICR1_PPL(_data,_x)         ((_data & ~(0x7ff << 15)) | (_x << 15))     /* Pixels per Line */
#define CICR1_RGB_CONV(_data,_x)    ((_data & ~(0x7 << 12)) | (_x << 12))       /* RGB Bits per Pixel Conversion */
#define CICR1_RGB_F     (1 << 11)   /* RGB Format */
#define CICR1_YCBCR_F   (1 << 10)   /* YCbCr Format */
#define CICR1_RGB_BPP(_data,_x)     ((_data & ~(0x7 << 7)) | (_x << 7))         /* RGB Bits per Pixel */
#define CICR1_RAW_BPP(_data,_x)     ((_data & ~(0x3 << 5)) | (_x << 5))         /* Raw Bits per Pixel */
#define CICR1_COLOR_SP(_data,_x)    ((_data & ~(0x3 << 3)) | (_x << 3))         /* Color Space */
#define CICR1_DW(_data,_x)          ((_data & ~(0x7 << 0)) | (_x << 0))         /* Data Width */


/* Quick Capture Interface - Control Register 3 */
#define CICR3_LPF(_data,_x)	        ((_data & ~(0x7ff << 0)) | (_x << 0))       /* Lines per Frame */
                                               
/* Quick Capture Interface - Control Register 4 */
#define CICR4_PCLK_EN   (1 << 23)   /* Pixel Clock Enable */
#define CICR4_HSP       (1 << 21)	/* Horizontal Sync Polarity */
#define CICR4_VSP       (1 << 20)	/* Vertical Sync Polarity */
#define CICR4_MCLK_EN   (1 << 19)	/* MCLK Enable */
#define CICR4_DIV(_data,_x)         ((_data & ~(0xff << 0)) | (_x << 0))        /* Clock Divisor */

/* Quick Capture Interface - Status Register */
#define CISR_FTO        (1 << 15)	/* FIFO Time-Out */
#define CISR_RDAV_2     (1 << 14)	/* Channel 2 Receive Data Available */
#define CISR_RDAV_1     (1 << 13)	/* Channel 1 Receive Data Available */
#define CISR_RDAV_0     (1 << 12)	/* Channel 0 Receive Data Available */
#define CISR_FEMPTY_2   (1 << 11)	/* Channel 2 FIFO Empty */
#define CISR_FEMPTY_1   (1 << 10)	/* Channel 1 FIFO Empty */
#define CISR_FEMPTY_0   (1 << 9)	/* Channel 0 FIFO Empty */
#define CISR_EOL        (1 << 8)	/* End-of-Line */
#define CISR_PAR_ERR    (1 << 7)	/* Parity Error */
#define CISR_CQD        (1 << 6)	/* Quick Campture Interface Quick Dissable */
#define CISR_CDD        (1 << 5)	/* Quick Campture Interface Quick Dissable Done */
#define CISR_SOF        (1 << 4)	/* Start-of-Frame */
#define CISR_EOF        (1 << 3)	/* End-of-Frame */
#define CISR_IFO_2      (1 << 2)	/* FIFO Overrun for Channel 2 */
#define CISR_IFO_1      (1 << 1)	/* FIFO Overrun for Channel 1 */
#define CISR_IFO_0      (1 << 0)	/* FIFO Overrun for Channel 0 */


/* Quick Capture Interface - FIFO Control Register */
#define CIFR_FLVL0(_data,_x)        ((_data & ~(0xff << 8)) | (_x << 8))        /* FIFO 0 Level: value from 0-128 indicates the number of bytes */
#define CIFR_THL_0(_data,_x)        ((_data & ~(0x3 << 4)) | (_x << 4))         /* Threshold Level for Channel 0 FIFO */
#define CIFR_RESETF     (1 << 3)	/* Reset input FIFOs */




/******************************************************************************/
/* DMA Controller */
/******************************************************************************/
#define DCSR0	_PXAREG(0x40000000) /* DMA Control/Status register for Channel 0 5-41 */
#define DCSR1	_PXAREG(0x40000004) /* DMA Control/Status register for Channel 1 5-41 */
#define DCSR2	_PXAREG(0x40000008) /* DMA Control/Status register for Channel 2 5-41 */
#define DCSR3	_PXAREG(0x4000000C) /* DMA Control/Status register for Channel 3 5-41 */
#define DCSR4	_PXAREG(0x40000010) /* DMA Control/Status register for Channel 4 5-41 */
#define DCSR5	_PXAREG(0x40000014) /* DMA Control/Status register for Channel 5 5-41 */
#define DCSR6	_PXAREG(0x40000018) /* DMA Control/Status register for Channel 6 5-41 */
#define DCSR7	_PXAREG(0x4000001C) /* DMA Control/Status register for Channel 7 5-41 */
#define DCSR8	_PXAREG(0x40000020) /* DMA Control/Status register for Channel 8 5-41 */
#define DCSR9	_PXAREG(0x40000024) /* DMA Control/Status register for Channel 9 5-41 */
#define DCSR10	_PXAREG(0x40000028) /* DMA Control/Status register for Channel 10 5-41 */
#define DCSR11	_PXAREG(0x4000002C) /* DMA Control/Status register for Channel 11 5-41 */
#define DCSR12	_PXAREG(0x40000030) /* DMA Control/Status register for Channel 12 5-41 */
#define DCSR13	_PXAREG(0x40000034) /* DMA Control/Status register for Channel 13 5-41 */
#define DCSR14	_PXAREG(0x40000038) /* DMA Control/Status register for Channel 14 5-41 */
#define DCSR15	_PXAREG(0x4000003C) /* DMA Control/Status register for Channel 15 5-41 */
#define DCSR16	_PXAREG(0x40000040) /* DMA Control/Status register for Channel 16 5-41 */
#define DCSR17	_PXAREG(0x40000044) /* DMA Control/Status register for Channel 17 5-41 */
#define DCSR18	_PXAREG(0x40000048) /* DMA Control/Status register for Channel 18 5-41 */
#define DCSR19	_PXAREG(0x4000004C) /* DMA Control/Status register for Channel 19 5-41 */
#define DCSR20	_PXAREG(0x40000050) /* DMA Control/Status register for Channel 20 5-41 */
#define DCSR21	_PXAREG(0x40000054) /* DMA Control/Status register for Channel 21 5-41 */
#define DCSR22	_PXAREG(0x40000058) /* DMA Control/Status register for Channel 22 5-41 */
#define DCSR23	_PXAREG(0x4000005C) /* DMA Control/Status register for Channel 23 5-41 */
#define DCSR24	_PXAREG(0x40000060) /* DMA Control/Status register for Channel 24 5-41 */
#define DCSR25	_PXAREG(0x40000064) /* DMA Control/Status register for Channel 25 5-41 */
#define DCSR26	_PXAREG(0x40000068) /* DMA Control/Status register for Channel 26 5-41 */
#define DCSR27	_PXAREG(0x4000006C) /* DMA Control/Status register for Channel 27 5-41 */
#define DCSR28	_PXAREG(0x40000070) /* DMA Control/Status register for Channel 28 5-41 */
#define DCSR29	_PXAREG(0x40000074) /* DMA Control/Status register for Channel 29 5-41 */
#define DCSR30	_PXAREG(0x40000078) /* DMA Control/Status register for Channel 30 5-41 */
#define DCSR31	_PXAREG(0x4000007C) /* DMA Control/Status register for Channel 31 5-41 */

#define DALGN	_PXAREG(0x400000A0) /* DMA Alignment register 5-49 */
#define DPCSR	_PXAREG(0x400000A4) /* DMA Programmed I/O Control Status register 5-51 */

#define DRQSR0	_PXAREG(0x400000E0) /* DMA DREQ<0> Status register 5-40 */
#define DRQSR1	_PXAREG(0x400000E4) /* DMA DREQ<1> Status register 5-40 */
#define DRQSR2	_PXAREG(0x400000E8) /* DMA DREQ<2> Status register 5-40 */

#define DINT	_PXAREG(0x400000F0) /* DMA Interrupt register 5-48 */

#define DRCMR0	_PXAREG(0x40000100) /* Request to Channel Map register for DREQ<0> (companion chip request 0) 5-31 */
#define DRCMR1	_PXAREG(0x40000104) /* Request to Channel Map register for DREQ<1> (companion chip request 1) 5-31 */
#define DRCMR2	_PXAREG(0x40000108) /* Request to Channel Map register for I2S receive request 5-31 */
#define DRCMR3	_PXAREG(0x4000010C) /* Request to Channel Map register for I2S transmit request 5-31 */
#define DRCMR4	_PXAREG(0x40000110) /* Request to Channel Map register for BTUART receive request 5-31 */
#define DRCMR5	_PXAREG(0x40000114) /* Request to Channel Map register for BTUART transmit request. 5-31 */
#define DRCMR6	_PXAREG(0x40000118) /* Request to Channel Map register for FFUART receive request 5-31 */
#define DRCMR7	_PXAREG(0x4000011C) /* Request to Channel Map register for FFUART transmit request 5-31 */
#define DRCMR8	_PXAREG(0x40000120) /* Request to Channel Map register for AC 97 microphone request 5-31 */
#define DRCMR9	_PXAREG(0x40000124) /* Request to Channel Map register for AC 97 modem receive request 5-31 */
#define DRCMR10	_PXAREG(0x40000128) /* Request to Channel Map register for AC 97 modem transmit request 5-31 */
#define DRCMR11	_PXAREG(0x4000012C) /* Request to Channel Map register for AC 97 audio receive request 5-31 */
#define DRCMR12	_PXAREG(0x40000130) /* Request to Channel Map register for AC 97 audio transmit request 5-31 */
#define DRCMR13	_PXAREG(0x40000134) /* Request to Channel Map register for SSP1 receive request 5-31 */
#define DRCMR14	_PXAREG(0x40000138) /* Request to Channel Map register for SSP1 transmit request 5-31 */
#define DRCMR15	_PXAREG(0x4000013C) /* Request to Channel Map register for SSP2 receive request 5-31 */
#define DRCMR16	_PXAREG(0x40000140) /* Request to Channel Map register for SSP2 transmit request 5-31 */
#define DRCMR17	_PXAREG(0x40000144) /* Request to Channel Map register for ICP receive request 5-31 */
#define DRCMR18	_PXAREG(0x40000148) /* Request to Channel Map register for ICP transmit request 5-31 */
#define DRCMR19	_PXAREG(0x4000014C) /* Request to Channel Map register for STUART receive request 5-31 */
#define DRCMR20	_PXAREG(0x40000150) /* Request to Channel Map register for STUART transmit request 5-31 */
#define DRCMR21	_PXAREG(0x40000154) /* Request to Channel Map register for MMC/SDIO receive request 5-31 */
#define DRCMR22	_PXAREG(0x40000158) /* Request to Channel Map register for MMC/SDIO transmit request 5-31 */
#define DRCMR24	_PXAREG(0x40000160) /* Request to Channel Map register for USB endpoint 0 request 5-31 */
#define DRCMR25	_PXAREG(0x40000164) /* Request to Channel Map register for USB endpoint A request 5-31 */
#define DRCMR26	_PXAREG(0x40000168) /* Request to Channel Map register for USB endpoint B request 5-31 */
#define DRCMR27	_PXAREG(0x4000016C) /* Request to Channel Map register for USB endpoint C request 5-31 */
#define DRCMR28	_PXAREG(0x40000170) /* Request to Channel Map register for USB endpoint D request 5-31 */
#define DRCMR29	_PXAREG(0x40000174) /* Request to Channel Map register for USB endpoint E request 5-31 */
#define DRCMR30	_PXAREG(0x40000178) /* Request to Channel Map register for USB endpoint F request 5-31 */
#define DRCMR31	_PXAREG(0x4000017C) /* Request to Channel Map register for USB endpoint G request 5-31 */
#define DRCMR32	_PXAREG(0x40000180) /* Request to Channel Map register for USB endpoint H request 5-31 */
#define DRCMR33	_PXAREG(0x40000184) /* Request to Channel Map register for USB endpoint I request 5-31 */
#define DRCMR34	_PXAREG(0x40000188) /* Request to Channel Map register for USB endpoint J request 5-31 */
#define DRCMR35	_PXAREG(0x4000018C) /* Request to Channel Map register for USB endpoint K request 5-31 */
#define DRCMR36	_PXAREG(0x40000190) /* Request to Channel Map register for USB endpoint L request 5-31 */
#define DRCMR37	_PXAREG(0x40000194) /* Request to Channel Map register for USB endpoint M request 5-31 */
#define DRCMR38	_PXAREG(0x40000198) /* Request to Channel Map register for USB endpoint N request 5-31 */
#define DRCMR39	_PXAREG(0x4000019C) /* Request to Channel Map register for USB endpoint P request 5-31 */
#define DRCMR40	_PXAREG(0x400001A0) /* Request to Channel Map register for USB endpoint Q request 5-31 */
#define DRCMR41	_PXAREG(0x400001A4) /* Request to Channel Map register for USB endpoint R request 5-31 */
#define DRCMR42	_PXAREG(0x400001A8) /* Request to Channel Map register for USB endpoint S request 5-31 */
#define DRCMR43	_PXAREG(0x400001AC) /* Request to Channel Map register for USB endpoint T request 5-31 */
#define DRCMR44	_PXAREG(0x400001B0) /* Request to Channel Map register for USB endpoint U request 5-31 */
#define DRCMR45	_PXAREG(0x400001B4) /* Request to Channel Map register for USB endpoint V request 5-31 */
#define DRCMR46	_PXAREG(0x400001B8) /* Request to Channel Map register for USB endpoint W request 5-31 */
#define DRCMR47	_PXAREG(0x400001BC) /* Request to Channel Map register for USB endpoint X request 5-31 */
#define DRCMR48	_PXAREG(0x400001C0) /* Request to Channel Map register for MSL receive request 1 5-31 */
#define DRCMR49	_PXAREG(0x400001C4) /* Request to Channel Map register for MSL transmit request 1 5-31 */
#define DRCMR50	_PXAREG(0x400001C8) /* Request to Channel Map register for MSL receive request 2 5-31 */
#define DRCMR51	_PXAREG(0x400001CC) /* Request to Channel Map register for MSL transmit request 2 5-31 */
#define DRCMR52	_PXAREG(0x400001D0) /* Request to Channel Map register for MSL receive request 3 5-31 */
#define DRCMR53	_PXAREG(0x400001D4) /* Request to Channel Map register for MSL transmit request 3 5-31 */
#define DRCMR54	_PXAREG(0x400001D8) /* Request to Channel Map register for MSL receive request 4 5-31 */
#define DRCMR55	_PXAREG(0x400001DC) /* Request to Channel Map register for MSL transmit request 4 5-31 */
#define DRCMR56	_PXAREG(0x400001E0) /* Request to Channel Map register for MSL receive request 5 5-31 */
#define DRCMR57	_PXAREG(0x400001E4) /* Request to Channel Map register for MSL transmit request 5 5-31 */
#define DRCMR58	_PXAREG(0x400001E8) /* Request to Channel Map register for MSL receive request 6 5-31 */
#define DRCMR59	_PXAREG(0x400001EC) /* Request to Channel Map register for MSL transmit request 6 5-31 */
#define DRCMR60	_PXAREG(0x400001F0) /* Request to Channel Map register for MSL receive request 7 5-31 */
#define DRCMR61	_PXAREG(0x400001F4) /* Request to Channel Map register for MSL transmit request 7 5-31 */
#define DRCMR62	_PXAREG(0x400001F8) /* Request to Channel Map register for USIM receive request 5-31 */
#define DRCMR63	_PXAREG(0x400001FC) /* Request to Channel Map register for USIM transmit request 5-31 */

#define DDADR0	_PXAREG(0x40000200) /* DMA Descriptor Address register for Channel 0 5-32 */
#define DSADR0	_PXAREG(0x40000204) /* DMA Source Address register for Channel 0 5-33 */
#define DTADR0	_PXAREG(0x40000208) /* DMA Target Address register for Channel 0 5-34 */
#define DCMD0	_PXAREG(0x4000020C) /* DMA Command Address register for Channel 0 5-35 */
#define DDADR1	_PXAREG(0x40000210) /* DMA Descriptor Address register for Channel 1 5-32 */
#define DSADR1	_PXAREG(0x40000214) /* DMA Source Address register for Channel 1 5-33 */
#define DTADR1	_PXAREG(0x40000218) /* DMA Target Address register for Channel 1 5-34 */
#define DCMD1	_PXAREG(0x4000021C) /* DMA Command Address register for Channel 1 5-35 */
#define DDADR2	_PXAREG(0x40000220) /* DMA Descriptor Address register for Channel 2 5-32 */
#define DSADR2	_PXAREG(0x40000224) /* DMA Source Address register for Channel 2 5-33 */
#define DTADR2	_PXAREG(0x40000228) /* DMA Target Address register for Channel 2 5-34 */
#define DCMD2	_PXAREG(0x4000022C) /* DMA Command Address register for Channel 2 5-35 */
#define DDADR3	_PXAREG(0x40000230) /* DMA Descriptor Address register for Channel 3 5-32 */
#define DSADR3	_PXAREG(0x40000234) /* DMA Source Address register for Channel 3 5-33 */
#define DTADR3	_PXAREG(0x40000238) /* DMA Target Address register for Channel 3 5-34 */
#define DCMD3	_PXAREG(0x4000023C) /* DMA Command Address register for Channel 3 5-35 */
#define DDADR4	_PXAREG(0x40000240) /* DMA Descriptor Address register for Channel 4 5-32 */
#define DSADR4	_PXAREG(0x40000244) /* DMA Source Address register for Channel 4 5-33 */
#define DTADR4	_PXAREG(0x40000248) /* DMA Target Address register for Channel 4 5-34 */
#define DCMD4	_PXAREG(0x4000024C) /* DMA Command Address register for Channel 4 5-35 */
#define DDADR5	_PXAREG(0x40000250) /* DMA Descriptor Address register for Channel 5 5-32 */
#define DSADR5	_PXAREG(0x40000254) /* DMA Source Address register for Channel 5 5-33 */
#define DTADR5	_PXAREG(0x40000258) /* DMA Target Address register for Channel 5 5-34 */
#define DCMD5	_PXAREG(0x4000025C) /* DMA Command Address register for Channel 5 5-35 */
#define DDADR6	_PXAREG(0x40000260) /* DMA Descriptor Address register for Channel 6 5-32 */
#define DSADR6	_PXAREG(0x40000264) /* DMA Source Address register for Channel 6 5-33 */
#define DTADR6	_PXAREG(0x40000268) /* DMA Target Address register for Channel 6 5-34 */
#define DCMD6	_PXAREG(0x4000026C) /* DMA Command Address register for Channel 6 5-35 */
#define DDADR7	_PXAREG(0x40000270) /* DMA Descriptor Address register for Channel 7 5-32 */
#define DSADR7	_PXAREG(0x40000274) /* DMA Source Address register for Channel 7 5-33 */
#define DTADR7	_PXAREG(0x40000278) /* DMA Target Address register for Channel 7 5-34 */
#define DCMD7	_PXAREG(0x4000027C) /* DMA Command Address register for Channel 7 5-35 */
#define DDADR8	_PXAREG(0x40000280) /* DMA Descriptor Address register for Channel 8 5-32 */
#define DSADR8	_PXAREG(0x40000284) /* DMA Source Address register for Channel 8 5-33 */
#define DTADR8	_PXAREG(0x40000288) /* DMA Target Address register for Channel 8 5-34 */
#define DCMD8	_PXAREG(0x4000028C) /* DMA Command Address register for Channel 8 5-35 */
#define DDADR9	_PXAREG(0x40000290) /* DMA Descriptor Address register for Channel 9 5-32 */
#define DSADR9	_PXAREG(0x40000294) /* DMA Source Address register for Channel 9 5-33 */
#define DTADR9	_PXAREG(0x40000298) /* DMA Target Address register for Channel 9 5-34 */
#define DCMD9	_PXAREG(0x4000029C) /* DMA Command Address register for Channel 9 5-35 */
#define DDADR10	_PXAREG(0x400002A0) /* DMA Descriptor Address register for Channel 10 5-32 */
#define DSADR10	_PXAREG(0x400002A4) /* DMA Source Address register for Channel 10 5-33 */
#define DTADR10	_PXAREG(0x400002A8) /* DMA Target Address register for Channel 10 5-34 */
#define DCMD10	_PXAREG(0x400002AC) /* DMA Command Address register for Channel 10 5-35 */
#define DDADR11	_PXAREG(0x400002B0) /* DMA Descriptor Address register for Channel 11 5-32 */
#define DSADR11	_PXAREG(0x400002B4) /* DMA Source Address register for Channel 11 5-33 */
#define DTADR11	_PXAREG(0x400002B8) /* DMA Target Address register for Channel 11 5-34 */
#define DCMD11	_PXAREG(0x400002BC) /* DMA Command Address register for Channel 11 5-35 */
#define DDADR12	_PXAREG(0x400002C0) /* DMA Descriptor Address register for Channel 12 5-32 */
#define DSADR12	_PXAREG(0x400002C4) /* DMA Source Address register for Channel 12 5-33 */
#define DTADR12	_PXAREG(0x400002C8) /* DMA Target Address register for Channel 12 5-34 */
#define DCMD12	_PXAREG(0x400002CC) /* DMA Command Address register for Channel 12 5-35 */
#define DDADR13	_PXAREG(0x400002D0) /* DMA Descriptor Address register for Channel 13 5-32 */
#define DSADR13	_PXAREG(0x400002D4) /* DMA Source Address register for Channel 13 5-33 */
#define DTADR13	_PXAREG(0x400002D8) /* DMA Target Address register for Channel 13 5-34 */
#define DCMD13	_PXAREG(0x400002DC) /* DMA Command Address register for Channel 13 5-35 */
#define DDADR14	_PXAREG(0x400002E0) /* DMA Descriptor Address register for Channel 14 5-32 */
#define DSADR14	_PXAREG(0x400002E4) /* DMA Source Address register for Channel 14 5-33 */
#define DTADR14	_PXAREG(0x400002E8) /* DMA Target Address register for Channel 14 5-34 */
#define DCMD14	_PXAREG(0x400002EC) /* DMA Command Address register for Channel 14 5-35 */
#define DDADR15	_PXAREG(0x400002F0) /* DMA Descriptor Address register for Channel 15 5-32 */
#define DSADR15	_PXAREG(0x400002F4) /* DMA Source Address register for Channel 15 5-33 */
#define DTADR15	_PXAREG(0x400002F8) /* DMA Target Address register for Channel 15 5-34 */
#define DCMD15	_PXAREG(0x400002FC) /* DMA Command Address register for Channel 15 5-35 */
#define DDADR16	_PXAREG(0x40000300) /* DMA Descriptor Address register for Channel 16 5-32 */
#define DSADR16	_PXAREG(0x40000304) /* DMA Source Address register for Channel 16 5-33 */
#define DTADR16	_PXAREG(0x40000308) /* DMA Target Address register for Channel 16 5-34 */
#define DCMD16	_PXAREG(0x4000030C) /* DMA Command Address register for Channel 16 5-35 */
#define DDADR17	_PXAREG(0x40000310) /* DMA Descriptor Address register for Channel 17 5-32 */
#define DSADR17	_PXAREG(0x40000314) /* DMA Source Address register for Channel 17 5-33 */
#define DTADR17	_PXAREG(0x40000318) /* DMA Target Address register for Channel 17 5-34 */
#define DCMD17	_PXAREG(0x4000031C) /* DMA Command Address register for Channel 17 5-35 */
#define DDADR18	_PXAREG(0x40000320) /* DMA Descriptor Address register for Channel 18 5-32 */
#define DSADR18	_PXAREG(0x40000324) /* DMA Source Address register for Channel 18 5-33 */
#define DTADR18	_PXAREG(0x40000328) /* DMA Target Address register for Channel 18 5-34 */
#define DCMD18	_PXAREG(0x4000032C) /* DMA Command Address register for Channel 18 5-35 */
#define DDADR19	_PXAREG(0x40000330) /* DMA Descriptor Address register for Channel 19 5-32 */
#define DSADR19	_PXAREG(0x40000334) /* DMA Source Address register for Channel 19 5-33 */
#define DTADR19	_PXAREG(0x40000338) /* DMA Target Address register for Channel 19 5-34 */
#define DCMD19	_PXAREG(0x4000033C) /* DMA Command Address register for Channel 19 5-35 */
#define DDADR20	_PXAREG(0x40000340) /* DMA Descriptor Address register for Channel 20 5-32 */
#define DSADR20	_PXAREG(0x40000344) /* DMA Source Address register for Channel 20 5-33 */
#define DTADR20	_PXAREG(0x40000348) /* DMA Target Address register for Channel 20 5-34 */
#define DCMD20	_PXAREG(0x4000034C) /* DMA Command Address register for Channel 20 5-35 */
#define DDADR21	_PXAREG(0x40000350) /* DMA Descriptor Address register for Channel 21 5-32 */
#define DSADR21	_PXAREG(0x40000354) /* DMA Source Address register for Channel 21 5-33 */
#define DTADR21	_PXAREG(0x40000358) /* DMA Target Address register for Channel 21 5-34 */
#define DCMD21	_PXAREG(0x4000035C) /* DMA Command Address register for Channel 21 5-35 */
#define DDADR22	_PXAREG(0x40000360) /* DMA Descriptor Address register for Channel 22 5-32 */
#define DSADR22	_PXAREG(0x40000364) /* DMA Source Address register for Channel 22 5-33 */
#define DTADR22	_PXAREG(0x40000368) /* DMA Target Address register for Channel 22 5-34 */
#define DCMD22	_PXAREG(0x4000036C) /* DMA Command Address register for Channel 22 5-35 */
#define DDADR23	_PXAREG(0x40000370) /* DMA Descriptor Address register for Channel 23 5-32 */
#define DSADR23	_PXAREG(0x40000374) /* DMA Source Address register for Channel 23 5-33 */
#define DTADR23	_PXAREG(0x40000378) /* DMA Target Address register for Channel 23 5-34 */
#define DCMD23	_PXAREG(0x4000037C) /* DMA Command Address register for Channel 23 5-35 */
#define DDADR24	_PXAREG(0x40000380) /* DMA Descriptor Address register for Channel 24 5-32 */
#define DSADR24	_PXAREG(0x40000384) /* DMA Source Address register for Channel 24 5-33 */
#define DTADR24	_PXAREG(0x40000388) /* DMA Target Address register for Channel 24 5-34 */
#define DCMD24	_PXAREG(0x4000038C) /* DMA Command Address register for Channel 24 5-35 */
#define DDADR25	_PXAREG(0x40000390) /* DMA Descriptor Address register for Channel 25 5-32 */
#define DSADR25	_PXAREG(0x40000394) /* DMA Source Address register for Channel 25 5-33 */
#define DTADR25	_PXAREG(0x40000398) /* DMA Target Address register for Channel 25 5-34 */
#define DCMD25	_PXAREG(0x4000039C) /* DMA Command Address register for Channel 25 5-35 */
#define DDADR26	_PXAREG(0x400003A0) /* DMA Descriptor Address register for Channel 26 5-32 */
#define DSADR26	_PXAREG(0x400003A4) /* DMA Source Address register for Channel 26 5-33 */
#define DTADR26	_PXAREG(0x400003A8) /* DMA Target Address register for Channel 26 5-34 */
#define DCMD26	_PXAREG(0x400003AC) /* DMA Command Address register for Channel 26 5-35 */
#define DDADR27	_PXAREG(0x400003B0) /* DMA Descriptor Address register for Channel 27 5-32 */
#define DSADR27	_PXAREG(0x400003B4) /* DMA Source Address register for Channel 27 5-33 */
#define DTADR27	_PXAREG(0x400003B8) /* DMA Target Address register for Channel 27 5-34 */
#define DCMD27	_PXAREG(0x400003BC) /* DMA Command Address register for Channel 27 5-35 */
#define DDADR28	_PXAREG(0x400003C0) /* DMA Descriptor Address register for Channel 28 5-32 */
#define DSADR28	_PXAREG(0x400003C4) /* DMA Source Address register for Channel 28 5-33 */
#define DTADR28	_PXAREG(0x400003C8) /* DMA Target Address register for Channel 28 5-34 */
#define DCMD28	_PXAREG(0x400003CC) /* DMA Command Address register for Channel 28 5-35 */
#define DDADR29	_PXAREG(0x400003D0) /* DMA Descriptor Address register for Channel 29 5-32 */
#define DSADR29	_PXAREG(0x400003D4) /* DMA Source Address register for Channel 29 5-33 */
#define DTADR29	_PXAREG(0x400003D8) /* DMA Target Address register for Channel 29 5-34 */
#define DCMD29	_PXAREG(0x400003DC) /* DMA Command Address register for Channel 29 5-35 */
#define DDADR30	_PXAREG(0x400003E0) /* DMA Descriptor Address register for Channel 30 5-32 */
#define DSADR30	_PXAREG(0x400003E4) /* DMA Source Address register for Channel 30 5-33 */
#define DTADR30	_PXAREG(0x400003E8) /* DMA Target Address register for Channel 30 5-34 */
#define DCMD30	_PXAREG(0x400003EC) /* DMA Command Address register for Channel 30 5-35 */
#define DDADR31	_PXAREG(0x400003F0) /* DMA Descriptor Address register for Channel 31 5-32 */
#define DSADR31	_PXAREG(0x400003F4) /* DMA Source Address register for Channel 31 5-33 */
#define DTADR31	_PXAREG(0x400003F8) /* DMA Target Address register for Channel 31 5-34 */
#define DCMD31	_PXAREG(0x400003FC) /* DMA Command Address register for Channel 31 5-35 */

#define DRCMR64	_PXAREG(0x40001100) /* Request to Channel Map register for Memory Stick receive request 5-31 */
#define DRCMR65	_PXAREG(0x40001104) /* Request to Channel Map register for Memory Stick transmit request 5-31 */
#define DRCMR66	_PXAREG(0x40001108) /* Request to Channel Map register for SSP3 receive request 5-31 */
#define DRCMR67	_PXAREG(0x4000110C) /* Request to Channel Map register for SSP3 transmit request 5-31 */
#define DRCMR68	_PXAREG(0x40001110) /* Request to Channel Map register for Quick Capture Interface Receive Request 0 5-31 */
#define DRCMR69	_PXAREG(0x40001114) /* Request to Channel Map register for Quick Capture Interface Receive Request 1 5-31 */
#define DRCMR70	_PXAREG(0x40001118) /* Request to Channel Map register for Quick Capture Interface Receive Request 2 5-31 */

#define DRCMR74	_PXAREG(0x40001128) /* Request to Channel Map register for DREQ<2> (companion chip request 2) 5-31 */

#define FLYCNFG	_PXAREG(0x48000020) /* Fly-by DMA DVAL<1:0> polarities 5-39 */

// DMA Register shortcuts
#define DCSR(_ch)  _PXAREG_OFFSET(&DCSR0,((_ch) << 2))
#define DRQSR(_line) _PXAREG_OFFSET(&DRQSR0,((_line) << 2))
#define DRCMR(_dev) *(((_dev) < 63) ? (&_PXAREG_OFFSET(&DRCMR0, (((_dev) & 0x3f) << 2))) \
				   : (&_PXAREG_OFFSET(&DRCMR64,(((_dev) & 0x3f) << 2))))
#define DDADR(_ch) _PXAREG_OFFSET(&DDADR0,((_ch) << 4))
#define DSADR(_ch) _PXAREG_OFFSET(&DSADR0,((_ch) << 4))
#define DTADR(_ch) _PXAREG_OFFSET(&DTADR0,((_ch) << 4))
#define DCMD(_ch) _PXAREG_OFFSET(&DCMD0,((_ch) << 4))


#define DDADR_DESCADDR	0xfffffff0	/* Address of next descriptor (mask) */
#define DDADR_STOP	(1 << 0)	/* Stop (read / write) */

#define DRCMR_MAPVLD	(1 << 7)	/* Map Valid Channel */
#define DRCMR_CHLNUM(_ch) ((_ch) & 0x1f)

#define DCSR_RUN	(1 << 31)	/* Run Bit (read / write) */
#define DCSR_NODESCFETCH (1 << 30)	/* No-Descriptor Fetch (read / write) */
#define DCSR_STOPIRQEN	(1 << 29)	/* Stop Interrupt Enabled */
#define DCSR_EORIRQEN	(1 << 28)	/* End-of-Receive Interrupt Enable */
#define DCSR_EORJMPEN	(1 << 27)	/* Jump to Next Descriptor on EOR */
#define DCSR_EORSTOPEN	(1 << 26)	/* Stop Channel on EOR */
#define DCSR_SETCMPST	(1 << 25)	/* Set Descriptor Compare Status */
#define DCSR_CLRCMPST	(1 << 24)	/* Clear Descriptor Compare Status */
#define DCSR_RASIRQEN	(1 << 23)	/* Request After Channel Stoopped Interrupt Enable */
#define DCSR_MASKRUN	(1 << 22)	/* Mask Run */
#define DCSR_CMPST	(1 << 10)	/* Descriptor Compare Status */
#define DCSR_EORINT	(1 << 9)	/* End of Recieve */
#define DCSR_REQPEND	(1 << 8)	/* Request Pending (read-only) */
#define DCSR_RASINTR	(1 << 4)	/* Request After Channel Stopped */
#define DCSR_STOPINTR	(1 << 3)	/* Stop Interrupt */
#define DCSR_ENDINTR	(1 << 2)	/* End Interrupt (read / write) */
#define DCSR_STARTINTR	(1 << 1)	/* Start Interrupt (read / write) */
#define DCSR_BUSERRINTR	(1 << 0)	/* Bus Error Interrupt (read / write) */

#define DRQSR_CLR	(1 << 8)	/* Clear Pending Requests */

#define DCMD_INCSRCADDR	(1 << 31)	/* Source Address Increment Setting. */
#define DCMD_INCTRGADDR	(1 << 30)	/* Target Address Increment Setting. */
#define DCMD_FLOWSRC	(1 << 29)	/* Flow Control by the source. */
#define DCMD_FLOWTRG	(1 << 28)	/* Flow Control by the target. */
#define DCMD_CMPEN	(1 << 25)	/* Descriptor Compare Enable */
#define DCMD_ADDRMODE   (1 << 23)	/* Addressing Mode */
#define DCMD_STARTIRQEN	(1 << 22)	/* Start Interrupt Enable */
#define DCMD_ENDIRQEN	(1 << 21)	/* End Interrupt Enable */
#define DCMD_FLYBYS	(1 << 20)	/* Fly-By Source */
#define DCMD_FLYBYT	(1 << 19)	/* Fly-By Target */
#define DCMD_BURST8	(1 << 16)	/* 8 byte burst */
#define DCMD_BURST16	(2 << 16)	/* 16 byte burst */
#define DCMD_BURST32	(3 << 16)	/* 32 byte burst */
#define DCMD_WIDTH1	(1 << 14)	/* 1 byte width */
#define DCMD_WIDTH2	(2 << 14)	/* 2 byte width (HalfWord) */
#define DCMD_WIDTH4	(3 << 14)	/* 4 byte width (Word) */
#define DCMD_SIZE(_x)	(((_x) & 0x3)<<16)	/* Burst Size */
#define DCMD_MAXSIZE    DCMD_SIZE(3)
#define DCMD_WIDTH(_x)	(((_x) & 0x3)<<14)	/* Peripheral Width  */
#define DCMD_MAXWIDTH   DCMD_WIDTH(3)
#define DCMD_LEN(_x)	(((_x) & 0x1fff))	/* Length of transfer (0 for descriptor ops) */
#define DCMD_MAXLEN     DCMD_LEN(0x1fff)

#define DMAREQ_DREQ0		(0)	
#define DMAREQ_DREQ1		(1)	
#define DMAREQ_I2S_RECV		(2)	
#define DMAREQ_I2S_XMT		(3)	
#define DMAREQ_BTUART_RECV	(4)	
#define DMAREQ_BTUART_XMT	(5)	
#define DMAREQ_FFUAR_RECV	(6)	
#define DMAREQ_FFUART_XMT	(7)	
#define DMAREQ_AC97_MICR	(8)	
#define DMAREQ_AC97_MODEM_RECV	(9)	
#define DMAREQ_AC97_MODEM_XMT	(10)	
#define DMAREQ_AC97_AUDIO_RECV	(11)	
#define DMAREQ_AC97_AUDIO_XMT	(12)	
#define DMAREQ_SSP1_RECV	(13)	
#define DMAREQ_SSP1_XMT		(14)	
#define DMAREQ_SSP2_RECV	(15)	
#define DMAREQ_SSP2_XMT		(16)	
#define DMAREQ_ICP_RECV		(17)	
#define DMAREQ_ICP_XMT		(18)	
#define DMAREQ_STUART_RECV	(19)	
#define DMAREQ_STUART_XMT	(20)	
#define DMAREQ_MMCSDIO_RECV	(21)	
#define DMAREQ_MMCSDIO_XMT	(22)	

#define DMAREQ_USB_EP_0		(24)	
#define DMAREQ_USB_EP_A		(25)	
#define DMAREQ_USB_EP_B		(26)	
#define DMAREQ_USB_EP_C		(27)	
#define DMAREQ_USB_EP_D		(28)	
#define DMAREQ_USB_EP_E		(29)	
#define DMAREQ_USB_EP_F		(30)	
#define DMAREQ_USB_EP_G		(31)	
#define DMAREQ_USB_EP_H		(32)	
#define DMAREQ_USB_EP_I		(33)	
#define DMAREQ_USB_EP_J		(34)	
#define DMAREQ_USB_EP_K		(35)	
#define DMAREQ_USB_EP_L		(36)	
#define DMAREQ_USB_EP_M		(37)	
#define DMAREQ_USB_EP_N		(38)	
#define DMAREQ_USB_EP_P		(39)	
#define DMAREQ_USB_EP_Q		(40)	
#define DMAREQ_USB_EP_R		(41)	
#define DMAREQ_USB_EP_S		(42)	
#define DMAREQ_USB_EP_T		(43)	
#define DMAREQ_USB_EP_U		(44)	
#define DMAREQ_USB_EP_V		(45)	
#define DMAREQ_USB_EP_W		(46)	
#define DMAREQ_USB_EP_X		(47)	
#define DMAREQ_MSL_RECV_1	(48)	
#define DMAREQ_MSL_XMT_1	(49)	
#define DMAREQ_MSL_RECV_2	(50)	
#define DMAREQ_MSL_XMT_2	(51)	
#define DMAREQ_MSL_RECV_3	(52)	
#define DMAREQ_MSL_XMT_3	(53)	
#define DMAREQ_MSL_RECV_4	(54)	
#define DMAREQ_MSL_XMT_4	(55)	
#define DMAREQ_MSL_RECV_5	(56)	
#define DMAREQ_MSL_XMT_5	(57)	
#define DMAREQ_MSL_RECV_6	(58)	
#define DMAREQ_MSL_XMT_6	(59)	
#define DMAREQ_MSL_RECV_7	(60)	
#define DMAREQ_MSL_XMT_7	(61)	
#define DMAREQ_USIM_RECV	(62)	
#define DMAREQ_USIM_XMT		(63)	
#define DMAREQ_MEMSTICK_RECV	(64)	
#define DMAREQ_MEMSTICK_XMT	(65)	
#define DMAREQ_SSP3_RECV	(66)	
#define DMAREQ_SSP3_XMT		(67)	
#define DMAREQ_CIF_RECV_0	(68)	
#define DMAREQ_CIF_RECV_1	(69)	
#define DMAREQ_CIF_RECV_2	(70)	
#define DMAREQ_DREQ2     	(74)	



/******************************************************************************/
/* Full-Function UART */
/******************************************************************************/
#define FFRBR	_PXAREG(0x40100000) /* Receive Buffer register 10-13 */
#define FFTHR	_PXAREG(0x40100000) /* Transmit Holding register 10-14 */
#define FFDLL	_PXAREG(0x40100000) /* Divisor Latch register, low byte 10-14 */
#define FFIER	_PXAREG(0x40100004) /* Interrupt Enable register 10-15 */
#define FFDLH	_PXAREG(0x40100004) /* Divisor Latch register, high byte 10-14 */
#define FFIIR	_PXAREG(0x40100008) /* Interrupt ID register 10-17 */
#define FFFCR	_PXAREG(0x40100008) /* FIFO Control register 10-19 */
#define FFLCR	_PXAREG(0x4010000C) /* Line Control register 10-25 */
#define FFMCR	_PXAREG(0x40100010) /* Modem Control register 10-29 */
#define FFLSR	_PXAREG(0x40100014) /* Line Status register 10-26 */
#define FFMSR	_PXAREG(0x40100018) /* Modem Status register 10-31 */
#define FFSPR	_PXAREG(0x4010001C) /* Scratch Pad register 10-33 */
#define FFISR	_PXAREG(0x40100020) /* Infrared Select register 10-33 */
#define FFFOR	_PXAREG(0x40100024) /* Receive FIFO Occupancy register 10-22 */
#define FFABR	_PXAREG(0x40100028) /* Auto-baud Control register 10-23 */
#define FFACR	_PXAREG(0x4010002C) /* Auto-baud Count register 10-24 */


/******************************************************************************/
/* Bluetooth UART */
/******************************************************************************/
#define BTRBR	_PXAREG(0x40200000) /* Receive Buffer register 10-13 */
#define BTTHR	_PXAREG(0x40200000) /* Transmit Holding register 10-14 */
#define BTDLL	_PXAREG(0x40200000) /* Divisor Latch register, low byte 10-14 */
#define BTIER	_PXAREG(0x40200004) /* Interrupt Enable register 10-15 */
#define BTDLH	_PXAREG(0x40200004) /* Divisor Latch register, high byte 10-14 */
#define BTIIR	_PXAREG(0x40200008) /* Interrupt ID register 10-17 */
#define BTFCR	_PXAREG(0x40200008) /* FIFO Control register 10-19 */
#define BTLCR	_PXAREG(0x4020000C) /* Line Control register 10-25 */
#define BTMCR	_PXAREG(0x40200010) /* Modem Control register 10-29 */
#define BTLSR	_PXAREG(0x40200014) /* Line Status register 10-26 */
#define BTMSR	_PXAREG(0x40200018) /* Modem Status register 10-31 */
#define BTSPR	_PXAREG(0x4020001C) /* Scratch Pad register 10-33 */
#define BTISR	_PXAREG(0x40200020) /* Infrared Select register 10-33 */
#define BTFOR	_PXAREG(0x40200024) /* Receive FIFO Occupancy register 10-22 */
#define BTABR	_PXAREG(0x40200028) /* Auto-Baud Control register 10-23 */
#define BTACR	_PXAREG(0x4020002C) /* Auto-Baud Count register 10-24 */

#define IER_DMAE	(1 << 7)	/* DMA Requests Enable */
#define IER_UUE		(1 << 6)	/* UART Unit Enable */
#define IER_NRZE	(1 << 5)	/* NRZ coding Enable */
#define IER_RTIOE	(1 << 4)	/* Receiver Time Out Interrupt Enable */
#define IER_MIE		(1 << 3)	/* Modem Interrupt Enable */
#define IER_RLSE	(1 << 2)	/* Receiver Line Status Interrupt Enable */
#define IER_TIE		(1 << 1)	/* Transmit Data request Interrupt Enable */
#define IER_RAVIE	(1 << 0)	/* Receiver Data Available Interrupt Enable */

#define IIR_FIFOES1	(1 << 7)	/* FIFO Mode Enable Status */
#define IIR_FIFOES0	(1 << 6)	/* FIFO Mode Enable Status */
#define IIR_TOD		(1 << 3)	/* Time Out Detected */
#define IIR_IID_MASK	(0x3 << 1)	/* Interrupt Source Encoded */
#define IIR_IP		(1 << 0)	/* Interrupt Pending (active low) */

#define FCR_ITL(_x)	((_x) << 6)	/* Interrupt Trigger Level */
#define FCR_BUS		(1 << 5)	/* 32-Bit Peripheral Bus */
#define FCR_TRAIL	(1 << 4)	/* Trailing Bytes */
#define FCR_TIL		(1 << 3)	/* Transmitter Interrupt Level */
#define FCR_RESETTF	(1 << 2)	/* Reset Transmitter FIFO */
#define FCR_RESETRF	(1 << 1)	/* Reset Receiver FIFO */
#define FCR_TRFIFOE	(1 << 0)	/* Transmit and Receive FIFO Enable */

#define ABR_ABT		(1 << 3)	/* Auto-Baud Rate Calculation */
#define ABR_ABUP	(1 << 2)	/* Auto-Baud Programmer */
#define ABR_ABLIE	(1 << 1)	/* Auto-Baud Interrupt */
#define ABR_ABE		(1 << 0)	/* Auto-Baud Enable */

#define LCR_DLAB	(1 << 7)	/* Divisor Latch Access */
#define LCR_SB		(1 << 6)	/* Set Break */
#define LCR_STKYP	(1 << 5)	/* Sticky Parity */
#define LCR_EPS		(1 << 4)	/* Even Parity Select */
#define LCR_PEN		(1 << 3)	/* Parity Enable */
#define LCR_STB		(1 << 2)	/* Stop Bit */
#define LCR_WLS(_x)	((_x) << 0)	/* Word Length Select */

#define LSR_FIFOE	(1 << 7)	/* FIFO Error Status */
#define LSR_TEMT	(1 << 6)	/* Transmitter Empty */
#define LSR_TDRQ	(1 << 5)	/* Transmit Data Request */
#define LSR_BI		(1 << 4)	/* Break Interrupt */
#define LSR_FE		(1 << 3)	/* Framing Error */
#define LSR_PE		(1 << 2)	/* Parity Error */
#define LSR_OE		(1 << 1)	/* Overrun Error */
#define LSR_DR		(1 << 0)	/* Data Ready */

#define MCR_AFE		(1 << 5)	/* Auto-Flow Control Enable */
#define MCR_LOOP	(1 << 4)	/* Loopback Mode */
#define MCR_OUT2	(1 << 3)	/* OUT2 Signal control */
#define MCR_OUT1	(1 << 2)	/* Test Bit */
#define MCR_RTS		(1 << 1)	/* Request to Send */
#define MCR_DTR		(1 << 0)	/* Data Terminal Ready */

#define MSR_DCD		(1 << 7)	/* Data Carrier Detect */
#define MSR_RI		(1 << 6)	/* Ring Indicator */
#define MSR_DSR		(1 << 5)	/* Data Set Ready */
#define MSR_CTS		(1 << 4)	/* Clear To Send */
#define MSR_DDCD	(1 << 3)	/* Delta Data Carrier Detect */
#define MSR_TERI	(1 << 2)	/* Trailing Edge Ring Indicator */
#define MSR_DDSR	(1 << 1)	/* Delta Data Set Ready */
#define MSR_DCTS	(1 << 0)	/* Delta Clear To Send */

#define ISR_RXPL	(1 << 4)	/* Receive Data Polarity */
#define ISR_TXPL	(1 << 3)	/* Transmit Data Polarity */
#define ISR_XMODE	(1 << 2)	/* Transmit Pulse Width Select */
#define ISR_RCVEIR	(1 << 1)	/* Receiver SIR Enable */
#define ISR_XMITIR	(1 << 0)	/* Transmitter SIR Enable */


/******************************************************************************/
/* Standard I2C */
/******************************************************************************/
#define IBMR	_PXAREG(0x40301680) /* I2C Bus Monitor register 9-30 */
#define IDBR	_PXAREG(0x40301688) /* I2C Data Buffer register 9-29 */
#define ICR	_PXAREG(0x40301690) /* I2C Control register 9-23 */
#define ISR	_PXAREG(0x40301698) /* I2C Status register 9-26 */
#define ISAR	_PXAREG(0x403016A0) /* I2C Slave Address register 9-28 */

/* I2C - Control Register */
#define ICR_FM	        (1 << 15)	/* Fast Mode */
#define ICR_UR	        (1 << 14)	/* Unit Reset */
#define ICR_SADIE       (1 << 13)	/* Slave Address Detected Interrupt Enable */
#define ICR_ALDIE	(1 << 12)	/* Arbitratino Loss Detected Interrupt Enable */
#define ICR_SSDIE	(1 << 11)	/* Slave STOP Detected Interrupt Enable */
#define ICR_BEIE	(1 << 10)	/* Bus Error Interrupt Enable */
#define ICR_DRFIE	(1 << 9)	/* DBR Receive Full Interupt Enable */
#define ICR_ITEIE	(1 << 8)	/* IDBR Transmit Empty Interrupt Enable */
#define ICR_GCD	        (1 << 7)	/* General Call Disable */
#define ICR_IUE	        (1 << 6)	/* I2C Unit Enable */
#define ICR_SCLE	(1 << 5)	/* SCL Enable */
#define ICR_MA	        (1 << 4)	/* Master Abort */
#define ICR_TB	        (1 << 3)	/* Transfer Byte */
#define ICR_ACKNAK	(1 << 2)	/* Positive/Negative Acknowledge */
#define ICR_STOP	(1 << 1)	/* Stop */
#define ICR_START	(1 << 0)	/* Start */
            
/* I2C - Status Register */
#define ISR_BED	        (1 << 10)       /* Bus Error Detected */
#define ISR_SAD	        (1 << 9)        /* Slave Address Detected */
#define ISR_GCAD        (1 << 8)        /* General Call Address Detected */
#define ISR_IRF	        (1 << 7)        /* IDBR Receive Full */
#define ISR_ITE	        (1 << 6)        /* IDBR Transmit Empty */
#define ISR_ALD	        (1 << 5)        /* Arbitration Loss Detection */
#define ISR_SSD	        (1 << 4)        /* Slave STOP Detected */
#define ISR_IBB	        (1 << 3)        /* I2C Bus Busy */
#define ISR_UB          (1 << 2)        /* Unit Busy */
#define ISR_ACKNAK      (1 << 1)        /* Ack/Nack Status */
#define ISR_RWM         (1 << 0)        /* Read/Write Mode */

/* I2C - Bus Monitor Register */
#define IBMR_SCL        (1 << 1)        /* Continousely reflects the value of the SCL pin */
#define IBMR_SDA        (1 << 0)        /* Continousely reflects the value of the SDA pin */




/******************************************************************************/
/* I2S Controller */
/******************************************************************************/
#define SACR0	_PXAREG(0x40400000) /* Serial Audio Global Control register 14-10 */
#define SACR1	_PXAREG(0x40400004) /* Serial Audio I2S/MSB-Justified Control register 14-13 */
#define SASR0	_PXAREG(0x4040000C) /* Serial Audio I2S/MSB-Justified Interface and FIFO Status register 14-14 */
#define SAIMR	_PXAREG(0x40400014) /* Serial Audio Interrupt Mask register 14-18 */
#define SAICR	_PXAREG(0x40400018) /* Serial Audio Interrupt Clear register 14-17 */
#define SADIV	_PXAREG(0x40400060) /* Audio Clock Divider register 14-16 */
#define SADR	_PXAREG(0x40400080) /* Serial Audio Data register (TX and RX FIFO access register). 14-18 */


/******************************************************************************/
/* USB Client Controller */
/******************************************************************************/
#define UDCCR	_PXAREG(0x40600000) /* UDC Control register 12-31 */
#define UDCICR0	_PXAREG(0x40600004) /* UDC Interrupt Control register 0 12-35 */
#define UDCICR1	_PXAREG(0x40600008) /* UDC Interrupt Control register 1 12-35 */
#define UDCISR0	_PXAREG(0x4060000C) /* UDC Interrupt Status register 0 12-49 */
#define UDCISR1	_PXAREG(0x40600010) /* UDC Interrupt Status register 1 12-49 */
#define UDCFNR	_PXAREG(0x40600014) /* UDC Frame Number register 12-52 */
#define UDCOTGICR	_PXAREG(0x40600018) /* UDC OTG Interrupt Control register 12-35 */
#define UDCOTGISR	_PXAREG(0x4060001C) /* UDC OTG Interrupt Status register 12-49 */
#define UP2OCR	_PXAREG(0x40600020) /* USB Port 2 Output Control register 12-41 */
#define UP3OCR	_PXAREG(0x40600024) /* USB Port 3 Output Control register 12-47 */
#define UDCCSR0	_PXAREG(0x40600100) /* UDC Control/Status register-Endpoint 0 12-53 */
#define UDCCSRA	_PXAREG(0x40600104) /* UDC Control/Status register-Endpoint A 12-56 */
#define UDCCSRB	_PXAREG(0x40600108) /* UDC Control/Status register-Endpoint B 12-56 */
#define UDCCSRC	_PXAREG(0x4060010C) /* UDC Control/Status register-Endpoint C 12-56 */
#define UDCCSRD	_PXAREG(0x40600110) /* UDC Control/Status register-Endpoint D 12-56 */
#define UDCCSRE	_PXAREG(0x40600114) /* UDC Control/Status register-Endpoint E 12-56 */
#define UDCCSRF	_PXAREG(0x40600118) /* UDC Control/Status register-Endpoint F 12-56 */
#define UDCCSRG	_PXAREG(0x4060011C) /* UDC Control/Status register-Endpoint G 12-56 */
#define UDCCSRH	_PXAREG(0x40600120) /* UDC Control/Status register-Endpoint H 12-56 */
#define UDCCSRI	_PXAREG(0x40600124) /* UDC Control/Status register-Endpoint I 12-56 */
#define UDCCSRJ	_PXAREG(0x40600128) /* UDC Control/Status register-Endpoint J 12-56 */
#define UDCCSRK	_PXAREG(0x4060012C) /* UDC Control/Status register-Endpoint K 12-56 */
#define UDCCSRL	_PXAREG(0x40600130) /* UDC Control/Status register-Endpoint L 12-56 */
#define UDCCSRM	_PXAREG(0x40600134) /* UDC Control/Status register-Endpoint M 12-56 */
#define UDCCSRN	_PXAREG(0x40600138) /* UDC Control/Status register-Endpoint N 12-56 */
#define UDCCSRP	_PXAREG(0x4060013C) /* UDC Control/Status register-Endpoint P 12-56 */
#define UDCCSRQ	_PXAREG(0x40600140) /* UDC Control/Status register-Endpoint Q 12-56 */
#define UDCCSRR	_PXAREG(0x40600144) /* UDC Control/Status register-Endpoint R 12-56 */
#define UDCCSRS	_PXAREG(0x40600148) /* UDC Control/Status register-Endpoint S 12-56 */
#define UDCCSRT	_PXAREG(0x4060014C) /* UDC Control/Status register-Endpoint T 12-56 */
#define UDCCSRU	_PXAREG(0x40600150) /* UDC Control/Status register-Endpoint U 12-56 */
#define UDCCSRV	_PXAREG(0x40600154) /* UDC Control/Status register-Endpoint V 12-56 */
#define UDCCSRW	_PXAREG(0x40600158) /* UDC Control/Status register-Endpoint W 12-56 */
#define UDCCSRX	_PXAREG(0x4060015C) /* UDC Control/Status register-Endpoint X 12-56 */

#define UDCBCR0	_PXAREG(0x40600200) /* UDC Byte Count register-Endpoint 0 12-62 */
#define UDCBCRA	_PXAREG(0x40600204) /* UDC Byte Count register-Endpoint A 12-62 */
#define UDCBCRB	_PXAREG(0x40600208) /* UDC Byte Count register-Endpoint B 12-62 */
#define UDCBCRC	_PXAREG(0x4060020C) /* UDC Byte Count register-Endpoint C 12-62 */
#define UDCBCRD	_PXAREG(0x40600210) /* UDC Byte Count register-Endpoint D 12-62 */
#define UDCBCRE	_PXAREG(0x40600214) /* UDC Byte Count register-Endpoint E 12-62 */
#define UDCBCRF	_PXAREG(0x40600218) /* UDC Byte Count register-Endpoint F 12-62 */
#define UDCBCRG	_PXAREG(0x4060021C) /* UDC Byte Count register-Endpoint G 12-62 */
#define UDCBCRH	_PXAREG(0x40600220) /* UDC Byte Count register-Endpoint H 12-62 */
#define UDCBCRI	_PXAREG(0x40600224) /* UDC Byte Count register-Endpoint I 12-62 */
#define UDCBCRJ	_PXAREG(0x40600228) /* UDC Byte Count register-Endpoint J 12-62 */
#define UDCBCRK	_PXAREG(0x4060022C) /* UDC Byte Count register-Endpoint K 12-62 */
#define UDCBCRL	_PXAREG(0x40600230) /* UDC Byte Count register-Endpoint L 12-62 */
#define UDCBCRM	_PXAREG(0x40600234) /* UDC Byte Count register-Endpoint M 12-62 */
#define UDCBCRN	_PXAREG(0x40600238) /* UDC Byte Count register-Endpoint N 12-62 */
#define UDCBCRP	_PXAREG(0x4060023C) /* UDC Byte Count register-Endpoint P 12-62 */
#define UDCBCRQ	_PXAREG(0x40600240) /* UDC Byte Count register-Endpoint Q 12-62 */
#define UDCBCRR	_PXAREG(0x40600244) /* UDC Byte Count register-Endpoint R 12-62 */
#define UDCBCRS	_PXAREG(0x40600248) /* UDC Byte Count register-Endpoint S 12-62 */
#define UDCBCRT	_PXAREG(0x4060024C) /* UDC Byte Count register-Endpoint T 12-62 */
#define UDCBCRU	_PXAREG(0x40600250) /* UDC Byte Count register-Endpoint U 12-62 */
#define UDCBCRV	_PXAREG(0x40600254) /* UDC Byte Count register-Endpoint V 12-62 */
#define UDCBCRW	_PXAREG(0x40600258) /* UDC Byte Count register-Endpoint W 12-62 */
#define UDCBCRX	_PXAREG(0x4060025C) /* UDC Byte Count register-Endpoint X 12-62 */

#define UDCDR0	_PXAREG(0x40600300) /* UDC Data register-Endpoint 0 12-62 */
#define UDCDRA	_PXAREG(0x40600304) /* UDC Data register-Endpoint A 12-62 */
#define UDCDRB	_PXAREG(0x40600308) /* UDC Data register-Endpoint B 12-62 */
#define UDCDRC	_PXAREG(0x4060030C) /* UDC Data register-Endpoint C 12-62 */
#define UDCDRD	_PXAREG(0x40600310) /* UDC Data register-Endpoint D 12-62 */
#define UDCDRE	_PXAREG(0x40600314) /* UDC Data register-Endpoint E 12-62 */
#define UDCDRF	_PXAREG(0x40600318) /* UDC Data register-Endpoint F 12-62 */
#define UDCDRG	_PXAREG(0x4060031C) /* UDC Data register-Endpoint G 12-62 */
#define UDCDRH	_PXAREG(0x40600320) /* UDC Data register-Endpoint H 12-62 */
#define UDCDRI	_PXAREG(0x40600324) /* UDC Data register-Endpoint I 12-62 */
#define UDCDRJ	_PXAREG(0x40600328) /* UDC Data register-Endpoint J 12-62 */
#define UDCDRK	_PXAREG(0x4060032C) /* UDC Data register-Endpoint K 12-62 */
#define UDCDRL	_PXAREG(0x40600330) /* UDC Data register-Endpoint L 12-62 */
#define UDCDRM	_PXAREG(0x40600334) /* UDC Data register-Endpoint M 12-62 */
#define UDCDRN	_PXAREG(0x40600338) /* UDC Data register-Endpoint N 12-62 */
#define UDCDRP	_PXAREG(0x4060033C) /* UDC Data register-Endpoint P 12-62 */
#define UDCDRQ	_PXAREG(0x40600340) /* UDC Data register-Endpoint Q 12-62 */
#define UDCDRR	_PXAREG(0x40600344) /* UDC Data register-Endpoint R 12-62 */
#define UDCDRS	_PXAREG(0x40600348) /* UDC Data register-Endpoint S 12-62 */
#define UDCDRT	_PXAREG(0x4060034C) /* UDC Data register-Endpoint T 12-62 */
#define UDCDRU	_PXAREG(0x40600350) /* UDC Data register-Endpoint U 12-62 */
#define UDCDRV	_PXAREG(0x40600354) /* UDC Data register-Endpoint V 12-62 */
#define UDCDRW	_PXAREG(0x40600358) /* UDC Data register-Endpoint W 12-62 */
#define UDCDRX	_PXAREG(0x4060035C) /* UDC Data register-Endpoint X 12-62 */

#define UDCCRA	_PXAREG(0x40600404) /* UDC Configuration register-Endpoint A 12-64 */
#define UDCCRB	_PXAREG(0x40600408) /* UDC Configuration register-Endpoint B 12-64 */
#define UDCCRC	_PXAREG(0x4060040C) /* UDC Configuration register-Endpoint C 12-64 */
#define UDCCRD	_PXAREG(0x40600410) /* UDC Configuration register-Endpoint D 12-64 */
#define UDCCRE	_PXAREG(0x40600414) /* UDC Configuration register-Endpoint E 12-64 */
#define UDCCRF	_PXAREG(0x40600418) /* UDC Configuration register-Endpoint F 12-64 */
#define UDCCRG	_PXAREG(0x4060041C) /* UDC Configuration register-Endpoint G 12-64 */
#define UDCCRH	_PXAREG(0x40600420) /* UDC Configuration register-Endpoint H 12-64 */
#define UDCCRI	_PXAREG(0x40600424) /* UDC Configuration register-Endpoint I 12-64 */
#define UDCCRJ	_PXAREG(0x40600428) /* UDC Configuration register-Endpoint J 12-64 */
#define UDCCRK	_PXAREG(0x4060042C) /* UDC Configuration register-Endpoint K 12-64 */
#define UDCCRL	_PXAREG(0x40600430) /* UDC Configuration register-Endpoint L 12-64 */
#define UDCCRM	_PXAREG(0x40600434) /* UDC Configuration register-Endpoint M 12-64 */
#define UDCCRN	_PXAREG(0x40600438) /* UDC Configuration register-Endpoint N 12-64 */
#define UDCCRP	_PXAREG(0x4060043C) /* UDC Configuration register-Endpoint P 12-64 */
#define UDCCRQ	_PXAREG(0x40600440) /* UDC Configuration register-Endpoint Q 12-64 */
#define UDCCRR	_PXAREG(0x40600444) /* UDC Configuration register-Endpoint R 12-64 */
#define UDCCRS	_PXAREG(0x40600448) /* UDC Configuration register-Endpoint S 12-64 */
#define UDCCRT	_PXAREG(0x4060044C) /* UDC Configuration register-Endpoint T 12-64 */
#define UDCCRU	_PXAREG(0x40600450) /* UDC Configuration register-Endpoint U 12-64 */
#define UDCCRV	_PXAREG(0x40600454) /* UDC Configuration register-Endpoint V 12-64 */
#define UDCCRW	_PXAREG(0x40600458) /* UDC Configuration register-Endpoint W 12-64 */
#define UDCCRX	_PXAREG(0x4060045C) /* UDC Configuration register-Endpoint X 12-64 */

/* UDCCR register */
#define UDCCR_UDE (1 << 0)	    /* UDC Enable */

/******************************************************************************/
/* Standard UART */
/******************************************************************************/
#define STRBR	_PXAREG(0x40700000) /* Receive Buffer register 10-13 */
#define STTHR	_PXAREG(0x40700000) /* Transmit Holding register 10-14 */
#define STDLL	_PXAREG(0x40700000) /* Divisor Latch register, low byte 10-14 */
#define STIER	_PXAREG(0x40700004) /* Interrupt Enable register 10-15 */
#define STDLH	_PXAREG(0x40700004) /* Divisor Latch register, high byte 10-14 */
#define STIIR	_PXAREG(0x40700008) /* Interrupt ID register 10-17 */
#define STFCR	_PXAREG(0x40700008) /* FIFO Control register 10-19 */
#define STLCR	_PXAREG(0x4070000C) /* Line Control register 10-25 */
#define STMCR	_PXAREG(0x40700010) /* Modem Control register 10-29 */
#define STLSR	_PXAREG(0x40700014) /* Line Status register 10-26 */
#define STMSR	_PXAREG(0x40700018) /* Modem Status register 10-31 */
#define STSPR	_PXAREG(0x4070001C) /* Scratch Pad register 10-33 */
#define STISR	_PXAREG(0x40700020) /* Infrared Select register 10-33 */
#define STFOR	_PXAREG(0x40700024) /* Receive FIFO Occupancy register 10-22 */
#define STABR	_PXAREG(0x40700028) /* Auto-Baud Control register 10-23 */
#define STACR	_PXAREG(0x4070002C) /* Auto-Baud Count register 10-24 */


/******************************************************************************/
/* Infrared Communications Port */
/******************************************************************************/
#define ICCR0	_PXAREG(0x40800000) /* FICP Control register 0 11-10 */
#define ICCR1	_PXAREG(0x40800004) /* FICP Control register 1 11-13 */
#define ICCR2	_PXAREG(0x40800008) /* FICP Control register 2 11-14 */
#define ICDR	_PXAREG(0x4080000C) /* FICP Data register 11-15 */

#define ICSR0	_PXAREG(0x40800014) /* FICP Status register 0 11-16 */
#define ICSR1	_PXAREG(0x40800018) /* FICP Status register 1 11-18 */
#define ICFOR	_PXAREG(0x4080001C) /* FICP FIFO Occupancy Status register 11-19 */


/******************************************************************************/
/* Real-Time Clock */
/******************************************************************************/
#define RCNR	_PXAREG(0x40900000) /* RTC Counter register 21-24 */
#define RTAR	_PXAREG(0x40900004) /* RTC Alarm register 21-19 */
#define RTSR	_PXAREG(0x40900008) /* RTC Status register 21-17 */
#define RTTR	_PXAREG(0x4090000C) /* RTC Timer Trim register 21-16 */
#define RDCR	_PXAREG(0x40900010) /* RTC Day Counter register 21-24 */
#define RYCR	_PXAREG(0x40900014) /* RTC Year Counter register 21-25 */
#define RDAR1	_PXAREG(0x40900018) /* RTC Wristwatch Day Alarm register 1 21-20 */
#define RYAR1	_PXAREG(0x4090001C) /* RTC Wristwatch Year Alarm register 1 21-21 */
#define RDAR2	_PXAREG(0x40900020) /* RTC Wristwatch Day Alarm register 2 21-20 */
#define RYAR2	_PXAREG(0x40900024) /* RTC Wristwatch Year Alarm register 2 21-21 */
#define SWCR	_PXAREG(0x40900028) /* RTC Stopwatch Counter register 21-26 */
#define SWAR1	_PXAREG(0x4090002C) /* RTC Stopwatch Alarm register 1 21-22 */
#define SWAR2	_PXAREG(0x40900030) /* RTC Stopwatch Alarm register 2 21-22 */
#define RTCPICR	_PXAREG(0x40900034) /* RTC Periodic Interrupt Counter register 21-27 */
#define PIAR	_PXAREG(0x40900038) /* RTC Periodic Interrupt Alarm register 21-23 */

/* RTSR */
#define RTSR_PICE	(1 << 15)  /* periodic interrupt count enable */
#define RTSR_PIALE	(1 << 14)  /* periodic interrupt alarm enable */
#define RTSR_PIAL	(1 << 13)  /* periodic interrupt alarm status */
#define RTSR_SWCE	(1 << 12)  /* stopwatch count enable */
#define RTSR_SWALE2	(1 << 11)  /* stopwatch alarm 2 enable */
#define RTSR_SWAL2	(1 << 10)  /* stopwatch alarm 2 status */
#define RTSR_SWALE1	(1 << 9)   /* stopwatch alarm 1 enable */
#define RTSR_SWAL1	(1 << 8)   /* stopwatch alarm 1 status */
#define RTSR_RDALE2	(1 << 7)   /* wristwatch alarm 2 enable */
#define RTSR_RDAL2	(1 << 6)   /* wristwatch alarm 2 status */
#define RTSR_RDALE1	(1 << 5)   /* wristwatch alarm 1 enable */
#define RTSR_RDAL1	(1 << 4)   /* wristwatch alarm 1 status */
#define RTSR_HZE	(1 << 3)   /* HZ interrupt enable */
#define RTSR_ALE	(1 << 2)   /* RTC alarm interrupt enable */
#define RTSR_HZ		(1 << 1)   /* HZ rising edge detected */
#define RTSR_AL		(1 << 0)   /* RTC alarm detected */

/******************************************************************************/
/* OS Timers */
/******************************************************************************/
#define OSMR0	_PXAREG(0x40A00000) /* OS Timer Match 0 register 22-15 */
#define OSMR1	_PXAREG(0x40A00004) /* OS Timer Match 1 register 22-15 */
#define OSMR2	_PXAREG(0x40A00008) /* OS Timer Match 2 register 22-15 */
#define OSMR3	_PXAREG(0x40A0000C) /* OS Timer Match 3 register 22-15 */
#define OSCR0	_PXAREG(0x40A00010) /* OS Timer Counter 0 register 22-17 */
#define OSSR	_PXAREG(0x40A00014) /* OS Timer Status register (used for all counters) 22-18 */
#define OWER	_PXAREG(0x40A00018) /* OS Timer Watchdog Enable register 22-16 */
#define OIER	_PXAREG(0x40A0001C) /* OS Timer Interrupt Enable register (used for all counters) 22-16 */
#define OSNR	_PXAREG(0x40A00020) /* OS Timer Snapshot register 22-19 */

#define OSCR4	_PXAREG(0x40A00040) /* OS Timer Counter 4-11 registers 22-17 */
#define OSCR5	_PXAREG(0x40A00044) 
#define OSCR6	_PXAREG(0x40A00048) 
#define OSCR7	_PXAREG(0x40A0004C) 
#define OSCR8	_PXAREG(0x40A00050) 
#define OSCR9	_PXAREG(0x40A00054) 
#define OSCR10	_PXAREG(0x40A00058) 
#define OSCR11	_PXAREG(0x40A0005C) 

#define OSMR4	_PXAREG(0x40A00080) /* OS Timer Match 4-11 registers 22-15 */
#define OSMR5	_PXAREG(0x40A00084) 
#define OSMR6	_PXAREG(0x40A00088) 
#define OSMR7	_PXAREG(0x40A0008C) 
#define OSMR8	_PXAREG(0x40A00090) 
#define OSMR9	_PXAREG(0x40A00094) 
#define OSMR10	_PXAREG(0x40A00098) 
#define OSMR11	_PXAREG(0x40A0009C) 

#define OMCR4	_PXAREG(0x40A000C0) /* OS Match Control 4-7 registers 22-9 */
#define OMCR5	_PXAREG(0x40A000C4) 
#define OMCR6	_PXAREG(0x40A000C8) 
#define OMCR7	_PXAREG(0x40A000CC) 
#define OMCR8	_PXAREG(0x40A000D0) /* OS Match Control 8 register 22-11 */
#define OMCR9	_PXAREG(0x40A000D4) /* OS Match Control 9 register 22-13 */
#define OMCR10	_PXAREG(0x40A000D8) /* OS Match Control 10 register 22-11 */
#define OMCR11	_PXAREG(0x40A000DC) /* OS Match Control 11 register 22-13 */

// OS Timer Register Shortcuts
#define OSCR(_ch) *(((_ch) == 0) ? (&OSCR0) : (&_PXAREG_OFFSET(&OSCR4,(((_ch) - 4) << 2)))) 
#define OSMR(_ch) *(((_ch) < 4) ? (&_PXAREG_OFFSET(&OSMR0,((_ch) << 2))) \
				: (&_PXAREG_OFFSET(&OSMR4,(((_ch) - 4) << 2))))
#define OMCR(_ch) _PXAREG_OFFSET(&OMCR4,(((_ch) - 4) << 2))

#define OMCR_N		(1 << 9)	/* Channel 9 & 11 Snapshot Mode */
#define OMCR_C		(1 << 7)	/* Channel 4-7 Match Against */
#define OMCR_P		(1 << 6)	/* Periodic Timer */
#define OMCR_S_NONE	(0 << 4)	/* No External Sync */
#define OMCR_S_EXT_SYNC_0 (1 << 4)	/* Ext Sync Reset OSCRx on rising edge EXT_SYNC<0> */
#define OMCR_S_EXT_SYNC_1 (2 << 4)	/* Ext Sync Reset OSCRx on rising edge EXT_SYNC<1> */
#define OMCR_R		(1 << 3)	/* Match Reset on match */	
#define OMCR_CRES(_x)	((((_x) & 0x8) << 5) | (((_x) & 0x7) << 0))	/* Match counter resolution */

#define OWER_WME	(1 << 0)	/* Watchdog Match Enable */

#define OIER_E11	(1 << 11)	/* Interrupt enable channel 11 */
#define OIER_E10	(1 << 10)	/* Interrupt enable channel 10 */
#define OIER_E9		(1 << 9)	/* Interrupt enable channel 9 */
#define OIER_E8		(1 << 8)	/* Interrupt enable channel 8 */
#define OIER_E7		(1 << 7)	/* Interrupt enable channel 7 */
#define OIER_E6		(1 << 6)	/* Interrupt enable channel 6 */
#define OIER_E5		(1 << 5)	/* Interrupt enable channel 5 */
#define OIER_E4		(1 << 4)	/* Interrupt enable channel 4 */
#define OIER_E3		(1 << 3)	/* Interrupt enable channel 3 */
#define OIER_E2		(1 << 2)	/* Interrupt enable channel 2 */
#define OIER_E1		(1 << 1)	/* Interrupt enable channel 1 */
#define OIER_E0		(1 << 0)	/* Interrupt enable channel 0 */

#define OSSR_M11	(1 << 11)	/* Match status channel 11 */
#define OSSR_M10	(1 << 10)	/* Match status channel 10 */
#define OSSR_M9		(1 << 9)	/* Match status channel 9 */
#define OSSR_M8		(1 << 8)	/* Match status channel 8 */
#define OSSR_M7		(1 << 7)	/* Match status channel 7 */
#define OSSR_M6		(1 << 6)	/* Match status channel 6 */
#define OSSR_M5		(1 << 5)	/* Match status channel 5 */
#define OSSR_M4		(1 << 4)	/* Match status channel 4 */
#define OSSR_M3		(1 << 3)	/* Match status channel 3 */
#define OSSR_M2		(1 << 2)	/* Match status channel 2 */
#define OSSR_M1		(1 << 1)	/* Match status channel 1 */
#define OSSR_M0		(1 << 0)	/* Match status channel 0 */


/******************************************************************************/
/* Pulse-Width Modulation */
/******************************************************************************/
#define PWMCR0	_PXAREG(0x40B00000) /* PWM 0 Control register 23-7 */
#define PWMDCR0	_PXAREG(0x40B00004) /* PWM 0 Duty Cycle register 23-8 */
#define PWMPCR0	_PXAREG(0x40B00008) /* PWM 0 Period register 23-9 */
#define PWMCR2	_PXAREG(0x40B00010) /* PWM 2 Control register 23-7 */
#define PWMDCR2	_PXAREG(0x40B00014) /* PWM 2 Duty Cycle register 23-8 */
#define PWMPCR2	_PXAREG(0x40B00018) /* PWM 2 Period register 23-9 */
#define PWMCR1	_PXAREG(0x40C00000) /* PWM 1 Control register 23-7 */
#define PWMDCR1	_PXAREG(0x40C00004) /* PWM 1 Duty Cycle register 23-8 */
#define PWMPCR1	_PXAREG(0x40C00008) /* PWM 1 Period register 23-9 */
#define PWMCR3	_PXAREG(0x40C00010) /* PWM 3 Control register 23-7 */
#define PWMDCR3	_PXAREG(0x40C00014) /* PWM 3 Duty Cycle register 23-8 */
#define PWMPCR3	_PXAREG(0x40C00018) /* PWM 3 Period register 23-9 */


/******************************************************************************/
/* Interrupt Controller */
/******************************************************************************/
#define ICIP	_PXAREG(0x40D00000) /* Interrupt Controller IRQ Pending register 25-11 */
#define ICMR	_PXAREG(0x40D00004) /* Interrupt Controller Mask register 25-20 */
#define ICLR	_PXAREG(0x40D00008) /* Interrupt Controller Level register 25-24 */
#define ICFP	_PXAREG(0x40D0000C) /* Interrupt Controller FIQ Pending register 25-15 */
#define ICPR	_PXAREG(0x40D00010) /* Interrupt Controller Pending register 25-6 */
#define ICCR	_PXAREG(0x40D00014) /* Interrupt Controller Control register 25-27 */
#define ICHP	_PXAREG(0x40D00018) /* Interrupt Controller Highest Priority register 25-30 */
#define IPR(_x) _PXAREG_OFFSET(0x40D0001C,(((_x) & 0x1F) << 2)) /* Interupt Priority Registers 25-29 */
#define ICIP2	_PXAREG(0x40D0009C) /* Interrupt Controller IRQ Pending register 2 25-10 */
#define ICMR2	_PXAREG(0x40D000A0) /* Interrupt Controller Mask register 2 25-23 */
#define ICLR2	_PXAREG(0x40D000A4) /* Interrupt Controller Level register 2 25-27 */
#define ICFP2	_PXAREG(0x40D000A8) /* Interrupt Controller FIQ Pending register 2 25-19 */
#define ICPR2	_PXAREG(0x40D000AC) /* Interrupt Controller Pending register 2 25-6 */

#define IPR_VALID	(1 << 31) 

#define ICCR_DIM	(1 << 0)

// Interrupt Controller Shortcuts 
// Argument _id is a peripheral ID number
#define _PPID_Bit(_id)	(1 << ((_id) & 0x1f))
#define _ICIP(_id)	*(((_id) & 0x20) ? (&ICIP2) : (&ICIP))
#define _ICMR(_id)	*(((_id) & 0x20) ? (&ICMR2) : (&ICMR))
#define _ICLR(_id)	*(((_id) & 0x20) ? (&ICLR2) : (&ICLR))
#define _ICFP(_id)	*(((_id) & 0x20) ? (&ICFP2) : (&ICFP))
#define _ICPR(_id)	*(((_id) & 0x20) ? (&ICPR2) : (&ICPR))

// Peripheral IDs
#define PPID_CIF	(33)	/* Quick Capture Interface */
#define PPID_RTC_AL	(31)	/* RTC Alarm */
#define PPID_RTC_HZ	(30)	/* RTC 1 Hz Clock */
#define PPID_OST_3	(29)	/* OS Timer 3 */
#define PPID_OST_2	(28)	/* OS Timer 2 */
#define PPID_OST_1	(27)	/* OS Timer 1 */
#define PPID_OST_0	(26)	/* OS Timer 0 */
#define PPID_DMAC 	(25)	/* DMA Controller */
#define PPID_SSP1	(24)	/* SSP 1 */
#define PPID_MMC	(23)	/* Flash Card Interface/MMC */
#define PPID_FFUART	(22)	/* FFUART */
#define PPID_BTUART	(21)	/* BTUART */
#define PPID_STUART	(20)	/* STUART */
#define PPID_ICP	(19)	/* Infrared Comm. Port*/
#define	PPID_I2C	(18)	/* I2C */
#define PPID_LCD	(17)	/* LCD */
#define PPID_SSP2	(16)	/* SSP 2 */
#define PPID_USIM	(15)	/* SmartCard Interface */
#define PPID_AC97	(14)	/* AC '97 */
#define PPID_I2S	(13)	/* I2S */
#define PPID_PMU	(12)	/* Performance Monitor */
#define PPID_USBC	(11)	/* USB Client */
#define PPID_GPIO_X	(10)	/* GPIO except GPIO<1> or GPIO<0> */
#define PPID_GPIO_1	(9)	/* GPIO<1> */
#define PPID_GPIO_0	(8)	/* GPIO<0> */
#define PPID_OST_4_11	(7)	/* OS Timer Channel 4 - 11 */
#define PPID_PWR_I2C	(6)	/* Power I2C */
#define PPID_MEM_STK	(5)	/* Memory Stick*/
#define PPID_KEYPAD	(4)	/* Keypad */
#define PPID_USBH1	(3)	/* USB Host 1 */
#define PPID_USBH2	(2)	/* USB Host 2 */
#define PPID_MSL	(1)	/* MSL */
#define PPID_SSP3	(0)	/* SSP 3 */


/******************************************************************************/
/* General-Purpose I/O (GPIO) Controller */
/******************************************************************************/
#define GPLR0	_PXAREG(0x40E00000) /* GPIO Pin-Level register GPIO<31:0> 24-28 */
#define GPLR1	_PXAREG(0x40E00004) /* GPIO Pin-Level register GPIO<63:32> 24-28 */
#define GPLR2	_PXAREG(0x40E00008) /* GPIO Pin-Level register GPIO<95:64> 24-28 */
#define GPDR0	_PXAREG(0x40E0000C) /* GPIO Pin Direction register GPIO<31:0> 24-11 */
#define GPDR1	_PXAREG(0x40E00010) /* GPIO Pin Direction register GPIO<63:32> 24-11 */
#define GPDR2	_PXAREG(0x40E00014) /* GPIO Pin Direction register GPIO<95:64> 24-11 */
#define GPSR0	_PXAREG(0x40E00018) /* GPIO Pin Output Set register GPIO<31:0> 24-14 */
#define GPSR1	_PXAREG(0x40E0001C) /* GPIO Pin Output Set register GPIO<63:32> 24-14 */
#define GPSR2	_PXAREG(0x40E00020) /* GPIO Pin Output Set register GPIO<95:64> 24-14 */
#define GPCR0	_PXAREG(0x40E00024) /* GPIO Pin Output Clear register GPIO<31:0> 24-14 */
#define GPCR1	_PXAREG(0x40E00028) /* GPIO Pin Output Clear register GPIO <63:32> 24-14 */
#define GPCR2	_PXAREG(0x40E0002C) /* GPIO pin Output Clear register GPIO <95:64> 24-14 */
#define GRER0	_PXAREG(0x40E00030) /* GPIO Rising-Edge Detect Enable register GPIO<31:0> 24-18 */
#define GRER1	_PXAREG(0x40E00034) /* GPIO Rising-Edge Detect Enable register GPIO<63:32> 24-18 */
#define GRER2	_PXAREG(0x40E00038) /* GPIO Rising-Edge Detect Enable register GPIO<95:64> 24-18 */
#define GFER0	_PXAREG(0x40E0003C) /* GPIO Falling-Edge Detect Enable register GPIO<31:0> 24-18 */
#define GFER1	_PXAREG(0x40E00040) /* GPIO Falling-Edge Detect Enable register GPIO<63:32> 24-18 */
#define GFER2	_PXAREG(0x40E00044) /* GPIO Falling-Edge Detect Enable register GPIO<95:64> 24-18 */
#define GEDR0	_PXAREG(0x40E00048) /* GPIO Edge Detect Status register GPIO<31:0> 24-30 */
#define GEDR1	_PXAREG(0x40E0004C) /* GPIO Edge Detect Status register GPIO<63:32> 24-30 */
#define GEDR2	_PXAREG(0x40E00050) /* GPIO Edge Detect Status register GPIO<95:64> 24-30 */
#define GAFR0_L	_PXAREG(0x40E00054) /* GPIO Alternate Function register GPIO<15:0> 24-23 */
#define GAFR0_U	_PXAREG(0x40E00058) /* GPIO Alternate Function register GPIO<31:16> 24-23 */
#define GAFR1_L	_PXAREG(0x40E0005C) /* GPIO Alternate Function register GPIO<47:32> 24-23 */
#define GAFR1_U	_PXAREG(0x40E00060) /* GPIO Alternate Function register GPIO<63:48> 24-23 */
#define GAFR2_L	_PXAREG(0x40E00064) /* GPIO Alternate Function register GPIO<79:64> 24-23 */
#define GAFR2_U	_PXAREG(0x40E00068) /* GPIO Alternate Function register GPIO <95:80> 24-23 */
#define GAFR3_L	_PXAREG(0x40E0006C) /* GPIO Alternate Function register GPIO<111:96> 24-23 */
#define GAFR3_U	_PXAREG(0x40E00070) /* GPIO Alternate Function register GPIO<120:112> 24-23 */

#define GPLR3	_PXAREG(0x40E00100) /* GPIO Pin-Level register GPIO<120:96> 24-28 */
#define GPDR3	_PXAREG(0x40E0010C) /* GPIO Pin Direction register GPIO<120:96> 24-11 */
#define GPSR3	_PXAREG(0x40E00118) /* GPIO Pin Output Set register GPIO<120:96> 24-14 */
#define GPCR3	_PXAREG(0x40E00124) /* GPIO Pin Output Clear register GPIO<120:96> 24-14 */
#define GRER3	_PXAREG(0x40E00130) /* GPIO Rising-Edge Detect Enable register GPIO<120:96> 24-18 */
#define GFER3	_PXAREG(0x40E0013C) /* GPIO Falling-Edge Detect Enable register GPIO<120:96> 24-18 */
#define GEDR3	_PXAREG(0x40E00148) /* GPIO Edge Detect Status register GPIO<120:96> 24-18 */

// GPIO Shortcuts
#define GPLR(_gpio) *(((_gpio) < 96) ? (&_PXAREG_OFFSET(&GPLR0, ((_gpio) & 0x60) >> 3)) : (&GPLR3))
#define GPDR(_gpio) *(((_gpio) < 96) ? (&_PXAREG_OFFSET(&GPDR0, ((_gpio) & 0x60) >> 3)) : (&GPDR3))
#define GPSR(_gpio) *(((_gpio) < 96) ? (&_PXAREG_OFFSET(&GPSR0, ((_gpio) & 0x60) >> 3)) : (&GPSR3))
#define GPCR(_gpio) *(((_gpio) < 96) ? (&_PXAREG_OFFSET(&GPCR0, ((_gpio) & 0x60) >> 3)) : (&GPCR3))
#define GRER(_gpio) *(((_gpio) < 96) ? (&_PXAREG_OFFSET(&GRER0, ((_gpio) & 0x60) >> 3)) : (&GRER3))
#define GFER(_gpio) *(((_gpio) < 96) ? (&_PXAREG_OFFSET(&GFER0, ((_gpio) & 0x60) >> 3)) : (&GFER3))
#define GEDR(_gpio) *(((_gpio) < 96) ? (&_PXAREG_OFFSET(&GEDR0, ((_gpio) & 0x60) >> 3)) : (&GEDR3))
#define GAFR(_gpio) (_PXAREG_OFFSET(0x40E00054, ((_gpio) & 0x70) >> 2))

// These provide the correct bit/function placement in a SINGLE register
#define _GPIO_bit(_gpio)  (1 << ((_gpio) & 0x1f))
#define _GPIO_fn(_gpio,_fn)	((_fn) << (((_gpio) & 0x0f) << 1))

#define _GPIO_setaltfn(_gp,_fn) \
   GAFR((_gp)) = ((GAFR((_gp)) & ~(_GPIO_fn((_gp),3))) | (_GPIO_fn((_gp),(_fn))))

#define _GPIO_getaltfun(_gp) \
   ((GAFR((_gp)) & (_GPIO_fn((_gp),0x3))) >> (((_gp) & 0x0f) << 1))

#define GPIO_OUT 1
#define GPIO_IN 0

#define _PXA_setaltfn(_gp,_fn,_dir) \
{ GPDR(_gp) = (_dir==GPIO_OUT)? (GPDR(_gp) |  _GPIO_bit(_gp)) : (GPDR(_gp) & ~_GPIO_bit(_gp)); _GPIO_setaltfn(_gp,_fn);}

#define _PXA_setgpio(_gp) \
{GPSR(_gp) = _GPIO_bit(_gp);}

#define _PXA_clrgpio(_gp) \
{GPCR(_gp) = _GPIO_bit(_gp);}

/******************************************************************************/
/* Power Manager and Reset Control */
/******************************************************************************/
#define PMCR	_PXAREG(0x40F00000) /* Power Manager Control register 3-67 */
#define PSSR	_PXAREG(0x40F00004) /* Power Manager Sleep Status register 3-69 */
#define PSPR	_PXAREG(0x40F00008) /* Power Manager Scratch Pad register 3-72 */
#define PWER	_PXAREG(0x40F0000C) /* Power Manager Wake-Up Enable register 3-73 */
#define PRER	_PXAREG(0x40F00010) /* Power Manager Rising-Edge Detect Enable register 3-76 */
#define PFER	_PXAREG(0x40F00014) /* Power Manager Falling-Edge Detect Enable register 3-77 */
#define PEDR	_PXAREG(0x40F00018) /* Power Manager Edge-Detect Status register 3-78 */
#define PCFR	_PXAREG(0x40F0001C) /* Power Manager General Configuration register 3-79 */
#define PGSR0	_PXAREG(0x40F00020) /* Power Manager GPIO Sleep State register for GPIO<31:0> 3-82 */
#define PGSR1	_PXAREG(0x40F00024) /* Power Manager GPIO Sleep State register for GPIO<63:32> 3-82 */
#define PGSR2	_PXAREG(0x40F00028) /* Power Manager GPIO Sleep State register for GPIO<95:64> 3-82 */
#define PGSR3	_PXAREG(0x40F0002C) /* Power Manager GPIO Sleep State register for GPIO<120:96> 3-82 */
#define RCSR	_PXAREG(0x40F00030) /* Reset Controller Status register 3-83 */
#define PSLR	_PXAREG(0x40F00034) /* Power Manager Sleep Configuration register 3-84 */
#define PSTR	_PXAREG(0x40F00038) /* Power Manager Standby Configuration register 3-87 */
#define PVCR	_PXAREG(0x40F00040) /* Power Manager Voltage Change Control register 3-88 */
#define PUCR	_PXAREG(0x40F0004C) /* Power Manager USIM Card Control/Status register 3-89 */
#define PKWR	_PXAREG(0x40F00050) /* Power Manager Keyboard Wake-Up Enable register 3-91 */
#define PKSR	_PXAREG(0x40F00054) /* Power Manager Keyboard Level-Detect Status register 3-92 */
#define PCMD(_x) _PXAREG_OFFSET(0x40F00080,((_x) << 2)) /* Power Manager I2C Command Register File */

#define PMCR_INTRS	(1 << 5)	/* Interrupt Status */
#define PMCR_IAS	(1 << 4)	/* Interrupt/Abort Select */
#define PMCR_VIDAS	(1 << 3)	/* Imprecise-Data-Abort Status for nVDD_FAULT */
#define PMCR_VIDAE	(1 << 2)	/* Imprecise-Data-Abort Enable for nVDD_FAULT */
#define PMCR_BIDAS	(1 << 1)	/* Imprecise-Data-Abort Status for nBATT_FAULT */
#define PMCR_BIDAE	(1 << 0)	/* Imprecise-Data-Abort Enable for nBATT_FAULT */

#define PSSR_OTGPH	(1 << 6)	/* OTG Peripheral Control Hold */
#define PSSR_RDH	(1 << 5)	/* Read Disable Hold */
#define PSSR_PH		(1 << 4)	/* Peripheral Control Hold */
#define PSSR_STS	(1 << 3)	/* Standby Mode Status */
#define PSSR_VFS	(1 << 2)	/* VDD Fault Status */
#define PSSR_BFS	(1 << 1)	/* Battery Fault Status */
#define PSSR_SSS	(1 << 0)	/* Software Sleep Status */

#define PWER_WERTC	(1 << 31)	/* Wake-up Enable for RTC Standby, Sleep or Deep-Sleep Mode */
#define PWER_WEP1	(1 << 30)	/* Wake-up Enable for PI Power Domain Standby or Deep-Sleep Mode */
#define PWER_WEUSBH2	(1 << 28)	/* Wake-up Enable for USB Host Port 2 Standby or Sleep Mode */
#define PWER_WEUSBH1	(1 << 27)	/* Wake-up Enable for USB Host Port 1 Standby or Sleep Mode */
#define PWER_WEUSBC	(1 << 26)	/* Wake-up Enable for USB Client Port Standby or Sleep Mode */
#define PWER_WBB        (1 << 25)	/* Wake-up Enable for a Rising Edge from MSL or Sleep Mode */
#define PWER_WE35	(1 << 24)	/* Wake-up Enable for GPIO<35> for Standby or Sleep Mode */
#define PWER_WEUSIM	(1 << 23)	/* Wake-up Enable for Rising or Falling Edge from UDET for Standby or Sleep Mode */
#define PWER_WEMUX3_GPIO31 (1 << 19)	/* Wake-up Enable due to GPIO<31> for Standby and Sleep Modes */
#define PWER_WEMUX3_GPIO113 (2 << 19)   /* Wake-up Enable due to GPIO<113> for Standby and Sleep Modes */
#define PWER_WEMUX2_GPIO38 (0x2 << 16)  /* Wake-up Enable due to GPIO<38> for Standby and Sleep Modes */
#define PWER_WEMUX2_GPIO53 (0x3 << 16)  /* Wake-up Enable due to GPIO<53> for Standby and Sleep Modes */
#define PWER_WEMUX2_GPIO40 (0x4 << 16)  /* Wake-up Enable due to GPIO<40> for Standby and Sleep Modes */
#define PWER_WEMUX2_GPIO36 (0x5 << 15)  /* Wake-up Enable due to GPIO<36> for Standby and Sleep Modes */
#define PWER_WE15	(1 << 15)	/* Wake-up Enables for GPIO<n> for Standby or Sleep Mode */
#define PWER_WE14	(1 << 14)
#define PWER_WE13	(1 << 13)
#define PWER_WE12	(1 << 12)
#define PWER_WE11	(1 << 11)
#define PWER_WE10	(1 << 10)
#define PWER_WE9	(1 << 9)
#define PWER_WE4	(1 << 4)
#define PWER_WE3	(1 << 3)
#define PWER_WE1	(1 << 1)
#define PWER_WE0	(1 << 0)

#define PRER_RE1	(1 << 1)

#define PFER_RE1	(1 << 1)

#define PCFR_RO		(1 << 15)	/* RDH Override */
#define PCFR_PO		(1 << 14)	/* PH Override */
#define PCFR_GPROD	(1 << 12)	/* GPIO nRESET_OUT Disable */
#define PCFR_L1_EN	(1 << 11)	/* Sleep MOde/Deep-Sleep Linear Regulator Enable */
#define PCFR_FVC	(1 << 10)	/* Frequency/Voltage Change */
#define PCFR_DC_EN	(1 << 7)	/* Sleep/Deep-sleep DC-DC Converter Enable */
#define PCFR_PI2C_EN	(1 << 6)	/* Power Manager I2C Enable */
#define PCFR_GPR_EN	(1 << 4)	/* nRESET_GPIO Pin Enable */
#define PCFR_FS		(1 << 2)	/* Float Static Chip Selects During Sleep Mode */
#define PCFR_FP		(1 << 1)	/* Float PC Card Pins During Sleep or Deep-Sleep Mode */
#define PCFR_OPDE	(1 << 0)	/* 13MHz Processor Oscillator Power-Down Enable */

#define RCSR_GPR	(1 << 3)	/* GPIO Reset */
#define RCSR_SMR	(1 << 2)	/* Sleep Mode */
#define RCSR_WDR	(1 << 1)	/* Watchdog Reset */
#define RCSR_HWR	(1 << 0)	/* Hardware Reset */

#define PCMD_MBC	(1 << 12)	/* Multi-Byte Command */
#define PCMD_DCE	(1 << 11)	/* Delay Command Execution */
#define PCMD_LC		(1 << 10)	/* Last command */
#define PCMD_SQC_CONT	(0 << 8)	/* Sequence Configuration Continue */
#define PCMD_SQC_PAUSE	(1 << 8)	/* Sequence Configuration Pause */
#define PCMD_DATA(_x)	(((_x) & 0xFF)) /* Command Data */

#define PSLR_SYS_DEL(_x) (((_x) & 0xf) << 28) /* High voltage ramp delay */
#define PSLR_PWR_DEL(_x) (((_x) & 0xf) << 24) /* Low voltage ramp delay */
#define PSLR_PSSD 	(1 << 23)	      /* Shorten wake-up delay */
#define PSLR_IVF 	(1 << 22)	      /* Ignore VDD_FAULT */
#define PSLR_SL_ROD 	(1 << 20)	      /*  Don't assert nRESET_OUT */
#define PSLR_SL_R3 	(1 << 11)	      /* SRAM bank 3 retains state */
#define PSLR_SL_R2 	(1 << 10)	      /* SRAM bank 2 retains state */
#define PSLR_SL_R1 	(1 << 9)	      /* SRAM bank 1 retains state */
#define PSLR_SL_R0 	(1 << 8)	      /* SRAM bank 0 retains state */
#define PSLR_SL_PI(_x) (((_x) & 0x3) << 2)    /* PI power domain */

#define PWRMODE_M_NORMAL	(0)
#define PWRMODE_M_IDLE		(1)
#define PWRMODE_M_STANDBY	(2)
#define PWRMODE_M_SLEEP		(3)
#define PWRMODE_M_DEEPSLEEP	(4)
#define PWRMODE_VC	(1 << 3)	/* Voltage Change */

/******************************************************************************/
/* Power Manager I2C */
/******************************************************************************/
#define PIBMR	_PXAREG(0x40F00180) /* Power Manager I2C Bus Monitor register 9-30 */
#define PIDBR	_PXAREG(0x40F00188) /* Power Manager I2C Data Buffer register 9-29 */
#define PICR	_PXAREG(0x40F00190) /* Power Manager I2C Control register 9-23 */
#define PISR	_PXAREG(0x40F00198) /* Power Manager I2C Status register 9-26 */
#define PISAR	_PXAREG(0x40F001A0) /* Power Manager I2C Slave Address register 9-28 */


/******************************************************************************/
/* Synchronous Serial Port 1 */
/******************************************************************************/
#define SSCR0_1	_PXAREG(0x41000000) /* SSP 1 Control register 0 8-25 */
#define SSCR1_1	_PXAREG(0x41000004) /* SSP 1 Control register 1 8-29 */
#define SSSR_1	_PXAREG(0x41000008) /* SSP 1 Status register 8-43 */
#define SSITR_1	_PXAREG(0x4100000C) /* SSP 1 Interrupt Test register 8-42 */
#define SSDR_1	_PXAREG(0x41000010) /* SSP 1 Data Write register/Data Read register 8-48 */

#define SSTO_1	_PXAREG(0x41000028) /* SSP 1 Time-Out register 8-41 */
#define SSPSP_1	_PXAREG(0x4100002C) /* SSP 1 Programmable Serial Protocol 8-39 */
#define SSTSA_1	_PXAREG(0x41000030) /* SSP1 TX Timeslot Active register 8-48 */
#define SSRSA_1	_PXAREG(0x41000034) /* SSP1 RX Timeslot Active register 8-49 */
#define SSTSS_1	_PXAREG(0x41000038) /* SSP1 Timeslot Status register 8-50 */
#define SSACD_1	_PXAREG(0x4100003C) /* SSP1 Audio Clock Divider register 8-51 */

// SSP Bit positions. THESE ARE ALSO VALID FOR SSP2 AND SSP3
#define SSCR0_MOD	(1 << 31)	  /* Mode Network Mode Enable */
#define SSCR0_ACS	(1 << 30)	  /* Audio Clock Select */
#define SSCR0_FRDC(_x)  (((_x) & 0x7) << 24)      /* Frame Rate Divider Control value */
#define SSCR0_TIM	(1 << 23)	  /* Transmit FIFO underrun interrupt mask */
#define SSCR0_RIM	(1 << 22)	  /* Receive FIFO overrun interrupt mask */
#define SSCR0_NCS	(1 << 21)	  /* Network Clock select */
#define SSCR0_EDSS	(1 << 20)	  /* Extended Data Size select */
#define SSCR0_SCR(_x)   (((_x) & 0xFFF) << 8)	  /* Serial Clock Rate */
#define SSCR0_SSE	(1 << 7)	  /* Synchronous Serial Enable */
#define SSCR0_ECS	(1 << 6)	  /* External Clock select */
#define SSCR0_FRF(_x)	(((_x) & 0x3) << 4)	  /* Frame Format */
#define SSCR0_DSS(_x)	(((_x) & 0xF) << 0)	  /* Data Size Select */

#define SSCR1_TTELP	(1 << 31)	 /* TXD Tristate Enable on Last Phase */
#define SSCR1_TTE	(1 << 30)	 /* TXD Tristate Enable */
#define SSCR1_EBCEI	(1 << 29)	 /* Enable Bit Count Error Interrupt */
#define SSCR1_SCFR	(1 << 28)	 /* Slave clock Free Running */
#define SSCR1_ECRA	(1 << 27)	 /* Enable Clock Request A */
#define SSCR1_ECRB	(1 << 26)	 /* Enable Clock Request B */
#define SSCR1_SCLKDIR	(1 << 25)	 /* SSPSCLKx Direction */
#define SSCR1_SFRMDIR	(1 << 24)	 /* SSP Frame Direction */
#define SSCR1_RWOT	(1 << 23)	 /* Receive Without Transmit */
#define SSCR1_TRAIL	(1 << 22)	 /* Trailing Byte DMA based */
#define SSCR1_TSRE	(1 << 21)	 /* Transmit Service Req Enable */
#define SSCR1_RSRE	(1 << 20)	 /* Receive Service Req. Enable */
#define SSCR1_TINTE	(1 << 19)	 /* Receiver Time-Out Interupt Enable */
#define SSCR1_PINTE	(1 << 18)	 /* Peripheral Trailing Byte Interrupt Enable */
#define SSCR1_IFS	(1 << 16)	 /* Invert Frame Signal */
#define SSCR1_STRF	(1 << 15)	 /* Select FIFO for EFWR */
#define SSCR1_EFWR	(1 << 14)	 /* Enable FIFO Write-Read */
#define SSCR1_RFT(_x)	(((_x) & 0xF) << 10)	 /* Receive FIFO Threshold */
#define SSCR1_TFT(_x)	(((_x) & 0xF) << 6)	 /* Transmit FIFO Threshold */
#define SSCR1_MWDS	(1 << 5)	 /* Microwire Transmit Data Size */
#define SSCR1_SPH	(1 << 4)	 /* Motorola SPI SSPSCLKx Phase */
#define SSCR1_SPO	(1 << 3)	 /* Motorola SPI SSPSCLKx Polarity */
#define SSCR1_LBM	(1 << 2)	 /* Loop-back mode */
#define SSCR1_TIE	(1 << 1)	 /* Transmit FIFO Interrupt Enable */
#define SSCR1_RIE	(1 << 0)	 /* Receive FIFO Interrupt Enable */

#define SSSR_BCE	(1 << 23)	 /* Bit Count Error */
#define SSSR_CSS	(1 << 22)	 /* Clock Synch Status */
#define SSSR_TUR	(1 << 21)	 /* Transmit FIFO Underrun */
#define SSSR_EOC	(1 << 20)	 /* End of Chain */
#define SSSR_TINT	(1 << 19)	 /* Time-out Interrupt */
#define SSSR_PINT	(1 << 18)	 /* Peripheral Trailing Byte Interrupt */
#define SSSR_RFL	((0xf) << 12)	 /* RX FIFO Level */
#define SSSR_TFL	((0xf) << 8)	 /* TX FIFO Level */
#define SSSR_ROR	(1 << 7)	 /* RX FIFO Overrun */
#define SSSR_RFS	(1 << 6)	 /* Receive FIFO Service */
#define SSSR_TFS	(1 << 5)	 /* Transmit FIFO Service */
#define SSSR_BSY	(1 << 4)	 /* SSP Port Busy */
#define SSSR_RNE	(1 << 3)	 /* RX FIFO Not Empty */
#define SSSR_TNF	(1 << 2)	 /* TX FIFO Not Full */

#define SSPSP_FSRT      (1 << 25)        /* Frame Sync Relative Timing */
#define SSPSP_DMYSTOP(_x) (((_x) & 0x3) << 23)	 /* Dummy Stop */
#define SSPSP_SFRMWDTH(_x)    (((_x) & 0x3F) << 16) /* Serial Frame width*/
#define SSPSP_SFRMDLY(_x)    (((_x) & 0x7F) << 9) /* Serial Frame delay*/
#define SSPSP_DMYSTRT(_x)    (((_x) & 0x3) << 7) /* Dummy Start*/
#define SSPSP_STRTDLY(_x)    (((_x) & 0x7) << 4) /* Start Delay*/
#define SSPSP_ETDS      (1 << 3)        /* End-of-Transfer Data State*/
#define SSPSP_SFRMP     (1 << 2)        /* Serial Frame Polarity */
#define SSPSP_SCMODE(_x)    (((_x) & 0x3)) /* Serial Bit-Rate Clock mode*/

#define SSACD_ACPS(_x)    (((_x) & 0x7) << 4) /* Audio Clock PLL Select */
#define SSACD_SCDB        (1 << 3) /* Audio Clock PLL Select */
#define SSACD_ACDS(_x)    (((_x) & 0x7)) /* Audio Clock Divider Select */


/******************************************************************************/
/* MultiMediaCard/SD/SDIO Controller */
/******************************************************************************/
#define MMC_STRPCL	_PXAREG(0x41100000) /* MMC Clock Start/Stop register 15-28 */
#define MMC_STAT	_PXAREG(0x41100004) /* MMC Status register 15-28 */
#define MMC_CLKRT	_PXAREG(0x41100008) /* MMC Clock Rate register 15-30 */
#define MMC_SPI	_PXAREG(0x4110000C) /* MMC SPI Mode register 15-30 */
#define MMC_CMDAT	_PXAREG(0x41100010) /* MMC Command/Data register 15-31 */
#define MMC_RESTO	_PXAREG(0x41100014) /* MMC Response Time-Out register 15-33 */
#define MMC_RDTO	_PXAREG(0x41100018) /* MMC Read Time-Out register 15-33 */
#define MMC_BLKLEN	_PXAREG(0x4110001C) /* MMC Block Length register 15-34 */
#define MMC_NUMBLK	_PXAREG(0x41100020) /* MMC Number of Blocks register 15-34 */
#define MMC_PRTBUF	_PXAREG(0x41100024) /* MMC Buffer Partly Full register 15-35 */
#define MMC_I_MASK	_PXAREG(0x41100028) /* MMC Interrupt Mask register 15-35 */
#define MMC_I_REG	_PXAREG(0x4110002C) /* MMC Interrupt Request register 15-37 */
#define MMC_CMD	_PXAREG(0x41100030) /* MMC Command register 15-40 */
#define MMC_ARGH	_PXAREG(0x41100034) /* MMC Argument High register 15-40 */
#define MMC_ARGL	_PXAREG(0x41100038) /* MMC Argument Low register 15-41 */
#define MMC_RES	_PXAREG(0x4110003C) /* MMC Response FIFO 15-41 */
#define MMC_RXFIFO	_PXAREG(0x41100040) /* MMC Receive FIFO 15-41 */
#define MMC_TXFIFO	_PXAREG(0x41100044) /* MMC Transmit FIFO 15-42 */
#define MMC_RDWAIT	_PXAREG(0x41100048) /* MMC RD_WAIT register 15-42 */
#define MMC_BLKS_REM	_PXAREG(0x4110004C) /* MMC Blocks Remaining register 15-43 */


/******************************************************************************/
/* Clocks Manager */
/******************************************************************************/
#define CCCR	_PXAREG(0x41300000) /* Core Clock Configuration register 3-94 */
#define CKEN	_PXAREG(0x41300004) /* Clock Enable register 3-97 */
#define OSCC	_PXAREG(0x41300008) /* Oscillator Configuration register 3-98 */
#define CCSR	_PXAREG(0x4130000C) /* Core Clock Status register 3-100 */

#define CCCR_CPDIS	(1 << 31)	/* Core PLL Output Disable */
#define CCCR_PPDIS	(1 << 30)	/* Peripheral PLL Output Disable */
#define CCCR_LCD_26	(1 << 27)	/* LCD Clock Frequency in Deep-Idle or 13M Mode */
#define CCCR_PLL_EARLY_EN (1 << 26)	/* Early PLL Enable */
#define CCCR_A		(1 << 25)	/* Alt. Setting for Memory Controller Clock */
#define CCCR_N_MASK	0x0380		/* Run Mode Frequency to Turbo Mode Frequency Multiplier */
#define CCCR_M_MASK	0x0060		/* Memory Frequency to Run Mode Frequency Multiplier */
#define CCCR_L_MASK	0x001f		/* Crystal Frequency to Memory Frequency Multiplier */
#define CCCR_2N(_x)      (((_x) & 0xf) << 7)
#define CCCR_L(_x)      (((_x) & 0x1f))


#define CKEN24_CIF	(1 << 24)	/* CIF Unit Clock Enable */
#define CKEN23_SSP1	(1 << 23)	/* SSP1 Unit Clock Enable */
#define CKEN22_MEMC	(1 << 22)	/* Memory Controller */
#define CKEN21_MEMS	(1 << 21)	/* Memory Stick Host Controller */
#define CKEN20_IMEM	(1 << 20)	/* Internal Memory Clock Enable */
#define CKEN19_KEYP	(1 << 19)	/* Keypad Interface Clock Enable */
#define CKEN18_USIM	(1 << 18)	/* USIM Unit Clock Enable */
#define CKEN17_MSL	(1 << 17)	/* MSL Inteface Unit Enable */
#define CKEN16_LCD	(1 << 16)	/* LCD Unit Clock Enable */
#define CKEN15_PMI2C	(1 << 15)	/* Pomer Manager I2C Unit Clock Enable */
#define CKEN14_I2C	(1 << 14)	/* I2C Unit Clock Enable */
#define CKEN13_IR	(1 << 13)	/* Infrared Port Clock Enable */
#define CKEN12_MMC	(1 << 12)	/* MMC Unit Clock Enable */
#define CKEN11_USBC	(1 << 11)	/* USB Unit Clock Enable */
#define CKEN10_USBH	(1 << 10)	/* USB Unit Clock Enable */
#define CKEN9_OST	(1 << 9)	/* USB Unit Clock Enable */
#define CKEN8_I2S	(1 << 8)	/* I2S Unit Clock Enable */
#define CKEN7_BTUART	(1 << 7)	/* BTUART Unit Clock Enable */
#define CKEN6_FFUART	(1 << 6)	/* FFUART Unit Clock Enable */
#define CKEN5_STUART	(1 << 5)	/* STUART Unit Clock Enable */
#define CKEN4_SSP3	(1 << 4)	/* SSP3 Unit Clock Enable */
#define CKEN3_SSP2	(1 << 3)	/* SSP2 Unit Clock Enable */
#define CKEN2_AC97	(1 << 2)	/* AC97 Unit Clock Enable */
#define CKEN1_PWM1	(1 << 1)	/* PWM1 Clock Enable */
#define CKEN0_PWM0	(1 << 0)	/* PWM0 Clock Enable */

#define OSCC_OSD(_x)	(((_x) & 0x3) << 5) /* Processor Oscillator Stabilization Delay */
#define OSCC_CRI	(1 << 4)	/* Clock Request Input Status */
#define OSCC_PIO_EN	(1 << 3)	/* 13-MHz Processor Oscillator Output Enable */
#define OSCC_TOUT_EN	(1 << 2)	/* Timekeeping (32.768kHz) Oscillator Output Enable */
#define OSCC_OON	(1 << 1)	/* 32.768kHz OON (write-once only bit) */
#define OSCC_OOK	(1 << 0)	/* 32.768kHz OOK (read-only bit) */

#define CCSR_CPDIS_S	(1 << 31)	/* Core PLL Output Disable Status */
#define CCSR_PPDIS_S	(1 << 30)	/* Peripheral PLL Output Disable Status */
#define CCSR_CPLCK	(1 << 29)	/* Core PLL Lock */
#define CCSR_PPLCK	(1 << 28)	/* Peripheral PLL Lock */
#define CCSR_2N_S_MASK	(0x7 << 7)
#define CCSR_L_S_MASK	(0x1f << 0)

#define CLKCFG_T    	(1 << 0)      	/* Turbo mode */
#define CLKCFG_F     	(1 << 1)	/* Frequency change */
#define CLKCFG_HT	(1 << 2)	/* Half-turbo Mode */
#define CLKCFG_B     	(1 << 3)	/* Fast-bus mode */


/******************************************************************************/
/* Mobile Scalable Link (MSL) Interface */
/******************************************************************************/
#define BBFIFO1	_PXAREG(0x41400004) /* MSL Channel 1 Receive/Transmit FIFO register 16-13 */
#define BBFIFO2	_PXAREG(0x41400008) /* MSL Channel 2 Receive/Transmit FIFO register 16-13 */
#define BBFIFO3	_PXAREG(0x4140000C) /* MSL Channel 3 Receive/Transmit FIFO register 16-13 */
#define BBFIFO4	_PXAREG(0x41400010) /* MSL Channel 4 Receive/Transmit FIFO register 16-13 */
#define BBFIFO5	_PXAREG(0x41400014) /* MSL Channel 5 Receive/Transmit FIFO register 16-13 */
#define BBFIFO6	_PXAREG(0x41400018) /* MSL Channel 6 Receive/Transmit FIFO register 16-13 */
#define BBFIFO7	_PXAREG(0x4140001C) /* MSL Channel 7 Receive/Transmit FIFO register 16-13 */

#define BBCFG1	_PXAREG(0x41400044) /* MSL Channel 1 Configuration register 16-15 */
#define BBCFG2	_PXAREG(0x41400048) /* MSL Channel 2 Configuration register 16-15 */
#define BBCFG3	_PXAREG(0x4140004C) /* MSL Channel 3 Configuration register 16-15 */
#define BBCFG4	_PXAREG(0x41400050) /* MSL Channel 4 Configuration register 16-15 */
#define BBCFG5	_PXAREG(0x41400054) /* MSL Channel 5 Configuration register 16-15 */
#define BBCFG6	_PXAREG(0x41400058) /* MSL Channel 6 Configuration register 16-15 */
#define BBCFG7	_PXAREG(0x4140005C) /* MSL Channel 7 Configuration register 16-15 */

#define BBSTAT1	_PXAREG(0x41400084) /* MSL Channel 1 Status register 16-19 */
#define BBSTAT2	_PXAREG(0x41400088) /* MSL Channel 2 Status register 16-19 */
#define BBSTAT3	_PXAREG(0x4140008C) /* MSL Channel 3 Status register 16-19 */
#define BBSTAT4	_PXAREG(0x41400090) /* MSL Channel 4 Status register 16-19 */
#define BBSTAT5	_PXAREG(0x41400094) /* MSL Channel 5 Status register 16-19 */
#define BBSTAT6	_PXAREG(0x41400098) /* MSL Channel 6 Status register 16-19 */
#define BBSTAT7	_PXAREG(0x4140009C) /* MSL Channel 7 Status register 16-19 */

#define BBEOM1	_PXAREG(0x414000C4) /* MSL Channel 1 EOM register 16-22 */
#define BBEOM2	_PXAREG(0x414000C8) /* MSL Channel 2 EOM register 16-22 */
#define BBEOM3	_PXAREG(0x414000CC) /* MSL Channel 3 EOM register 16-22 */
#define BBEOM4	_PXAREG(0x414000D0) /* MSL Channel 4 EOM register 16-22 */
#define BBEOM5	_PXAREG(0x414000D4) /* MSL Channel 5 EOM register 16-22 */
#define BBEOM6	_PXAREG(0x414000D8) /* MSL Channel 6 EOM register 16-22 */
#define BBEOM7	_PXAREG(0x414000DC) /* MSL Channel 7 EOM register 16-22 */

#define BBIID	_PXAREG(0x41400108) /* MSL Interrupt ID register 16-23 */

#define BBFREQ	_PXAREG(0x41400110) /* MSL Transmit Frequency Select register 10-6 */
#define BBWAIT	_PXAREG(0x41400114) /* MSL Wait Count register 16-24 */
#define BBCST	_PXAREG(0x41400118) /* MSL Clock Stop Time register 16-25 */
#define BBWAKE	_PXAREG(0x41400140) /* MSL Wake-Up register 16-26 */
#define BBITFC	_PXAREG(0x41400144) /* MSL Interface Width register 10-6 */


/******************************************************************************/
/* Keypad Interface */
/******************************************************************************/
#define KPC	_PXAREG(0x41500000) /* Keypad Interface Control register 18-12 */
#define KPDK	_PXAREG(0x41500008) /* Keypad Interface Direct Key register 18-16 */
#define KPREC	_PXAREG(0x41500010) /* Keypad Interface Rotary Encoder Count register 18-17 */
#define KPMK	_PXAREG(0x41500018) /* Keypad Interface Matrix Key register 18-18 */
#define KPAS	_PXAREG(0x41500020) /* Keypad Interface Automatic Scan register 18-18 */
#define KPASMKP0	_PXAREG(0x41500028) /* Keypad Interface Automatic Scan Multiple Keypress register 0 18-20 */
#define KPASMKP1	_PXAREG(0x41500030) /* Keypad Interface Automatic Scan Multiple Keypress register 1 18-20 */
#define KPASMKP2	_PXAREG(0x41500038) /* Keypad Interface Automatic Scan Multiple Keypress register 2 18-20 */
#define KPASMKP3	_PXAREG(0x41500040) /* Keypad Interface Automatic Scan Multiple Keypress register 3 18-20 */
#define KPKDI	_PXAREG(0x41500048) /* Keypad Interface Key Debounce Interval register 18-23 */


/******************************************************************************/
/* Universal Subscriber ID (USIM) Interface */
/******************************************************************************/
#define RBR	_PXAREG(0x41600000) /* USIM Receive Buffer register 19-18 */
#define THR	_PXAREG(0x41600004) /* USIM Transmit Holding register 19-19 */
#define IER	_PXAREG(0x41600008) /* USIM Interrupt Enable register 19-20 */
#define IIR	_PXAREG(0x4160000C) /* USIM Interrupt Identification register 19-22 */
#define FCR	_PXAREG(0x41600010) /* USIM FIFO Control register 19-24 */
#define FSR	_PXAREG(0x41600014) /* USIM FIFO Status register 19-26 */
#define ECR	_PXAREG(0x41600018) /* USIM Error Control register 19-27 */
#define LCR	_PXAREG(0x4160001C) /* USIM Line Control register 19-29 */
#define USCCR	_PXAREG(0x41600020) /* USIM Card Control register 19-31 */
#define LSR	_PXAREG(0x41600024) /* USIM Line Status register 19-32 */
#define EGTR	_PXAREG(0x41600028) /* USIM Extra Guard Time register 19-34 */
#define BGTR	_PXAREG(0x4160002C) /* USIM Block Guard Time register 19-34 */
#define TOR	_PXAREG(0x41600030) /* USIM Time-Out register 19-35 */
#define CLKR	_PXAREG(0x41600034) /* USIM Clock register 19-36 */
#define DLR	_PXAREG(0x41600038) /* USIM Divisor Latch register 19-37 */
#define FLR	_PXAREG(0x4160003C) /* USIM Factor Latch register 19-37 */
#define CWTR	_PXAREG(0x41600040) /* USIM Character Waiting Time register 19-38 */
#define BWTR	_PXAREG(0x41600044) /* USIM Block Waiting Time register 19-39 */


/******************************************************************************/
/* Synchronous Serial Port 2 */
/******************************************************************************/
#define SSCR0_2	_PXAREG(0x41700000) /* SSP2 Control register 0 8-25 */
#define SSCR1_2	_PXAREG(0x41700004) /* SSP 2 Control register 1 8-29 */
#define SSSR_2	_PXAREG(0x41700008) /* SSP 2 Status register 8-43 */
#define SSITR_2	_PXAREG(0x4170000C) /* SSP 2 Interrupt Test register 8-42 */
#define SSDR_2	_PXAREG(0x41700010) /* SSP 2 Data Write register/Data Read register 8-48 */
#define SSTO_2	_PXAREG(0x41700028) /* SSP 2 Time-Out register 8-41 */
#define SSPSP_2	_PXAREG(0x4170002C) /* SSP 2 Programmable Serial Protocol 8-39 */
#define SSTSA_2	_PXAREG(0x41700030) /* SSP2 TX Timeslot Active register 8-48 */
#define SSRSA_2	_PXAREG(0x41700034) /* SSP2 RX Timeslot Active register 8-49 */
#define SSTSS_2	_PXAREG(0x41700038) /* SSP2 Timeslot Status register 8-50 */
#define SSACD_2	_PXAREG(0x4170003C) /* SSP2 Audio Clock Divider register 8-51 */


/******************************************************************************/
/* Memory Stick Host Controller */
/******************************************************************************/
#define MSCMR	_PXAREG(0x41800000) /* MSHC Command register 17-8 */
#define MSCRSR	_PXAREG(0x41800004) /* MSHC Control and Status register 17-9 */
#define MSINT	_PXAREG(0x41800008) /* MSHC Interrupt and Status register 17-10 */
#define MSINTEN	_PXAREG(0x4180000C) /* MSHC Interrupt Enable register 17-11 */
#define MSCR2	_PXAREG(0x41800010) /* MSHC Control register 2 17-12 */
#define MSACD	_PXAREG(0x41800014) /* MSHC ACD Command register 17-13 */
#define MSRXFIFO	_PXAREG(0x41800018) /* MSHC Receive FIFO register 17-14 */
#define MSTXFIFO	_PXAREG(0x4180001C) /* MSHC Transmit FIFO register 17-15 */


/******************************************************************************/
/* Synchronous Serial Port 3 */
/******************************************************************************/
#define SSCR0_3	_PXAREG(0x41900000) /* SSP 3 Control register 0 8-25 */
#define SSCR1_3	_PXAREG(0x41900004) /* SSP 3 Control register 1 8-29 */
#define SSSR_3	_PXAREG(0x41900008) /* SSP 3 Status register 8-43 */
#define SSITR_3	_PXAREG(0x4190000C) /* SSP 3 Interrupt Test register 8-42 */
#define SSDR_3	_PXAREG(0x41900010) /* SSP 3 Data Write register/Data Read register 8-48 */
#define SSTO_3	_PXAREG(0x41900028) /* SSP 3 Time-Out register 8-41 */
#define SSPSP_3	_PXAREG(0x4190002C) /* SSP 3 Programmable Serial Protocol 8-39 */
#define SSTSA_3	_PXAREG(0x41900030) /* SSP TX Timeslot Active register 8-48 */
#define SSRSA_3	_PXAREG(0x41900034) /* SSP RX Timeslot Active register 8-49 */
#define SSTSS_3	_PXAREG(0x41900038) /* SSP Timeslot Status register 8-50 */
#define SSACD_3	_PXAREG(0x4190003C) /* SSP Audio Clock Divider register 8-51 */

#endif /* _PXA27X_REGISTER_H */
