/* ----------------------------------------------------------------------------
 *         ATMEL Microcontroller Software Support 
 * ----------------------------------------------------------------------------
 * Copyright (c) 2008, Atmel Corporation
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
 * ----------------------------------------------------------------------------
 */

/** 
 \unit

 !!!Purpose

    Implementation of USB device functions on a UDP controller.

    See "USBD API Methods".
*/

//------------------------------------------------------------------------------
//      Headers
//------------------------------------------------------------------------------

#include "USBD.h"
#include "USBDCallbacks.h"
#include <board.h>
#include <pio/pio.h>
#include <utility/trace.h>
#include <utility/led.h>
#include <usb/common/core/USBEndpointDescriptor.h>
#include <usb/common/core/USBGenericRequest.h>

#if defined(BOARD_USB_UDP)

//------------------------------------------------------------------------------
//         Definitions
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
/// \page "UDP register field values"
///
/// This page lists the initialize values of UDP registers.
///
/// !Values
/// - UDP_RXDATA

/// Bit mask for both banks of the UDP_CSR register.
#define UDP_RXDATA              (AT91C_UDP_RX_DATA_BK0 | AT91C_UDP_RX_DATA_BK1)
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
/// \page "Endpoint states"
///
/// This page lists the endpoint states.
///
/// !States
//  - UDP_ENDPOINT_DISABLED
//  - UDP_ENDPOINT_HALTED
//  - UDP_ENDPOINT_IDLE
//  - UDP_ENDPOINT_SENDING
//  - UDP_ENDPOINT_RECEIVING

/// Endpoint states: Endpoint is disabled
#define UDP_ENDPOINT_DISABLED       0
/// Endpoint states: Endpoint is halted (i.e. STALLs every request)
#define UDP_ENDPOINT_HALTED         1
/// Endpoint states: Endpoint is idle (i.e. ready for transmission)
#define UDP_ENDPOINT_IDLE           2
/// Endpoint states: Endpoint is sending data
#define UDP_ENDPOINT_SENDING        3
/// Endpoint states: Endpoint is receiving data
#define UDP_ENDPOINT_RECEIVING      4
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
/// \page "UDP_CSR register access"
///
/// This page lists the macroes to access UDP CSR register.
///
/// !Macros
/// - CLEAR_CSR
/// - SET_CSR

/// Bitmap for all status bits in CSR.
#define REG_NO_EFFECT_1_ALL      AT91C_UDP_RX_DATA_BK0 | AT91C_UDP_RX_DATA_BK1 \
                                |AT91C_UDP_STALLSENT   | AT91C_UDP_RXSETUP \
                                |AT91C_UDP_TXCOMP

/// Clears the specified bit(s) in the UDP_CSR register.
/// \param endpoint The endpoint number of the CSR to process.
/// \param flags The bitmap to set to 1.
#define SET_CSR(endpoint, flags) \
    { \
        volatile unsigned int reg; \
        reg = AT91C_BASE_UDP->UDP_CSR[endpoint] ; \
        reg |= REG_NO_EFFECT_1_ALL; \
        reg |= (flags); \
        AT91C_BASE_UDP->UDP_CSR[endpoint] = reg; \
        while ( (AT91C_BASE_UDP->UDP_CSR[endpoint] & (flags)) != (flags)); \
    }

/// Sets the specified bit(s) in the UDP_CSR register.
/// \param endpoint The endpoint number of the CSR to process.
/// \param flags The bitmap to clear to 0.
#define CLEAR_CSR(endpoint, flags) \
    { \
        volatile unsigned int reg; \
        reg = AT91C_BASE_UDP->UDP_CSR[endpoint]; \
        reg |= REG_NO_EFFECT_1_ALL; \
        reg &= ~(flags); \
        AT91C_BASE_UDP->UDP_CSR[endpoint] = reg; \
        while ( (AT91C_BASE_UDP->UDP_CSR[endpoint] & (flags)) == (flags)); \
    }
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//      Types
//------------------------------------------------------------------------------

/// Describes an ongoing transfer on a UDP endpoint.
typedef struct {

    /// Pointer to a data buffer used for emission/reception.
    char             *pData;
    /// Number of bytes which have been written into the UDP internal FIFO
    /// buffers.
    volatile int     buffered;
    /// Number of bytes which have been sent/received.
    volatile int     transferred;
    /// Number of bytes which have not been buffered/transferred yet.
    volatile int     remaining;
    /// Optional callback to invoke when the transfer completes.
    volatile TransferCallback fCallback;
    /// Optional argument to the callback function.
    void             *pArgument;
} Transfer;

//------------------------------------------------------------------------------
/// Describes the state of an endpoint of the UDP controller.
//------------------------------------------------------------------------------
typedef struct {

    /// Current endpoint state.
    volatile unsigned char  state;
    /// Current reception bank (0 or 1).
    volatile unsigned char  bank;
    /// Maximum packet size for the endpoint.
    volatile unsigned short size;
    /// Describes an ongoing transfer (if current state is either
    ///  <UDP_ENDPOINT_SENDING> or <UDP_ENDPOINT_RECEIVING>)
    Transfer       transfer;
} Endpoint;

//------------------------------------------------------------------------------
//         Internal variables
//------------------------------------------------------------------------------

/// Holds the internal state for each endpoint of the UDP.
static Endpoint endpoints[BOARD_USB_NUMENDPOINTS];

/// Device current state.
static unsigned char deviceState;
/// Indicates the previous device state
static unsigned char previousDeviceState;

