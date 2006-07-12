/****************************************************************************
 *       
 * "Copyright (c) 2006 The University of Southern California"  
 * All rights reserved.   
 *       
 * Permission to use, copy, modify, and distribute all components of 
 * this software and its documentation for any purpose, without fee, 
 * and without written agreement is hereby granted, 
 * provided that the above copyright notice, the following two paragraphs 
 * and the author names appear in all copies of this software.  
 *     
 * NO REPRESENTATIONS ARE MADE ABOUT THE SUITABILITY OF THE SOFTWARE FOR ANY  
 * PURPOSE. IT IS PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY.  
 *     
 * Neither the software developers, the Autonomous Network Research Group  
 * (ANRG), or USC, shall be liable for any damages suffered from using this  
 * software.   
 *     
 * Author:  Marco Zuniga, Avinash Sridharan
 * Director: Prof. Bhaskar Krishnamachari
 * Autonomous Networks Reseach Group, University of Southern California
 * http://ceng.usc.edu/~anrg
 * Contact: marcozun@usc.edu
 *
 * Date last modified: 2004/07/02 marcozun
 * Date last modified: 2006/02/05 asridhar
 *       
 *     
 * Description: This file contains the code that generates the
 * gains for all links in the network and noise floor values for
 * all nodes.
 *     
 ****************************************************************************/

package net.tinyos.sim;

import java.io.*;
import java.util.*;
import java.text.DecimalFormat;

/**
 * Stores channel, radio and topology parameters provided by user
 * through the configuration file.
 */

class InputVariables {

  // Channel parameters
  double n;  // path loss exponent
  double sigma; // standard deviation shadowing variance
  double  d0;  // reference distance
  double pld0; // power decay for reference distance d0
  // Radio parameters
  double pn;  // radio noise floor
  double wgn; // white gaussian noise 
  // Covariance Matrix for hardware variance
  double  s11;
  double  s12;
  double  s21;
  double  s22;
  // Topology parameters
  int  numNodes; // number of nodes
  int  top;  // topology option
  double grid;  // grid unit
  double Xterr;  // X dimension of Terrain
  double Yterr;  // Y dimension of Terrain
  String topFile; // file name with nodes' coordinates (user-defined)
  // data directly derived from configuration file
  double area;  // area of the terrain


  InputVariables() { // Constructor, loading default values
    n  = 3;
    sigma = 3;
    pld0 = 55;
    d0  = 1;
    pn  = -105;
    wgn  = 4;
    s11  = 3.7;
    s12  = -3.3;
    s21  = -3.3;
    s22  = 6.0;
    numNodes= 0;
    top  = 0;
    Xterr = 0;
    Yterr = 0;
    topFile = "";
    area  = 0;
  }

}

/**
 * Stores nodes' coordinates, link gains and noise floor values for a given topology 
 */

class OutputVariables {

  double[] nodePosX;  // X coordinate
  double[] nodePosY;  // Y coordinate
  double[] outputpowervar; // output power
  double[] noisefloor;  // noise floor
  double[][]  linkGain;  // link gain

  OutputVariables(int numNodes) { // Constructor

    nodePosX = new double[numNodes];
    nodePosY = new double[numNodes];
    outputpowervar = new double[numNodes];
    noisefloor  = new double[numNodes];
    linkGain = new double[numNodes][numNodes];
  }

}


/**
 * Simulates gains for all links of a specific topology, and noise
 * floor values for all nodes.  <p>The link gain between nodes A and B
 * is defined as the output power of A minus the pathloss between A
 * and B.  The user specifies the desired channel, radio and topology
 * parameters through a configuration file.  The configuration file is
 * provided as a command line argument: <tt>$ java LinkLayerModel
 * configurationFileName</tt>, and the link gains and noise floor
 * values are provided on a file called <tt>linkgain.out</tt>.
 */

public class LinkLayerModel  {

