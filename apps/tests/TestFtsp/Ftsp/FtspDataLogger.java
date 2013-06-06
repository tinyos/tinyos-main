/*                  tab:4
 * Copyright (c) 2000-2003 The Regents of the University  of California.
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

public class FtspDataLogger implements MessageListener {
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
                        mote.registerListener(new TestFtspMsg(), this);
                        System.out.println("Connection ok!");
                }
                catch(Exception e) {
                        e.printStackTrace();
                        System.exit(2);
                }
        }
        PrintStream outReport = null;

        public FtspDataLogger() {
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
                        System.out.println("FtspDataLogger.FtspDataLogger(): "+e.toString());
                }
        }

        public void writeReprot(TestFtspMsg tspr)
        {
                String foo = (System.currentTimeMillis()
                		+" "+tspr.get_src_addr()+" "+tspr.get_counter()
                        +" "+tspr.get_global_rx_timestamp()+" "+tspr.get_is_synced());
                outReport.println(foo);
                System.out.println(foo);
                outReport.flush();
        }

        public void writeFullReprot(TestFtspMsg tspr)
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
                if (msg instanceof TestFtspMsg)
                        //writeFullReprot((TestFtspMsg)msg);
                        writeReprot((TestFtspMsg)msg);
        }

        /* Just start the app... */
        public static void main(String[] args)
        {
                new FtspDataLogger();
        }
}