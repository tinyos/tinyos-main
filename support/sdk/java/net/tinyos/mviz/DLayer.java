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

import javax.imageio.ImageIO;
import javax.swing.*;

import java.util.*;
import java.awt.event.*;
import java.io.*;

import javax.swing.*;
import javax.swing.border.Border;
import javax.swing.border.LineBorder;
import javax.swing.table.*;

import java.awt.image.*;


// Standard imports for XML
import javax.xml.parsers.*;
import org.xml.sax.*;
import org.w3c.dom.*;




public class DLayer extends JPanel implements ActionListener{
	
    public static final int MOTE = 0;
    public static final int LINK = 1;
    public static final int FIELD = 2;
    private static final Color[] COLORS = {
	new Color(231, 220, 206),
	new Color(250, 210, 99),
	new Color(209, 230, 179)
    };
	
    private int type;
    protected int index;
    protected int zIndex;
    protected int z_index = 0;
    private ArrayList layer = new ArrayList();
	
    private JLabel label;
    private JCheckBox check;
    private String[][] DISPLAYS = { {"circle", "img", "txt"}, {"line", "line+label", "label"}, {"color 256", "color 1024", "color 4096", "color 16384"}};
    private JComboBox displays;
	
    private ArrayList models;
    private ArrayList linkModels;
    private JButton up;
    private JButton down;
	
    protected int paintMode = 0;
    // Values chosen for COLOR so that readings can be right shifted
    // that many bits to be in range 0-255
    static public final int COLOR_256 = 0;
    static public final int OVAL = 1;
    static public final int COLOR_1024 = 2;
    static public final int IMG = 3;
    static public final int COLOR_4096 = 4;
    static public final int TXT_MOTE = 5;
    static public final int COLOR_16384 = 6;
    static public final int LINE = 7;
    static public final int LABEL = 8;
    static public final int LINE_LABEL = 9;
    
    protected DNavigate navigator;
	
    private String name;
    private DDocument parent;
	
    public DLayer(int zIndex, int index, String label, int type, DDocument parent, ArrayList models, DNavigate navigator){
	this.parent = parent;
	this.type = type;
	this.models = models;
	this.zIndex = zIndex;
	this.index = index;
	this.navigator = navigator;
	this.name = label;
	if (type == MOTE) {
	    this.paintMode = OVAL;
	}
	else if (type == LINK) {
	    this.paintMode = LINE;
	}

	
	SpringLayout layout = new SpringLayout();
	setLayout(layout);
	setMaximumSize(new Dimension(350, 25));
	setPreferredSize(new Dimension(350, 25));
	setSize(new Dimension(350, 25));
	setDoubleBuffered(true);
	setBackground(COLORS[type]);
	setBorder(new LineBorder(new Color(155, 155, 155)));
		
	check = new JCheckBox();
	check.setSize(35, 25);
	check.setMaximumSize(new Dimension(35, 25));
	check.setMinimumSize(new Dimension(35, 25));
	check.setPreferredSize(new Dimension(35, 25));
	
	up = new JButton("^");
	up.setFont(new Font("Times", Font.PLAIN, 9));
	up.setSize(25, 25);
	up.setMaximumSize(new Dimension(25, 25));
	up.setMinimumSize(new Dimension(25, 25));
	up.setPreferredSize(new Dimension(25, 25));
	up.setMargin(new Insets(2, 2, 2, 2));

	down = new JButton("v");
	down.setFont(new Font("Times", Font.PLAIN, 8));
	down.setSize(25, 25);
	down.setMaximumSize(new Dimension(25, 25));
	down.setMinimumSize(new Dimension(25, 25));
	down.setPreferredSize(new Dimension(25, 25));
	down.setMargin(new Insets(2, 2, 2, 2));

	this.label = new JLabel(" " + label, JLabel.LEFT);
	this.label.setSize(125, 25);
	this.label.setMaximumSize(new Dimension(125, 25));
	this.label.setMinimumSize(new Dimension(125, 25));
	this.label.setPreferredSize(new Dimension(125, 25));
	switch (type) {
	case MOTE:
	    this.label.setBackground(new Color(255, 200, 200));
	    break;
	case FIELD:
	    this.label.setBackground(new Color(200, 255, 200));
	    break;
	case LINK:
	    this.label.setBackground(new Color(200, 200, 255));
	    break;
	default:
	    // do nothing
	}
	
	displays = new JComboBox(DISPLAYS[type]);
	displays.setSize(100, 25);
	//displays.setMaximumSize(new Dimension(125, 25));
	displays.setMinimumSize(new Dimension(125, 25));
	displays.setPreferredSize(new Dimension(125, 25));
	
	
	check.addActionListener(this);
	up.addActionListener(this);
	down.addActionListener(this);
	displays.addActionListener(this);

	layout.putConstraint(SpringLayout.WEST, this, 0, SpringLayout.WEST, down);
	layout.putConstraint(SpringLayout.EAST, check, 0, SpringLayout.WEST, down);
	layout.putConstraint(SpringLayout.EAST, down, 0, SpringLayout.WEST, up);
	layout.putConstraint(SpringLayout.EAST, up, 0, SpringLayout.WEST, this.label);
	layout.putConstraint(SpringLayout.EAST, this.label, 0, SpringLayout.WEST, displays);
	layout.putConstraint(SpringLayout.EAST, displays, 0, SpringLayout.EAST, this);

	
	add(check);
	add(down);
	add(up);
	add(this.label);
	add(displays);

	
		
    }
	
