/*
 * Copyright (c) 2012 Martin Cerveny
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Generic table reader.
 *
 * @author Martin Cerveny
 */

interface TableReader {

	/**
	 * Set "row" index to first row
	 * 
	 * @param row pointer to "row" index
	 * @param rowptrsize size of  "row" index 
	 * @return SUCCESS - *row contains valid "row" index, ESIZE - rowptrsize too small to hold index, ELAST - table is empty
	 */
	command error_t rowFirst(void * row, uint8_t rowptrsize);

	/**
	 * Set "row" index to next row
	 *
	 * @param row pointer to "row" index (contains previous valid "row" index)
	 * @param rowptrsize size of  "row" index 
	 * @return SUCCESS - *row contains valid "row" index, ESIZE - rowptrsize too small to hold index, ELAST - no more rows
	 */
	command error_t rowNext(void * row, uint8_t rowptrsize);

	/**
	 *
	 * @param row pointer to "row" index 
	 * @param colid id of column to read 
	 * @param col pointer to receive data of column
	 * @param colptrsize size of data 
	 * @return SUCCESS - *col contains valid data, ESIZE - colptrsize too small to hold data, FAIL - row not found (invalid "row" index) or invalid colid
	 */
	command error_t colRead(void * row, uint8_t col_id, void * col, uint8_t colptrsize);
}