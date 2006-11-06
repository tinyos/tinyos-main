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

import java.lang.reflect.*;
import java.util.*;

public class DataModel {
    Vector packetClasses = new Vector();
    Vector fields = new Vector();
    Vector links = new Vector();

    public DataModel(Vector messageNames) {
	createPackets(messageNames);
	parseFieldsAndLinks();
    }

    public Vector fields() {
	return fields;
    }

    public Vector links() {
	return links;
    }
	
    private void createPackets(Vector messageNames) {
	for (int i = 0; i < messageNames.size(); i++) {
	    try {
		System.out.println("Making " + messageNames.elementAt(i));
		Class c = Class.forName((String)messageNames.elementAt(i));
		packetClasses.add(c);
	    }
	    catch (ClassNotFoundException ex) {
		System.err.println("Unable to find message type " + messageNames.elementAt(i) + ": please check your CLASSPATH.");
	    }
	}
    }

    private boolean isSubClass(Class subC, Class superC) {
	if (subC == superC) {return false;}
	for (Class tmp = subC.getSuperclass(); tmp != null; tmp = tmp.getSuperclass()) {
	    if (tmp.equals(superC)) {
		return true;
	    }
	}
	return false;
    }

    private void parseFieldsAndLinks() {
	net.tinyos.message.Message msg = new net.tinyos.message.Message(0);
	Class messageClass = msg.getClass();
	for (int i = 0; i < packetClasses.size(); i++) {
	    Class pkt = (Class)packetClasses.elementAt(i);
	    if (!(isSubClass(pkt, messageClass))) {
		continue;
	    }
	    loadFieldsAndLinks(pkt);
	}
    }

    private void loadFieldsAndLinks(Class pkt) {
	Method[] methods = pkt.getMethods();
	for (int i = 0; i < methods.length; i++) {
	    Method method = methods[i];
	    String name = method.getName();
	    if (name.startsWith("get_") && !name.startsWith("get_link")) {
		name = name.substring(4); // Chop off "get_"
		Class[] params = method.getParameterTypes();
		if (params.length == 0 && !method.getReturnType().isArray()) {
		    loadField(name, method, method.getReturnType());
		    System.out.println("Loading " + name);
		}
	    }
	    else if (name.startsWith("get_link_") && name.endsWith("_value")) {
		name = name.substring(9); // chop off "get_link_"
		name = name.substring(0, name.length() - 6); // chop off "_value"
		Class[] params = method.getParameterTypes();
		if (params.length == 0) {
		    loadLink(name, method, method.getReturnType());
		}
	    }
	}
    }

    private void loadField(String name, Method method, Class param) {
	fields.add(name);
    }
    private void loadLink(String name, Method method, Class param) {
	System.out.println("Loading link <" + name + ">");
	links.add(name);
    }
}
