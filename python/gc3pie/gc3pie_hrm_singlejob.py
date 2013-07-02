#!/usr/bin/env python
# -*- coding: utf-8 -*-#
# @(#)gc3pie_hrm_singlejob.py
#
"""
This is a test script to run a fully prepared job on a hucore.

You can specify the resource you want to use by passing its name as
command line argument.
"""

# stdlib imports
import sys
import time

# GC3Pie imports
import gc3libs

import logging
# loglevel = logging.DEBUG
loglevel = logging.WARN
gc3libs.configure_logger(loglevel, "gc3hucore")

class HucoreDeconvolveApplication(gc3libs.Application):
    """
    This application calls `hucore` with a given template file and retrives the
    stdout/stderr in a file named `stdout.txt` plus the directories `resultdir`
    and `previews` into a directory `deconvolved` inside the current directory.
    """
    def __init__(self):
        gc3libs.Application.__init__(
            self,
            arguments = ["/usr/local/bin/hucore",
                '-template', 'hrm_template_relative.tcl'],
            inputs = ['./hrm_template_relative.tcl', 'bad.lsm'],
            outputs = ['resultdir', 'previews'],
            output_dir = './deconvolved',
            stderr = 'stdout.txt', # combine stdout & stderr
            stdout = 'stdout.txt')

# Create an instance of HucoreDeconvolveApplication
app = HucoreDeconvolveApplication()

# Create an instance of `Engine` using the configuration file present in your
# home directory.
engine = gc3libs.create_engine()

# Add your application to the engine. This will NOT submit your application
# yet, but will make the engine *aware* of the application.
engine.add(app)

# in case you want to select a specific resource, call
# `Engine.select_resource(<resource_name>)`
if len(sys.argv)>1:
    engine.select_resource(sys.argv[1])

# Periodically check the status of your application.
while app.execution.state != gc3libs.Run.State.TERMINATED:
    print "Job in status %s " % app.execution.state
    # `Engine.progress()` will do the GC3Pie magic: submit new jobs, update
    # status of submitted jobs, get results of terminating jobs etc...
    engine.progress()

    # Wait a few seconds...
    time.sleep(1)

print "Job is now terminated."
print "The output of the application is in `%s`." %  app.output_dir