//------------------------------------------------------------------------------
//      Internal Functions
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
/// Enables the clock of the UDP peripheral.
//------------------------------------------------------------------------------
static inline void UDP_EnablePeripheralClock(void)
{
    AT91C_BASE_PMC->PMC_PCER = 1 << AT91C_ID_UDP;
}

//------------------------------------------------------------------------------
/// Disables the UDP peripheral clock.
//------------------------------------------------------------------------------
static inline void UDP_DisablePeripheralClock(void)
{
    AT91C_BASE_PMC->PMC_PCDR = 1 << AT91C_ID_UDP;
}

//------------------------------------------------------------------------------
/// Enables the 48MHz USB clock.
//------------------------------------------------------------------------------
static inline void UDP_EnableUsbClock(void)
{
    AT91C_BASE_PMC->PMC_SCER = AT91C_PMC_UDP;
}

//------------------------------------------------------------------------------
///  Disables the 48MHz USB clock.
//------------------------------------------------------------------------------
static inline void UDP_DisableUsbClock(void)
{
    AT91C_BASE_PMC->PMC_SCDR = AT91C_PMC_UDP;
}

//------------------------------------------------------------------------------
/// Enables the UDP transceiver.
//------------------------------------------------------------------------------
static inline void UDP_EnableTransceiver(void)
{
    AT91C_BASE_UDP->UDP_TXVC &= ~AT91C_UDP_TXVDIS;
}

//------------------------------------------------------------------------------
/// Disables the UDP transceiver.
//------------------------------------------------------------------------------
static inline void UDP_DisableTransceiver(void)
{
    AT91C_BASE_UDP->UDP_TXVC |= AT91C_UDP_TXVDIS;
}

//------------------------------------------------------------------------------
/// Handles a completed transfer on the given endpoint, invoking the
/// configured callback if any.
/// \param bEndpoint Number of the endpoint for which the transfer has completed.
/// \param bStatus   Status code returned by the transfer operation
//------------------------------------------------------------------------------
static void UDP_EndOfTransfer(unsigned char bEndpoint, char bStatus)
{
    Endpoint *pEndpoint = &(endpoints[bEndpoint]);
    Transfer *pTransfer = &(pEndpoint->transfer);

    // Check that endpoint was sending or receiving data
    if( (pEndpoint->state == UDP_ENDPOINT_RECEIVING)
        || (pEndpoint->state == UDP_ENDPOINT_SENDING)) {

        TRACE_DEBUG_WP("Eo");

        // Endpoint returns in Idle state
        pEndpoint->state = UDP_ENDPOINT_IDLE;

        // Invoke callback is present
        if (pTransfer->fCallback != 0) {

            ((TransferCallback) pTransfer->fCallback)
                (pTransfer->pArgument,
                 bStatus,
                 pTransfer->transferred,
                 pTransfer->remaining + pTransfer->buffered);
        }
        else {
            TRACE_DEBUG_WP("No callBack\n\r");
        }
    }
}

//------------------------------------------------------------------------------
/// Clears the correct reception flag (bank 0 or bank 1) of an endpoint
/// \param bEndpoint Index of endpoint
//------------------------------------------------------------------------------
static void UDP_ClearRxFlag(unsigned char bEndpoint)
{
    Endpoint *pEndpoint = &(endpoints[bEndpoint]);

    // Clear flag and change banks
    if (pEndpoint->bank == 0) {

        CLEAR_CSR(bEndpoint, AT91C_UDP_RX_DATA_BK0);
        // Swap bank if in dual-fifo mode
        if (BOARD_USB_ENDPOINTS_BANKS(bEndpoint) > 1) {

            pEndpoint->bank = 1;
        }
    }
    else {

        CLEAR_CSR(bEndpoint, AT91C_UDP_RX_DATA_BK1);
        pEndpoint->bank = 0;
    }
}

//------------------------------------------------------------------------------
/// Transfers a data payload from the current tranfer buffer to the endpoint
/// FIFO
/// \param bEndpoint Number of the endpoint which is sending data.
//------------------------------------------------------------------------------
static void UDP_WritePayload(unsigned char bEndpoint)
{
    Endpoint *pEndpoint = &(endpoints[bEndpoint]);
    Transfer *pTransfer = &(pEndpoint->transfer);
    signed int size;

    // Get the number of bytes to send
    size = pEndpoint->size;
    if (size > pTransfer->remaining) {

        size = pTransfer->remaining;
    }

    // Update transfer descriptor information
    pTransfer->buffered += size;
    pTransfer->remaining -= size;

    // Write packet in the FIFO buffer
    while (size > 0) {

        AT91C_BASE_UDP->UDP_FDR[bEndpoint] = *(pTransfer->pData);
        pTransfer->pData++;
        size--;
    }
}


//------------------------------------------------------------------------------
/// Transfers a data payload from an endpoint FIFO to the current transfer buffer
/// \param bEndpoint Endpoint number.
/// \param wPacketSize Size of received data packet
//------------------------------------------------------------------------------
static void UDP_ReadPayload(unsigned char bEndpoint, int wPacketSize)
{
    Endpoint *pEndpoint = &(endpoints[bEndpoint]);
    Transfer *pTransfer = &(pEndpoint->transfer);

    // Check that the requested size is not bigger than the remaining transfer
    if (wPacketSize > pTransfer->remaining) {

        pTransfer->buffered += wPacketSize - pTransfer->remaining;
        wPacketSize = pTransfer->remaining;
    }

    // Update transfer descriptor information
    pTransfer->remaining -= wPacketSize;
    pTransfer->transferred += wPacketSize;

    // Retrieve packet
    while (wPacketSize > 0) {

        *(pTransfer->pData) = (char) AT91C_BASE_UDP->UDP_FDR[bEndpoint];
        pTransfer->pData++;
        wPacketSize--;
    }
}

