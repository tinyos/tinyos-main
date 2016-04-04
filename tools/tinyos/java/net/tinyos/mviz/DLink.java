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

// DShape.java
import java.awt.*;
import java.util.*;
import javax.swing.*;
import java.awt.event.*;
import java.awt.geom.GeneralPath;
import java.awt.geom.Line2D;

public class DLink 
extends JComponent 
implements DLinkModelListener
{
	
	protected DLinkModel model;
	protected DDocument document;
    private DLayer layer;
    // remember the last point for mouse tracking
	private int lastX, lastY;
	
	// Move or Resize ?
	private int action;
    private static final int MOVE = 0;
	//=========================================================================//
    public DLink(DLinkModel model, DDocument document, DLayer layer) {
		super();
		this.model = model;
		this.layer = layer;
		this.document = document;
		model.addListener(this);
		
		// Mouse listeners.
		addMouseListener( 
		        new MouseAdapter() 
		        {
		            public void mousePressed(MouseEvent e) {
		                selected();
		                lastX = e.getX()+getX();
		                lastY = e.getY()+getY();
		                
		                if (e.isControlDown()){ 
		                }else if(e.isAltDown()){ 
		                }else if(e.isShiftDown()){
		                }else{ DetermineAction(lastX, lastY); }			    
		            }
		        }
		);

		addMouseMotionListener( 
		        new MouseMotionAdapter() 
		        {
		            public void mouseDragged(MouseEvent e) {
		                
		                int x = e.getX()+getX();
		                int y = e.getY()+getY();
		                // compute delta from last point
		                int dx = x-lastX;
		                int dy = y-lastY;
		                lastX = x;
		                lastY = y;
		                
		                switch(action){
		                case MOVE: DoAction(dx, dy); break;
		                }
		            }
		        }
		);
		
		synchToModel();		
	}
   
	//=========================================================================//
	public DLinkModel getModel() {
		return(model);
	}
	
	//=========================================================================//
	public void shapeChanged(DLinkModel changed, int type) {
	    synchToModel();
	    repaint();
	}
	//=========================================================================//
    public void paintShape(Graphics g){
	    Graphics2D g2 = (Graphics2D) g;
	    g.setColor(Color.BLACK);
	    int diffX = (model.m1.getLocX() - model.m2.getLocX());
	    int diffY = (model.m1.getLocY() - model.m2.getLocY());
	    if (diffX == 0 && diffY == 0) {
		return;
	    }
	    if (diffX == 0) {diffX = 1;}
	    if (diffY == 0) {diffY = 1;}
	    int midX = (model.m1.getLocX() + model.m2.getLocX()) / 2;
	    int midY = (model.m1.getLocY() + model.m2.getLocY()) / 2;
	    int arrowX = midX;
	    int arrowY = midY;
	    midY += 8;
	    midX += 10;
	    //midX += Math.abs(((double)diffX / ((double)Math.abs(diffY) + (double)Math.abs(diffX))) * 60);
	    if (diffX * diffY < 0) {
		midY += Math.abs(((double)diffX / ((double)Math.abs(diffY) + (double)Math.abs(diffX))) * 10);
		midX += Math.abs(((double)diffX / ((double)Math.abs(diffY) + (double)Math.abs(diffX))) * 10);
	    }
	    else {
		midY -= Math.abs(((double)diffX / ((double)Math.abs(diffY) + (double)Math.abs(diffX))) * 10);
		midX += Math.abs((double)diffX / ((double)Math.abs(diffY) + (double)Math.abs(diffX)) * 10);
	    }
	    
	    //draw a arrow
	    
	    switch(layer.paintMode) {
	    case DLayer.LINE_LABEL:
		g.setColor(Color.BLACK);
		g2.setFont(new Font("Tahoma", Font.BOLD, 12));
		g2.drawString(document.sensed_links.elementAt(layer.index) + ": " + (int)model.getValue(layer.index), midX, midY);
	    case DLayer.LINE:
		//set line width
		g2.setStroke(new BasicStroke(1));
		//set line color
		if((int)model.getValue(layer.index)>300 && (int)model.getValue(layer.index)<500){
			g2.setColor(Color.orange);
		}else if((int)model.getValue(layer.index)>500){
			g2.setColor(Color.RED);
		}else{
			g2.setColor(Color.GREEN);
		}
		g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
		g2.draw(new Line2D.Double(model.m1.getLocX(),  model.m1.getLocY(), model.m2.getLocX(), model.m2.getLocY()));
		
		drawAL(model.m1.getLocX(),model.m1.getLocY(),arrowX,arrowY,g2);
		break;
		
	    case DLayer.LABEL:
		g.setColor(Color.BLACK);
		g2.drawString(document.sensed_links.elementAt(layer.index) + ": " + (int)model.getValue(layer.index), midX, midY);
		break;
	    }
	}
    //=========================================================================//
    public void paintComponent(Graphics g) {
    }
	//=========================================================================//
	private void DetermineAction(int x, int y){
        action = MOVE;	        
	}
	//=========================================================================//
	private void DoAction(int dx, int dy){
	}
	//=========================================================================//
	private void synchToModel(){
	    setBounds(model.getTop(), model.getLeft(), model.getWidth(), model.getHeight());
	}
	//=========================================================================//
	private void selected(){    
	}
	
	 public static void drawAL(int sx, int sy, int ex, int ey, Graphics2D g2)  
	    {  
	  
	        double H = 10; // arrow'height
	        double L = 4;
	        int x3 = 0;
	        int y3 = 0;
	        int x4 = 0;
	        int y4 = 0;
	        double awrad = Math.atan(L / H); //
	        double arraow_len = Math.sqrt(L * L + H * H); // arrow'length
	        double[] arrXY_1 = rotateVec(ex - sx, ey - sy, awrad, true, arraow_len);
	        double[] arrXY_2 = rotateVec(ex - sx, ey - sy, -awrad, true, arraow_len);
	        double x_3 = ex - arrXY_1[0]; // startPoint
	        double y_3 = ey - arrXY_1[1];
	        double x_4 = ex - arrXY_2[0]; // endPoint 
	        double y_4 = ey - arrXY_2[1];
	  
	        Double X3 = new Double(x_3);
	        x3 = X3.intValue();
	        Double Y3 = new Double(y_3);
	        y3 = Y3.intValue();  
	        Double X4 = new Double(x_4);
	        x4 = X4.intValue();
	        Double Y4 = new Double(y_4);
	        y4 = Y4.intValue();
	        // drawline 
	       // g2.drawLine(sx, sy, ex, ey);
	        //  
	        GeneralPath triangle = new GeneralPath();
	        triangle.moveTo(ex, ey);
	        triangle.lineTo(x3, y3);
	        triangle.lineTo(x4, y4);
	        triangle.closePath();
	         
	        g2.fill(triangle);
	        
	        //g2.draw(triangle);  
	  
	    }

    public static double[] rotateVec(int px, int py, double ang,
            boolean isChLen, double newLen) {
  
        double mathstr[] = new double[2];
        double vx = px * Math.cos(ang) - py * Math.sin(ang);
        double vy = px * Math.sin(ang) + py * Math.cos(ang);
        if (isChLen) {
            double d = Math.sqrt(vx * vx + vy * vy);
            vx = vx / d * newLen;
            vy = vy / d * newLen;
            mathstr[0] = vx;
            mathstr[1] = vy;
        }
        return mathstr;
    }
}




