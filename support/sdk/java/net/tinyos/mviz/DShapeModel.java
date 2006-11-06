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


// DShapeModel.java
/*
 Store the data state for a single shape:
  type, two points, color
 Supports DShapeModelListeners.
*/
import java.awt.*;

import javax.swing.*;
import java.util.*;
import java.awt.event.*;
import java.io.*;


class DShapeModel extends Object implements Serializable {

	// The 5 standard things for a DShapeModel to store
    protected char type;
    protected int x1, y1, x;
    protected int x2, y2, y;
    protected Color fill; 
    
    protected float value;
    
    protected int HALF_WIDTH = 20;
    protected int HALF_HEIGHT = 20;

    // NOTE: "transient" -- not serialized
    transient private ArrayList listeners;
      
    public DShapeModel(char type, int x, int y, float value) {
        this.type = type;
        this.x = x;
        this.y = y;
        this.value = value;
        int color = (int)(value)%230;
        this.fill = new Color(color+15, color, color+25);
        
        listeners = null;
        
        this.x1 = x - this.HALF_WIDTH;
        this.x2 = x + this.HALF_WIDTH;
        this.y1 = y - this.HALF_HEIGHT;
        this.y2 = y + this.HALF_HEIGHT;
    }
    
    // Construct a DShapeModel with default size.
	public DShapeModel(char type, Color color) {
		this(type, 50, 50, 89, 89, color);
	}
    
    public DShapeModel(){
        this('m', new Color(12,24,48));
    }

	public DShapeModel(char type, int x1, int y1, int x2, int y2, Color fill) {
		this.type = type;
		this.x1 = x1;
		this.y1 = y1;
		this.x2 = x2;
		this.y2 = y2;
		this.fill = fill;
		
		listeners = null;
	}
	
	public DShapeModel(DShapeModel other) {
		this.type = other.type;
		this.x1 = other.x1;
		this.y1 = other.y1;
		this.x2 = other.x2;
		this.y2 = other.y2;
		this.fill = other.fill;
		
		listeners = null;
	}
	
	public char getType() { return(type); }
	
	public int getX1() { return(x1); }
	public int getY1() { return(y1); }
	public int getX2() { return(x2); }
	public int getY2() { return(y2); }
	
	
	// Below here, code not done
	
	
	public void applyDeltas(int dx1, int dy1, int dx2, int dy2) {
	    x1 += dx1;
	    x2 += dx2;
	    y1 += dy1;
	    y2 += dy2;
        
        x += dx1;
        y += dy1;
	    fireChanges();
	}
	
	public int getWidth() {
	    return Math.abs(x2-x1)+1;
	}
	
	public int getHeight() {
	    return Math.abs(y2-y1)+1;
	}
	
	public int getLocX() {
	    return Math.min(x1, x2);
	}
	
	public int getLocY() {
	    return Math.min(y1, y2);
	}
			
	
	
	public Color getColor() { return(fill); }
	public void setColor(Color color) {
	    if (fill.equals(color)) return;
	    fill = color;
	    fireChanges();
	}
	
	
	public void addListener(DShapeModelListener listener) {
	    if (listeners == null) listeners = new ArrayList();
	    Iterator it = listeners.iterator();
		while (it.hasNext()) {
		    if (it.next() == listener)
		        return;
		}
		listeners.add(listener);	    
	}

	public void removeListener(DShapeModelListener listener) {
	    if (listeners == null) return;	    
	    Iterator it = listeners.iterator();
		while (it.hasNext()) {
		    if (it.next() == listener){
		        it.remove();
		        return;
		    }		
		}	        	
	}
	//=========================================================================/
	protected void fireChanges(){
	    if (listeners==null) return;
	    Iterator it = listeners.iterator();
		while (it.hasNext()) 
		   ((DShapeModelListener)(it.next())).shapeChanged(this);
	}
	//=========================================================================/
	public void rotate(){
	    // Get old height/width and locations.
	    int x = getLocX();	int y = getLocY();
	    int w = getWidth();	int h = getHeight();
	    int dL = (h/2-w/2);
	    // Get the locations right.
	    x-=dL;	y+= dL;
	    x1=x;	x2=x+h-1;
	    y1=y;	y2=y+w-1;	
		fireChanges();
	}
	//=========================================================================/
	// Rotation with respect to center.
	public void scale(int magnitude){
	    if (x1<x2){	x1-=magnitude;	x2+=magnitude;
	    }else{ 		x1+=magnitude;	x2-=magnitude;	}
	    if (y1<y2){	y1-=magnitude;	y2+=magnitude;
	    }else{ 		y1+=magnitude;	y2-=magnitude;	}    
	    fireChanges();
	}
	//=========================================================================/
	public void move(int x, int y){
	    int h = getHeight();
	    int w = getWidth();
	    x1=x; x2=x+w-1;
	    y1=y; y2=y+h-1;
	    fireChanges();	    
	}
	
}