//------------------------------------------------------------------------------
/// Received SETUP packet from endpoint 0 FIFO
/// \param pRequest Generic USB SETUP request sent over Control endpoints
//------------------------------------------------------------------------------
static void UDP_ReadRequest(USBGenericRequest *pRequest)
{
    unsigned char *pData = (unsigned char *)pRequest;
    unsigned int i;

    // Copy packet
    for (i = 0; i < 8; i++) {

        *pData = (unsigned char) AT91C_BASE_UDP->UDP_FDR[0];
        pData++;
    }
}

//------------------------------------------------------------------------------
/// Reset all endpoint transfer descriptors
//------------------------------------------------------------------------------
static void UDP_ResetEndpoints( void )
{
    Endpoint *pEndpoint;
    Transfer *pTransfer;
    unsigned char bEndpoint;

    // Reset the transfer descriptor of every endpoint
    for (bEndpoint = 0; bEndpoint < BOARD_USB_NUMENDPOINTS; bEndpoint++) {

        pEndpoint = &(endpoints[bEndpoint]);
        pTransfer = &(pEndpoint->transfer);

        // Reset endpoint transfer descriptor
        pTransfer->pData = 0;
        pTransfer->transferred = -1;
        pTransfer->buffered = -1;
        pTransfer->remaining = -1;
        pTransfer->fCallback = 0;
        pTransfer->pArgument = 0;

        // Reset endpoint state
        pEndpoint->bank = 0;
        pEndpoint->state = UDP_ENDPOINT_DISABLED;
    }
}

//------------------------------------------------------------------------------
/// Disable all endpoints (except control endpoint 0), aborting current 
/// transfers if necessary
//------------------------------------------------------------------------------
static void UDP_DisableEndpoints( void )

{
    unsigned char bEndpoint;

    // Disable each endpoint, terminating any pending transfer
    // Control endpoint 0 is not disabled
    for (bEndpoint = 1; bEndpoint < BOARD_USB_NUMENDPOINTS; bEndpoint++) {

        UDP_EndOfTransfer(bEndpoint, USBD_STATUS_ABORTED);
        endpoints[bEndpoint].state = UDP_ENDPOINT_DISABLED;
    }
}

//------------------------------------------------------------------------------
/// Checks if an ongoing transfer on an endpoint has been completed.
/// \param bEndpoint Endpoint number.
/// \return 1 if the current transfer on the given endpoint is complete;
///         otherwise 0.
//------------------------------------------------------------------------------
static unsigned char UDP_IsTransferFinished(unsigned char bEndpoint)
{
    Endpoint *pEndpoint = &(endpoints[bEndpoint]);
    Transfer *pTransfer = &(pEndpoint->transfer);

    // Check if it is a Control endpoint
    //  -> Control endpoint must always finish their transfer with a zero-length
    //     packet
    if ((AT91C_BASE_UDP->UDP_CSR[bEndpoint] & AT91C_UDP_EPTYPE)
        == AT91C_UDP_EPTYPE_CTRL) {

        return (pTransfer->buffered < pEndpoint->size);
    }
    // Other endpoints only need to transfer all the data
    else {

        return (pTransfer->buffered <= pEndpoint->size)
               && (pTransfer->remaining == 0);
    }
}

