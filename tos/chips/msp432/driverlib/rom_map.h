/*
 * -------------------------------------------
 *    MSP432 DriverLib - v3_21_00_05
 * Modified.
 * -------------------------------------------
 *
 * --COPYRIGHT--,BSD,BSD
 * Copyright (c) 2016, Texas Instruments Incorporated
 * Copyright (c) 2016, Eric B. Decker
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * *  Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * *  Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * *  Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 * EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * --/COPYRIGHT--*/

#ifndef __ROM_MAP_H__
#define __ROM_MAP_H__

#ifdef __MSP432_DVRLIB_ROM__
#define ROM_MAP(x) ROM_ ## x
#else
#define ROM_MAP(x) x
#endif

//*****************************************************************************
//
// Macros for the ADC14 API.
//
//*****************************************************************************
#define MAP_ADC14_enableModule                  ROM_MAP(ADC14_enableModule)
#define MAP_ADC14_disableModule                 ROM_MAP(ADC14_disableModule)
#define MAP_ADC14_initModule                    ROM_MAP(ADC14_initModule)
#define MAP_ADC14_setResolution                 ROM_MAP(ADC14_setResolution)
#define MAP_ADC14_getResolution                 ROM_MAP(ADC14_getResolution)
#define MAP_ADC14_setSampleHoldTrigger          ROM_MAP(ADC14_setSampleHoldTrigger)
#define MAP_ADC14_setSampleHoldTime             ROM_MAP(ADC14_setSampleHoldTime)
#define MAP_ADC14_configureMultiSequenceMode    ROM_MAP(ADC14_configureMultiSequenceMode)
#define MAP_ADC14_configureSingleSampleMode     ROM_MAP(ADC14_configureSingleSampleMode)
#define MAP_ADC14_enableConversion              ROM_MAP(ADC14_enableConversion)
#define MAP_ADC14_disableConversion             ROM_MAP(ADC14_disableConversion)
#define MAP_ADC14_isBusy                        ROM_MAP(ADC14_isBusy)
#define MAP_ADC14_configureConversionMemory     ROM_MAP(ADC14_configureConversionMemory)
#define MAP_ADC14_enableComparatorWindow        ROM_MAP(ADC14_enableComparatorWindow)
#define MAP_ADC14_disableComparatorWindow       ROM_MAP(ADC14_disableComparatorWindow)
#define MAP_ADC14_setComparatorWindowValue      ROM_MAP(ADC14_setComparatorWindowValue)
#define MAP_ADC14_setResultFormat               ROM_MAP(ADC14_setResultFormat)
#define MAP_ADC14_getResult                     ROM_MAP(ADC14_getResult)
#define MAP_ADC14_getMultiSequenceResult        ROM_MAP(ADC14_getMultiSequenceResult)
#define MAP_ADC14_getResultArray                ROM_MAP(ADC14_getResultArray)
#define MAP_ADC14_enableReferenceBurst          ROM_MAP(ADC14_enableReferenceBurst)
#define MAP_ADC14_disableReferenceBurst         ROM_MAP(ADC14_disableReferenceBurst)
#define MAP_ADC14_setPowerMode                  ROM_MAP(ADC14_setPowerMode)
#define MAP_ADC14_enableInterrupt               ROM_MAP(ADC14_enableInterrupt)
#define MAP_ADC14_disableInterrupt              ROM_MAP(ADC14_disableInterrupt)
#define MAP_ADC14_getInterruptStatus            ROM_MAP(ADC14_getInterruptStatus)
#define MAP_ADC14_getEnabledInterruptStatus     ROM_MAP(ADC14_getEnabledInterruptStatus)
#define MAP_ADC14_clearInterruptFlag            ROM_MAP(ADC14_clearInterruptFlag)
#define MAP_ADC14_toggleConversionTrigger       ROM_MAP(ADC14_toggleConversionTrigger)
#define MAP_ADC14_enableSampleTimer             ROM_MAP(ADC14_enableSampleTimer)
#define MAP_ADC14_disableSampleTimer            ROM_MAP(ADC14_disableSampleTimer)
//#define MAP_ADC14_registerInterrupt             ADC14_registerInterrupt
//#define MAP_ADC14_unregisterInterrupt           ADC14_unregisterInterrupt

//*****************************************************************************
//
// Macros for the AES256 API.
//
//*****************************************************************************
#define MAP_AES256_setCipherKey                 ROM_MAP(AES256_setCipherKey)
#define MAP_AES256_encryptData                  ROM_MAP(AES256_encryptData)
#define MAP_AES256_decryptData                  ROM_MAP(AES256_decryptData)
#define MAP_AES256_setDecipherKey               ROM_MAP(AES256_setDecipherKey)
#define MAP_AES256_reset                        ROM_MAP(AES256_reset)
#define MAP_AES256_startEncryptData             ROM_MAP(AES256_startEncryptData)
#define MAP_AES256_startDecryptData             ROM_MAP(AES256_startDecryptData)
#define MAP_AES256_startSetDecipherKey          ROM_MAP(AES256_startSetDecipherKey)
#define MAP_AES256_getDataOut                   ROM_MAP(AES256_getDataOut)
#define MAP_AES256_isBusy                       ROM_MAP(AES256_isBusy)
#define MAP_AES256_clearErrorFlag               ROM_MAP(AES256_clearErrorFlag)
#define MAP_AES256_getErrorFlagStatus           ROM_MAP(AES256_getErrorFlagStatus)
#define MAP_AES256_clearInterruptFlag           ROM_MAP(AES256_clearInterruptFlag)
#define MAP_AES256_getInterruptStatus           ROM_MAP(AES256_getInterruptStatus)
#define MAP_AES256_enableInterrupt              ROM_MAP(AES256_enableInterrupt)
#define MAP_AES256_disableInterrupt             ROM_MAP(AES256_disableInterrupt)
//#define MAP_AES256_registerInterrupt            AES256_registerInterrupt
//#define MAP_AES256_unregisterInterrupt          AES256_unregisterInterrupt
#define MAP_AES256_getInterruptFlagStatus       ROM_MAP(AES256_getInterruptFlagStatus)

