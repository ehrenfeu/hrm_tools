<?php
// This file is part of the Huygens Remote Manager
// Copyright and license notice: see license.txt
?>
<!DOCTYPE html>
<html>
  <head>
    <title></title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <script src="scripts/jquery-1.8.3.min.js"></script>
    <script src="scripts/json-rpc-client.js"></script>    
  </head>
  <body>
    <div id = "info"></div>
    <script>
      $(document).ready(function() {
        var data = {
          'method' : 'someMethod',
          'params': [ '1', '2' ]
        };
        JSONRPCRequest(data, function(response) {
          if (!response) {
            $('#info').html("Got empty response!");
            return;
          }
          $.each(response, function() {
            $('#info').append("<p>" + this.toString() + "</p>");
          });
        });
      });
    </script>
  </body>
</html>
