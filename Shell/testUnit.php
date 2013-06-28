<?php

require_once 'Shell.inc.php';

$shell = new Process();

//$shell->exec("/Users/aaron/Development/cpp/FakeProc/FakeProc");
$shell->exec("ls -la");

echo "Here we are. The command returned.\n";

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
?>