//*****************************************************************************
//
// Macros for the Comp API.
//
//*****************************************************************************
#define MAP_COMP_E_initModule                   ROM_MAP(COMP_E_initModule)
#define MAP_COMP_E_setReferenceVoltage          ROM_MAP(COMP_E_setReferenceVoltage)
#define MAP_COMP_E_setReferenceAccuracy         ROM_MAP(COMP_E_setReferenceAccuracy)
#define MAP_COMP_E_setPowerMode                 ROM_MAP(COMP_E_setPowerMode)
#define MAP_COMP_E_enableModule                 ROM_MAP(COMP_E_enableModule)
#define MAP_COMP_E_disableModule                ROM_MAP(COMP_E_disableModule)
#define MAP_COMP_E_shortInputs                  ROM_MAP(COMP_E_shortInputs)
#define MAP_COMP_E_unshortInputs                ROM_MAP(COMP_E_unshortInputs)
#define MAP_COMP_E_disableInputBuffer           ROM_MAP(COMP_E_disableInputBuffer)
#define MAP_COMP_E_enableInputBuffer            ROM_MAP(COMP_E_enableInputBuffer)
#define MAP_COMP_E_swapIO                       ROM_MAP(COMP_E_swapIO)
#define MAP_COMP_E_outputValue                  ROM_MAP(COMP_E_outputValue)
#define MAP_COMP_E_enableInterrupt              ROM_MAP(COMP_E_enableInterrupt)
#define MAP_COMP_E_disableInterrupt             ROM_MAP(COMP_E_disableInterrupt)
#define MAP_COMP_E_clearInterruptFlag           ROM_MAP(COMP_E_clearInterruptFlag)
#define MAP_COMP_E_getInterruptStatus           ROM_MAP(COMP_E_getInterruptStatus)
#define MAP_COMP_E_getEnabledInterruptStatus    ROM_MAP(COMP_E_getEnabledInterruptStatus)
#define MAP_COMP_E_setInterruptEdgeDirection    ROM_MAP(COMP_E_setInterruptEdgeDirection)
#define MAP_COMP_E_toggleInterruptEdgeDirection ROM_MAP(COMP_E_toggleInterruptEdgeDirection)
//#define MAP_COMP_E_registerInterrupt            COMP_E_registerInterrupt
//#define MAP_COMP_E_unregisterInterrupt          COMP_E_unregisterInterrupt

//*****************************************************************************
//
// Macros for the CRC32 API.
//
//*****************************************************************************
#define MAP_CRC32_setSeed                       ROM_MAP(CRC32_setSeed)
#define MAP_CRC32_set8BitData                   ROM_MAP(CRC32_set8BitData)
#define MAP_CRC32_set16BitData                  ROM_MAP(CRC32_set16BitData)
#define MAP_CRC32_set32BitData                  ROM_MAP(CRC32_set32BitData)
#define MAP_CRC32_set8BitDataReversed           ROM_MAP(CRC32_set8BitDataReversed)
#define MAP_CRC32_set16BitDataReversed          ROM_MAP(CRC32_set16BitDataReversed)
#define MAP_CRC32_set32BitDataReversed          ROM_MAP(CRC32_set32BitDataReversed)
#define MAP_CRC32_getResult                     ROM_MAP(CRC32_getResult)
#define MAP_CRC32_getResultReversed             ROM_MAP(CRC32_getResultReversed)

//*****************************************************************************
//
// Macros for the CS API.
//
//*****************************************************************************
#define MAP_CS_initClockSignal                  ROM_MAP(CS_initClockSignal)
#define MAP_CS_setReferenceOscillatorFrequency  ROM_MAP(CS_setReferenceOscillatorFrequency)
#define MAP_CS_enableClockRequest               ROM_MAP(CS_enableClockRequest)
#define MAP_CS_disableClockRequest              ROM_MAP(CS_disableClockRequest)
#define MAP_CS_setDCOCenteredFrequency          ROM_MAP(CS_setDCOCenteredFrequency)
#define MAP_CS_tuneDCOFrequency                 ROM_MAP(CS_tuneDCOFrequency)
#define MAP_CS_enableDCOExternalResistor        ROM_MAP(CS_enableDCOExternalResistor)
#define MAP_CS_disableDCOExternalResistor       ROM_MAP(CS_disableDCOExternalResistor)
#define MAP_CS_enableInterrupt                  ROM_MAP(CS_enableInterrupt)
#define MAP_CS_disableInterrupt                 ROM_MAP(CS_disableInterrupt)
#define MAP_CS_getEnabledInterruptStatus        ROM_MAP(CS_getEnabledInterruptStatus)
#define MAP_CS_getInterruptStatus               ROM_MAP(CS_getInterruptStatus)
#define MAP_CS_setDCOFrequency                  ROM_MAP(CS_setDCOFrequency)
#define MAP_CS_getDCOFrequency                  ROM_MAP(CS_getDCOFrequency)
#define MAP_CS_enableFaultCounter               ROM_MAP(CS_enableFaultCounter)
#define MAP_CS_disableFaultCounter              ROM_MAP(CS_disableFaultCounter)
#define MAP_CS_resetFaultCounter                ROM_MAP(CS_resetFaultCounter)
#define MAP_CS_startFaultCounter                ROM_MAP(CS_startFaultCounter)
//#define MAP_CS_registerInterrupt                CS_registerInterrupt
//#define MAP_CS_unregisterInterrupt              CS_unregisterInterrupt
#define MAP_CS_clearInterruptFlag               ROM_MAP(CS_clearInterruptFlag)
//#define MAP_CS_getACLK                          CS_getACLK
//#define MAP_CS_getSMCLK                         CS_getSMCLK
//#define MAP_CS_getMCLK                          CS_getMCLK
//#define MAP_CS_getBCLK                          CS_getBCLK
//#define MAP_CS_getHSMCLK                        CS_getHSMCLK
//#define MAP_CS_startHFXT                        CS_startHFXT
//#define MAP_CS_startHFXTWithTimeout             CS_startHFXTWithTimeout
//#define MAP_CS_startLFXT                        CS_startLFXT
//#define MAP_CS_startLFXTWithTimeout             CS_startLFXTWithTimeout
//#define MAP_CS_setExternalClockSourceFrequency  CS_setExternalClockSourceFrequency
#define MAP_CS_setDCOExternalResistorCalibration                              \
                                                ROM_MAP(CS_setDCOExternalResistorCalibration)