  public static void main (String args[]) {
    if (args.length != 1) {
      usage();
      return;
    }
    // variable that contains input parameters
    InputVariables inVar = new InputVariables();
    // parse configuration file and store parameters in inVar
    readFile  ( args[0], inVar );
    // if user defined topology (TOPOLOGY = 4), obtain number of nodes
    if (inVar.top == 4) {
      obtainNumNodes (inVar.topFile, inVar);
    }
    // variable that contains output data
    OutputVariables outVar = new OutputVariables( inVar.numNodes ); 
    // create topology
    System.out.print("Topology ...\t\t\t");
    obtainTopology ( inVar, outVar );
    System.out.println("done");
    // obtain ouput power and noise floor for all nodes
    System.out.print("Radio Pt and Pn ...\t\t");
    obtainRadioPtPn ( inVar, outVar );
    System.out.println("done");
    // obtain link gains 
    System.out.print("Links Gain .....\t\t");
    obtainLinkGain ( inVar, outVar);
    System.out.println("done");
    // print linkgain.out (link gains and noise floor) and topology.out (x/y coordinates)
    System.out.print("Printing Output File ...\t");
    printFile  ( inVar, outVar);
    System.out.println("done");
  }


  /**
   * Parses configuration file provided by user and stores specified
   * parameters
   *
   * @param inputFile configuration file containing channel, radio and
   * deployment parameters
   * @param  var   class that stores input parameters from configuration file
   * @return    true if file parsing was performed without errors
   */

  protected static boolean readFile (String inputFile, InputVariables var )
  {

    String thisLine;
    StringTokenizer st;

    // open configuration file
    try {
      FileInputStream fin =  new FileInputStream(inputFile);
      try {
        BufferedReader myInput = new BufferedReader(new InputStreamReader(fin));
        try {
          // parse the file
          while ((thisLine = myInput.readLine()) != null) {

            if ( !thisLine.equals("") && !thisLine.startsWith("%") ) {
              st = new StringTokenizer(thisLine, " =;\t");
              String key = st.nextToken();
              String value = st.nextToken();

              if ( key.equals("PATH_LOSS_EXPONENT")) {
                var.n = Double.valueOf(value).doubleValue();
                if (var.n < 0) {
                  System.out.println("Error: value of PATH_LOSS_EXPONENT must be positive");
                  System.exit(1);
                }
              }
              else if ( key.equals("SHADOWING_STANDARD_DEVIATION")) {
                var.sigma = Double.valueOf(value).doubleValue();
                if (var.sigma < 0) {
                  System.out.println("Error: value of SHADOWING_STANDARD_DEVIATION must be positive");
                  System.exit(1);
                }
              }
              else if ( key.equals("PL_D0")) {
                var.pld0 = Double.valueOf(value).doubleValue();
                if (var.pld0 < 0) {
                  System.out.println("Error: value of PL_D0 must be positive");
                  System.exit(1);
                }
              }
              else if ( key.equals("D0")) {
                var.d0 = Double.valueOf(value).doubleValue();
                if (var.d0 <= 0) {
                  System.out.println("Error: value of D0 must be greater than zero");
                  System.exit(1);
                }
              }
              else if ( key.equals("NOISE_FLOOR")) {
                var.pn = Double.valueOf(value).doubleValue();
              }
              else if ( key.equals("WHITE_GAUSSIAN_NOISE")) {
                var.wgn = Double.valueOf(value).doubleValue();
                if (var.wgn < 0) {
                  System.out.println("Error: value of WHITE_GAUSSIAN_NOISE must be greater equal than 0");
                  System.exit(1);
                }
              }
              else if ( key.equals("S11")) {
                var.s11 = Double.valueOf(value).doubleValue();
                if (var.s11 < 0) {
                  System.out.println("Error: value of S11 must be greater equal than 0");
                  System.exit(1);
                }
              }
              else if ( key.equals("S12")) {
                var.s12 = Double.valueOf(value).doubleValue();
              }
              else if ( key.equals("S21")) {
                var.s21 = Double.valueOf(value).doubleValue();
              }
              else if ( key.equals("S22")) {
                var.s22 = Double.valueOf(value).doubleValue();
                if (var.s22 < 0) {
                  System.out.println("Error: value of S22 must be greater equal than 0");
                  System.exit(1);
                }
              }
              else if ( key.equals("NUMBER_OF_NODES")) {
                var.numNodes = Integer.parseInt(value);
                if (var.numNodes <= 0) {
                  System.out.println("Error: value of NUMBER_OF_NODES must be positive");
                  System.exit(1);
                }
              } 
              else if ( key.equals("TOPOLOGY")) {
                var.top = Integer.parseInt(value);
                if ( (var.top < 1) | (var.top > 4) ) {
                  System.out.println("Error: value of TOPOLOGY must be between 1 and 4");
                  System.exit(1);
                }
              }
              else if ( key.equals("GRID_UNIT")) {
                var.grid = Double.valueOf(value).doubleValue();
              }
              else if ( key.equals("TOPOLOGY_FILE")) {
                var.topFile = value;
              }
              else if ( key.equals("TERRAIN_DIMENSIONS_X")) {
                var.Xterr = Double.valueOf(value).doubleValue();
                if (var.Xterr < 0) {
                  System.out.println("Error: value of TERRAIN_DIMENSIONS_X must be positive");
                  System.exit(1);
                }
              } 
              else if ( key.equals("TERRAIN_DIMENSIONS_Y")) {
                var.Yterr = Double.valueOf(value).doubleValue();
                if (var.Yterr < 0) {
                  System.out.println("Error: value of TERRAIN_DIMENSIONS_Y must be positive");
                  System.exit(1);
                }
                var.area = var.Xterr * var.Yterr;
              } 
              else {
                System.out.println("Error: undefined parameter " + key + ", please review your configuration file");
                System.exit(1);
              } 
            }
          } // end while loop
        }
        catch (Exception e) {
          System.out.println("Error1: " + e);
          System.exit(1);
        }

      } // end try
      catch (Exception e) {
        System.out.println("Error2: " + e);
        System.exit(1);
      }

    } // end try
    catch (Exception e) {
      System.out.println("Error Failed to Open file " + inputFile + e);
      System.exit(1);
    }

    return true;

  }

