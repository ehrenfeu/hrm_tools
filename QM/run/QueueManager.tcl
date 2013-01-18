#!/usr/bin/env tclsh

# Tcl implementation of a Queue Manager / Job Dispatcher prototype.
#
# The final version should get arguments for the available servers,
# their statuses and the job queue with priorities.

source QueueManagerUtils.tcl

# ------------------------------- UTILITIES ---------------------------------- #

proc postToWebServer { postList } {
    puts $postList
    set post [tclPost "http://localhost/HRMHackathon/collect.php" $postList]
}


# We would like to prevent the ioP variable from growing too much. Remove
# the variables associated to a specific id.
proc flushDispatchId { dispatchId } {
    variable ioP

    set fList [array names ioP]

    foreach f $fList {
        if { [string match "*,$dispatchId" $f]} {
            unset ioP($f)
        }
    }
}


# ------------------- PIPE LAYER: SSH CONNECTIONS TO THE BACKEND-------------- #

proc readFromPipe { pipeId } {
    if { [eof $pipeId] } {
        catch {close $pipeId}
        return
    }
    set error [gets $pipeId line]
}


# ---------------- SOCKET LAYER:  CONNECTIONS TO THE FRONTEND ---------------- #

proc getClientRequest { clientId } {

    # Read from the client any data sent to the server.
    if {[catch {gets $clientId} clientRequest] != 0} {
        return 0
    } elseif {$clientRequest eq ""} {
        return 0
    } elseif {[eof $clientId]} {

        # Nothing to do, what was read from the socket was the eof signal.
        puts "Closing socket $clientId"
        close $clientId
        return 0
    }

    return $clientRequest
}


proc processClientRequest { clientRequest clientId } {

    if {$clientRequest == 0} {return}

    if { [string match "*DECONLAUNCH*" $clientRequest] } {
        launchDeconvolution $clientRequest $clientId
    }

    if { [string match "*PREVIEWGEN*" $clientRequest] } {
        generatePreview $clientRequest $clientId
    }

    if { [string match "*SNRESTIMATE*" $clientRequest] } {
        estimateSnr $clientRequest $clientId
    }

    if { [string match "*STOP*" $clientRequest] } {
        stopProcess $clientRequest $clientId
    }

    if { [string match "*RENICE*" $clientRequest] } {
        renice $clientRequest $clientId
    }

    if { [string match "*SHUTDOWN*" $clientRequest] } {
        shutdownServer $clientId
    } 
}


# Open an SSH connection to a processing server to run a deconvolution job.
proc launchDeconvolution { clientRequest clientId } {
    variable ioP ; variable dispatchId

    # Extract template path, template name, and processing server 
    # from the client request.
    regexp {.*\| (.*?) \| (.*?)} $clientRequest matches huTemplate procServer

    # Execute the template.
    set cmd "ssh $procServer hucore -checkUpdates disable -noExecLog\
            -template $huTemplate"

    set pipeId [open "| $cmd"]
    fileevent $pipeId readable [list readFromPipe $pipeId]    
    fconfigure $pipeId -blocking 0

    # Link this request to the particular socket client that sent it, and to 
    # the processing server where it will be processed.
    set pid [pid $pipeId]
    set ioP(process,pid,$dispatchId)        $pid
    set ioP(process,procServer,$dispatchId) $procServer
    set ioP(process,client,$dispatchId)     $clientId
    set ioP(process,pipe,$dispatchId)       $pipeId

    # The process id must be unique, increase it.
    incr dispatchId

     # Report back to the web server whether or not the process is Ok.
    set msgToWebServer [list process "decon" \
                            server $procServer \
                            status "busy" \
                            pid $pid \
                            dispatchId $dispatchId]
    postToWebServer $msgToWebServer
}


# Open an SSH connection to a processing server to create an image preview.
proc generatePreview { clientRequest clientId } {
    variable ioP ; variable dispatchId

    # Extract processing server name, preview options, etc from the 
    # client request.
    set pattern {.*\| (.*?) \| (.*?) \| (.*?) \| (.*?)}
    regexp $pattern $clientRequest matches procServer huCoreTcl tool options

    # Execute the preview instructions (to be replaced by templates).
    set cmd "ssh $procServer hucore -noExecLog -checkUpdates disable \
             -tool $tool -task $huCoreTcl -huCoreTcl $huCoreTcl \
             -options $options" 

    set pipeId [open "| $cmd"]
    fileevent $pipeId readable [list readFromPipe $pipeId]    
    fconfigure $pipeId -blocking 0

    # Link this request to the particular socket client that sent it, and to 
    # the processing server where it will be processed.
    set pid [pid $pipeId]
    set ioP(process,pid,$dispatchId)        $pid
    set ioP(process,procServer,$dispatchId) $procServer
    set ioP(process,client,$dispatchId)     $clientId
    set ioP(process,pipe,$dispatchId)       $pipeId

    # The process id must be unique, increase it.
    incr dispatchId

    # Report back to the web server whether or not the process is Ok.
    set msgToWebServer [list process "preview" server $server status "busy"]
    postToWebServer $msgToWebServer
}


