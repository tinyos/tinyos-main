// $Id: BagPanel.java,v 1.1 2007-04-04 21:01:11 idgay Exp $

/*									tab:4
 * Copyright (c) 2007 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


import javax.swing.*;
import java.awt.*;
import java.awt.event.*;

/**
 * A GridBagLayout based panel with convenience methods for 
 * making various swing items. These methods also ensure a
 * consistent appearance.
 *
 * @author David Gay
 */
public class BagPanel extends JPanel {
    Font boldFont = new Font("Dialog", Font.BOLD, 12);
    Font normalFont = new Font("Dialog", Font.PLAIN, 12);

    GridBagLayout bag;
    GridBagConstraints c;

    public BagPanel() {
	bag = new GridBagLayout();
	setLayout(bag);
	c = new GridBagConstraints();
    }

    public JButton makeButton(String label, ActionListener action) {
	JButton button = new JButton();
        button.setText(label);
        button.setFont(boldFont);
	button.addActionListener(action);
	bag.setConstraints(button, c);
	add(button);
	return button;
    }

    public JCheckBox makeCheckBox(String label, boolean selected) {
	JCheckBox box = new JCheckBox(label, selected);
	box.setFont(normalFont);
	bag.setConstraints(box, c);
	add(box);
	return box;
    }

    public JLabel makeLabel(String txt, int alignment) {
	JLabel label = new JLabel(txt, alignment);
	label.setFont(boldFont);
	bag.setConstraints(label, c);
	add(label);
	return label;
    }

    public JTextField makeTextField(int columns, ActionListener action) {
	JTextField tf = new JTextField(columns);
	tf.setFont(normalFont);
	tf.setMaximumSize(tf.getPreferredSize());
	tf.addActionListener(action);
	bag.setConstraints(tf, c);
	add(tf);
	return tf;
    }

    public void addSeparator(int axis) {
	JSeparator sep = new JSeparator(axis);
	bag.setConstraints(sep, c);
	add(sep);
    }

}
