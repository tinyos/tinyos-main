/*
 * Copyright (c) 2006 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package net.tinyos.mviz;

// DDocument.java

import java.awt.*;
import java.awt.event.*;
import java.awt.image.*;
import java.io.*;
import java.lang.reflect.*;
import java.net.*;
import java.util.*;

import javax.imageio.ImageIO;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.table.*;

import net.tinyos.message.*;

public class DDocument
    extends JPanel 
    implements ActionListener{    

    protected String directory;
    protected JPanel canvas;
    protected Vector layers;
	
    private Color currentColor;
	
    public float[] maxValues;
    public int selectedFieldIndex;
    public int selectedLinkIndex;
    public ImageIcon icon;
    public Image image;
	
	
    public DNavigate navigator;
    public Color getColor(){ return currentColor; }
    public Vector sensed_motes;
    public Vector sensed_links;
    public ArrayList moteModels;
    public ArrayList linkModels;
    private JTextField jText;
    private DrawTableModel tableModel;
    private JTable jTable;
	
    private String[] toStringArray(Vector v) {
	String[] array = new String[v.size()];
	for (int i = 0; i < v.size(); i++) {
	    array[i] = (String)v.elementAt(i);
	}
	return array;
    }
    
    public DDocument(int width, int height, Vector fieldVector, Vector linkVector, String dir) {
	super();
	layers = new Vector();
	directory = dir;
	
	setOpaque(false);
	setLayout(new BorderLayout(6,6));
	try{ UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
	} catch (Exception ignore){}
		
	selectedFieldIndex = 0;
	selectedLinkIndex = 0;
	canvas = new DPanel(this);
	canvas.setLayout(null);
	canvas.setDoubleBuffered(true);
	canvas.setPreferredSize(new Dimension(width, height));
	canvas.setMinimumSize(new Dimension(width, height));
	canvas.setSize(new Dimension(width, height));
	canvas.setOpaque(false);
	canvas.setBorder(new SoftBevelBorder(SoftBevelBorder.LOWERED));
	add(canvas, BorderLayout.CENTER);
	sensed_motes = fieldVector;
	sensed_links = linkVector;
	moteIndex = new HashMap();
	linkIndex = new HashMap();
		
	String imgName = directory + "/node.png";
	try {
	    image = Toolkit.getDefaultToolkit().getImage(imgName);
	}
	catch (Exception e) {
	    System.out.println(e);
	}
	System.out.println(imgName);
		
		
	canvas.addComponentListener(new ComponentListener(){
		public void componentResized(ComponentEvent e) {
		    navigator.redrawAllLayers();
		}
		public void componentHidden(ComponentEvent arg0) {
		}
		public void componentMoved(ComponentEvent arg0) {
		}
		public void componentShown(ComponentEvent arg0) {
		}			
	    });

		
		
	// Make control area
	JPanel west = new JPanel();
	west.setDoubleBuffered(true);
	west.setLayout(new BoxLayout(west, BoxLayout.Y_AXIS));
	add(west, BorderLayout.WEST);
	currentColor = Color.GRAY;
	navigator = new DNavigate(sensed_motes, sensed_links, this);
	west.add(navigator);
	west.add(Box.createVerticalStrut(10));
	tableModel = new DrawTableModel(sensed_motes);
	jTable = new JTable(tableModel);
	jTable.setAutoResizeMode(JTable.AUTO_RESIZE_ALL_COLUMNS);
	JScrollPane scroller = new JScrollPane(jTable);
	scroller.setPreferredSize(new Dimension(350, 200));
	scroller.setMinimumSize(new Dimension(350, 200));
	scroller.setSize(new Dimension(350, 200));
	west.add(scroller);
		
	enableEvents(LinkSetEvent.EVENT_ID);
	enableEvents(ValueSetEvent.EVENT_ID);
    }
    public void actionPerformed(ActionEvent e) {
    }

    private void zMove(int direction){
	tableModel.updateTable();
    }
    public int width_canvas = 600;
    public int height_canvas = 600;
	
    protected ArrayList motes = new ArrayList();
    protected ArrayList links = new ArrayList();
    protected DMoteModel selected = null;
    
    protected HashMap moteIndex;
    protected HashMap linkIndex;
	
    // Provided default ctor that calls the regular ctor
    public DDocument(Vector fieldVector, Vector linkVector) {
	this(300, 300, fieldVector, linkVector, ".");	 // this syntax calls one ctor from another
    }
	
	
    public DShape getSelected() {
	return null;
    }
	
    public void setSelected(DShape selected) {
    }

    Random rand = new Random();


    private DMoteModel createNewMote(int moteID){
	DMoteModel m = new DMoteModel(moteID, rand, this);
	//System.out.println("Adding mote " + moteID);
	motes.add(m);
	moteIndex.put(new Integer(moteID), m);
	tableModel.add(m);

	navigator.addMote(m);
	return m;
    }
    
    public void setMoteValue(int moteID, String name, int value) {
	ValueSetEvent vsv = new ValueSetEvent(this, moteID, name, value);
	EventQueue eq = Toolkit.getDefaultToolkit().getSystemEventQueue();
	eq.postEvent(vsv);
    }

    private DLinkModel createNewLink(DMoteModel start, DMoteModel end) {
	DLinkModel dl = new DLinkModel(start, end, rand, this);
	links.add(dl);
	linkIndex.put(start.getId() + " " + end.getId(), dl);
	//System.out.println("Put with key <" + start.getId() + " " + end.getId() + ">");
	return dl;
    }
    
    public void setLinkValue(int startMote, int endMote, String name, int value) {
	LinkSetEvent lsv = new LinkSetEvent(this, name, value, startMote, endMote);
	EventQueue eq = Toolkit.getDefaultToolkit().getSystemEventQueue();
	eq.postEvent(lsv);
    }

    protected void processEvent(AWTEvent event) {
	if (event instanceof ValueSetEvent) {
	    ValueSetEvent vsv = (ValueSetEvent)event;
	    String name = vsv.name();
	    int moteID = vsv.moteId();
	    int value = vsv.value();
	    DMoteModel m = (DMoteModel)moteIndex.get(new Integer(moteID));
	    if (m == null) {
		m = createNewMote(moteID);
	    }
	    //System.out.println("Set " + moteID + ":" + name + " to " + value);
	    m.setMoteValue(name, value);
	    navigator.redrawAllLayers();
	}
	else if (event instanceof LinkSetEvent) {
	    LinkSetEvent lsv = (LinkSetEvent)event;
	    String name = lsv.name();
	    int startMote = lsv.start();
	    int endMote = lsv.end();
	    int value = lsv.value();
	    DMoteModel m = (DMoteModel)moteIndex.get(new Integer(startMote));
	    if (m == null) {
		m = createNewMote(startMote);
	    }
	    DMoteModel m2 = (DMoteModel)moteIndex.get(new Integer(endMote));
	    if (m2 == null) {
		m2 = createNewMote(endMote);
	    }


	    String name1 = null;
            for (Iterator ite = linkIndex.keySet().iterator()  ;ite.hasNext();) {
                    String name2 = (String)ite.next();
                    String  temp = name2.substring( 0,name2.indexOf(' '));
                   // System.out.println("name:"+name2+"\n");
                    if(Integer.parseInt(temp) == startMote){//link with the same start mote
                    	String name3 = startMote+" " + endMote;
                    	if(!name2.equals(name3) )//whether they are the same link
                    	{
                    	     name1 = name2;
                             break;
                    	}
                    }
            }
           if(name1 != null){
           DLinkModel deleteModel = null;
          //we still have to remove linkmode in links
           try {
        	  deleteModel = getDLinkModeWithFlag(name1);
              links.remove(deleteModel);
              linkIndex.remove(name1);
		} catch (Exception e) {
			// TODO: handle exception
			System.out.println(e);
		}
            }


	    DLinkModel dl = (DLinkModel)linkIndex.get(startMote + " " + endMote);
	    if (dl == null) {
		//System.out.println("Does not contain key <" + startMote + " " + endMote + ">");
		dl = createNewLink(m, m2);
	    }
	    //System.out.println("Setting " + name + " " + startMote + " -> " + endMote + " to " + value);
	    dl.setLinkValue(name, value);
	    navigator.redrawAllLayers();
	}
	else {
	    super.processEvent(event);
	}
    }
    /**
     * Get link mode with start and end node id
     * @param flag
     * @return
     */
    private DLinkModel getDLinkModeWithFlag(String flag){
    	for (Iterator it = links.iterator();it.hasNext();) {
            DLinkModel model = (DLinkModel)it.next();
            if(model.getLinkFlag().equals( flag)){
             //   del = true;
                return model;
            }
        }
        return null;
    }
    public static void usage() {
	System.err.println("usage: tos-mviz [-comm source] [-dir image_dir] message_type [message_type ...]");
    }
	
    // Just a test main -- put a little DDocument on screen
    public static void main(String[] args)	{
	JFrame frame = new JFrame("MViz");
	Vector packetVector = new Vector();
	String source = null;
	String dir = ".";
	if (args.length > 0) {
	    for (int i = 0; i < args.length; i++) {
		if (args[i].equals("-comm")) {
		    source = args[++i];
		}
		else if (args[i].equals("-dir")) {
		    dir = args[++i];
		}
		else {
		    String className = args[i];
		    packetVector.add(className);
		}
	    }
	}
	else if (args.length != 0) {
	    usage();
	    System.exit(1);
	}
	if (packetVector.size() == 0) {
	    usage();
	    System.exit(1);
	}
	
	DataModel model = new DataModel(packetVector);
	DDocument doc = new DDocument(600, 600, model.fields(), model.links(), dir);
        
	frame.setContentPane(doc);
	frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
	frame.pack();
	frame.setVisible(true);
	
	MessageInput input = new MessageInput(packetVector, source, doc);
	input.start();
    }
	
    private void repaintAllMotes(){    	
	Iterator it = motes.iterator();
	while(it.hasNext()){
	    ((DMoteModel)it.next()).requestRepaint();
	}
    }
    private void repaintAllLinks(){      	
	Iterator it = links.iterator();
	while(it.hasNext()){
	    ((DLink)it.next()).repaint();
	}
    }
    //#########################################################################//
	
	
	
    private class DrawTableModel
	extends AbstractTableModel
	implements DMoteModelListener {
	private Vector fields;
	
	public DrawTableModel(Vector fields) {
	    this.fields = fields;
	}
	//-----------------------------o
	public String getColumnName(int col){
	    switch(col) {
	    case 0:
		return "X";
	    case 1:
		return "Y";
	    default:
		return (String)fields.elementAt(col - 2);
	    }
	}
	//-----------------------------o
	public int getColumnCount() { return fields.size() + 2; }
	//-----------------------------o
	public int getRowCount() {
	    return DDocument.this.motes.size();
	}	    
	//-----------------------------o
	public Object getValueAt(int row, int col) {
	    DMoteModel model = (DMoteModel) DDocument.this.motes.get(row);
	    switch(col) {
	    case 0:
		return "" + (int)model.getLocX();
	    case 1:
		return "" + (int)model.getLocY();
	    default:
		return("" + (int)model.getValue(col - 2));
	    }
	}
	//-----------------------------o
	public void shapeChanged(DMoteModel changed, int type){
	    int row = findModel(changed);
	    if (row != -1) fireTableRowsUpdated(row, row);	
	}
	//-----------------------------o
	public void add(DMoteModel model){
	    model.addListener(this);
	    int last = DDocument.this.motes.size()-1;
	    fireTableRowsInserted(last, last);
	}
	//-----------------------------o
	public void remove(DMoteModel model){
	    int row = findModel(model);
	    if (row != -1) fireTableRowsDeleted(row, row);	        
	}
	//-----------------------------o
	public void updateTable(){
	    fireTableDataChanged();
	}
	//-----------------------------o
	private int findModel(DMoteModel changed){
	    for (int i=0; i<DDocument.this.motes.size(); i++){
		if ((DMoteModel)DDocument.this.motes.get(i) == changed)
		    return i;
	    }
	    return -1;	            
			
	}
    }
    
    private class DPanel extends JPanel {
	private DDocument doc;
	private int lastX = -1;
	private int lastY = -1;
	
	public DPanel(DDocument d) {
	    super();
	    doc = d;
	    addMouseListener( new MouseAdapter() {
		    private boolean withinRange(int val, int low, int high) {
			return (val >= low && val <= high);
		    }
		    public void mousePressed(MouseEvent e) {
			lastX = e.getX();
			lastY = e.getY();
			Iterator it = doc.motes.iterator();
			while (it.hasNext()) {
			    DMoteModel model = (DMoteModel)it.next();
			    if (withinRange(e.getX(),
					    model.getLocX() - 20,
					    model.getLocX() + 20) &&
				withinRange(e.getY(),
					    model.getLocY() - 20,
					    model.getLocY() + 20)) {
				selected = model;
				return;
			    }
			}
		    }
		    public void mouseReleased(MouseEvent e) {
			if (doc.selected != null) {
			    doc.selected = null;
			    lastX = -1;
			    lastY = -1;
			}
		    }
		});
	    addMouseMotionListener(new MouseMotionAdapter() {
		    public void mouseDragged(MouseEvent e) {
			if (doc.selected != null) {
			    if (lastY == -1) {
				lastY = e.getY();
			    }
			    if (lastX == -1) {
				lastX = e.getX();
			    }
			    int x = e.getX();
			    int y = e.getY();	
			    int dx = x-lastX;
			    int dy = y-lastY;
			    lastX = x;
			    lastY = y;
			    
			    selected.move(selected.getLocX() + dx, selected.getLocY() + dy);
			}
			doc.navigator.redrawAllLayers();
		    }
		});
	}

	public void paintComponent(Graphics g) {
	    super.paintComponent(g);
	    setOpaque(false);
	    //System.out.println("Painting panel!");
	    doc.navigator.redrawAllLayers();
	}
    }

    private class CanvasMouse extends MouseAdapter {

    }
    protected class ValueSetEvent extends AWTEvent {
	public static final int EVENT_ID = AWTEvent.RESERVED_ID_MAX + 1;
	private String name;
	private int value;
	private int mote;
	
	public ValueSetEvent(Object target, int mote, String name, int value) {
	    super(target, EVENT_ID);
	    this.value = value;
	    this.name = name;
	    this.mote = mote;
	}
	
	public String name() {
	    return name;
	}

	public int value() {
	    return value;
	}

	public int moteId() {
	    return mote;
	}
    }


    protected class LinkSetEvent extends AWTEvent {
	public static final int EVENT_ID = AWTEvent.RESERVED_ID_MAX + 2;
	private String name;
	private int value;
	private int start;
	private int end;
	
	public LinkSetEvent(Object target, String name, int value, int start, int end) {
	    super(target, EVENT_ID);
	    this.value = value;
	    this.name = name;
	    this.start = start;
	    this.end = end;
	}
	
	public String name() {
	    return name;
	}

	public int value() {
	    return value;
	}

	public int start() {
	    return start;
	}

	public int end() {
	    return end;
	}
    }
}