//------------------------------------------------------------------------------
/// Endpoint interrupt handler.
/// Handle IN/OUT transfers, received SETUP packets and STALLing
/// \param bEndpoint Index of endpoint
//------------------------------------------------------------------------------
static void UDP_EndpointHandler(unsigned char bEndpoint)
{
    Endpoint *pEndpoint = &(endpoints[bEndpoint]);
    Transfer *pTransfer = &(pEndpoint->transfer);
    unsigned int status = AT91C_BASE_UDP->UDP_CSR[bEndpoint];
    unsigned short wPacketSize;
    USBGenericRequest request;

    TRACE_DEBUG_WP("E%d ", bEndpoint);
    TRACE_DEBUG_WP("st:0x%X ", status);

    // Handle interrupts
    // IN packet sent
    if ((status & AT91C_UDP_TXCOMP) != 0) {

        TRACE_DEBUG_WP("Wr ");

        // Check that endpoint was in Sending state
        if (pEndpoint->state == UDP_ENDPOINT_SENDING) {

            // End of transfer ?
            if (UDP_IsTransferFinished(bEndpoint)) {

                pTransfer->transferred += pTransfer->buffered;
                pTransfer->buffered = 0;

                // Disable interrupt if this is not a control endpoint
                if ((status & AT91C_UDP_EPTYPE) != AT91C_UDP_EPTYPE_CTRL) {

                    AT91C_BASE_UDP->UDP_IDR = 1 << bEndpoint;
                }

                UDP_EndOfTransfer(bEndpoint, USBD_STATUS_SUCCESS);
                CLEAR_CSR(bEndpoint, AT91C_UDP_TXCOMP);
            }
            else {

                // Transfer remaining data
                TRACE_DEBUG_WP(" %d ", pEndpoint->size);

                pTransfer->transferred += pEndpoint->size;
                pTransfer->buffered -= pEndpoint->size;

                // Send next packet
                if (BOARD_USB_ENDPOINTS_BANKS(bEndpoint) == 1) {

                    // No double buffering
                    UDP_WritePayload(bEndpoint);
                    SET_CSR(bEndpoint, AT91C_UDP_TXPKTRDY);
                    CLEAR_CSR(bEndpoint, AT91C_UDP_TXCOMP);
                }
                else {
                    // Double buffering
                    SET_CSR(bEndpoint, AT91C_UDP_TXPKTRDY);
                    CLEAR_CSR(bEndpoint, AT91C_UDP_TXCOMP);
                    UDP_WritePayload(bEndpoint);
                }
            }
        }
        else {
            // Acknowledge interrupt
            TRACE_ERROR("Error Wr");
            CLEAR_CSR(bEndpoint, AT91C_UDP_TXCOMP);
        }
    }

    // OUT packet received
    if ((status & UDP_RXDATA) != 0) {

        TRACE_DEBUG_WP("Rd ");

        // Check that the endpoint is in Receiving state
        if (pEndpoint->state != UDP_ENDPOINT_RECEIVING) {

            // Check if an ACK has been received on a Control endpoint
            if (((status & AT91C_UDP_EPTYPE) == AT91C_UDP_EPTYPE_CTRL)
                && ((status & AT91C_UDP_RXBYTECNT) == 0)) {

                // Acknowledge the data and finish the current transfer
                UDP_ClearRxFlag(bEndpoint);
                UDP_EndOfTransfer(bEndpoint, USBD_STATUS_SUCCESS);
            }
            // Check if the data has been STALLed
            else if ((status & AT91C_UDP_FORCESTALL) != 0) {

                // Discard STALLed data
                TRACE_DEBUG_WP("Discard ");
                UDP_ClearRxFlag(bEndpoint);
            }
            // NAK the data
            else {

                TRACE_DEBUG_WP("Nak ");
                AT91C_BASE_UDP->UDP_IDR = 1 << bEndpoint;
            }
        }
        // Endpoint is in Read state
        else {

            // Retrieve data and store it into the current transfer buffer
            wPacketSize = (unsigned short) (status >> 16);
            TRACE_DEBUG_WP("%d ", wPacketSize);
            UDP_ReadPayload(bEndpoint, wPacketSize);
            UDP_ClearRxFlag(bEndpoint);

            // Check if the transfer is finished
            if ((pTransfer->remaining == 0) || (wPacketSize < pEndpoint->size)) {

                // Disable interrupt if this is not a control endpoint
                if ((status & AT91C_UDP_EPTYPE) != AT91C_UDP_EPTYPE_CTRL) {

                    AT91C_BASE_UDP->UDP_IDR = 1 << bEndpoint;
                }
                UDP_EndOfTransfer(bEndpoint, USBD_STATUS_SUCCESS);
            }
        }
    }

    // STALL sent
    if ((status & AT91C_UDP_STALLSENT) != 0) {

        TRACE_WARNING( "Sta 0x%X [%d] ", status, bEndpoint);

        // If the endpoint is not halted, clear the STALL condition
        CLEAR_CSR(bEndpoint, AT91C_UDP_STALLSENT);
        if (pEndpoint->state != UDP_ENDPOINT_HALTED) {

            TRACE_WARNING( "_ " );
            CLEAR_CSR(bEndpoint, AT91C_UDP_FORCESTALL);
        }
    }

    // SETUP packet received
    if ((status & AT91C_UDP_RXSETUP) != 0) {

        TRACE_DEBUG_WP("Stp ");

        // If a transfer was pending, complete it
        // Handles the case where during the status phase of a control write
        // transfer, the host receives the device ZLP and ack it, but the ack
        // is not received by the device
        if ((pEndpoint->state == UDP_ENDPOINT_RECEIVING)
            || (pEndpoint->state == UDP_ENDPOINT_SENDING)) {

            UDP_EndOfTransfer(bEndpoint, USBD_STATUS_SUCCESS);
        }
        // Copy the setup packet
        UDP_ReadRequest(&request);

        // Set the DIR bit before clearing RXSETUP in Control IN sequence
        if (USBGenericRequest_GetDirection(&request) == USBGenericRequest_IN) {

            SET_CSR(bEndpoint, AT91C_UDP_DIR);
        }
        // Acknowledge setup packet
        CLEAR_CSR(bEndpoint, AT91C_UDP_RXSETUP);

        // Forward the request to the upper layer
        USBDCallbacks_RequestReceived(&request);
    }

}

