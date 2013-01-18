<?php

require_once( "../inc/Dispatcher.inc.php" );

$sock = new Dispatcher("127.0.0.1",9114);
$sock->send("This is a simple send...");
//$msg = $sock->sendAndReceive("This is a send and receive terminated by OK...", "OK");
//echo "Received message: $msg\n";
$sock->send("SHUTDOWN");

?>