//*****************************************************************************
//
// Macros for the DMA API.
//
//*****************************************************************************
#define MAP_DMA_enableModule                    ROM_MAP(DMA_enableModule)
#define MAP_DMA_disableModule                   ROM_MAP(DMA_disableModule)
#define MAP_DMA_getErrorStatus                  ROM_MAP(DMA_getErrorStatus)
#define MAP_DMA_clearErrorStatus                ROM_MAP(DMA_clearErrorStatus)
#define MAP_DMA_enableChannel                   ROM_MAP(DMA_enableChannel)
#define MAP_DMA_disableChannel                  ROM_MAP(DMA_disableChannel)
#define MAP_DMA_isChannelEnabled                ROM_MAP(DMA_isChannelEnabled)
#define MAP_DMA_setControlBase                  ROM_MAP(DMA_setControlBase)
#define MAP_DMA_getControlBase                  ROM_MAP(DMA_getControlBase)
#define MAP_DMA_getControlAlternateBase         ROM_MAP(DMA_getControlAlternateBase)
#define MAP_DMA_requestChannel                  ROM_MAP(DMA_requestChannel)
#define MAP_DMA_enableChannelAttribute          ROM_MAP(DMA_enableChannelAttribute)
#define MAP_DMA_disableChannelAttribute         ROM_MAP(DMA_disableChannelAttribute)
#define MAP_DMA_getChannelAttribute             ROM_MAP(DMA_getChannelAttribute)
#define MAP_DMA_setChannelControl               ROM_MAP(DMA_setChannelControl)
#define MAP_DMA_setChannelTransfer              ROM_MAP(DMA_setChannelTransfer)
#define MAP_DMA_setChannelScatterGather         ROM_MAP(DMA_setChannelScatterGather)
#define MAP_DMA_getChannelSize                  ROM_MAP(DMA_getChannelSize)
#define MAP_DMA_getChannelMode                  ROM_MAP(DMA_getChannelMode)
#define MAP_DMA_assignChannel                   ROM_MAP(DMA_assignChannel)
#define MAP_DMA_requestSoftwareTransfer         ROM_MAP(DMA_requestSoftwareTransfer)
#define MAP_DMA_assignInterrupt                 ROM_MAP(DMA_assignInterrupt)
#define MAP_DMA_enableInterrupt                 ROM_MAP(DMA_enableInterrupt)
#define MAP_DMA_disableInterrupt                ROM_MAP(DMA_disableInterrupt)
#define MAP_DMA_getInterruptStatus              ROM_MAP(DMA_getInterruptStatus)
#define MAP_DMA_clearInterruptFlag              ROM_MAP(DMA_clearInterruptFlag)
//#define MAP_DMA_registerInterrupt               DMA_registerInterrupt
//#define MAP_DMA_unregisterInterrupt             DMA_unregisterInterrupt

//*****************************************************************************
//
// Macros for the Flash API.
//
//*****************************************************************************
//#define MAP_FlashCtl_enableReadParityCheck      FlashCtl_enableReadParityCheck
//#define MAP_FlashCtl_disableReadParityCheck     FlashCtl_disableReadParityCheck
#define MAP_FlashCtl_enableReadBuffering        ROM_MAP(FlashCtl_enableReadBuffering)
#define MAP_FlashCtl_disableReadBuffering       ROM_MAP(FlashCtl_disableReadBuffering)
#define MAP_FlashCtl_unprotectSector            ROM_MAP(FlashCtl_unprotectSector)
#define MAP_FlashCtl_protectSector              ROM_MAP(FlashCtl_protectSector)
#define MAP_FlashCtl_isSectorProtected          ROM_MAP(FlashCtl_isSectorProtected)
#define MAP_FlashCtl_verifyMemory               ROM_MAP(FlashCtl_verifyMemory)
#define MAP_FlashCtl_performMassErase           ROM_MAP(FlashCtl_performMassErase)
#define MAP_FlashCtl_eraseSector                ROM_MAP(FlashCtl_eraseSector)
#define MAP_FlashCtl_programMemory              ROM_MAP(FlashCtl_programMemory)
#define MAP_FlashCtl_setProgramVerification     ROM_MAP(FlashCtl_setProgramVerification)
#define MAP_FlashCtl_clearProgramVerification   ROM_MAP(FlashCtl_clearProgramVerification)
#define MAP_FlashCtl_enableWordProgramming      ROM_MAP(FlashCtl_enableWordProgramming)
#define MAP_FlashCtl_disableWordProgramming     ROM_MAP(FlashCtl_disableWordProgramming)
#define MAP_FlashCtl_isWordProgrammingEnabled   ROM_MAP(FlashCtl_isWordProgrammingEnabled)
#define MAP_FlashCtl_enableInterrupt            ROM_MAP(FlashCtl_enableInterrupt)
#define MAP_FlashCtl_disableInterrupt           ROM_MAP(FlashCtl_disableInterrupt)
#define MAP_FlashCtl_getEnabledInterruptStatus  ROM_MAP(FlashCtl_getEnabledInterruptStatus)
#define MAP_FlashCtl_getInterruptStatus         ROM_MAP(FlashCtl_getInterruptStatus)
#define MAP_FlashCtl_clearInterruptFlag         ROM_MAP(FlashCtl_clearInterruptFlag)
#define MAP_FlashCtl_setWaitState               ROM_MAP(FlashCtl_setWaitState)
#define MAP_FlashCtl_getWaitState               ROM_MAP(FlashCtl_getWaitState)
#define MAP_FlashCtl_setReadMode                ROM_MAP(FlashCtl_setReadMode)
#define MAP_FlashCtl_getReadMode                ROM_MAP(FlashCtl_getReadMode)
//#define MAP_FlashCtl_registerInterrupt          FlashCtl_registerInterrupt
//#define MAP_FlashCtl_unregisterInterrupt        FlashCtl_unregisterInterrupt
#define MAP___FlashCtl_remaskData8Post          ROM_MAP(__FlashCtl_remaskData8Post)
#define MAP___FlashCtl_remaskData8Pre           ROM_MAP(__FlashCtl_remaskData8Pre)
#define MAP___FlashCtl_remaskData32Pre          ROM_MAP(__FlashCtl_remaskData32Pre)
#define MAP___FlashCtl_remaskData32Post         ROM_MAP(__FlashCtl_remaskData32Post)
#define MAP___FlashCtl_remaskBurstDataPre       ROM_MAP(__FlashCtl_remaskBurstDataPre)
#define MAP___FlashCtl_remaskBurstDataPost      ROM_MAP(__FlashCtl_remaskBurstDataPost)
#define MAP_FlashCtl_initiateSectorErase        ROM_MAP(FlashCtl_initiateSectorErase)
#define MAP_FlashCtl_initiateMassErase          ROM_MAP(FlashCtl_initiateMassErase)
//#define MAP_FlashCtl_getMemoryInfo              FlashCtl_getMemoryInfo

//*****************************************************************************
//
// Macros for the FPU API.
//
//*****************************************************************************
#define MAP_FPU_enableModule                    ROM_MAP(FPU_enableModule)
#define MAP_FPU_disableModule                   ROM_MAP(FPU_disableModule)
#define MAP_FPU_enableStacking                  ROM_MAP(FPU_enableStacking)
#define MAP_FPU_enableLazyStacking              ROM_MAP(FPU_enableLazyStacking)
#define MAP_FPU_disableStacking                 ROM_MAP(FPU_disableStacking)
#define MAP_FPU_setHalfPrecisionMode            ROM_MAP(FPU_setHalfPrecisionMode)
#define MAP_FPU_setNaNMode                      ROM_MAP(FPU_setNaNMode)
#define MAP_FPU_setFlushToZeroMode              ROM_MAP(FPU_setFlushToZeroMode)
#define MAP_FPU_setRoundingMode                 ROM_MAP(FPU_setRoundingMode)


//*****************************************************************************
//
// Macros for the GPIO API.
//
//*****************************************************************************
#define MAP_GPIO_setAsOutputPin                 ROM_MAP(GPIO_setAsOutputPin)
#define MAP_GPIO_setOutputHighOnPin             ROM_MAP(GPIO_setOutputHighOnPin)
#define MAP_GPIO_setOutputLowOnPin              ROM_MAP(GPIO_setOutputLowOnPin)
#define MAP_GPIO_toggleOutputOnPin              ROM_MAP(GPIO_toggleOutputOnPin)
#define MAP_GPIO_setAsInputPinWithPullDownResistor                            \
                                                ROM_MAP(GPIO_setAsInputPinWithPullDownResistor)
