/*
 * "Copyright (c) 2008, 2009 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

#include "vty.h"

void init_argv(char *cmd, int len, char **argv, int *argc) {
  int inArg = 0;
  *argc = 0;
  while (len > 0 && *argc < N_ARGS) {
    if (*cmd == ' ' || *cmd == '\n' || 
        *cmd == '\t' || *cmd == '\0' || 
        *cmd == '\r' || *cmd == '\4' ||
        len == 1){
      if (inArg) {
        *argc = *argc + 1;
        inArg = 0;
        *cmd = '\0';
      }
    } else if (!inArg) {
      argv[*argc] = cmd;
        inArg = 1;
    }
    cmd ++;
    len --;
  }
}
