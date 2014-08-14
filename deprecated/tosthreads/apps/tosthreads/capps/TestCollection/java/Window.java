/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

import javax.swing.*;
import javax.swing.table.*;
import javax.swing.event.*;
import java.awt.*;
import java.awt.event.*;
import java.util.*;

/* The main GUI object. Build the GUI and coordinate all user activities */
class Window
{
    Oscilloscope parent;
    Graph graph;

    Font smallFont = new Font("Dialog", Font.PLAIN, 8);
    Font boldFont = new Font("Dialog", Font.BOLD, 12);
    Font normalFont = new Font("Dialog", Font.PLAIN, 12);
    MoteTableModel moteListModel; // GUI view of mote list
    JLabel xLabel; // Label displaying X axis range
    JTextField sampleText, yText; // inputs for sample period and Y axis range
    JFrame frame;

    Window(Oscilloscope parent) {
	this.parent = parent;
    }

    /* A model for the mote table, and general utility operations on the mote
       list */
    class MoteTableModel extends AbstractTableModel {
	private ArrayList motes = new ArrayList();
	private ArrayList colors = new ArrayList();

	/* Initial mote colors cycle through this list. Add more colors if
	   you want. */
	private Color[] cycle = {
	    Color.RED, Color.WHITE, Color.GREEN, Color.MAGENTA,
	    Color.YELLOW, Color.GRAY, Color.YELLOW
	};
	int cycleIndex;

	/* TableModel methods for achieving our table appearance */
	public String getColumnName(int col) {
	    if (col == 0)
		return "Mote";
	    else
		return "Color";
	}
	public int getColumnCount() { return 2; }
	public synchronized int getRowCount() { return motes.size(); }
	public synchronized Object getValueAt(int row, int col) {
	    if (col == 0)
		return motes.get(row);
	    else
		return colors.get(row);
	}
        public Class getColumnClass(int col) {
            return getValueAt(0, col).getClass();
        }
	public boolean isCellEditable(int row, int col) { return col == 1; }
        public synchronized void setValueAt(Object value, int row, int col) {
	    colors.set(row, value);
            fireTableCellUpdated(row, col);
	    graph.repaint();
        }

	/* Return mote id of i'th mote */
	int get(int i) { return ((Integer)motes.get(i)).intValue(); }
	
	/* Return color of i'th mote */
	Color getColor(int i)  { return (Color)colors.get(i); }

	/* Return number of motes */
	int size() { return motes.size(); }

	/* Add a new mote */
	synchronized void newNode(int nodeId) {
	    /* Shock, horror. No binary search. */
	    int i, len = motes.size();

	    for (i = 0; ; i++)
		if (i == len || nodeId < get(i)) {
		    motes.add(i, new Integer(nodeId));
		    // Cycle through a set of initial colors
		    colors.add(i, cycle[cycleIndex++ % cycle.length]);
		    break;
		}
	    fireTableRowsInserted(i, i);
	}

	/* Remove all motes */
	void clear() {
	    motes = new ArrayList();
	    colors = new ArrayList();
	    fireTableDataChanged();
	}
    }

    /* A simple full-color cell */
    static class MoteColor extends JLabel implements TableCellRenderer {
	public MoteColor() { setOpaque(true); }
	public Component getTableCellRendererComponent
	    (JTable table, Object color,
	     boolean isSelected, boolean hasFocus, int row, int column) {
	    setBackground((Color)color);
	    return this;
	}
    }

    /* Convenience methods for making buttons, labels and textfields.
       Simplifies code and ensures a consistent style. */

    JButton makeButton(String label, ActionListener action) {
	JButton button = new JButton();
        button.setText(label);
        button.setFont(boldFont);
	button.addActionListener(action);
	return button;
    }

    JLabel makeLabel(String txt, int alignment) {
	JLabel label = new JLabel(txt, alignment);
	label.setFont(boldFont);
	return label;
    }

    JLabel makeSmallLabel(String txt, int alignment) {
	JLabel label = new JLabel(txt, alignment);
	label.setFont(smallFont);
	return label;
    }

    JTextField makeTextField(int columns, ActionListener action) {
	JTextField tf = new JTextField(columns);
	tf.setFont(normalFont);
	tf.setMaximumSize(tf.getPreferredSize());
	tf.addActionListener(action);
	return tf;
    }