#define MAP_GPIO_setAsInputPinWithPullUpResistor                              \
                                                ROM_MAP(GPIO_setAsInputPinWithPullUpResistor)
#define MAP_GPIO_setAsPeripheralModuleFunctionOutputPin                       \
                                                ROM_MAP(GPIO_setAsPeripheralModuleFunctionOutputPin)
#define MAP_GPIO_setAsPeripheralModuleFunctionInputPin                        \
                                                ROM_MAP(GPIO_setAsPeripheralModuleFunctionInputPin)
#define MAP_GPIO_getInputPinValue               ROM_MAP(GPIO_getInputPinValue)
#define MAP_GPIO_interruptEdgeSelect            ROM_MAP(GPIO_interruptEdgeSelect)
#define MAP_GPIO_enableInterrupt                ROM_MAP(GPIO_enableInterrupt)
#define MAP_GPIO_disableInterrupt               ROM_MAP(GPIO_disableInterrupt)
#define MAP_GPIO_getInterruptStatus             ROM_MAP(GPIO_getInterruptStatus)
#define MAP_GPIO_clearInterruptFlag             ROM_MAP(GPIO_clearInterruptFlag)
#define MAP_GPIO_setAsInputPin                  ROM_MAP(GPIO_setAsInputPin)
#define MAP_GPIO_getEnabledInterruptStatus      ROM_MAP(GPIO_getEnabledInterruptStatus)
#define MAP_GPIO_setDriveStrengthHigh           ROM_MAP(GPIO_setDriveStrengthHigh)
#define MAP_GPIO_setDriveStrengthLow            ROM_MAP(GPIO_setDriveStrengthLow)
//#define MAP_GPIO_registerInterrupt              GPIO_registerInterrupt
//#define MAP_GPIO_unregisterInterrupt            GPIO_unregisterInterrupt


//*****************************************************************************
//
// Macros for the I2C API.
//
//*****************************************************************************
#define MAP_I2C_initMaster                      ROM_MAP(I2C_initMaster)
#define MAP_I2C_initSlave                       ROM_MAP(I2C_initSlave)
#define MAP_I2C_enableModule                    ROM_MAP(I2C_enableModule)
#define MAP_I2C_disableModule                   ROM_MAP(I2C_disableModule)
#define MAP_I2C_setSlaveAddress                 ROM_MAP(I2C_setSlaveAddress)
#define MAP_I2C_setMode                         ROM_MAP(I2C_setMode)
#define MAP_I2C_slavePutData                    ROM_MAP(I2C_slavePutData)
#define MAP_I2C_slaveGetData                    ROM_MAP(I2C_slaveGetData)
#define MAP_I2C_isBusBusy                       ROM_MAP(I2C_isBusBusy)
#define MAP_I2C_masterSendSingleByte            ROM_MAP(I2C_masterSendSingleByte)
#define MAP_I2C_masterSendSingleByteWithTimeout ROM_MAP(I2C_masterSendSingleByteWithTimeout)
#define MAP_I2C_masterSendMultiByteStart        ROM_MAP(I2C_masterSendMultiByteStart)
#define MAP_I2C_masterSendMultiByteStartWithTimeout                           \
                                                ROM_MAP(I2C_masterSendMultiByteStartWithTimeout)
#define MAP_I2C_masterSendMultiByteNext         ROM_MAP(I2C_masterSendMultiByteNext)
#define MAP_I2C_masterSendMultiByteNextWithTimeout                            \
                                                ROM_MAP(I2C_masterSendMultiByteNextWithTimeout)
#define MAP_I2C_masterSendMultiByteFinish       ROM_MAP(I2C_masterSendMultiByteFinish)
#define MAP_I2C_masterSendMultiByteFinishWithTimeout                          \
                                                ROM_MAP(I2C_masterSendMultiByteFinishWithTimeout)
#define MAP_I2C_masterSendMultiByteStop         ROM_MAP(I2C_masterSendMultiByteStop)
#define MAP_I2C_masterSendMultiByteStopWithTimeout                            \
                                                ROM_MAP(I2C_masterSendMultiByteStopWithTimeout)
#define MAP_I2C_masterReceiveStart              ROM_MAP(I2C_masterReceiveStart)
#define MAP_I2C_masterReceiveMultiByteNext      ROM_MAP(I2C_masterReceiveMultiByteNext)
#define MAP_I2C_masterReceiveMultiByteFinish    ROM_MAP(I2C_masterReceiveMultiByteFinish)
#define MAP_I2C_masterReceiveMultiByteFinishWithTimeout                       \
                                                ROM_MAP(I2C_masterReceiveMultiByteFinishWithTimeout)
#define MAP_I2C_masterReceiveMultiByteStop      ROM_MAP(I2C_masterReceiveMultiByteStop)
#define MAP_I2C_masterReceiveSingleByte         ROM_MAP(I2C_masterReceiveSingleByte)
#define MAP_I2C_masterReceiveSingle             ROM_MAP(I2C_masterReceiveSingle)
#define MAP_I2C_getReceiveBufferAddressForDMA   ROM_MAP(I2C_getReceiveBufferAddressForDMA)
#define MAP_I2C_getTransmitBufferAddressForDMA  ROM_MAP(I2C_getTransmitBufferAddressForDMA)
#define MAP_I2C_masterIsStopSent                ROM_MAP(I2C_masterIsStopSent)
#define MAP_I2C_masterIsStartSent               ROM_MAP(I2C_masterIsStartSent)
#define MAP_I2C_masterSendStart                 ROM_MAP(I2C_masterSendStart)
#define MAP_I2C_enableMultiMasterMode           ROM_MAP(I2C_enableMultiMasterMode)
#define MAP_I2C_disableMultiMasterMode          ROM_MAP(I2C_disableMultiMasterMode)
#define MAP_I2C_enableInterrupt                 ROM_MAP(I2C_enableInterrupt)
#define MAP_I2C_disableInterrupt                ROM_MAP(I2C_disableInterrupt)
#define MAP_I2C_clearInterruptFlag              ROM_MAP(I2C_clearInterruptFlag)
#define MAP_I2C_getInterruptStatus              ROM_MAP(I2C_getInterruptStatus)
#define MAP_I2C_getEnabledInterruptStatus       ROM_MAP(I2C_getEnabledInterruptStatus)
#define MAP_I2C_getMode                         ROM_MAP(I2C_getMode)
//#define MAP_I2C_registerInterrupt               I2C_registerInterrupt
//#define MAP_I2C_unregisterInterrupt             I2C_unregisterInterrupt
//#define MAP_I2C_slaveSendNAK                    I2C_slaveSendNAK

