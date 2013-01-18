<?php

// This file is part of the Huygens Remote Manager
// Copyright and license notice: see license.txt

require_once( "Util.inc.php" );

/*!
  \class	Dispatcher
  \brief	Interacts with the queue manager through socket connections

  Communication from the QueueManager (Tcl) to PHP occurs through POSTs to
  the apache web server. Communication from PHP to the QueueManager (Tcl)
  occurs through socket connection on a predefined port.
 */
class Dispatcher {
  /*!
    \var    $m_Address
    \brief  IP address to the server to connect to
   */
  private $m_Address;

  /*!
    \var    $m_Port
    \brief  Port on the server to connect to
   */
  private $m_Port;

  /*!
    \var    $m_Socket
    \brief  Stream socket
   */
  private $m_Socket;

  /*!
   * \brief Constructor.
   * \param type $address Server address.
   * \param type $port    Server port.
   */
  public function __construct($address, $port) {

    // Make sure we have an ip address
    $this->m_Address = gethostbyname($address);
    $this->m_Port = $port;
    $this->connect();
  }

  /*!
   * \brief Destructor.
   */
  public function __destruct() {

    $this->disconnect();
  }

  /*!
   * \brief Sends a message to the server
   * \param type $message Message to be sent to the server
   */
  public function send($message) {

    // Send the message
    $this->connect();
    if ($this->m_Socket != NULL) {
      fwrite($this->m_Socket, "$message\n");
    }

    $this->disconnect();
  }

  /*!
    \brief  Sends a message to the server and collects the reply.
    \param  $message String to be sent to the server
    \param  $stopCode String received from the server that stops the reading
            Set it to "" to stop as soon as anything is received
    \return string received from the server
   */
  public function sendAndReceive($message, $stopCode) {

    // Send the message
    $this->connect();
    if ($this->m_Socket == NULL) {
      return "";
    }

    // Write to the server
    fwrite($this->m_Socket, "$message\n");

    // Prepare the string to be returned
    $str = "";

    // Now get the message
    $CANSTOP = 0;
    while ($CANSTOP == 0) {
      $read = array($this->m_Socket);
      $write = NULL;
      $except = NULL;
      if (false === ($num_changed_streams = stream_select($read, $write, $except, 0))) {
        // Error
        report("Dispatcher::sendAndReceive(): socket select error!", 0);
        $CANSTOP = 1;
      } elseif ($num_changed_streams > 0) {
        // Something ready to read from the socket
        $out = fread($this->m_Socket, 2048);
        if ($out != "") {
          // If no stop code, we just return
          if ($stopCode == "") {
            $str = $out;
            $CANSTOP = 1;
          } else {
            /// Append to the result string
            $str .= $out;
            // Check that the string contains the stop code, otherwise
            // continue reading
            if (stristr($out, $stopCode) != FALSE) {
              $CANSTOP = 1;
            }
          }
        }
      }
    }

    // Disconnect
    $this->disconnect();

    // Return the string
    return $str;
  }

  /*!
   * \brief Connects to the server.
   * \TODO This should return a boolean.
   */
  private function connect() {

    // Connection string
    $conn = "tcp://$this->m_Address:$this->m_Port";

    // Create a stream socket
    $fp = stream_socket_client($conn, $errno, $errstr, 30);
    if (!$fp) {
      report("Dispatcher::connect(): connection error: $errno - $errstr", 0);
      $this->m_Socket = NULL;
      return;
    }
    $this->m_Socket = $fp;
  }

  /*!
   * Disconnect from the server.
   */
  private function disconnect() {

    // Close the socket
    if ($this->m_Socket != NULL) {
      fclose($this->m_Socket);
      $this->m_Socket = NULL;
    }
  }

}

?>
