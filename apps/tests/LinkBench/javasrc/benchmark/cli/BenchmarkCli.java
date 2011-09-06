/** Copyright (c) 2010, University of Szeged
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions
* are met:
*
* - Redistributions of source code must retain the above copyright
* notice, this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above
* copyright notice, this list of conditions and the following
* disclaimer in the documentation and/or other materials provided
* with the distribution.
* - Neither the name of University of Szeged nor the names of its
* contributors may be used to endorse or promote products derived
* from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
* FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
* COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
* INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
* HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
* STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
* OF THE POSSIBILITY OF SUCH DAMAGE.
*
* Author: Krisztian Veress
*         veresskrisztian@gmail.com
*/

package benchmark.cli;

import benchmark.common.*;
import java.io.FileNotFoundException;
import java.io.PrintStream;

import org.apache.commons.cli.*;

public class BenchmarkCli {

  private BenchmarkController ctrl;

  public BenchmarkCli() {
    ctrl = new BenchmarkController();
  }

  /**
   * Print out the help information
   */
  public static void printHelp(final Options opt) {
    
    HelpFormatter f = new HelpFormatter();
    System.out.println("Usage scenarios:");

    Options opt0 = new Options();
    opt0.addOption(opt.getOption("h"));
    System.out.println();
    System.out.println("1. Print help information.");
    System.out.println("--------------------------------------------------------------------");
    f.printHelp(150, "linkbench", "", opt0, "", true);

    // Batch - usage
    Options opt1 = new Options();
    opt1.addOption(opt.getOption("F"));
    opt1.addOption(opt.getOption("o"));
    opt1.addOption(opt.getOption("tossim"));
    System.out.println();
    System.out.println("2. Running benchmarks with pre-defined configurations in batch mode.");
    System.out.println("--------------------------------------------------------------------");
    f.printHelp(150, "linkbench", "", opt1, "", true);
    
    // Reset - usage
    Options opt2 = new Options();
    opt2.addOption(opt.getOption("r"));
    opt2.addOption(opt.getOption("tossim"));
    System.out.println();
    System.out.println("3. Reset all motes.");
    System.out.println("--------------------------------------------------------------------");
    f.printHelp(150, "linkbench", "", opt2, "", true);
    
    // Download - usage
    Options opt3 = new Options();
    opt3.addOption(opt.getOption("dload"));
    opt3.addOption(opt.getOption("mc"));
    opt3.addOption(opt.getOption("xml"));
    System.out.println();
    System.out.println("4. Only download data from the motes (if data available).");
    System.out.println("--------------------------------------------------------------------");
    f.printHelp(150, "linkbench", "", opt3, "", true);
    
    // Command-line usage
    Options opt4 = new Options();
    opt4.addOption(opt.getOption("b"));
    opt4.addOption(opt.getOption("t"));
    opt4.addOption(opt.getOption("rs"));
    opt4.addOption(opt.getOption("lc"));
    opt4.addOption(opt.getOption("tr"));
    opt4.addOption(opt.getOption("ack"));
    opt4.addOption(opt.getOption("bcast"));
    opt4.addOption(opt.getOption("xml"));
    opt4.addOption(opt.getOption("mac"));
    opt4.addOption(opt.getOption("mc"));
    opt4.addOption(opt.getOption("tossim"));
    System.out.println();
    System.out.println("5. Running a specific benchmark with command-line arguments");
    System.out.println("--------------------------------------------------------------------");
    f.printHelp(88, "linkbench", "", opt4, "", true);
    
  }

