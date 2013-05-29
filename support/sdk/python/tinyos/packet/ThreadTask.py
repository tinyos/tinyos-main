#
# Copyright (c) 2005
#      The President and Fellows of Harvard College.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of the University nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE UNIVERSITY AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE UNIVERSITY OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# Author: Geoffrey Mainland <mainland@eecs.harvard.edu>
#
import threading
import time

class ThreadTask:
    def __init__(self, runner):
        self.done = False
        self.runner = runner

        runner.add(self)

    def isDone(self):
        return self.done

    def cancel(self):
        self.done = True

    def finish(self):
        self.runner.remove(self)

class ThreadTaskRunner:
    def __init__(self):
        self.taskList = []
        self.taskListLock = threading.Lock()

    def add(self, task):
        self.taskListLock.acquire()
        self.taskList = [task] + self.taskList
        self.taskListLock.release()

    def remove(self, task):
        self.taskListLock.acquire()
        self.taskList.remove(task)
        self.taskListLock.release()

    def start(self, task):
        thread = threading.Thread(None, task)
        thread.setDaemon(True)
        thread.start()

    def cancelAll(self):
        self.taskListLock.acquire()

        for t in self.taskList:
            try:
                t.cancel()
            except:
                pass

        self.taskListLock.release()

    def finish(self):
        try:
            self.taskListLock.acquire()

            while len(self.taskList) != 0:
                self.taskListLock.release()
                time.sleep(0.2)
                self.taskListLock.acquire()

            self.taskListLock.release()
        except:
            pass
