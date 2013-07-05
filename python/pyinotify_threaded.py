#!/usr/bin/env python

'''
Simple ThreadedNotifier script based on the one given in the pyinotify-tutorial
on http://github.com/seb-m/pyinotify/wiki/Tutorial
'''

import pyinotify
import time

wm = pyinotify.WatchManager() # Watch Manager
mask = pyinotify.IN_DELETE | pyinotify.IN_CREATE # watched events

class EventHandler(pyinotify.ProcessEvent):
    def __init__(self):
        super(EventHandler, self).__init__()
        print('Instantiated "EventHandler" object.')

    def process_IN_CREATE(self, event):
        print "Creating:", event.pathname
        time.sleep(1)

    def process_IN_DELETE(self, event):
        print "Removing:", event.pathname
        time.sleep(1)


#log.setLevel(10)
notifier = pyinotify.ThreadedNotifier(wm, EventHandler())
notifier.start()

watchdir = '/tmp/spool'
wdd = wm.add_watch(watchdir, mask, rec=True)

print('Added watch to "%s", press Ctrl-C to abort.' % watchdir)
while True:
    try:
        time.sleep(100)
    except KeyboardInterrupt:
        break

print('Cleaning up.')
wm.rm_watch(wdd.values())
notifier.stop()
