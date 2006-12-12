// $Id: SFWindow.java,v 1.4 2006-12-12 18:23:00 vlahan Exp $

/*									tab:4
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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


/**
 * File: ControlWindow.java
 *
 * Description:
 * This class displays the GUI that allows the serial forwarder
 * to be more easily configured
 *
 * @author <a href="mailto:bwhull@sourceforge.net">Bret Hull</a>
 * @author <a href="mailto:dgay@intel-research.net">David Gay</a>
 */

package net.tinyos.sf;

import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import net.tinyos.packet.*;

public class SFWindow extends JPanel implements WindowListener, SFRenderer {
    JScrollPane   mssgPanel             = new JScrollPane();
    JTextArea     mssgArea              = new JTextArea();
    BorderLayout  toplayout             = new BorderLayout();
    JTabbedPane   pnlTabs               = new JTabbedPane();
    JLabel        labelPacketsSent      = new JLabel();
    JLabel        labelServerPort       = new JLabel();
    JTextField    fieldServerPort       = new JTextField();
    JLabel        labelMoteCom          = new JLabel();
    JLabel        labelPacketsReceived  = new JLabel();
    JTextField    fieldMoteCom          = new JTextField();
    ButtonGroup   bttnGroup             = new ButtonGroup();
    JPanel        pnlMain               = new JPanel();
    GridLayout    gridLayout1           = new GridLayout();
    JLabel        labelNumClients       = new JLabel();
    JCheckBox     cbVerboseMode         = new JCheckBox();
    JButton       bStopServer           = new JButton();
    GridLayout    gridLayout2           = new GridLayout();
    JButton       bHelp                 = new JButton();
    JButton       bClear                 = new JButton();
    JButton       bQuit                 = new JButton();
    private SerialForwarder sf;

    public SFWindow(SerialForwarder SF) {
	sf = SF;
	try {
	    jbInit();
	}
	catch(Exception e) {
	    e.printStackTrace();
	    System.exit(2);
	}
    }

    static public SFWindow createGui( SerialForwarder sf, String title )
    {
        JFrame mainFrame = new JFrame(title);
        SFWindow cntrlWndw = new SFWindow(sf);
        mainFrame.setSize(cntrlWndw.getPreferredSize());
        mainFrame.getContentPane().add("Center", cntrlWndw);
        mainFrame.show();
        mainFrame.addWindowListener(cntrlWndw);
        return cntrlWndw;
    }

