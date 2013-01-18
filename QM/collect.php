<?php

require_once 'inc/Collector.inc.php';

// Process the posted data
if (isset($_POST)) {
  Collector::process($_POST);
}
?>