//*****************************************************************************
//
// Macros for the Interrupt API.
//
//*****************************************************************************
#define MAP_Interrupt_enableMaster              ROM_MAP(Interrupt_enableMaster)
#define MAP_Interrupt_disableMaster             ROM_MAP(Interrupt_disableMaster)
#define MAP_Interrupt_setPriorityGrouping       ROM_MAP(Interrupt_setPriorityGrouping)
#define MAP_Interrupt_getPriorityGrouping       ROM_MAP(Interrupt_getPriorityGrouping)
#define MAP_Interrupt_setPriority               ROM_MAP(Interrupt_setPriority)
#define MAP_Interrupt_getPriority               ROM_MAP(Interrupt_getPriority)
#define MAP_Interrupt_enableInterrupt           ROM_MAP(Interrupt_enableInterrupt)
#define MAP_Interrupt_disableInterrupt          ROM_MAP(Interrupt_disableInterrupt)
#define MAP_Interrupt_isEnabled                 ROM_MAP(Interrupt_isEnabled)
#define MAP_Interrupt_pendInterrupt             ROM_MAP(Interrupt_pendInterrupt)
#define MAP_Interrupt_setPriorityMask           ROM_MAP(Interrupt_setPriorityMask)
#define MAP_Interrupt_getPriorityMask           ROM_MAP(Interrupt_getPriorityMask)
#define MAP_Interrupt_setVectorTableAddress     ROM_MAP(Interrupt_setVectorTableAddress)
#define MAP_Interrupt_getVectorTableAddress     ROM_MAP(Interrupt_getVectorTableAddress)
#define MAP_Interrupt_enableSleepOnIsrExit      ROM_MAP(Interrupt_enableSleepOnIsrExit)
#define MAP_Interrupt_disableSleepOnIsrExit     ROM_MAP(Interrupt_disableSleepOnIsrExit)
//#define MAP_Interrupt_registerInterrupt         Interrupt_registerInterrupt
//#define MAP_Interrupt_unregisterInterrupt       Interrupt_unregisterInterrupt
#define MAP_Interrupt_unpendInterrupt           ROM_MAP(Interrupt_unpendInterrupt)

//*****************************************************************************
//
// Macros for the MPU API.
//
//*****************************************************************************
#define MAP_MPU_enableModule                    ROM_MAP(MPU_enableModule)
#define MAP_MPU_disableModule                   ROM_MAP(MPU_disableModule)
#define MAP_MPU_getRegionCount                  ROM_MAP(MPU_getRegionCount)
#define MAP_MPU_enableRegion                    ROM_MAP(MPU_enableRegion)
#define MAP_MPU_disableRegion                   ROM_MAP(MPU_disableRegion)
#define MAP_MPU_setRegion                       ROM_MAP(MPU_setRegion)
#define MAP_MPU_getRegion                       ROM_MAP(MPU_getRegion)
#define MAP_MPU_enableInterrupt                 ROM_MAP(MPU_enableInterrupt)
#define MAP_MPU_disableInterrupt                ROM_MAP(MPU_disableInterrupt)
//#define MAP_MPU_registerInterrupt               MPU_registerInterrupt
//#define MAP_MPU_unregisterInterrupt             MPU_unregisterInterrupt

//*****************************************************************************
//
// Macros for the PCM API.
//
//*****************************************************************************
#define MAP_PCM_setCoreVoltageLevel             ROM_MAP(PCM_setCoreVoltageLevel)
#define MAP_PCM_getCoreVoltageLevel             ROM_MAP(PCM_getCoreVoltageLevel)
#define MAP_PCM_setCoreVoltageLevelWithTimeout  ROM_MAP(PCM_setCoreVoltageLevelWithTimeout)
#define MAP_PCM_setPowerMode                    ROM_MAP(PCM_setPowerMode)
#define MAP_PCM_setPowerModeWithTimeout         ROM_MAP(PCM_setPowerModeWithTimeout)
#define MAP_PCM_getPowerMode                    ROM_MAP(PCM_getPowerMode)
#define MAP_PCM_setPowerState                   ROM_MAP(PCM_setPowerState)
#define MAP_PCM_setPowerStateWithTimeout        ROM_MAP(PCM_setPowerStateWithTimeout)
#define MAP_PCM_getPowerState                   ROM_MAP(PCM_getPowerState)
#define MAP_PCM_shutdownDevice                  ROM_MAP(PCM_shutdownDevice)
#define MAP_PCM_gotoLPM0                        ROM_MAP(PCM_gotoLPM0)
#define MAP_PCM_gotoLPM3                        ROM_MAP(PCM_gotoLPM3)
#define MAP_PCM_enableInterrupt                 ROM_MAP(PCM_enableInterrupt)
#define MAP_PCM_disableInterrupt                ROM_MAP(PCM_disableInterrupt)
#define MAP_PCM_getInterruptStatus              ROM_MAP(PCM_getInterruptStatus)
#define MAP_PCM_getEnabledInterruptStatus       ROM_MAP(PCM_getEnabledInterruptStatus)
#define MAP_PCM_clearInterruptFlag              ROM_MAP(PCM_clearInterruptFlag)
#define MAP_PCM_enableRudeMode                  ROM_MAP(PCM_enableRudeMode)
#define MAP_PCM_disableRudeMode                 ROM_MAP(PCM_disableRudeMode)
#define MAP_PCM_gotoLPM0InterruptSafe           ROM_MAP(PCM_gotoLPM0InterruptSafe)
#define MAP_PCM_gotoLPM3InterruptSafe           ROM_MAP(PCM_gotoLPM3InterruptSafe)
//#define MAP_PCM_registerInterrupt               PCM_registerInterrupt
//#define MAP_PCM_unregisterInterrupt             PCM_unregisterInterrupt
#define MAP_PCM_setCoreVoltageLevelNonBlocking  ROM_MAP(PCM_setCoreVoltageLevelNonBlocking)
#define MAP_PCM_setPowerModeNonBlocking         ROM_MAP(PCM_setPowerModeNonBlocking)
#define MAP_PCM_setPowerStateNonBlocking        ROM_MAP(PCM_setPowerStateNonBlocking)
#define MAP_PCM_gotoLPM4                        ROM_MAP(PCM_gotoLPM4)
#define MAP_PCM_gotoLPM4InterruptSafe           ROM_MAP(PCM_gotoLPM4InterruptSafe)


//*****************************************************************************
//
// Macros for the PMAP API.
//
//*****************************************************************************
#define MAP_PMAP_configurePorts                 ROM_MAP(PMAP_configurePorts)

