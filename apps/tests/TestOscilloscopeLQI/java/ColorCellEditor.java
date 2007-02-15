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
import java.awt.*;
import java.awt.event.*;

/* Editor for table cells representing colors. Popup a color chooser. */
public class ColorCellEditor extends AbstractCellEditor
    implements TableCellEditor {
    private Color color;
    private JButton button;

    public ColorCellEditor(String title) {
	button = new JButton();
	final JColorChooser chooser = new JColorChooser();
	final JDialog dialog = JColorChooser.createDialog
	    (button, title, true, chooser,
	     new ActionListener() {
		 public void actionPerformed(ActionEvent e) {
		     color = chooser.getColor();
		 } },
	     null);

	button.setBorderPainted(false);
	button.addActionListener
	    (new ActionListener () {
		    public void actionPerformed(ActionEvent e) {
			button.setBackground(color);
			chooser.setColor(color);
			dialog.setVisible(true);
			fireEditingStopped();
		    } } );
	
    }

    public Object getCellEditorValue() { return color; }
    public Component getTableCellEditorComponent(JTable table,
                                                 Object value,
                                                 boolean isSelected,
                                                 int row,
                                                 int column) {
        color = (Color)value;
        return button;
    }
}

