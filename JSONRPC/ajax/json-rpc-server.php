<?php
// This file is part of the Huygens Remote Manager
// Copyright and license notice: see license.txt

// This is not strictly necessary for the Ajax communication, but will be 
// necessary for accessing session data to create the response.
session_start();

// Check that we have a valid request
if (isset($_POST)) {
  
  // Do we jave a JSON-RPC 2.0 request? We do NOT test for the value of id.
  if (!(isset($_POST['id']) &&
          isset($_POST['jsonrpc']) && $_POST['jsonrpc'] == "2.0")) {
    
    // Invalid JSON-RPC 2.0 call
    die(json_encode(
            array(
                "status" => "fail",
                "message" => "Invalid JSON-RPC 2.0 call."
                )));
  };
  
  // Do we have a method with params?
  if (!isset($_POST['method']) && !isset($_POST['params'])) {

    // Expected 'method' and 'params'
    die(json_encode(
            array(
                "status" => "fail",
                "message" => "Expected 'method' and 'params'."
                )));
  }
  
  // Get the method and its params
  $method = $_POST['method'];
  $params = $_POST['params'];
  
  // Currently we just echo the method and params back as a proof that it works.
  // Later, obviously, we would call the relevant PHP method and pack the 
  // response back into JSON.
  $out = array();
  $out['method'] = $method;

  for ($i = 0; $i < count($params); $i++) {
    $out["param" . $i] = $params[$i]; 
  }

  header("Content-Type: application/json", true);
  echo json_encode($out);
  
} else {
  
  header("Content-Type: application/json", true);
  echo json_encode(array("message" => "Nothing POSTed!"));

}

?>