  /**
   * Obtain X and Y coordinates for all nodes. Different type of topologies are available 
   * (grid, uniform, random, user-defined)
   * 
   * @param inVar class that contains input parameters from configuration file
   * @param outVar class that stores x/y coordinates
   * @return true if X/Y coordinates are obtained without errors
   */

  protected static boolean obtainTopology( InputVariables  inVar, 
                                           OutputVariables outVar )
  {

    Random rand = new Random();
    int i, j;
    int sqrtNumNodes, nodesX;
    double cellArea, cellLength;
    double Xdist, Ydist, dist;
    boolean wrongPlacement;

    if (inVar.numNodes <= 0) {
      System.out.println("\nError: value of NUMBER_OF_NODES must be positive");
      System.exit(1);
    }

    switch (inVar.top) {
    case 1: // GRID
      if (inVar.grid < inVar.d0) {
        System.out.println("\nError: value of GRID_UNIT must be equal or greater than D0");
        System.exit(1);
      }
      sqrtNumNodes = (int) Math.sqrt(inVar.numNodes);
      if ( sqrtNumNodes != Math.sqrt(inVar.numNodes) ) {
        System.out.println ("\nError: on GRID topology, NUMBER_OF_NODES should be the square of a natural number");
        System.exit(1);
      }
      for (i = 0; i < inVar.numNodes; i = i+1) {
        outVar.nodePosX[i] = (i%sqrtNumNodes) * inVar.grid;
        outVar.nodePosY[i] = (i/sqrtNumNodes) * inVar.grid;
      }
      break;
    case 2: // UNIFORM
      sqrtNumNodes = (int) Math.sqrt(inVar.numNodes);
      if ( sqrtNumNodes != Math.sqrt(inVar.numNodes) ) {
        System.out.println ("\nError: on UNIFORM topology, NUMBER_OF_NODES should be the square of a natural number");
        System.exit(1);
      }
      if ( (inVar.Xterr <= 0) | (inVar.Yterr <= 0) ) {
        System.out.println("\nError: values of TERRAIN_DIMENSIONS must be positive");
        System.exit(1);
      }
      if ( inVar.Xterr != inVar.Yterr ) {
        System.out.println("\nError: values of TERRAIN_DIMENSIONS_X and TERRAIN_DIMENSIONS_Y must be equal");
        System.exit(1);
      }
      cellLength = Math.sqrt ( inVar.area / inVar.numNodes );
      nodesX = sqrtNumNodes; 
      if ( cellLength < (inVar.d0*1.4) ) {
        System.out.println ("\nError: on UNIFORM topology, density is too high, increase physical terrain");
        System.exit(1);
      }
      for (i = 0; i < inVar.numNodes; i = i+1) {
        outVar.nodePosX[i] = (i%nodesX) * cellLength + rand.nextDouble()*cellLength;
        outVar.nodePosY[i] = (i/nodesX) * cellLength + rand.nextDouble()*cellLength;
        wrongPlacement = true;
        while ( wrongPlacement ) {
          for (j = 0; j < i; j = j+1) {
            Xdist = outVar.nodePosX[i] - outVar.nodePosX[j];
            Ydist = outVar.nodePosY[i] - outVar.nodePosY[j];
            // distance between a given pair of nodes
            dist = Math.pow((Xdist*Xdist + Ydist*Ydist), 0.5);
            if (dist < inVar.d0) {
              outVar.nodePosX[i] = (i%nodesX) * cellLength + rand.nextDouble()*cellLength;
              outVar.nodePosY[i] = (i/nodesX) * cellLength + rand.nextDouble()*cellLength;
              wrongPlacement = true;
              break;
            }
          }
          if ( j == i ) {
            wrongPlacement = false;
          }
        }
      }
      break;
    case 3: // RANDOM
      if ( (inVar.Xterr <= 0) | (inVar.Yterr <= 0) ) {
        System.out.println("\nError: values of TERRAIN_DIMENSIONS must be positive");
        System.exit(1);
      }
      cellLength = Math.sqrt ( inVar.area / inVar.numNodes );   
      if ( cellLength < (inVar.d0*1.4) ) {
        System.out.println ("\nError: on RANDOM topology, density is too high, increase physical terrain");
        System.exit(1);
      }
      for (i = 0; i < inVar.numNodes; i = i+1) {
        outVar.nodePosX[i] = rand.nextDouble() * inVar.Xterr;
        outVar.nodePosY[i] = rand.nextDouble() * inVar.Yterr;
        wrongPlacement = true;
        while ( wrongPlacement ) {
          for (j = 0; j < i; j = j+1) {
            Xdist = outVar.nodePosX[i] - outVar.nodePosX[j];
            Ydist = outVar.nodePosY[i] - outVar.nodePosY[j];
            // distance between a given pair of nodes
            dist = Math.pow((Xdist*Xdist + Ydist*Ydist), 0.5);
            if (dist < inVar.d0) {
              outVar.nodePosX[i] = rand.nextDouble() * inVar.Xterr;
              outVar.nodePosY[i] = rand.nextDouble() * inVar.Yterr;
              wrongPlacement = true;
              break;
            }
          }
          if ( j == i ) {
            wrongPlacement = false;
          }
        }
      }
      break;
    case 4: // FILE (user-defined topology)
      readTopologyFile(inVar.topFile, outVar);
      correctTopology (inVar, outVar);
      break;
    default:
      System.out.println("\nError: topology is not correct, please check TOPOLOGY in the configuration file");
      System.exit(1);
    }

    return true;
  }


