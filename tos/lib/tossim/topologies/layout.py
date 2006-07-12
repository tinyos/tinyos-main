#!/usr/bin/env python

import pygtk
pygtk.require('2.0')
import gtk

class Mote:
    def __init__(self):
        self.x = 0
        self.y = 0
        self.selected = False

class HelloWorld:
    def hello(self, widget, data=None):
        print "Hello World"

    def delete_event(self, widget, event, data=None):
        print "delete event occured"
        return False

    def destroy(self, widget, data=None):
        gtk.main_quit()

    def addButton(self, string, function, data=None):
        button = gtk.Button(string)
        button.connect("clicked", function, data)
        self.buttonArea.add(button)
        button.show()

    def close(self, x1, y1, x2, y2):
        x1 -= x2
        y1 -= y2
        x1 *= x1
        y1 *= y1
        if (x1 + y1 < 50):
            print "close: ", x1, " ", y1
            return True
        else:
            print "not close: ", x1, " ", y1 
            return False

    def within(self, m, x1, y1, x2, y2):
        gX = max(x1, x2) + 5
        lX = min(x1, x2) - 5
        gY = max(y1, y2) + 5
        lY = min(y1, y2) - 5
        if (m.x >= lX and m.x <= gX and
            m.y >= lY and m.y <= gY):
            print "X: ", lX, "<=", m.x, "<=", gX
            print "Y: ", lY, "<=", m.y, "<=", gY
            return True
        else:
            print "X: ", lX, ">", m.x, ">", gX
            print "Y: ", lY, ">", m.y, ">", gY
            return False
        
    def button_press_event(self, widget, event):
        if event.button == 1 and self.pixmap != None:
            x = event.x
            y = event.y
            print "press at ", x, " ", y
            self.start_x = event.x
            self.start_y = event.y
            self.dx = 0
            self.dy = 0
            self.new_target = True

            for m in self.selected:
                if self.close(m.x, m.y, x, y):
                    self.new_target = False
                            
            if self.new_target:
                for m in self.selected:
                    m.selected = False
                self.selected = []
                
            self.redraw_motes()

    def button_release_event(self, widget, event):
        if event.button == 1 and self.pixmap != None:
            if self.new_target:
                x = event.x
                y = event.y
                print "release at ", x, " ", y
                for m in self.motes:
                    if self.within(m, x, y, self.start_x, self.start_y):
                        m.selected = True
                        self.selected.append(m)
                        self.redraw_motes()
                        self.new_target = False
            else:
                for m in self.selected:
                    m.x += self.dx
                    m.y += self.dy
                    
            self.dx = 0
            self.dy = 0
            self.redraw_motes()
            
    def drag_event(self, widget, event):
        x = y = state = None
        if event.is_hint:
            x, y, state = event.window.get_pointer()
        else:
            x = event.x
            y = event.y
            state = event.state
            
        if state & gtk.gdk.BUTTON1_MASK and self.pixmap != None:
            if not self.new_target:
                self.dx = event.x - self.start_x
                self.dy = event.y - self.start_y
                self.redraw_motes()
                print "drag"

                
    def configure_event(self, widget, event):
        self.widget = widget
        self.x, self.y, self.width, self.height = widget.get_allocation()
        self.pixmap = gtk.gdk.Pixmap(widget.window, self.width, self.height)
        self.pixmap.draw_rectangle(widget.get_style().white_gc, True, 0, 0, self.width, self.height)
        print "Configuring ", self.x, " ", self.y, " ", self.height, " ", self.width
        return True
    
    def expose_event(self, widget, event):
        x , y, width, height = event.area
        print "expose"
        widget.window.draw_drawable(widget.get_style().fg_gc[gtk.STATE_NORMAL],
                                    self.pixmap, x, y, x, y, width, height)
        return False

    def redraw_motes(self):
        self.pixmap.draw_rectangle(self.widget.get_style().white_gc, True, 0, 0, self.width, self.height)
        self.widget.queue_draw_area(0, 0, self.width, self.height)
        for mote in self.motes:
            self.draw_mote(mote)
            
    def draw_mote(self, mote):
        x = mote.x
        y = mote.y
        if mote.selected:
            x += self.dx
            y += self.dy
            
        rect = (int(x-5), int(y-5), 10, 10)
        gc = self.widget.get_style().black_gc
        if mote.selected:
            gc = self.widget.get_style().light_gc[gtk.STATE_SELECTED]
            
        self.pixmap.draw_rectangle(gc, True,
                                   rect[0], rect[1], rect[2], rect[3])

    def createDrawPanel(self):
        self.moteArea = gtk.DrawingArea()
        self.moteArea.set_size_request(400,400)
        self.drawArea.add(self.moteArea)
        self.moteArea.show()
        self.moteArea.connect("expose_event", self.expose_event)
        self.moteArea.connect("configure_event", self.configure_event)
        
        self.moteArea.connect("motion_notify_event", self.drag_event)
        self.moteArea.connect("button_press_event", self.button_press_event)
        self.moteArea.connect("button_release_event", self.button_release_event)

        self.moteArea.set_events(gtk.gdk.EXPOSURE_MASK
                               | gtk.gdk.LEAVE_NOTIFY_MASK
                               | gtk.gdk.BUTTON_PRESS_MASK
                               | gtk.gdk.POINTER_MOTION_MASK
                               | gtk.gdk.POINTER_MOTION_HINT_MASK
                               | gtk.gdk.BUTTON_RELEASE_MASK)


    def createButtonPanel(self):
        self.addButton("Add", self.addNode)
        self.addButton("Remove", self.removeSelected)
        self.addButton("Print", self.printTopology)

        table = gtk.Table(2, 2, True)
        
        label = gtk.Label("Area")
        label.set_justify(gtk.JUSTIFY_LEFT)
        label.show()
        self.distanceText = gtk.TextBuffer()
        self.distanceText.set_text("100")
        view = gtk.TextView(self.distanceText)
        table.attach(label, 0, 1, 0, 1)
        table.attach(view, 1, 2, 0, 1)
        view.show()    

        label = gtk.Label("File")
        label.set_justify(gtk.JUSTIFY_LEFT)
        label.show()
        self.fileText = gtk.TextBuffer()
        self.fileText.set_text("layout.txt")
        view = gtk.TextView(self.fileText)
        view.show()
        table.attach(label, 0, 1, 1, 2)
        table.attach(view, 1, 2, 1, 2)

        self.buttonArea.add(table)
        table.set_row_spacings(4)
        table.show()
        self.addButton("Quit", self.quit);
        
    def __init__(self):
        self.window = gtk.Window(gtk.WINDOW_TOPLEVEL)
        self.window.connect("delete_event", self.delete_event)
        self.window.connect("destroy", self.destroy)
        self.window.set_border_width(10)

        self.buttonArea = gtk.VBox()
        self.drawArea = gtk.VBox()
        self.totalArea = gtk.HBox()
        self.totalArea.add(self.buttonArea)
        self.totalArea.add(self.drawArea)

        self.createDrawPanel()
        self.createButtonPanel()
        
        self.window.add(self.totalArea)
        self.buttonArea.show()
        self.drawArea.show()
        self.totalArea.show()
        self.window.show()

        self.motes = []

        # For clicking and selecting motes
        self.selected = []
        self.new_target = False
        self.start_x = 0
        self.start_y = 0
        self.dx = 0
        self.dy = 0
        
    def add_mote(self, x, y):
        m = Mote()
        m.x = x
        m.y = y
        self.motes.append(m)

    def addNode(self, widget, data=None):
        self.add_mote(50, 50)
        self.redraw_motes()
        print "add node"

    def removeSelected(self, widget, data=None):
        for m in self.selected:
            for other in self.motes:
                if m == other:
                    self.motes.remove(m)
        self.selected = []
        self.redraw_motes()
        print "remove selected"

    def printTopology(self, widget, data=None):
        counter = 0
        startiter, enditer = self.fileText.get_bounds()
        filename = self.fileText.get_text(startiter, enditer)
        file = open(filename, "w")
        for m in self.motes:
            x = m.x
            y = m.y
            startiter, enditer = self.distanceText.get_bounds()
            text = self.distanceText.get_text(startiter, enditer)
            x *= int(text)
            y *= int(text)
            x /= 400
            y /= 400
            file.write(str(counter) + " "+ str(x) + " "+ str(y) + "\n")
        print "print topology"

    def quit(self, widget, data=None):
        gtk.main_quit()
        
    def main(self):
        gtk.main()



if __name__ == "__main__":
    hello = HelloWorld()
    hello.main()

   