# Open an SSH connection to a processing server to estimate the SNR.
proc estimateSnr { clientRequest clientId } {
    variable ioP ; variable dispatchId

    # Extract processing server name, preview options, etc from the 
    # client request.
    set pattern {.*\| (.*?) \| (.*?) \| (.*?) \| (.*?)}
    regexp $pattern $clientRequest matches procServer huCoreTcl tool options

    # Execute the snr estimation (to be replaced by templates).
    set cmd "ssh $procServer hucore -noExecLog -checkUpdates disable \
             -tool $tool -task $huCoreTcl -huCoreTcl $huCoreTcl \
             -options $options" 

    set pipeId [open "| $cmd"]
    fileevent $pipeId readable [list readFromPipe $pipeId]    
    fconfigure $pipeId -blocking 0

    # Link this request to the particular socket client that sent it, and to 
    # the processing server where it will be processed.
    set pid [pid $pipeId]
    set ioP(process,pid,$dispatchId)        $pid
    set ioP(process,procServer,$dispatchId) $procServer
    set ioP(process,client,$dispatchId)     $clientId
    set ioP(process,pipe,$dispatchId)       $pipeId

    # The process id must be unique, increase it.
    incr dispatchId

     # Report back to the web server whether or not the process is Ok.
    set msgToWebServer [list process "Snr" server $procServer status "busy"]
    postToWebServer $msgToWebServer
}


# Change the priority of a running process.
proc renice { clientRequest clientId } {
    variable ioP ; variable dispatchId

    # Extract processing server name, preview options, etc from the 
    # client request.
    set pattern {.*\| (.*?) \| (.*?) \| (.*?)}
    regexp $pattern $clientRequest matches procServer priority procId

    # Renice an existing, ongoing process.
    set cmd "ssh $procServer renice $priority $procId"

    set pipeId [open "| $cmd"]
    fileevent $pipeId readable [list readFromPipe $pipeId]    
    fconfigure $pipeId -blocking 0

    # Link this request to the particular socket client that sent it, and to 
    # the processing server where it will be processed.
    set pid [pid $pipeId]
    set ioP(process,pid,$dispatchId)        $pid
    set ioP(process,procServer,$dispatchId) $procServer
    set ioP(process,client,$dispatchId)     $clientId
    set ioP(process,pipe,$dispatchId)       $pipeId

    # The process id must be unique, increase it.
    incr dispatchId

    # Report back to the web server whether or not the process is Ok.
    set msgToWebServer [list process "Renice" server $procServer status "busy"]
    postToWebServer $msgToWebServer
}


proc stopProcess { clientRequest clientId } {
    variable ioP ; variable dispatchId

    # Extract processing server name, preview options, etc from the 
    # client request.
    set pattern {.*\| (.*?) \| (.*?)}
    regexp $pattern $clientRequest matches pid procServer

    # Stop (kill) an existing, ongoing process.
    set cmd "ssh $procServer kill $pid"

    set pipeId [open "| $cmd"]
    fileevent $pipeId readable [list readFromPipe $pipeId]    
    fconfigure $pipeId -blocking 0

    # Link this request to the particular socket client that sent it, and to 
    # the processing server where it will be processed.
    set pid [pid $pipeId]
    set ioP(process,pid,$dispatchId)        $pid
    set ioP(process,procServer,$dispatchId) $procServer
    set ioP(process,client,$dispatchId)     $clientId
    set ioP(process,pipe,$dispatchId)       $pipeId

    # The process id must be unique, increase it.
    set dispatchIdToFlush $dispatchId
    incr dispatchId

    # Report back to the web server whether or not the process is Ok.
    set msgToWebServer [list process "Stop" server $procServer status "busy"]
    postToWebServer $msgToWebServer

    flushDispatchId $dispatchIdToFlush
}


# The socket client can signal the server to shutdown.
proc shutdownServer { clientId } {
    variable shutdownSignal

    after 5000
    set shutdownSignal 1

    set msgToWebServer [list process "shutdown" status "Ok"]
    postToWebServer $msgToWebServer
}


proc readFromClientCB { clientId } {

    if {[eof $clientId]} {
        puts "Closing socket $clientId"
        close $clientId
        return
    }
    
    set clientRequest [getClientRequest $clientId]
    processClientRequest $clientRequest $clientId
}


# We'll keep the sockets unidirectional (client->server) as the server->client
# messages are redirected via POST. Still add this callback for when the
# server-client direction has to be used. Moreover, it seems that the client
# does a need a callback for completness sake.
proc writeToClientCB { clientId } {
    variable ioP

    if { ![info exists ioP(msg,clientId)]} {
        return
    } elseif {$ioP(msg,clientId) eq ""} {
        return
    } else {
        set ioP(msg,clientId) ""
        flush $clientId
    }

    flush $clientId
}


# ---------------------------------------------------------------------------- #

# Add callbacks to process the communication with the client.
proc installClientHandlers {clientId clientAddress clientPort} {
    fileevent $clientId readable [list readFromClientCB $clientId]
    fileevent $clientId writable [list writeToClientCB  $clientId]
}


# dispatchId is, in this context, not linked to the OS pid. It stores a process 
# number linked to the processes handled in the lifetime of the server.
proc startSocketServer { port } {
    variable dispatchId

    if { ![info exists dispatchId] } {set dispatchId 0}

    set server [socket -server installClientHandlers $port]
    puts "Server started"
}


# ---------------------------------------------------------------------------- #

set serverPort 9114
startSocketServer $serverPort
vwait shutdownSignal