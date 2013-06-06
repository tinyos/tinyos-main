/* Copyright (c) 2010 Urs Hunkeler (urs.hunkeler@epfl.ch)  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR THE AUTHOR BE LIABLE TO ANY PARTY
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE COPYRIGHT
 * HOLDER AND/OR THE AUTHOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE COPYRIGHT HOLDER AND THE AUTHOR SPECIFICALLY DISCLAIM ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN
 * "AS IS" BASIS, AND NEITHER THE COPYRIGHT OWNER NOR THE AUTHOR HAS ANY
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS.
 */
package net.tinyos.util;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintStream;

/**
 * This is a loader for native libraries that tries
 * to load the libraries from an alternative path if
 * the tradition loading fails.
 * 
 * The traditional approach is to find and load the native
 * libraries from an operating system and Java implementation
 * specific path. This requires the user to install the
 * libraries in a specific location and has proven to be
 * error prone and a frequent source of problems. The
 * traditional approach is supported by default to give
 * developers a means to easily test new versions of the
 * libraries.
 * 
 * The alternative approach is strictly considered a
 * fall-back method if the libraries have not been installed
 * properly and to ease the deployment of back-end software
 * on non-developer machines.
 * 
 * The alternative method determines the file (or resource)
 * name of the native library based on the current operating
 * system and architecture. It then attempts to copy the
 * library from a resource on the classpath (which might be
 * inside a .jar file, such as the tinyos.jar file) to a
 * temporary file and load the library from this temporary
 * file. The advantage of this method is that no native
 * library files need to be installed on the computer (and
 * thus no administrator rights are necessary). The temporary
 * files are deleted when the virtual machine terminates.
 * 
 * Currently, the library loader class recognizes the
 * following operating systems: Mac OS X, Linux, and Windows.
 * The library loader class further recognizes the following
 * architectures: ppc (PowerPC), x86 (the common Intel x86
 * 32-bit compatible processors), and amd64 (the x86 64-bit
 * processors). Precompiled libraries are only available
 * for the toscomm and getenv libraries for the following
 * platforms: macosx_ppc, macosx_x86, and windows_x86.
 * 
 * @author Urs Hunkeler (urs.hunkeler@epfl.ch)
 */
public class TOSLibraryLoader {
	public static void load(String libName) {
		boolean loaded = false;
		boolean ok = true;
		InputStream is = null;
		FileOutputStream fos = null;
		String text = "";
		
		// attempt to load the library the conventional way
		// (using Java's default library locations and loading
		// mechanism)
		try {
			text += "Attempting to load library '" + libName + "'\n";
			
			System.loadLibrary(libName);
			
			loaded = true;
			text += "Library loaded successfully\n";
		} catch(Throwable t) {
			text += "Could not load library '" + libName + "': " + t.getMessage() + "\n";
			ByteArrayOutputStream baos = new ByteArrayOutputStream();
			PrintStream ps = new PrintStream(baos);
			t.printStackTrace(ps);
			text += "----------\n";
			text += baos.toString();
			text += "----------\n";
		}
		
		if(!loaded) {
			// failed to load the library the conventional way
			System.err.println("Error loading the TinyOS JNI libraries the conventional way!");
			System.err.println(text);
			
			// try to extract the library from the classpath
			// (might be in tinyos.jar)
			
			// First some debugging information
			System.out.println("In order to load the library '" + libName +
					"' Java tries to locate the file '" +
					System.mapLibraryName(libName) + "' in one of the " +
					"following paths:");
			System.out.println(System.getProperty("java.library.path"));
			System.out.println();
			
			String os   = System.getProperty("os.name");
			String arch = System.getProperty("os.arch");
			System.out.println("The operating system is '" + os +
					"' (" + arch + ")");
			System.out.println();
			
			String libFile = null;
			File tmpFile = null;
			if(os.toLowerCase().startsWith("linux")) {
				// Linux
				if(arch.toLowerCase().equals("x86") || arch.toLowerCase().equals("i386")) {
					libFile = "linux_x86_" + libName;
				} else if(arch.toLowerCase().equals("ppc")) {
					// not currently supported
					//libFile = "linux_ppc_" + libName;
				} else if(arch.toLowerCase().equals("amd64")) {
					libFile = "linux_amd64_" + libName;
				}
			} else if(os.toLowerCase().startsWith("windows")) {
				// Windows
				if(arch.toLowerCase().equals("x86") || arch.toLowerCase().equals("i386")) {
					libFile = "windows_x86_" + libName;
				} else if(arch.toLowerCase().equals("ppc")) {
					// not currently supported
					//libFile = "windows_ppc_" + libName;
				} else if(arch.toLowerCase().equals("amd64")) {
					// not currently supported
					//libFile = "windows_amd64_" + libName;
				}
			} else if(os.toLowerCase().startsWith("mac os x")) {
				libFile = "macosx_universal_" + libName;
			}
			if(libFile != null) libFile += ".lib";
			
			if(libFile == null) {
				ok = false;
				System.out.println("The operating system and architecture " +
						"is currently not supported");
			}
			
			if(ok) {
				System.out.println("Trying to locate the file '" + libFile + "' in the classpath");
				// we found a mapping, now let's try to copy
				// the library from the classpath (might be
				// inside a .jar file) to a temporary file
				// and load it from there
				
				// open the library file in the classpath (potentially inside the .jar file)
				is = TOSLibraryLoader.class.getResourceAsStream(libFile);

				if(is == null) {
					System.out.println("The library file was not found in the classpath");
					ok = false;
				}
			}
			
			if(ok) {
				try {
					tmpFile = File.createTempFile(libName, ".lib");
				} catch(IOException ioe) {
					ok = false;
					tmpFile = null;
					System.out.println("Could not create temporary file to extract library, aborting...");
					ioe.printStackTrace();
				}
			}
			if(tmpFile == null) {
				ok = false;
			}
			
			if(ok) {
				System.out.println("Temporary file created: '" + tmpFile.getAbsolutePath() + "'");
				tmpFile.deleteOnExit();
				
				try {
					// open the temporary file for writing
					fos = new FileOutputStream(tmpFile);

					// copy the file
					byte[] buffer = new byte[1024];
					int len = 0;
					while((len = is.read(buffer, 0, buffer.length)) > 0) {
						fos.write(buffer, 0, len);
					}
				} catch(IOException ioe) {
					ok = false;
					System.out.println("An error occurred while copying the library file, aborting...");
					tmpFile.delete();
					tmpFile = null;
				} finally {
					if(fos != null) try { fos.close(); } catch(IOException ioe) { ioe.printStackTrace(); }
					if( is != null) try {  is.close(); } catch(IOException ioe) { ioe.printStackTrace(); }
				}
			}
			
			if(ok) {
				try {
					System.out.println("Library copied successfully. Let's load it.");
					System.load(tmpFile.getAbsolutePath());
					loaded = true;
					System.out.println("Library loaded successfully");
				} catch(Throwable t) {
					ok = false;
					System.out.println("Error loading the library: " + t.getMessage());
					t.printStackTrace();
					tmpFile.delete();
					tmpFile = null;
				}
			}
		}
	}
	
	public static void main(String[] args) {
		load("toscomm");
	}
}