    /* Build the GUI */
    void setup() {
	JPanel main = new JPanel(new BorderLayout());

	main.setMinimumSize(new Dimension(500, 250));
	main.setPreferredSize(new Dimension(800, 400));

	// Three panels: mote list, graph, controls
	moteListModel = new  MoteTableModel();
	JTable moteList = new JTable(moteListModel);
	moteList.setDefaultRenderer(Color.class, new MoteColor());
	moteList.setDefaultEditor(Color.class, new ColorCellEditor("Pick Mote Color"));
	moteList.setPreferredScrollableViewportSize(new Dimension(100, 400));
	JScrollPane motePanel = new JScrollPane();
	motePanel.getViewport().add(moteList, null);
	main.add(motePanel, BorderLayout.WEST);

	graph = new Graph(this);
	main.add(graph, BorderLayout.CENTER);

	// Controls. Organised using box layouts.

	// Sample period.
	JLabel sampleLabel = makeLabel("Sample period (ms):", JLabel.RIGHT);
	sampleText = makeTextField(6, new ActionListener() {
		public void actionPerformed(ActionEvent e) { setSamplePeriod(); }
	    } );
	updateSamplePeriod();

	// Clear data.
	JButton clearButton = makeButton("Clear data", new ActionListener() {
		public void actionPerformed(ActionEvent e) { clearData(); }
	    } );

	// Adjust X-axis zoom.
	Box xControl = new Box(BoxLayout.Y_AXIS);
	xLabel = makeLabel("", JLabel.CENTER);
	final JSlider xSlider = new JSlider(JSlider.HORIZONTAL, 0, 8, graph.scale);
	Hashtable xTable = new Hashtable();
	for (int i = 0; i <= 8; i += 2)
	    xTable.put(new Integer(i),
		       makeSmallLabel("" + (Graph.MIN_WIDTH << i),
				      JLabel.CENTER));
	xSlider.setLabelTable(xTable);
	xSlider.setPaintLabels(true);
	graph.updateXLabel();
	graph.setScale(graph.scale);
	xSlider.addChangeListener(new ChangeListener() {
		public void stateChanged(ChangeEvent e) {
		    //if (!xSlider.getValueIsAdjusting())
			graph.setScale((int)xSlider.getValue());
		}
	    });
	xControl.add(xLabel);
	xControl.add(xSlider);

	// Adjust Y-axis range.
	JLabel yLabel = makeLabel("Y:", JLabel.RIGHT);
	yText = makeTextField(12, new ActionListener() {
		public void actionPerformed(ActionEvent e) { setYAxis(); }
	    } );
	yText.setText(graph.gy0 + " - " + graph.gy1);

	Box controls = new Box(BoxLayout.X_AXIS);
	controls.add(clearButton);
	controls.add(Box.createHorizontalGlue());
	controls.add(Box.createRigidArea(new Dimension(20, 0)));
	controls.add(sampleLabel);
	controls.add(sampleText);
	controls.add(Box.createHorizontalGlue());
	controls.add(Box.createRigidArea(new Dimension(20, 0)));
	controls.add(xControl);
	controls.add(yLabel);
	controls.add(yText);
	main.add(controls, BorderLayout.SOUTH);

	// The frame part
	frame = new JFrame("Oscilloscope");
	frame.setSize(main.getPreferredSize());
	frame.getContentPane().add(main);
	frame.setVisible(true);
	frame.addWindowListener(new WindowAdapter() {
		public void windowClosing(WindowEvent e) { System.exit(0); }
	    });
    }

    /* User operation: clear data */
    void clearData() {
	synchronized (parent) {
	    moteListModel.clear();
	    parent.clear();
	    graph.newData();
	}
    }

    /* User operation: set Y-axis range. */
    void setYAxis() {
	String val = yText.getText();

	try {
	    int dash = val.indexOf('-');
	    if (dash >= 0) {
		String min = val.substring(0, dash).trim();
		String max = val.substring(dash + 1).trim();

		if (!graph.setYAxis(Integer.parseInt(min), Integer.parseInt(max)))
		    error("Invalid range " + min + " - " + max + " (expected values between 0 and 65535)");
		return;
	    }
	}
	catch (NumberFormatException e) { }
	error("Invalid range " + val + " (expected NN-MM)");
    }

    /* User operation: set sample period. */
    void setSamplePeriod() {
	String periodS = sampleText.getText().trim();
	try {
	    int newPeriod = Integer.parseInt(periodS);
	    if (parent.setInterval(newPeriod))
		return;
	}
	catch (NumberFormatException e) { }
	error("Invalid sample period " + periodS);
    }

    /* Notification: sample period changed. */
    void updateSamplePeriod() {
	sampleText.setText("" + parent.interval);
    }

    /* Notification: new node. */
    void newNode(int nodeId) {
	moteListModel.newNode(nodeId);
    }

    /* Notification: new data. */
    void newData() {
	graph.newData();
    }

    void error(String msg) {
	JOptionPane.showMessageDialog(frame, msg, "Error",
				      JOptionPane.ERROR_MESSAGE);
    }
}