  /**
   * Construct the Options opt appropriate for
   * the Apache CLI command-line interpreter.
   */
  private static void initOptions(Options opt) {

    // Batch related options
    Option batchfile = OptionBuilder
            .withArgName("file")
            .hasArg()
            .withDescription("The batch file with configuration parameters for multiple benchmark runs")
            .create("F");

    Option batchoutput = OptionBuilder
            .withArgName("file")
            .hasArg()
            .withDescription("The output XML file name. [default: results.xml]")
            .create("o");

    // Problem id option
    Option problem = OptionBuilder
            .withArgName("number")
            .hasArg()
            .withDescription("The benchmark to be used")
            .withLongOpt("benchmark")
            .create("b");

    // Time- related options
    Option randomstart = OptionBuilder
            .withArgName("number")
            .hasArg()
            .withDescription("Random start delay in millisecs. [default: " +
              BenchmarkCommons.DEF_RANDSTART + " msec]")
            .withLongOpt("randomstart")
            .create("rs");

    Option runtime = OptionBuilder
            .withArgName("normal")
            .hasArg()
            .withDescription("The benchmark running time in millisecs. " +
              "[default: " + BenchmarkCommons.DEF_RUNTIME + " msec]")
            .withLongOpt("time")
            .create("t");

    Option lastchance = OptionBuilder
            .withArgName("number")
            .hasArg()
            .withDescription("The grace time period after test completion for" +
              " last-chance reception. [default : " +
              BenchmarkCommons.DEF_LASTCHANCE + " msec]")
            .withLongOpt("lastchance")
            .create("lc");

    Option trtimers = OptionBuilder
            .withArgName("timer config list")
            .hasArg()
            .withDescription("Trigger timer configuration " +
              "index:isoneshot,maxrandomdelay,period.  [default : 1:" +
              TimerParser.DEF_TIMER_ONESHOT + "," +
              TimerParser.DEF_TIMER_DELAY + "," +
              TimerParser.DEF_TIMER_PERIOD + " ]")
            .withLongOpt("triggers")
            .create("tr");

    Option mac = OptionBuilder
            .withArgName("MAC params")
            .hasArg()
            .withDescription("MAC along with parameters:  mactype:param1,param2,...,paramN [ mactypes: lpl,plink ]")
            .create("mac");

    Option xml = OptionBuilder
            .withArgName("file")
            .hasArg()
            .withDescription("Produce xml output")
            .create("xml");

    Option mcount = OptionBuilder
            .withArgName("number")
            .hasArg()
            .withDescription("How many motes are in the network.")
            .withLongOpt("motecount")
            .create("mc");


    Option reset = OptionBuilder
            .withArgName("moteid")
            .hasArg()
            .withDescription("Reset the mote. If moteid set to 0, all motes are reset.")
            .withLongOpt("reset")
            .create("r");


    opt.addOption(problem);
    opt.addOption(randomstart);
    opt.addOption(runtime);
    opt.addOption(lastchance);
    opt.addOption(xml);
    opt.addOption(mac);
    opt.addOption(mcount);
    opt.addOption(trtimers);
    opt.addOption(batchfile);
    opt.addOption(batchoutput);
    opt.addOption(reset);

    opt.addOption("h", "help", false, "Print help for this application");
    opt.addOption("ack", false, "Force acknowledgements. [default : false]");
    opt.addOption("bcast", "broadcast", false, "Force broadcasting. [default : false]");
    opt.addOption("dload", "download", false, "Only download data from motes.");

    opt.addOption("tossim", false, "MUST be used if TOSSIM is in use.");

  }

  public boolean doReset(final boolean is_tossim, final int moteid) {
    if ( moteid == 0 )
        System.out.print("> Reset all motes ...     ");
    else
        System.out.print(String.format("> Reset mote %2d ...       ",moteid));
        
    try {
      if ( moteid == 0 )
          ctrl.reset(!is_tossim);
      else
          ctrl.resetMote(moteid);
          
      System.out.println("OK");
      return true;
    } catch (BenchmarkController.MessageSendException ex) {
      System.out.println("FAIL");
      return false;
    }
  }

  public boolean doSync() {
    System.out.print("> Synchronize motes ...   ");
    try {
      ctrl.syncAll();
      System.out.println("OK");
      return true;
    } catch (BenchmarkController.CommunicationException ex) {
      System.out.println("FAIL");
      System.out.println("  " + ex.getMessage() );
      return false;
    }
  }