//------------------------------------------------------------------------------
//      Exported functions
//------------------------------------------------------------------------------
//------------------------------------------------------------------------------
/// USB interrupt handler
/// Manages device resume, suspend, end of bus reset. 
/// Forwards endpoint interrupts to the appropriate handler.
//------------------------------------------------------------------------------
void RealUdphsIrqHandler() @spontaneous()
{
    unsigned int status;
    int eptnum = 0;
    
    // Get interrupt status
    // Some interrupts may get masked depending on the device state
    status = AT91C_BASE_UDP->UDP_ISR;
    status &= AT91C_BASE_UDP->UDP_IMR;

    if (deviceState < USBD_STATE_POWERED) {

        status &= AT91C_UDP_WAKEUP | AT91C_UDP_RXRSM;
        AT91C_BASE_UDP->UDP_ICR = ~status;
    }

    // Return immediately if there is no interrupt to service
    if (status == 0) {

        return;
    }

    // Toggle USB LED if the device is active
    if (deviceState >= USBD_STATE_POWERED) {

        //LED_Set(USBD_LEDUSB);
        //TOSH_SET_GREEN_LED_PIN();
    }

    // Service interrupts

    //// Start Of Frame (SOF)
    //if (ISSET(dStatus, AT91C_UDP_SOFINT)) {
    //
    //    TRACE_DEBUG("SOF");
    //
    //    // Invoke the SOF callback
    //    USB_StartOfFrameCallback(pUsb);
    //
    //    // Acknowledge interrupt
    //    AT91C_BASE_UDP->UDP_ICR = AT91C_UDP_SOFINT;
    //    dStatus &= ~AT91C_UDP_SOFINT;
    //}

    // Suspend
    // This interrupt is always treated last (hence the '==')
    if (status == AT91C_UDP_RXSUSP) {

        TRACE_INFO_WP("Susp ");

        // Don't do anything if the device is already suspended
        if (deviceState != USBD_STATE_SUSPENDED) {

            // The device enters the Suspended state
            // Enable wakeup
            AT91C_BASE_UDP->UDP_IER = AT91C_UDP_WAKEUP | AT91C_UDP_RXRSM;

            // Acknowledge interrupt
            AT91C_BASE_UDP->UDP_ICR = AT91C_UDP_RXSUSP;

            // Switch to the Suspended state
            previousDeviceState = deviceState;
            deviceState = USBD_STATE_SUSPENDED;
            // Invoke the Suspended callback
            USBDCallbacks_Suspended();
            UDP_DisableTransceiver();
            UDP_DisablePeripheralClock();
            UDP_DisableUsbClock();
        }
    }
    // Resume
    else if ((status & (AT91C_UDP_WAKEUP | AT91C_UDP_RXRSM)) != 0) {

        TRACE_INFO_WP("Res ");

        // Don't do anything if the device was not suspended
        if (deviceState == USBD_STATE_SUSPENDED) {

            // The device enters its previous state
            UDP_EnablePeripheralClock();
            UDP_EnableUsbClock();

            // Enable the transceiver if the device was past the Default
            // state
            deviceState = previousDeviceState;
            if (deviceState >= USBD_STATE_DEFAULT) {

                UDP_EnableTransceiver();

                // Invoke the Resume callback
                USBDCallbacks_Resumed();
            }
        }
        
        // Clear and disable resume interrupts
        AT91C_BASE_UDP->UDP_ICR = AT91C_UDP_WAKEUP 
                                  | AT91C_UDP_RXRSM
                                  | AT91C_UDP_RXSUSP;
        AT91C_BASE_UDP->UDP_IDR = AT91C_UDP_WAKEUP | AT91C_UDP_RXRSM;
    }
    // End of bus reset
    else if ((status & AT91C_UDP_ENDBUSRES) != 0) {

        TRACE_INFO_WP("EoBRes ");

        // The device enters the Default state
        deviceState = USBD_STATE_DEFAULT;
        UDP_EnableTransceiver();
        UDP_ResetEndpoints();
        UDP_DisableEndpoints();
        USBD_ConfigureEndpoint(0);

        // Flush and enable the Suspend interrupt
        AT91C_BASE_UDP->UDP_ICR = AT91C_UDP_WAKEUP
                                  | AT91C_UDP_RXRSM
                                  | AT91C_UDP_RXSUSP;
        AT91C_BASE_UDP->UDP_IER = AT91C_UDP_RXSUSP;

        //// Enable the Start Of Frame (SOF) interrupt if needed
        //if (pUsb->pCallbacks->startOfFrame != 0) {
        //
        //    AT91C_BASE_UDP->UDP_IER = AT91C_UDP_SOFINT;
        //}

        // Invoke the Reset callback
        USBDCallbacks_Reset();

        // Acknowledge end of bus reset interrupt
        AT91C_BASE_UDP->UDP_ICR = AT91C_UDP_ENDBUSRES;
    }
    // Endpoint interrupts
    else {

        while (status != 0) {

            // Check if endpoint has a pending interrupt
            if ((status & (1 << eptnum)) != 0) {
            
                UDP_EndpointHandler(eptnum);
                status &= ~(1 << eptnum);
                
                if (status != 0) {
                
                    TRACE_INFO_WP("\n\r  - ");
                }
            }
            eptnum++;
        }
    }

    // Toggle LED back to its previous state
    TRACE_INFO_WP("\n\r");
    if (deviceState >= USBD_STATE_POWERED) {

        //LED_Clear(USBD_LEDUSB);
        //TOSH_CLR_GREEN_LED_PIN();
    }
}
void UdphsIrqHandler(void) @C() @spontaneous()
{
    call UdphsInterruptWrapper.preamble();
    RealUdphsIrqHandler();
    call UdphsInterruptWrapper.postamble();
}

