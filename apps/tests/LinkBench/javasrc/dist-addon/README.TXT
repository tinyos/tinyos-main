Howto run the LinkBench application
-----------------------------------

I. Windows users:
---------------------
   1, You should start a command line tool by clicking on Start->Run and entering cmd.exe .
   2, Then, navigate to the directory where this (README.TXT) file is located.
   3, Type the following in the command line for more instructions :
      java -jar linkbench.jar --help

II. Unix/Linux users:
---------------------
   1, Open a terminal (xterm, gnome-terminal, etc) and navigate to the directory where this 
      (README.TXT) file is located.
  
   2/a, Type the following in the command line for more instructions :
          java -jar linkbench.jar --help

   2/b, First make the bmark.sh file executable, and start the application after :
          chmod u+x linkbench.sh
          ./linkbench.sh --help
          
Troubleshooting:
----------------
   1, Problem : The linkbench.jar file does not exist.
      Solution: Maybe you forgot to compile the sources, or deleted that file. You should re-compile the Java
                sources (and possibly the TinyOS sources). For instructions, see the README file in the root 
                directory of the application.
                
   2, Problem : There is no such command as 'java'.
      Solution: You must install the Java SDK 1.6 to be able to compile and run this application. Once you
                have it, follow the instruction in the README file in the root directory of the application.
   
   3, Problem : I have read all READMEs, instructions, but I cannot overcome my specific problem.
      Solution: Write me an email (verkri@inf.u-szeged.hu) describing your system ( platform, JDK version,
                TinyOS version, where you have installed the application, etc).