    private void jbInit() throws Exception {
	this.setLayout(toplayout);

	mssgPanel.setVerticalScrollBarPolicy(JScrollPane.VERTICAL_SCROLLBAR_ALWAYS);
	mssgPanel.setAutoscrolls(true);
	this.setMinimumSize(new Dimension(500, 250));
	this.setPreferredSize(new Dimension(500, 300));
	labelPacketsSent.setFont(new java.awt.Font("Dialog", 1, 10));
	labelPacketsSent.setHorizontalTextPosition(SwingConstants.LEFT);
	labelPacketsSent.setText("Pckts Read: 0");
	labelServerPort.setFont(new java.awt.Font("Dialog", 1, 10));
	labelServerPort.setText("Server Port:");
	fieldServerPort.setFont(new java.awt.Font("Dialog", 0, 10));
	fieldServerPort.setText(Integer.toString (sf.serverPort));
	labelMoteCom.setFont(new java.awt.Font("Dialog", 1, 10));
	labelMoteCom.setText("Mote Communications:");

	labelPacketsReceived.setFont(new java.awt.Font("Dialog", 1, 10));
	labelPacketsReceived.setHorizontalTextPosition(SwingConstants.LEFT);
	labelPacketsReceived.setText("Pckts Wrttn: 0");
	fieldMoteCom.setFont(new java.awt.Font("Dialog", 0, 10));
	fieldMoteCom.setText(sf.motecom);

	// Input CheckBoxes
	ActionListener cbal = new ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    updateGlobals();
		}
	    };

	bQuit.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    shutdown();
		}
	    });
        bQuit.setText("Quit");
        bQuit.setFont(new java.awt.Font("Dialog", 1, 10));

	bClear.addActionListener(new java.awt.event.ActionListener() {
		public synchronized void actionPerformed(ActionEvent e) {
		    mssgArea.setText("");
		    sf.clearCounts();
		}
	    });
        bClear.setText("Clear");
        bClear.setFont(new java.awt.Font("Dialog", 1, 10));

	bHelp.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    sf.message("The Mote communications field must");
		    sf.message("specify a known packet source, one of:");
		    sf.message(BuildSource.sourceHelp());
		}
	    });
        bHelp.setText("Help");
        bHelp.setFont(new java.awt.Font("Dialog", 1, 10));

	pnlMain.setLayout(gridLayout1);
	pnlMain.setMinimumSize(new Dimension(150, 75));
	pnlMain.setPreferredSize(new Dimension(150, 75));
	gridLayout1.setRows(13);
	labelNumClients.setFont(new java.awt.Font("Dialog", 1, 10));
	labelNumClients.setText("Num Clients: 0");
	cbVerboseMode.setSelected(sf.verbose.on);
	cbVerboseMode.setText("Verbose Mode");
	cbVerboseMode.setFont(new java.awt.Font("Dialog", 1, 10));
	cbVerboseMode.addActionListener(cbal);

	bStopServer.setFont(new java.awt.Font("Dialog", 1, 10));
	bStopServer.setText("Stop Server");
	bStopServer.addActionListener(new java.awt.event.ActionListener() {
		public void actionPerformed(ActionEvent e) {
		    if (sf.listenServer != null) {
			sf.stopListenServer();
		    }
		    else {
			updateGlobals();
			sf.startListenServer();
		    }
		}
	    });
	gridLayout2.setRows(15);
	gridLayout2.setColumns(1);

	toplayout.setHgap(1);
	toplayout.setVgap(1);
	this.add(mssgPanel, BorderLayout.CENTER);
	this.add(pnlTabs, BorderLayout.EAST);
	pnlTabs.add(pnlMain, "Main");

	// Main Panel Setup
	pnlMain.add(labelServerPort, null);
	pnlMain.add(fieldServerPort, null);
	pnlMain.add(labelMoteCom, null);
	pnlMain.add(fieldMoteCom, null);
	pnlMain.add(bStopServer, null);

	pnlMain.add(cbVerboseMode, null);

	pnlMain.add(labelPacketsSent, null);
	pnlMain.add(labelPacketsReceived, null);
	pnlMain.add(labelNumClients, null);
        pnlMain.add(bHelp, null);
        pnlMain.add(bClear, null);
        pnlMain.add(bQuit, null);

	mssgPanel.getViewport().add(mssgArea, null);
	mssgArea.setFont(new java.awt.Font("Monospaced", Font.PLAIN, 12));
    }

    public synchronized void windowClosing (WindowEvent e) {
	shutdown();
    }

    public void windowClosed      (WindowEvent e) { }
    public void windowActivated   (WindowEvent e) { }
    public void windowIconified   (WindowEvent e) { }
    public void windowDeactivated (WindowEvent e) { }
    public void windowDeiconified (WindowEvent e) { }
    public void windowOpened      (WindowEvent e) { }

    public synchronized void message(String mssg) {
	mssgArea.append(mssg + "\n");
	mssgArea.setCaretPosition(mssgArea.getDocument().getLength());
    }

    public void updatePacketsRead(int numPackets) {
	labelPacketsSent.setText("Pckts Read: " + numPackets);
    }

    public void updatePacketsWritten(int numPackets) {
	labelPacketsReceived.setText("Pckts Wrttn: " + numPackets);
    }

    public void updateNumClients(int numClients) {
	labelNumClients.setText("Num Clients: " + numClients);
    }

    private void updateGlobals() {
	// set application/communications defaults
	sf.verbose.on          = cbVerboseMode.isSelected();
	sf.motecom             = fieldMoteCom.getText();
	sf.serverPort          = Integer.parseInt(fieldServerPort.getText());
    }

    public void updateListenServerStatus(boolean running) {
	if (!running) {
	    bStopServer.setText("Start Server");
	}
	else {
	    bStopServer.setText("Stop Server");
	}
    }

    synchronized private void shutdown() {
        //sf.cntrlWndw = null;
	sf.stopListenServer();
        System.out.println("Serial Forwarder Exited Normally\n");
        System.exit(0);
    }

}