//*****************************************************************************
//
// Macros for the PSS API.
//
//*****************************************************************************
#define MAP_PSS_enableHighSidePinToggle         ROM_MAP(PSS_enableHighSidePinToggle)
#define MAP_PSS_disableHighSidePinToggle        ROM_MAP(PSS_disableHighSidePinToggle)
#define MAP_PSS_enableHighSide                  ROM_MAP(PSS_enableHighSide)
#define MAP_PSS_disableHighSide                 ROM_MAP(PSS_disableHighSide)
//#define MAP_PSS_enableLowSide                   PSS_enableLowSide
//#define MAP_PSS_disableLowSide                  PSS_disableLowSide
#define MAP_PSS_setHighSidePerformanceMode      ROM_MAP(PSS_setHighSidePerformanceMode)
#define MAP_PSS_getHighSidePerformanceMode      ROM_MAP(PSS_getHighSidePerformanceMode)
//#define MAP_PSS_setLowSidePerformanceMode       PSS_setLowSidePerformanceMode
//#define MAP_PSS_getLowSidePerformanceMode       PSS_getLowSidePerformanceMode
#define MAP_PSS_enableHighSideMonitor           ROM_MAP(PSS_enableHighSideMonitor)
#define MAP_PSS_disableHighSideMonitor          ROM_MAP(PSS_disableHighSideMonitor)
#define MAP_PSS_setHighSideVoltageTrigger       ROM_MAP(PSS_setHighSideVoltageTrigger)
#define MAP_PSS_getHighSideVoltageTrigger       ROM_MAP(PSS_getHighSideVoltageTrigger)
#define MAP_PSS_enableInterrupt                 ROM_MAP(PSS_enableInterrupt)
#define MAP_PSS_disableInterrupt                ROM_MAP(PSS_disableInterrupt)
#define MAP_PSS_getInterruptStatus              ROM_MAP(PSS_getInterruptStatus)
#define MAP_PSS_clearInterruptFlag              ROM_MAP(PSS_clearInterruptFlag)
//#define MAP_PSS_registerInterrupt               PSS_registerInterrupt
//#define MAP_PSS_unregisterInterrupt             PSS_unregisterInterrupt
#define MAP_PSS_enableForcedDCDCOperation       ROM_MAP(PSS_enableForcedDCDCOperation)
#define MAP_PSS_disableForcedDCDCOperation      ROM_MAP(PSS_disableForcedDCDCOperation)

//*****************************************************************************
//
// Macros for the Ref API.
//
//*****************************************************************************
#define MAP_REF_A_setReferenceVoltage           ROM_MAP(REF_A_setReferenceVoltage)
#define MAP_REF_A_disableTempSensor             ROM_MAP(REF_A_disableTempSensor)
#define MAP_REF_A_enableTempSensor              ROM_MAP(REF_A_enableTempSensor)
#define MAP_REF_A_enableReferenceVoltageOutput  ROM_MAP(REF_A_enableReferenceVoltageOutput)
#define MAP_REF_A_disableReferenceVoltageOutput ROM_MAP(REF_A_disableReferenceVoltageOutput)
#define MAP_REF_A_enableReferenceVoltage        ROM_MAP(REF_A_enableReferenceVoltage)
#define MAP_REF_A_disableReferenceVoltage       ROM_MAP(REF_A_disableReferenceVoltage)
#define MAP_REF_A_getBandgapMode                ROM_MAP(REF_A_getBandgapMode)
#define MAP_REF_A_isBandgapActive               ROM_MAP(REF_A_isBandgapActive)
#define MAP_REF_A_isRefGenBusy                  ROM_MAP(REF_A_isRefGenBusy)
#define MAP_REF_A_isRefGenActive                ROM_MAP(REF_A_isRefGenActive)
#define MAP_REF_A_getBufferedBandgapVoltageStatus                             \
                                                ROM_MAP(REF_A_getBufferedBandgapVoltageStatus)
#define MAP_REF_A_getVariableReferenceVoltageStatus                           \
                                                ROM_MAP(REF_A_getVariableReferenceVoltageStatus)
#define MAP_REF_A_setReferenceVoltageOneTimeTrigger                           \
                                                ROM_MAP(REF_A_setReferenceVoltageOneTimeTrigger)
#define MAP_REF_A_setBufferedBandgapVoltageOneTimeTrigger                     \
                                                ROM_MAP(REF_A_setBufferedBandgapVoltageOneTimeTrigger)

//*****************************************************************************
//
// Macros for the ResetCtl API.
//
//*****************************************************************************
#define MAP_ResetCtl_initiateSoftReset          ROM_MAP(ResetCtl_initiateSoftReset)
#define MAP_ResetCtl_initiateSoftResetWithSource                              \
                                                ROM_MAP(ResetCtl_initiateSoftResetWithSource)
#define MAP_ResetCtl_getSoftResetSource         ROM_MAP(ResetCtl_getSoftResetSource)
#define MAP_ResetCtl_clearSoftResetSource       ROM_MAP(ResetCtl_clearSoftResetSource)
#define MAP_ResetCtl_initiateHardReset          ROM_MAP(ResetCtl_initiateHardReset)
#define MAP_ResetCtl_initiateHardResetWithSource                              \
                                                ROM_MAP(ResetCtl_initiateHardResetWithSource)
#define MAP_ResetCtl_getHardResetSource         ROM_MAP(ResetCtl_getHardResetSource)
#define MAP_ResetCtl_clearHardResetSource       ROM_MAP(ResetCtl_clearHardResetSource)
#define MAP_ResetCtl_getPSSSource               ROM_MAP(ResetCtl_getPSSSource)
#define MAP_ResetCtl_clearPSSFlags              ROM_MAP(ResetCtl_clearPSSFlags)
#define MAP_ResetCtl_getPCMSource               ROM_MAP(ResetCtl_getPCMSource)
#define MAP_ResetCtl_clearPCMFlags              ROM_MAP(ResetCtl_clearPCMFlags)

//*****************************************************************************
//
// Macros for the RTC API.
//
//*****************************************************************************
#define MAP_RTC_C_startClock                    ROM_MAP(RTC_C_startClock)
#define MAP_RTC_C_holdClock                     ROM_MAP(RTC_C_holdClock)
#define MAP_RTC_C_setCalibrationFrequency       ROM_MAP(RTC_C_setCalibrationFrequency)
#define MAP_RTC_C_setCalibrationData            ROM_MAP(RTC_C_setCalibrationData)
#define MAP_RTC_C_setTemperatureCompensation    ROM_MAP(RTC_C_setTemperatureCompensation)
#define MAP_RTC_C_initCalendar                  ROM_MAP(RTC_C_initCalendar)
#define MAP_RTC_C_getCalendarTime               ROM_MAP(RTC_C_getCalendarTime)
#define MAP_RTC_C_setCalendarAlarm              ROM_MAP(RTC_C_setCalendarAlarm)
#define MAP_RTC_C_setCalendarEvent              ROM_MAP(RTC_C_setCalendarEvent)
#define MAP_RTC_C_definePrescaleEvent           ROM_MAP(RTC_C_definePrescaleEvent)
#define MAP_RTC_C_getPrescaleValue              ROM_MAP(RTC_C_getPrescaleValue)
#define MAP_RTC_C_setPrescaleValue              ROM_MAP(RTC_C_setPrescaleValue)
#define MAP_RTC_C_convertBCDToBinary            ROM_MAP(RTC_C_convertBCDToBinary)
#define MAP_RTC_C_convertBinaryToBCD            ROM_MAP(RTC_C_convertBinaryToBCD)
#define MAP_RTC_C_enableInterrupt               ROM_MAP(RTC_C_enableInterrupt)
#define MAP_RTC_C_disableInterrupt              ROM_MAP(RTC_C_disableInterrupt)
#define MAP_RTC_C_getInterruptStatus            ROM_MAP(RTC_C_getInterruptStatus)
#define MAP_RTC_C_getEnabledInterruptStatus     ROM_MAP(RTC_C_getEnabledInterruptStatus)
#define MAP_RTC_C_clearInterruptFlag            ROM_MAP(RTC_C_clearInterruptFlag)
//#define MAP_RTC_C_registerInterrupt             RTC_C_registerInterrupt
//#define MAP_RTC_C_unregisterInterrupt           RTC_C_unregisterInterrupt