  public boolean doDownloadStat(final int maxMoteId) {
    System.out.print("> Downloading data ...    ");
    try {
      ctrl.download_stat();
      System.out.println("OK");
      return true;
    } catch (BenchmarkController.CommunicationException ex) {
      System.out.println("FAIL");
      System.out.println("  " + ex.getMessage() );
      return false;
    }
  }

  public boolean doDownloadProfile(final int maxMoteId) {
    System.out.print("> Downloading profile ... ");
    try {
      ctrl.download_profile();
      System.out.println("OK");
      return true;
    } catch (BenchmarkController.CommunicationException ex) {
      System.out.println("FAIL");
      System.out.println("  " + ex.getMessage() );
      return false;
    }
  }

  public boolean doSetup(final SetupT st, final boolean is_tossim) {
    System.out.print("> Setting up motes ...    ");
    try {
      ctrl.setup(st,!is_tossim);
      System.out.println("OK");
      return true;
    } catch (BenchmarkController.MessageSendException ex) {
      System.out.println("FAIL");
      return false;
    }
  }

  public boolean doRun(final boolean is_tossim) {
    System.out.print("> Running benchmark ...   ");
    try {
      ctrl.run(!is_tossim);
      System.out.println("OK");
      return true;
    } catch (BenchmarkController.MessageSendException ex) {
      System.out.println("FAIL");
      return false;
    }
  }

  public void doPrintXml(final String filename) {
    PrintStream ps;
    try {
      ps = new PrintStream(filename);
      ps.println(BenchmarkCommons.xmlHeader());
      this.ctrl.getResults().printXml(ps);
      ps.println(BenchmarkCommons.xmlFooter());
      ps.close();
    } catch (FileNotFoundException ex) {
      System.out.println("Cannot open " + filename + " for writing!");
    } 
  }

  public void doPrint() {
    this.ctrl.getResults().print(System.out);
  }