  /**
   * Checks that user-defined topology does not have inter-node distances less than D0 meter, 
   * where D0 is the reference distance in the channel model (specified in configuration file)
   *
   * @param inVar class that stores input parameters from configuration file
   * @param outVar class that stores link gains, noise floors and x/y coordinates
   * @return true if x/y coordinates provided by user satisfy the condition that no internode distance is lesss than D0
   */

  protected static boolean correctTopology ( InputVariables  inVar, 
                                             OutputVariables outVar )
  {
    Random rand = new Random();
    int i, j;
    double Xdist, Ydist, dist, avgDecay;

    for (i = 0; i < inVar.numNodes; i = i+1) {
      for (j = i+1; j < inVar.numNodes; j = j+1 ) {
        Xdist = outVar.nodePosX[i] - outVar.nodePosX[j];
        Ydist = outVar.nodePosY[i] - outVar.nodePosY[j];
        // distance between a given pair of nodes
        dist = Math.pow((Xdist*Xdist + Ydist*Ydist), 0.5);
        if (dist < inVar.d0) {
          System.out.println("\nError: file " + inVar.topFile + " contains inter-node distances less than one.");
          System.exit(1);
        }
      }
    }
    return true;
  }


  /**
   * Obtains output power and noise floor for all nodes in the network
   *
   * @param inVar class that contains radio parameters
   * @param outVar class that stores output powers and noise floors
   * @return true if all output powers and noise floors were obtained correctly
   */