//*****************************************************************************
//
// Macros for the SPI API.
//
//*****************************************************************************
#define MAP_SPI_initMaster                      ROM_MAP(SPI_initMaster)
#define MAP_SPI_selectFourPinFunctionality      ROM_MAP(SPI_selectFourPinFunctionality)
#define MAP_SPI_changeMasterClock               ROM_MAP(SPI_changeMasterClock)
#define MAP_SPI_initSlave                       ROM_MAP(SPI_initSlave)
#define MAP_SPI_changeClockPhasePolarity        ROM_MAP(SPI_changeClockPhasePolarity)
#define MAP_SPI_transmitData                    ROM_MAP(SPI_transmitData)
#define MAP_SPI_receiveData                     ROM_MAP(SPI_receiveData)
#define MAP_SPI_enableModule                    ROM_MAP(SPI_enableModule)
#define MAP_SPI_disableModule                   ROM_MAP(SPI_disableModule)
#define MAP_SPI_getReceiveBufferAddressForDMA   ROM_MAP(SPI_getReceiveBufferAddressForDMA)
#define MAP_SPI_getTransmitBufferAddressForDMA  ROM_MAP(SPI_getTransmitBufferAddressForDMA)
#define MAP_SPI_isBusy                          ROM_MAP(SPI_isBusy)
#define MAP_SPI_enableInterrupt                 ROM_MAP(SPI_enableInterrupt)
#define MAP_SPI_disableInterrupt                ROM_MAP(SPI_disableInterrupt)
#define MAP_SPI_getInterruptStatus              ROM_MAP(SPI_getInterruptStatus)
#define MAP_SPI_getEnabledInterruptStatus       ROM_MAP(SPI_getEnabledInterruptStatus)
#define MAP_SPI_clearInterruptFlag              ROM_MAP(SPI_clearInterruptFlag)
//#define MAP_SPI_registerInterrupt               SPI_registerInterrupt
//#define MAP_SPI_unregisterInterrupt             SPI_unregisterInterrupt

//*****************************************************************************
//
// Macros for the SysCtl API.
//
//*****************************************************************************
#define MAP_SysCtl_getSRAMSize                  ROM_MAP(SysCtl_getSRAMSize)
#define MAP_SysCtl_getFlashSize                 ROM_MAP(SysCtl_getFlashSize)
#define MAP_SysCtl_rebootDevice                 ROM_MAP(SysCtl_rebootDevice)
#define MAP_SysCtl_enableSRAMBank               ROM_MAP(SysCtl_enableSRAMBank)
#define MAP_SysCtl_disableSRAMBank              ROM_MAP(SysCtl_disableSRAMBank)
#define MAP_SysCtl_enableSRAMBankRetention      ROM_MAP(SysCtl_enableSRAMBankRetention)
#define MAP_SysCtl_disableSRAMBankRetention     ROM_MAP(SysCtl_disableSRAMBankRetention)
#define MAP_SysCtl_enablePeripheralAtCPUHalt    ROM_MAP(SysCtl_enablePeripheralAtCPUHalt)
#define MAP_SysCtl_disablePeripheralAtCPUHalt   ROM_MAP(SysCtl_disablePeripheralAtCPUHalt)
#define MAP_SysCtl_setWDTTimeoutResetType       ROM_MAP(SysCtl_setWDTTimeoutResetType)
#define MAP_SysCtl_setWDTPasswordViolationResetType                           \
                                                ROM_MAP(SysCtl_setWDTPasswordViolationResetType)
#define MAP_SysCtl_disableNMISource             ROM_MAP(SysCtl_disableNMISource)
#define MAP_SysCtl_enableNMISource              ROM_MAP(SysCtl_enableNMISource)
#define MAP_SysCtl_getNMISourceStatus           ROM_MAP(SysCtl_getNMISourceStatus)
#define MAP_SysCtl_getTempCalibrationConstant   ROM_MAP(SysCtl_getTempCalibrationConstant)
#define MAP_SysCtl_enableGlitchFilter           ROM_MAP(SysCtl_enableGlitchFilter)
#define MAP_SysCtl_disableGlitchFilter          ROM_MAP(SysCtl_disableGlitchFilter)
#define MAP_SysCtl_getTLVInfo                   ROM_MAP(SysCtl_getTLVInfo)

//*****************************************************************************
//
// Macros for the SysTick API.
//
//*****************************************************************************
#define MAP_SysTick_enableModule                ROM_MAP(SysTick_enableModule)
#define MAP_SysTick_disableModule               ROM_MAP(SysTick_disableModule)
#define MAP_SysTick_enableInterrupt             ROM_MAP(SysTick_enableInterrupt)
#define MAP_SysTick_disableInterrupt            ROM_MAP(SysTick_disableInterrupt)
#define MAP_SysTick_setPeriod                   ROM_MAP(SysTick_setPeriod)
#define MAP_SysTick_getPeriod                   ROM_MAP(SysTick_getPeriod)
#define MAP_SysTick_getValue                    ROM_MAP(SysTick_getValue)
//#define MAP_SysTick_registerInterrupt           SysTick_registerInterrupt
//#define MAP_SysTick_unregisterInterrupt         SysTick_unregisterInterrupt

//*****************************************************************************
//
// Macros for the Timer_A API.
//
//*****************************************************************************
#define MAP_Timer_A_startCounter                ROM_MAP(Timer_A_startCounter)
#define MAP_Timer_A_configureContinuousMode     ROM_MAP(Timer_A_configureContinuousMode)
#define MAP_Timer_A_configureUpMode             ROM_MAP(Timer_A_configureUpMode)
#define MAP_Timer_A_configureUpDownMode         ROM_MAP(Timer_A_configureUpDownMode)
#define MAP_Timer_A_initCapture                 ROM_MAP(Timer_A_initCapture)
#define MAP_Timer_A_initCompare                 ROM_MAP(Timer_A_initCompare)
#define MAP_Timer_A_clearTimer                  ROM_MAP(Timer_A_clearTimer)
#define MAP_Timer_A_getSynchronizedCaptureCompareInput                        \
                                                ROM_MAP(Timer_A_getSynchronizedCaptureCompareInput)
