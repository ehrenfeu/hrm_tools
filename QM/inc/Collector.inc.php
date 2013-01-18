<?php
// This file is part of the Huygens Remote Manager
// Copyright and license notice: see license.txt

require_once( "Util.inc.php" );

/*!
  \class	Collector
  \brief	Processes the reports coming from the queue manager (as posts to apache)
 
  Communication from the QueueManager (Tcl) to PHP occurs through POSTs to
  the apache web server. Communication from PHP to the QueueManager (Tcl) 
  occurs through socket connection on admin-defined port.
*/
class Collector {

  /*!
   * Processes the POSTed array
   * \param type $post POST array
   */
  public static function process( $post ) {
    
    // Is there anything to process?
    if (!isset($post)) {
      return;
    }
    
    // It $post a valid array?
    if (!is_array($post)) {
      report( "Collector: \$post must be an array!", 0);
      return;
    }

    // Check the ID of the caller
    // TODO
    
    // Now interpret the commands
    // TODO
  }

}

?>
