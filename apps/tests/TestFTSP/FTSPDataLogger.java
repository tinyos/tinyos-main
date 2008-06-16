/*                  tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.
 * All rights reserved.
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
 * Copyright (c) 2002-2007 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA,
 * 94704.  Attention:  Intel License Inquiry.
 */


/**
 * @author Brano Kusy
 */

import java.io.FileOutputStream;
import java.io.PrintStream;
import net.tinyos.message.*;
import net.tinyos.util.*;

public class FTSPDataLogger implements MessageListener {
        public class RunWhenShuttingDown extends Thread {
                public void run()
                {
                        System.out.println("Control-C caught. Shutting down...");
                        if (outReport!=null)
                        outReport.close();
                }
        }

  MoteIF mote;    // For talking to the antitheft root node

        void connect()
        {
                try {
                        mote = new MoteIF(PrintStreamMessenger.err);
                        mote.registerListener(new TestFTSPMsg(), this);
                        System.out.println("Connection ok!");
                }
                catch(Exception e) {
                        e.printStackTrace();
                        System.exit(2);
                }
        }
        PrintStream outReport = null;

        public FTSPDataLogger() {
                connect();
                Runtime.getRuntime().addShutdownHook(new RunWhenShuttingDown());
                String name=""+System.currentTimeMillis();
                try
                {
                        outReport = new PrintStream(new FileOutputStream(name+".report"));
                        outReport.println("#[JAVA_TIME] [NODE_ID] [SEQ_NUM] [GLOB_TIME] [IS_TIME_VALID]");
                }
                catch (Exception e)
                {
                        System.out.println("FTSPDataLogger.FTSPDataLogger(): "+e.toString());
                }
        }

        public void writeReprot(TestFTSPMsg tspr)
        {
                String foo = (System.currentTimeMillis()
                		+" "+tspr.get_src_addr()+" "+tspr.get_counter()
                        +" "+tspr.get_global_rx_timestamp()+" "+tspr.get_is_synced());
                outReport.println(foo);
                System.out.println(foo);
                outReport.flush();
        }

        public void writeFullReprot(TestFTSPMsg tspr)
        {
                String foo = (System.currentTimeMillis()
                		+" "+tspr.get_src_addr()
                        +" "+tspr.get_counter()
                        +" "+tspr.get_local_rx_timestamp()
                        +" "+tspr.get_global_rx_timestamp()
                        +" "+tspr.get_skew_times_1000000()
                        +" "+tspr.get_is_synced()
                        +" "+tspr.get_ftsp_root_addr()
                        +" "+tspr.get_ftsp_seq()
                        +" "+tspr.get_ftsp_table_entries());
                outReport.println(foo);
                System.out.println(foo);
                outReport.flush();
        }

        public void messageReceived(int dest_addr, Message msg)
        {
                if (msg instanceof TestFTSPMsg)
                        //writeFullReprot((TestFTSPMsg)msg);
                        writeReprot((TestFTSPMsg)msg);
        }

        /* Just start the app... */
        public static void main(String[] args)
        {
                new FTSPDataLogger();
        }
}