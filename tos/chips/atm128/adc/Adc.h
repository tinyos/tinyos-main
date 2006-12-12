/* $Id: Adc.h,v 1.4 2006-12-12 18:23:03 vlahan Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/*
 * @author David Gay
 */
#ifndef ADC_H
#define ADC_H

#include "Atm128Adc.h"

/* Read and ReadNow share client ids */
#define UQ_ADC_READ "adc.read"
#define UQ_ADC_READNOW UQ_ADC_READ
#define UQ_ADC_READSTREAM "adc.readstream"

#endif