    public boolean isFieldSelected(){
	return (type==FIELD && check.isSelected());
    }
	
    public void actionPerformed(ActionEvent e) {
	if (e.getSource() == check) {
	    if (check.isSelected()){
		parent.selectedFieldIndex = index;
		//repaintLayer(g);
		//System.out.println("redraw index " +zIndex +" on layer");
	    } else if(type==FIELD){
		//System.out.println("clear");
		//parent.canvas.repaint();
		//repaintLayer(g);
	    } else {
		//repaintLayer(g);
	    }
	} else if (e.getSource() == up){
	    parent.navigator.moveLayerUp(this.zIndex);
	} else if (e.getSource() == down){
	    parent.navigator.moveLayerDown(this.zIndex);
	} else if (e.getSource() == displays){
	    String selected = (String)displays.getSelectedItem();
	    if (selected.equals("circle")){
		paintMode = OVAL;
	    } else if (selected.equals("img")){
		paintMode = IMG;        		
	    } else if (selected.equals("txt")){
		paintMode = TXT_MOTE;        		
	    } else if (selected.equals("color 256")) {
		paintMode = COLOR_256;
	    } else if (selected.equals("color 1024")) {
		paintMode = COLOR_1024;
	    } else if (selected.equals("color 4096")) {
		paintMode = COLOR_4096;
	    } else if (selected.equals("color 16384")) {
		paintMode = COLOR_16384;
	    } else if (selected.equals("line")) {
		paintMode = LINE;
	    } else if (selected.equals("label")) {
		paintMode = LABEL;
	    } else if (selected.equals("line+label")) {
		paintMode = LINE_LABEL;
	    }
	}
	//System.out.println("Repainting parent?");
	//parent.repaint();
    }

    public void init(){
	if (type==LINK){
	    //addLinks(true);
	} else {
	    addMotes(true);
	}
    }

    public String toString() {
	return "Layer " +  name + " " + type;
    }
    
	
    // private void addLinks(boolean paint){
    // 		Iterator it = models.iterator();
    // 		while(it.hasNext()){
    // 			DLink mm = (DLink) it.next();
    // 			//canvas.add(mm);
    // 			if (paint) mm.repaint();
    // 		}    	
    //     }
	
    protected void addMote(DMoteModel model, boolean paint){
	DShape mote = new DMote(model, this.parent, this);
	layer.add(mote);
    }
	
    private void addMotes(boolean paint){
	Iterator it = models.iterator();
        while(it.hasNext()){
	    addMote((DMoteModel) it.next(), paint);
	} 	    
    }
    
	
    public void updateIndex(int index, boolean repaint){
	zIndex = index;
	z_index = (navigator.totalLayers - zIndex)*100;
	//if (repaint) redrawLayer();
	//parent.canvas.setLayer(d.canvas, length - i);
    }

    public void paintScreenBefore(Graphics g) 
    {

        Dimension d = parent.canvas.getSize();
        int x = 0;
        int y = 0;
        int xstep = (int)(d.width / 40);
	int ystep = (int)(d.height / 40);  

        for(;x < d.width; x += xstep){
            for(y = 0;y < d.height; y += ystep){
                double val = 0;
                double sum = 0;
                double total = 0;
                double min = 10000000;
                Iterator it = models.iterator();
                while(it.hasNext()){
                    DMoteModel m = (DMoteModel) it.next();
                    double dist = distance(x, y, m.x, m.y);   
                    if(true){ //121
                        if(dist < min) min = dist;
                        val += ((double)(((int)m.getValue(index)) >> paintMode ))  / dist /dist;
                        sum += (1/dist/dist);
                    }
                }
                int reading = (int)(val / sum);
		//System.out.println("Reading: " + reading);
                if (reading > 255)
                    reading = 255;
                g.setColor(new Color(reading, reading, reading));
		//System.out.println("Filling "  + x + "+" + step + " " + y + "+" + step + " with " + g.getColor());
                g.fillRect(x, y, xstep, ystep);
            }
        }

	
    }

    public double distance(int x, int y, int x1, int y1){
        return Math.sqrt( (x-x1)*(x-x1)+(y-y1)*(y-y1));
    }

    protected void repaintLayer(Graphics g){
    	if (check.isSelected()){
	    //System.out.println("Repaint layer " + name);
	    if 	(type==FIELD){
		paintScreenBefore(g);
	    } else if (type == LINK) {
		Iterator it = models.iterator();
		//System.out.print("Draw links: ");
		while (it.hasNext()) {
		    DLinkModel model = (DLinkModel)it.next();
		    DLink lnk = new DLink(model, parent, this);
		    lnk.paintShape(g);
		    //System.out.print("+");
		}
		//System.out.println();
	    }
	    else if (type == MOTE) {
		Iterator it = models.iterator();
		//System.out.print("Draw motes: ");
		while (it.hasNext()){
		    DMoteModel model = (DMoteModel)it.next();
		    DShape m = new DMote(model, parent, this);
		    m.paintShape(g);
		    //System.out.print("+");
		}
		//System.out.println();
	    }
    	}	
    }
}