//------------------------------------------------------------------------------
/// Configures an endpoint according to its Endpoint Descriptor.
/// \param pDescriptor Pointer to an Endpoint descriptor.
//------------------------------------------------------------------------------
void USBD_ConfigureEndpoint(const USBEndpointDescriptor *pDescriptor)
{
    Endpoint *pEndpoint;
    unsigned char bEndpoint;
    unsigned char bType;
    unsigned char bEndpointDir;

    // NULL descriptor -> Control endpoint 0
    if (pDescriptor == 0) {

        bEndpoint = 0;
        pEndpoint = &(endpoints[bEndpoint]);
        bType= USBEndpointDescriptor_CONTROL;
        bEndpointDir = 0;
        pEndpoint->size = BOARD_USB_ENDPOINTS_MAXPACKETSIZE(0);
    }
    else {

        bEndpoint = USBEndpointDescriptor_GetNumber(pDescriptor);
        pEndpoint = &(endpoints[bEndpoint]);
        bType = USBEndpointDescriptor_GetType(pDescriptor);
        bEndpointDir = USBEndpointDescriptor_GetDirection(pDescriptor);
        pEndpoint->size = USBEndpointDescriptor_GetMaxPacketSize(pDescriptor);
    }

    // Abort the current transfer is the endpoint was configured and in
    // Write or Read state
    if ((pEndpoint->state == UDP_ENDPOINT_RECEIVING)
        || (pEndpoint->state == UDP_ENDPOINT_SENDING)) {

        UDP_EndOfTransfer(bEndpoint, USBD_STATUS_RESET);
    }
    pEndpoint->state = UDP_ENDPOINT_IDLE;

    // Reset Endpoint Fifos
    AT91C_BASE_UDP->UDP_RSTEP |= (1 << bEndpoint);
    AT91C_BASE_UDP->UDP_RSTEP &= ~(1 << bEndpoint);

    // Configure endpoint
    if (bType != USBEndpointDescriptor_CONTROL) {

        SET_CSR(bEndpoint, (unsigned int)AT91C_UDP_EPEDS
                            | (bType << 8) | (bEndpointDir << 10));
    }
    else {

        SET_CSR(bEndpoint, (bType << 8) | (bEndpointDir << 10));
        AT91C_BASE_UDP->UDP_IER = (1 << bEndpoint);
    }

    TRACE_INFO_WP("CfgEpt%d ", bEndpoint);
}

//------------------------------------------------------------------------------
/// Sends data through a USB endpoint. Sets up the transfer descriptor,
/// writes one or two data payloads (depending on the number of FIFO bank
/// for the endpoint) and then starts the actual transfer. The operation is
/// complete when all the data has been sent.
///
/// *If the size of the buffer is greater than the size of the endpoint
///  (or twice the size if the endpoint has two FIFO banks), then the buffer
///  must be kept allocated until the transfer is finished*. This means that
///  it is not possible to declare it on the stack (i.e. as a local variable
///  of a function which returns after starting a transfer).
///
/// \param bEndpoint Endpoint number.
/// \param pData Pointer to a buffer with the data to send.
/// \param dLength Size of the data buffer.
/// \param fCallback Optional callback function to invoke when the transfer is
///        complete.
/// \param pArgument Optional argument to the callback function.
/// \return USBD_STATUS_SUCCESS if the transfer has been started;
///         otherwise, the corresponding error status code.
//------------------------------------------------------------------------------
char USBD_Write( unsigned char    bEndpoint,
                 const void       *pData,
                 unsigned int     dLength,
                 TransferCallback fCallback,
                 void             *pArgument )
{
    Endpoint *pEndpoint = &(endpoints[bEndpoint]);
    Transfer *pTransfer = &(pEndpoint->transfer);

    // Check that the endpoint is in Idle state
    if (pEndpoint->state != UDP_ENDPOINT_IDLE) {

        return USBD_STATUS_LOCKED;
    }
    TRACE_DEBUG_WP("Write%d(%d) ", bEndpoint, dLength);

    // Setup the transfer descriptor
    pTransfer->pData = (void *) pData;
    pTransfer->remaining = dLength;
    pTransfer->buffered = 0;
    pTransfer->transferred = 0;
    pTransfer->fCallback = fCallback;
    pTransfer->pArgument = pArgument;

    // Send the first packet
    pEndpoint->state = UDP_ENDPOINT_SENDING;
    while((AT91C_BASE_UDP->UDP_CSR[bEndpoint]&AT91C_UDP_TXPKTRDY)==AT91C_UDP_TXPKTRDY);
    UDP_WritePayload(bEndpoint);
    SET_CSR(bEndpoint, AT91C_UDP_TXPKTRDY);

    // If double buffering is enabled and there is data remaining,
    // prepare another packet
    if ((BOARD_USB_ENDPOINTS_BANKS(bEndpoint) > 1) && (pTransfer->remaining > 0)) {

        UDP_WritePayload(bEndpoint);
    }

    // Enable interrupt on endpoint
    AT91C_BASE_UDP->UDP_IER = 1 << bEndpoint;

    return USBD_STATUS_SUCCESS;
}


//------------------------------------------------------------------------------
/// Reads incoming data on an USB endpoint This methods sets the transfer
/// descriptor and activate the endpoint interrupt. The actual transfer is
/// then carried out by the endpoint interrupt handler. The Read operation
/// finishes either when the buffer is full, or a short packet (inferior to
/// endpoint maximum  size) is received.
///
/// *The buffer must be kept allocated until the transfer is finished*.
/// \param bEndpoint Endpoint number.
/// \param pData Pointer to a data buffer.
/// \param dLength Size of the data buffer in bytes.
/// \param fCallback Optional end-of-transfer callback function.
/// \param pArgument Optional argument to the callback function.
/// \return USBD_STATUS_SUCCESS if the read operation has been started;
///         otherwise, the corresponding error code.
//------------------------------------------------------------------------------
char USBD_Read(unsigned char    bEndpoint,
               void             *pData,
               unsigned int     dLength,
               TransferCallback fCallback,
               void             *pArgument)
{
    Endpoint *pEndpoint = &(endpoints[bEndpoint]);
    Transfer *pTransfer = &(pEndpoint->transfer);

    // Return if the endpoint is not in IDLE state
    if (pEndpoint->state != UDP_ENDPOINT_IDLE) {

        return USBD_STATUS_LOCKED;
    }

    // Endpoint enters Receiving state
    pEndpoint->state = UDP_ENDPOINT_RECEIVING;
    TRACE_DEBUG_WP("Read%d(%d) ", bEndpoint, dLength);

    // Set the transfer descriptor
    pTransfer->pData = pData;
    pTransfer->remaining = dLength;
    pTransfer->buffered = 0;
    pTransfer->transferred = 0;
    pTransfer->fCallback = fCallback;
    pTransfer->pArgument = pArgument;

    // Enable interrupt on endpoint
    AT91C_BASE_UDP->UDP_IER = 1 << bEndpoint;

    return USBD_STATUS_SUCCESS;
}