  protected static boolean obtainRadioPtPn ( InputVariables  inVar, 
                                             OutputVariables outVar )
  {
    Random rand = new Random();
    int i, j;
    double t11, t12, t21, t22;
    double rn1, rn2;

    t11 = 0;
    t12 = 0;
    t21 = 0;
    t22 = 0;

    if ( (inVar.s11 == 0) && (inVar.s22 == 0) ) { // symmetric links do nothing
    }
    else if ( (inVar.s11 == 0) && (inVar.s22 != 0) ) { // both S11 and S22 must be 0 for symmetric links
      System.out.println("\nError: symmetric links require both, S11 and S22 to be 0, not only S11.");
      System.exit(1);
    }
    else {
      if ( (inVar.s12 != inVar.s21) ) { // check that S is symmetric
        System.out.println("\nError: S12 and S21 must have the same value.");
        System.exit(1);
      }
      if ( Math.abs(inVar.s12) > Math.sqrt(inVar.s11*inVar.s22) ) { // check that correlation is within [-1,1]
        System.out.println("\nError: S12 (and S21) must be less than sqrt(S11xS22).");
        System.exit(1);
      }
      t11 = Math.sqrt(inVar.s11);
      t12 = inVar.s12/Math.sqrt(inVar.s11);
      t21 = 0;
      t22 = Math.sqrt( (inVar.s11*inVar.s22 - Math.pow( inVar.s12, 2)) / inVar.s11 );
    }

    for (i = 0; i < inVar.numNodes; i = i+1) {
      rn1 = rand.nextGaussian();
      rn2 = rand.nextGaussian();
      outVar.noisefloor[i]  = inVar.pn + t11 * rn1;
      outVar.outputpowervar[i] = t12 * rn1 + t22 * rn2;
    }
    return true;
  }


  /**
   * Obtains gain for all links in the network. The link gain between nodes A and B 
   * is defined as the output power of A minus the pathloss between A and B.
   *
   * @param inVar class that contains channel parameters from configuration file
   * @param outVar class that stores link gains
   * @return true if all link gains were obtained correctly
   */

  protected static boolean obtainLinkGain ( InputVariables  inVar, 
                                            OutputVariables outVar )
  {
    Random rand = new Random();
    int i, j;
    double Xdist, Ydist, dist, pathloss;

    for (i = 0; i < inVar.numNodes; i = i+1) {
      for (j = i+1; j < inVar.numNodes; j = j+1 ) {
        Xdist = outVar.nodePosX[i] - outVar.nodePosX[j];
        Ydist = outVar.nodePosY[i] - outVar.nodePosY[j];
        // distance between a given pair of nodes
        dist = Math.pow((Xdist*Xdist + Ydist*Ydist), 0.5);
        // mean decay dependent on distance
        pathloss = - inVar.pld0 - 10*inVar.n*(Math.log(dist/inVar.d0)/Math.log(10.0)) + ( rand.nextGaussian()*inVar.sigma );
        // assymetric links are given by running two different
        // R.V.s for each unidirectional link (output power variance).
        outVar.linkGain[i][j] = outVar.outputpowervar[i] + pathloss;
        outVar.linkGain[j][i] = outVar.outputpowervar[j] + pathloss;
  
      }
    }
    return true;

  }


  /**
   * Provides link gain and noise floor in file linkgain.out, and the
   * X/Y coordinates in file topology.out.
   *
   * @param inVar class that contains input parameters from configuration file
   * @param outVar class that stores link gains, noise floors and x/y coordinates
   * @return true if files linkgain.out and topology.out were printed correctly
   */

