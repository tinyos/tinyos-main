/*
 * Copyright (c) 2010 Johns Hopkins University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef HPLNANDFLASH_H
#define HPLNANDFLASH_H

/// \page "NandFlashModel options"
/// This page lists the possible options for a NandFlash chip.
/// 
/// !Options
/// - NandFlashModel_DATABUS8
/// - NandFlashModel_DATABUS16
/// - NandFlashModel_COPYBACK

/// Indicates the Nand uses an 8-bit databus.
#define NandFlashModel_DATABUS8     (0 << 0)

/// Indicates the Nand uses a 16-bit databus.
#define NandFlashModel_DATABUS16    (1 << 0)

/// The Nand supports the copy-back function (internal page-to-page copy).
#define NandFlashModel_COPYBACK     (1 << 1)

//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//         Types
//------------------------------------------------------------------------------

/// Maximum number of blocks in a device
#define NandCommon_MAXNUMBLOCKS             1024//2048

/// Maximum number of pages in one block
#define NandCommon_MAXNUMPAGESPERBLOCK      64

/// Maximum size of the data area of one page, in bytes.
#define NandCommon_MAXPAGEDATASIZE          2048

/// Maximum size of the spare area of one page, in bytes.
#define NandCommon_MAXPAGESPARESIZE         64

/// Maximum number of ecc bytes stored in the spare for one single page.
#define NandCommon_MAXSPAREECCBYTES         24

/// Maximum number of extra free bytes inside the spare area of a page.
#define NandCommon_MAXSPAREEXTRABYTES       38


struct NandSpareScheme {

    uint8_t badBlockMarkerPosition;
    uint8_t numEccBytes;
    uint8_t eccBytesPositions[NandCommon_MAXSPAREECCBYTES];
    uint8_t numExtraBytes;
    uint8_t extraBytesPositions[NandCommon_MAXSPAREEXTRABYTES];
};

//------------------------------------------------------------------------------
/// Describes a particular model of NandFlash device.
//------------------------------------------------------------------------------
struct NandFlashModel {

    /// Identifier for the device.
    uint8_t deviceId;
    /// Special options for the NandFlash.
    uint8_t options;
    /// Size of the data area of a page, in bytes.
    uint16_t pageSizeInBytes;
    /// Size of the device in MB.
    uint16_t deviceSizeInMegaBytes;
    /// Size of one block in kilobytes.
    uint16_t blockSizeInKBytes;
    /// Spare area placement scheme
    const struct NandSpareScheme *scheme;
};


struct RawNandFlash {

    /// Model describing this NandFlash characteristics.
    struct NandFlashModel model;
    /// Address for sending commands to the NandFlash.
    uint32_t commandAddress;
    /// Address for sending addresses to the NandFlash
    uint32_t addressAddress;
    /// Address for sending data to the NandFlash.
    uint32_t dataAddress;
    /// Pin used to enable the NandFlash chip.
  //Pin pinChipEnable;
    /// Pin used to monitor the ready/busy signal from the NandFlash.
    //Pin pinReadyBusy;
};


/// No more blocks can be allocated for a write operation.
#define NandCommon_ERROR_NOMOREBLOCKS       1

/// The desired logical block has no current physical mapping.
#define NandCommon_ERROR_BLOCKNOTMAPPED     2

/// Access if out-of-bounds.
#define NandCommon_ERROR_OUTOFBOUNDS        3

/// There are no block having the desired property.
#define NandCommon_ERROR_NOBLOCKFOUND       4

/// The nandflash device has no logical mapping information on it.
#define NandCommon_ERROR_MAPPINGNOTFOUND    5

/// A read operation cannot be carried out.
#define NandCommon_ERROR_CANNOTREAD         6

/// A write operation cannot be carried out.
#define NandCommon_ERROR_CANNOTWRITE        7

/// NandFlash chip model cannot be recognized.
#define NandCommon_ERROR_UNKNOWNMODEL       8

/// Page data is corrupted according to ECC
#define NandCommon_ERROR_CORRUPTEDDATA      9

/// Block is not in the required status.
#define NandCommon_ERROR_WRONGSTATUS        10

/// Device has no logical mapping stored in it
#define NandCommon_ERROR_NOMAPPING          11

/// The block being accessed is bad and must be replaced
#define NandCommon_ERROR_BADBLOCK           12

/// Failed to perform an erase operation
#define NandCommon_ERROR_CANNOTERASE        13

/// A hardware copyback operation failed.
#define NandCommon_ERROR_CANNOTCOPY         14

/// HW Ecc Not compatible with the Nand Model
#define NandCommon_ERROR_ECC_NOT_COMPATIBLE 15

// -------- HSMC4_CFG : (HSMC4 Offset: 0x0) Configuration Register -------- 
#define AT91C_HSMC4_PAGESIZE  (0x3 <<  0) // (HSMC4) PAGESIZE field description
#define         AT91C_HSMC4_PAGESIZE_528_Bytes            (0x0) // (HSMC4) 512 bytes plus 16 bytes page size
#define         AT91C_HSMC4_PAGESIZE_1056_Bytes           (0x1) // (HSMC4) 1024 bytes plus 32 bytes page size
#define         AT91C_HSMC4_PAGESIZE_2112_Bytes           (0x2) // (HSMC4) 2048 bytes plus 64 bytes page size
#define         AT91C_HSMC4_PAGESIZE_4224_Bytes           (0x3) // (HSMC4) 4096 bytes plus 128 bytes page size

/// Address for transferring command bytes to the nandflash.
#define BOARD_NF_COMMAND_ADDR   0x61400000
/// Address for transferring address bytes to the nandflash.
#define BOARD_NF_ADDRESS_ADDR   0x61200000
/// Address for transferring data bytes to the nandflash.
#define BOARD_NF_DATA_ADDR      0x61000000


#endif // HPLNANDFLASH_H