//------------------------------------------------------------------------------
/// Sets the HALT feature on the given endpoint (if not already in this state).
/// \param bEndpoint Endpoint number.
//------------------------------------------------------------------------------
void USBD_Halt(unsigned char bEndpoint)
{
    Endpoint *pEndpoint = &(endpoints[bEndpoint]);
    
    // Check that endpoint is enabled and not already in Halt state
    if ((pEndpoint->state != UDP_ENDPOINT_DISABLED)
        && (pEndpoint->state != UDP_ENDPOINT_HALTED)) {

        TRACE_DEBUG_WP("Halt%d ", bEndpoint);

        // Abort the current transfer if necessary
        UDP_EndOfTransfer(bEndpoint, USBD_STATUS_ABORTED);

        // Put endpoint into Halt state
        SET_CSR(bEndpoint, AT91C_UDP_FORCESTALL);
        pEndpoint->state = UDP_ENDPOINT_HALTED;

        // Enable the endpoint interrupt
        AT91C_BASE_UDP->UDP_IER = 1 << bEndpoint;
    }
}

//------------------------------------------------------------------------------
/// Clears the Halt feature on the given endpoint.
/// \param bEndpoint Index of endpoint
//------------------------------------------------------------------------------
void USBD_Unhalt(unsigned char bEndpoint)
{
    Endpoint *pEndpoint = &(endpoints[bEndpoint]);

    // Check if the endpoint is enabled
    if (pEndpoint->state != UDP_ENDPOINT_DISABLED) {

        TRACE_DEBUG_WP("Unhalt%d ", bEndpoint);

        // Return endpoint to Idle state
        pEndpoint->state = UDP_ENDPOINT_IDLE;

        // Clear FORCESTALL flag
        CLEAR_CSR(bEndpoint, AT91C_UDP_FORCESTALL);

        // Reset Endpoint Fifos, beware this is a 2 steps operation
        AT91C_BASE_UDP->UDP_RSTEP |= 1 << bEndpoint;
        AT91C_BASE_UDP->UDP_RSTEP &= ~(1 << bEndpoint);
    }
}
    
//------------------------------------------------------------------------------
/// Returns the current Halt status of an endpoint.
/// \param bEndpoint Index of endpoint
/// \return 1 if the endpoint is currently halted; otherwise 0
//------------------------------------------------------------------------------
unsigned char USBD_IsHalted(unsigned char bEndpoint)
{
    Endpoint *pEndpoint = &(endpoints[bEndpoint]);
    unsigned char status = 0;

    if (pEndpoint->state == UDP_ENDPOINT_HALTED) {

        status = 1;
    }
    return( status );
}

//------------------------------------------------------------------------------
/// Indicates if the device is running in high or full-speed. Always returns 0
/// since UDP does not support high-speed mode.
//------------------------------------------------------------------------------
unsigned char USBD_IsHighSpeed(void)
{
    return 0;
}

//------------------------------------------------------------------------------
/// Causes the given endpoint to acknowledge the next packet it receives
/// with a STALL handshake.
/// \param bEndpoint Endpoint number.
/// \return USBD_STATUS_SUCCESS or USBD_STATUS_LOCKED.
//------------------------------------------------------------------------------
unsigned char USBD_Stall(unsigned char bEndpoint)

{
    Endpoint *pEndpoint = &(endpoints[bEndpoint]);

    // Check that endpoint is in Idle state
    if (pEndpoint->state != UDP_ENDPOINT_IDLE) {

        TRACE_WARNING("UDP_Stall: Endpoint%d locked\n\r", bEndpoint);
        return USBD_STATUS_LOCKED;
    }

    TRACE_DEBUG_WP("Stall%d ", bEndpoint);
    SET_CSR(bEndpoint, AT91C_UDP_FORCESTALL);

    return USBD_STATUS_SUCCESS;
}

//------------------------------------------------------------------------------
/// Starts a remote wake-up procedure.
//------------------------------------------------------------------------------
void USBD_RemoteWakeUp(void)
{
    UDP_EnablePeripheralClock();
    UDP_EnableUsbClock();
    UDP_EnableTransceiver();

    TRACE_INFO_WP("RWUp ");

    // Activates a remote wakeup (edge on ESR), then clear ESR
    AT91C_BASE_UDP->UDP_GLBSTATE |= AT91C_UDP_ESR;
    AT91C_BASE_UDP->UDP_GLBSTATE &= ~AT91C_UDP_ESR;
}

//------------------------------------------------------------------------------
/// Sets the device address to the given value.
/// \param address New device address.
//------------------------------------------------------------------------------
void USBD_SetAddress(unsigned char address)
{
    TRACE_INFO_WP("SetAddr(%d) ", address);

    // Set address
    AT91C_BASE_UDP->UDP_FADDR = AT91C_UDP_FEN | address;

    // If the address is 0, the device returns to the Default state
    if (address == 0) {

        AT91C_BASE_UDP->UDP_GLBSTATE = 0;
        deviceState = USBD_STATE_DEFAULT;
    }
    // If the address is non-zero, the device enters the Address state
    else {

        AT91C_BASE_UDP->UDP_GLBSTATE = AT91C_UDP_FADDEN;
        deviceState = USBD_STATE_ADDRESS;
    }
}