  protected static boolean printFile( InputVariables  inVar, 
                                      OutputVariables outVar )
  {

    int i, j;

    DecimalFormat posFormat = new DecimalFormat("##0.00");

    /*
     * Output file for xy coordinates.
     */

    try{
      FileOutputStream fout =  new FileOutputStream("topology.out");
      try {
        PrintStream myOutput = new PrintStream(fout);
        for (i = 0; i < inVar.numNodes; i = i+1) {
          myOutput.print( i + "\t" + posFormat.format(outVar.nodePosX[i]) + "\t"+ posFormat.format(outVar.nodePosY[i]) + "\n");
        }
      }
      catch (Exception e) {
        System.out.println("\nError : Failed to open a print stream to the linkgain file" + e);
      }

    }
    catch (Exception e) {
      System.out.println("\nError : Failed to open the link gain file linkgains.out:" + e);
    }

   
    /*
     * Output file for link gains.
     */
    try{
      FileOutputStream fout =  new FileOutputStream("linkgain.out");
      try {
        PrintStream myOutput = new PrintStream(fout);
        for (i = 0; i < inVar.numNodes; i = i+1) {
          for (j = (i+1); j < inVar.numNodes; j = j+1 ) {
            if ( i != j) {
              myOutput.print( "gain\t" + i + "\t" + j + "\t" + posFormat.format(outVar.linkGain[i][j]) + "\n");
              myOutput.print( "gain\t" + j + "\t" + i + "\t" + posFormat.format(outVar.linkGain[j][i]) + "\n");
            }
          }
        }
        for (i = 0; i < inVar.numNodes; i = i+1) {
          myOutput.print( "noise\t" + i + "\t" + posFormat.format(outVar.noisefloor[i]) + "\t" + posFormat.format(inVar.wgn) + "\n");
        }
      }
      catch (Exception e) {
        System.out.println("\nError : Failed to open a print stream to the linkgain file" + e);
      }

    }
    catch (Exception e) {
      System.out.println("\nError : Failed to open the link gain file linkgains.out:" + e);
    }

    return true;
  }

  /**
   * Obtains nodes coordinates for user-defined topology.
   *  
   * @param inputTopoFile topology file provided by user
   * @param outVar class that contains variables to store x/y coordinates of nodes
   * @return true if x/y coordinates of user-defined topology file were read correctly.
   */

  protected static boolean readTopologyFile ( String inputTopoFile,
                                              OutputVariables outVar )
  {

    String thisLine;
    StringTokenizer st;
    int counter = 0;

    try {
      FileInputStream fin =  new FileInputStream(inputTopoFile);
      try {
        BufferedReader myInput = new BufferedReader(new InputStreamReader(fin));

        try {

          while ((thisLine = myInput.readLine()) != null) {

            if ( !thisLine.equals("")  && !thisLine.startsWith("%") && 
                 !thisLine.startsWith(" ") ) {
              st = new StringTokenizer(thisLine, " \t");
              int node = Integer.parseInt(st.nextToken());
              double x = Double.valueOf(st.nextToken()).doubleValue();
              double y = Double.valueOf(st.nextToken()).doubleValue();
              outVar.nodePosX[node] = x;
              outVar.nodePosY[node] = y;
              counter++;
            }
          }
        } // end try
        catch (Exception e) {
          System.out.println("Error4: " + e);
          System.exit(1);
        }

      } // end try
      catch (Exception e) {
        System.out.println("Error5: " + e);
        System.exit(1);
      }

    } // end try
    catch (Exception e) {
      System.out.println("Error: Failed to Open TOPOLOGY_FILE " + inputTopoFile + e);
      System.exit(1);
    }

    return true;
  }


  /**
   * Obtains number of nodes in network when user defines the topology.
   *
   * @param inputTopoFile topology file provided by user
   * @param inVar class that contains variable for number of nodes
   * @return true if number of nodes from user-defined topology file were obtained correctly
   */

  protected static boolean obtainNumNodes ( String inputTopoFile,
                                            InputVariables inVar )
  {

    String thisLine;
    StringTokenizer st;
    int counter = 0;

    try {
      FileInputStream fin =  new FileInputStream(inputTopoFile);
      try {
        BufferedReader myInput = new BufferedReader(new InputStreamReader(fin));

        try {

          while ((thisLine = myInput.readLine()) != null) {

            if ( !thisLine.equals("")  && !thisLine.startsWith("%") && 
                 !thisLine.startsWith(" ") ) {
              counter++;
            }
          }
          inVar.numNodes = counter; 

        } // end try
        catch (Exception e) {
          System.out.println("Error4: " + e);
          System.exit(1);
        }

      } // end try
      catch (Exception e) {
        System.out.println("Error5: " + e);
        System.exit(1);
      }

    } // end try
    catch (Exception e) {
      System.out.println("Error: Failed to Open TOPOLOGY_FILE " + inputTopoFile + e);
      System.exit(1);
    }

    return true;
  }

  private static void usage() {
    System.err.println("usage: net.tinyos.sim.LinkLayerModel <config file>");
  }
}


