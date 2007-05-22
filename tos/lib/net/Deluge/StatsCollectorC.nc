/* Copyright (c) 2007 Johns Hopkins University.
*  All rights reserved.
*
*  Permission to use, copy, modify, and distribute this software and its
*  documentation for any purpose, without fee, and without written
*  agreement is hereby granted, provided that the above copyright
*  notice, the (updated) modification history and the author appear in
*  all copies of this source code.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * @author Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
 * @author Razvan Musaloiu-E. <razvanm@cs.jhu.edu>
 */

configuration StatsCollectorC
{
  provides {
    interface StatsCollector;
  }
}

implementation
{
  components GlobalsC, StatsCollectorP,
    new CounterToLocalTimeC(TMilli),
#ifdef TOSSIM
    HilTimerMilliC,
#else
    new TransformCounterC(TMilli, uint32_t, T32khz, uint16_t, 5, uint32_t) as Transform,
    Msp430Counter32khzC,
#endif
    new TimerMilliC() as Timer;

#ifdef TOSSIM
    StatsCollectorP.LocalTime -> HilTimerMilliC;
#else
  CounterToLocalTimeC.Counter -> Transform;
  Transform.CounterFrom -> Msp430Counter32khzC;
  StatsCollectorP.LocalTime -> CounterToLocalTimeC;
#endif
  
  StatsCollectorP.Globals -> GlobalsC.Globals;
  StatsCollector = StatsCollectorP.StatsCollector;
  StatsCollectorP.Timer -> Timer;
  
  components SerialStarterC, new SerialAMSenderC(0);
  StatsCollectorP.AMSend -> SerialAMSenderC;
}