	public static void main (String[] args)
  {
    try {
      // Make the options and parse it
      Options opt = new Options();
      BenchmarkCli.initOptions(opt);
      
      BasicParser parser = new BasicParser();
      CommandLine cl = parser.parse(opt, args);

      // Help request -- if present, do nothing else.
      // -----------------------------------------------------------------------
      if ( cl.hasOption('h') ) {
        BenchmarkCli.printHelp(opt);
        System.exit(0);
      }
      // Reset request -- if present, do nothing else.
      // -----------------------------------------------------------------------
      else if ( cl. hasOption('r') ) {
        BenchmarkCli cli = new BenchmarkCli();
        if ( cli.doReset( cl.hasOption("tossim"), Integer.parseInt(cl.getOptionValue("r")) ) )
            System.exit(0);
        else
            System.exit(1);
      }
      // Download request
      // -----------------------------------------------------------------------
      else if ( cl.hasOption("dload") ) {
      
        int maxmoteid = cl.hasOption("mc")
                                ? Integer.parseInt(cl.getOptionValue("mc")) 
                                : 1;
        if ( maxmoteid < 1 )
          throw new MissingOptionException("Invalid number of motes specified!");

        // Do what needs to be done
        BenchmarkCli cli = new BenchmarkCli();
        if ( cli.doSync() &&
             cli.doDownloadStat(maxmoteid) &&
             cli.doDownloadProfile(maxmoteid) )
        {
          // Dump results to XML or STDOUT
          if ( cl.hasOption("xml") )
            cli.doPrintXml(cl.getOptionValue("xml"));
          else
            cli.doPrint();

          System.exit(0);
        } else
          System.exit(1);
      }
      // Batch request
      // -----------------------------------------------------------------------
      else if ( cl.hasOption('F') ) {
        String bfile = cl.getOptionValue('F');
        String ofile = cl.hasOption('o') ? cl.getOptionValue('o') : "results.xml";
        
        BenchmarkBatch rbb = new BenchmarkBatch(ofile);
        if ( rbb.parse(bfile) && rbb.run( cl.hasOption("tossim") ) ) {
          System.exit(0);
        } else
          System.exit(1);
      }
      // Command line control
      // -----------------------------------------------------------------------
      else if ( cl.hasOption('b') ) {
        
        short problemidx = (short)Integer.parseInt(cl.getOptionValue('b'));
        if ( problemidx < 0 )
          throw new MissingOptionException("Invalid problem specified!");
  
        int startdelay = cl.hasOption("rs") 
                                ? Integer.parseInt(cl.getOptionValue("rs")) 
                                : BenchmarkCommons.DEF_RANDSTART;
        if ( startdelay < 0 )
            throw new MissingOptionException("Invalid random start time specified!");

        int runtimemsec = cl.hasOption('t')
                                ? Integer.parseInt(cl.getOptionValue("t"))
                                : BenchmarkCommons.DEF_RUNTIME;
        if ( runtimemsec <= 0 )
          throw new MissingOptionException("Invalid runtime specified!");

        int lchance = cl.hasOption("lc") 
                                ? Integer.parseInt(cl.getOptionValue("lc")) 
                                : BenchmarkCommons.DEF_LASTCHANCE;
        if ( lchance < 0 )
          throw new MissingOptionException("Invalid last chance time specified!");        

        int maxmoteid = cl.hasOption("mc")
                                ? Integer.parseInt(cl.getOptionValue("mc")) 
                                : 1;
        if ( maxmoteid < 1 )
          throw new MissingOptionException("Invalid number of motes specified!");
 
        // Trigger timer parsing
        TimerParser tp = new TimerParser(BenchmarkStatic.MAX_TIMER_COUNT);
        if ( cl.hasOption("tr") ) {
          for ( String s : cl.getOptionValues("tr") ) {
            tp.parse(s);
          }
        }

        // Trigger timer parsing
        MacParser mac = new MacParser();
        if ( cl.hasOption("mac") ) {
          for ( String s : cl.getOptionValues("mac") ) {
            mac.parse(s);
          }
        }

        // Mac protocols may have flags set
        short flags = mac.getFlags();
        if ( cl.hasOption("ack") )
          flags |= BenchmarkStatic.GLOBAL_USE_ACK;
        if ( cl.hasOption("bcast") )
          flags |= BenchmarkStatic.GLOBAL_USE_BCAST;
        
        // Create the setup structure
        SetupT st = new SetupT();
        st.set_problem_idx(problemidx);
        st.set_pre_run_msec(startdelay);
        st.set_runtime_msec(runtimemsec);
        st.set_post_run_msec(lchance);
        st.set_flags(flags);
        st.set_timers_isoneshot(tp.getIos());
        st.set_timers_delay(tp.getDelay());
        st.set_timers_period_msec(tp.getPeriod());
        st.set_mac_setup(mac.getMacParams());

        // Do what needs to be done
        boolean tossim = cl.hasOption("tossim");
        BenchmarkCli cli = new BenchmarkCli();
        if (cli.doReset(tossim,0)            &&
            cli.doSetup(st,tossim)           &&
            cli.doSync()                     &&
            cli.doRun(tossim)                &&
            cli.doDownloadStat(maxmoteid)    &&
            cli.doDownloadProfile(maxmoteid) )
        {

          // Dump results to XML or STDOUT
          if ( cl.hasOption("xml") )
            cli.doPrintXml(cl.getOptionValue("xml"));
          else
            cli.doPrint();
          
          System.exit(0);
        } else {
          System.exit(1);
        }
      } else {
        throw new MissingOptionException("Invalid program arguments, use --help for help!");
      }
    } catch (Exception e) {
      System.err.println();
      System.err.println("Error : " + e.getMessage());
      System.err.println();
      System.exit(1);
    } 
  }
}