#define MAP_Timer_A_getOutputForOutputModeOutBitValue                         \
                                                ROM_MAP(Timer_A_getOutputForOutputModeOutBitValue)
#define MAP_Timer_A_getCaptureCompareCount      ROM_MAP(Timer_A_getCaptureCompareCount)
#define MAP_Timer_A_setOutputForOutputModeOutBitValue                         \
                                                Timer_A_setOutputForOutputModeOutBitValue
#define MAP_Timer_A_generatePWM                 ROM_MAP(Timer_A_generatePWM)
#define MAP_Timer_A_stopTimer                   ROM_MAP(Timer_A_stopTimer)
#define MAP_Timer_A_setCompareValue             ROM_MAP(Timer_A_setCompareValue)
#define MAP_Timer_A_clearInterruptFlag          ROM_MAP(Timer_A_clearInterruptFlag)
#define MAP_Timer_A_clearCaptureCompareInterrupt                              \
                                                ROM_MAP(Timer_A_clearCaptureCompareInterrupt)
#define MAP_Timer_A_enableInterrupt             ROM_MAP(Timer_A_enableInterrupt)
#define MAP_Timer_A_disableInterrupt            ROM_MAP(Timer_A_disableInterrupt)
#define MAP_Timer_A_getInterruptStatus          ROM_MAP(Timer_A_getInterruptStatus)
#define MAP_Timer_A_getEnabledInterruptStatus   ROM_MAP(Timer_A_getEnabledInterruptStatus)
#define MAP_Timer_A_enableCaptureCompareInterrupt                             \
                                                ROM_MAP(Timer_A_enableCaptureCompareInterrupt)
#define MAP_Timer_A_disableCaptureCompareInterrupt                            \
                                                ROM_MAP(Timer_A_disableCaptureCompareInterrupt)
#define MAP_Timer_A_getCaptureCompareInterruptStatus                          \
                                                ROM_MAP(Timer_A_getCaptureCompareInterruptStatus)
#define MAP_Timer_A_getCaptureCompareEnabledInterruptStatus                   \
                                                ROM_MAP(Timer_A_getCaptureCompareEnabledInterruptStatus)
//#define MAP_Timer_A_registerInterrupt           Timer_A_registerInterrupt
//#define MAP_Timer_A_unregisterInterrupt         Timer_A_unregisterInterrupt
#define MAP_Timer_A_getCounterValue             ROM_MAP(Timer_A_getCounterValue)

//*****************************************************************************
//
// Macros for the Timer32 API.
//
//*****************************************************************************
#define MAP_Timer32_initModule                  ROM_MAP(Timer32_initModule)
#define MAP_Timer32_setCount                    ROM_MAP(Timer32_setCount)
#define MAP_Timer32_setCountInBackground        ROM_MAP(Timer32_setCountInBackground)
#define MAP_Timer32_getValue                    ROM_MAP(Timer32_getValue)
#define MAP_Timer32_startTimer                  ROM_MAP(Timer32_startTimer)
#define MAP_Timer32_haltTimer                   ROM_MAP(Timer32_haltTimer)
#define MAP_Timer32_enableInterrupt             ROM_MAP(Timer32_enableInterrupt)
#define MAP_Timer32_disableInterrupt            ROM_MAP(Timer32_disableInterrupt)
#define MAP_Timer32_clearInterruptFlag          ROM_MAP(Timer32_clearInterruptFlag)
#define MAP_Timer32_getInterruptStatus          ROM_MAP(Timer32_getInterruptStatus)
//#define MAP_Timer32_registerInterrupt           Timer32_registerInterrupt
//#define MAP_Timer32_unregisterInterrupt         Timer32_unregisterInterrupt

//*****************************************************************************
//
// Macros for the UART API.
//
//*****************************************************************************
#define MAP_UART_initModule                     ROM_MAP(UART_initModule)
#define MAP_UART_transmitData                   ROM_MAP(UART_transmitData)
#define MAP_UART_enableModule                   ROM_MAP(UART_enableModule)
#define MAP_UART_disableModule                  ROM_MAP(UART_disableModule)
#define MAP_UART_queryStatusFlags               ROM_MAP(UART_queryStatusFlags)
#define MAP_UART_setDormant                     ROM_MAP(UART_setDormant)
#define MAP_UART_resetDormant                   ROM_MAP(UART_resetDormant)
#define MAP_UART_transmitAddress                ROM_MAP(UART_transmitAddress)
#define MAP_UART_transmitBreak                  ROM_MAP(UART_transmitBreak)
#define MAP_UART_getReceiveBufferAddressForDMA  ROM_MAP(UART_getReceiveBufferAddressForDMA)
#define MAP_UART_getTransmitBufferAddressForDMA ROM_MAP(UART_getTransmitBufferAddressForDMA)
#define MAP_UART_selectDeglitchTime             ROM_MAP(UART_selectDeglitchTime)
#define MAP_UART_enableInterrupt                ROM_MAP(UART_enableInterrupt)
#define MAP_UART_disableInterrupt               ROM_MAP(UART_disableInterrupt)
#define MAP_UART_getInterruptStatus             ROM_MAP(UART_getInterruptStatus)
#define MAP_UART_clearInterruptFlag             ROM_MAP(UART_clearInterruptFlag)
#define MAP_UART_receiveData                    ROM_MAP(UART_receiveData)
#define MAP_UART_getEnabledInterruptStatus      ROM_MAP(UART_getEnabledInterruptStatus)
//#define MAP_UART_registerInterrupt              UART_registerInterrupt
//#define MAP_UART_unregisterInterrupt            UART_unregisterInterrupt

//*****************************************************************************
//
// Macros for the WDT API.
//
//*****************************************************************************
#define MAP_WDT_A_holdTimer                     ROM_MAP(WDT_A_holdTimer)
#define MAP_WDT_A_startTimer                    ROM_MAP(WDT_A_startTimer)
#define MAP_WDT_A_clearTimer                    ROM_MAP(WDT_A_clearTimer)
#define MAP_WDT_A_initWatchdogTimer             ROM_MAP(WDT_A_initWatchdogTimer)
#define MAP_WDT_A_initIntervalTimer             ROM_MAP(WDT_A_initIntervalTimer)
//#define MAP_WDT_A_registerInterrupt             WDT_A_registerInterrupt
//#define MAP_WDT_A_unregisterInterrupt           WDT_A_unregisterInterrupt
#define MAP_WDT_A_setPasswordViolationReset     ROM_MAP(WDT_A_setPasswordViolationReset)
#define MAP_WDT_A_setTimeoutReset               ROM_MAP(WDT_A_setTimeoutReset)

#endif          // __ROM_MAP_H__
