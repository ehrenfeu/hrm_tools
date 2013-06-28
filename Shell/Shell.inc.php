<?php

/**
 * A new Shell class
 */
class Process {

    /**
     * @var type A shell process 
     */
    protected $shell = null;
    
    /**
      @var array Array of descriptors (for stdin, stdout, stderr)
     */
    protected $descr = array();

    /**
     * Constructor
     */
    public function __construct() {

        // Set up the descriptors
        $this->descr = array(
            0 => array("pipe", "r"), // stdin from pipe
            1 => array("file", "/tmp/out.txt", "w"), // stdout to file
            2 => array("file", "/tmp/err.txt", "a")  // stderr to file
        );
    }

    /**
     * Execute a process
     */
    public function exec($cmd, $options = array()) {

        // Working directory
        $cwd = "/tmp";
        
        // Run the process
        $process = proc_open("/bin/bash", $this->descr, $pipes, $cwd, $options);

        // This was suggested: check
        //stream_set_blocking($pipes[2], 0);
        //$err = stream_get_contents($pipes[2]);
        //if ($err) {
        //    throw new Exception('Process could not be started [' . $err . ']');
        //}

        if (is_resource($process)) {
            
            // Now send the command
            fwrite($pipes[0], $cmd);
            fclose($pipes[0]);

            // Check the status
            $status = proc_get_status($process);
            echo $status;

            // Get the output
            echo stream_get_contents($pipes[1]);
            fclose($pipes[1]);

            // It is important that you close any pipes before calling
            // proc_close in order to avoid a deadlock
            $return_value = proc_close($process);

            echo "command returned $return_value\n";
        }
    
    }

}

?>