//------------------------------------------------------------------------------
/// Sets the current device configuration.
/// \param cfgnum - Configuration number to set.
//------------------------------------------------------------------------------
void USBD_SetConfiguration(unsigned char cfgnum)
{
    TRACE_INFO_WP("SetCfg(%d) ", cfgnum);

    // If the configuration number if non-zero, the device enters the
    // Configured state
    if (cfgnum != 0) {

        // Enter Configured state
        deviceState = USBD_STATE_CONFIGURED;
        AT91C_BASE_UDP->UDP_GLBSTATE |= AT91C_UDP_CONFG;
    }
    // If the configuration number is zero, the device goes back to the Address
    // state
    else {

        deviceState = USBD_STATE_ADDRESS;
        AT91C_BASE_UDP->UDP_GLBSTATE = AT91C_UDP_FADDEN;

        // Abort all transfers
        UDP_DisableEndpoints();
    }
}

//------------------------------------------------------------------------------
/// Connects the pull-up on the D+ line of the USB.
//------------------------------------------------------------------------------
void USBD_Connect(void)
{
    TRACE_DEBUG("Conn ");

#if defined(BOARD_USB_PULLUP_EXTERNAL)
    const Pin pinPullUp = PIN_USB_PULLUP;
    if (pinPullUp.attribute == PIO_OUTPUT_0) {

        PIO_Set(&pinPullUp);
    }
    else {

        PIO_Clear(&pinPullUp);
    }
#elif defined(BOARD_USB_PULLUP_INTERNAL)
    AT91C_BASE_UDP->UDP_TXVC |= AT91C_UDP_PUON;
#elif defined(BOARD_USB_PULLUP_MATRIX)
    AT91C_BASE_MATRIX->MATRIX_USBPCR |= AT91C_MATRIX_USBPCR_PUON;
#elif !defined(BOARD_USB_PULLUP_ALWAYSON)
    #error Unsupported pull-up type.
#endif
}

//------------------------------------------------------------------------------
/// Disconnects the pull-up from the D+ line of the USB.
//------------------------------------------------------------------------------
void USBD_Disconnect(void)
{
    TRACE_DEBUG("Disc ");

#if defined(BOARD_USB_PULLUP_EXTERNAL)
    const Pin pinPullUp = PIN_USB_PULLUP;
    if (pinPullUp.attribute == PIO_OUTPUT_0) {

        PIO_Clear(&pinPullUp);
    }
    else {

        PIO_Set(&pinPullUp);
    }
#elif defined(BOARD_USB_PULLUP_INTERNAL)
    AT91C_BASE_UDP->UDP_TXVC &= ~AT91C_UDP_PUON;
#elif defined(BOARD_USB_PULLUP_MATRIX)
    AT91C_BASE_MATRIX->MATRIX_USBPCR &= ~AT91C_MATRIX_USBPCR_PUON;
#elif !defined(BOARD_USB_PULLUP_ALWAYSON)
    #error Unsupported pull-up type.
#endif

    // Device returns to the Powered state
    if (deviceState > USBD_STATE_POWERED) {
    
        deviceState = USBD_STATE_POWERED;
    }

    if (previousDeviceState > USBD_STATE_POWERED) {

        previousDeviceState = USBD_STATE_POWERED;
    }
}

//------------------------------------------------------------------------------
/// Initializes the USB driver.
//------------------------------------------------------------------------------
void USBD_Init(void)
{
    TRACE_INFO_WP("USBD_Init\n\r");

    // Reset endpoint structures
    UDP_ResetEndpoints();

    // Configure the pull-up on D+ and disconnect it
#if defined(BOARD_USB_PULLUP_EXTERNAL)
    const Pin pinPullUp = PIN_USB_PULLUP;
    PIO_Configure(&pinPullUp, 1);
#elif defined(BOARD_USB_PULLUP_INTERNAL)
    AT91C_BASE_UDP->UDP_TXVC &= ~AT91C_UDP_PUON;
#elif defined(BOARD_USB_PULLUP_MATRIX)
    AT91C_BASE_MATRIX->MATRIX_USBPCR &= ~AT91C_MATRIX_USBPCR_PUON;
#elif !defined(BOARD_USB_PULLUP_ALWAYSON)
    #error Missing pull-up definition.
#endif

    // Device is in the Attached state
    deviceState = USBD_STATE_SUSPENDED;
    previousDeviceState = USBD_STATE_POWERED;
    UDP_EnablePeripheralClock();
    UDP_EnableUsbClock();

    AT91C_BASE_UDP->UDP_IDR = 0xFE;

    AT91C_BASE_UDP->UDP_IER = AT91C_UDP_WAKEUP;

    // Configure interrupts
    USBDCallbacks_Initialized();
}

//------------------------------------------------------------------------------
/// Configure USB Speed, should be invoked before USB attachment.
/// \param forceFS Force to use FS mode.
//------------------------------------------------------------------------------
void USBD_ConfigureSpeed(unsigned char forceFS)
{
}

//------------------------------------------------------------------------------
/// Returns the current state of the USB device.
/// \return Device current state.
//------------------------------------------------------------------------------
unsigned char USBD_GetState(void)
{
    return deviceState;
}

#endif // BOARD_USB_UDP
