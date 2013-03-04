// This file is part of the Huygens Remote Manager
// Copyright and license notice: see license.txt

/**
 * Performs an asynchronous Ajax call to the JSON-RPC (2.0) server and
 * passes the results in JSON format to the provided callback
 * in the form function(response) {}
 * @param {JSON object} data   Javascript object in JSON format; it must be in 
 *                             the form:
 *                             
 *                                 data = {
 *                                   method: 'someMethod',
 *                                   params: [ 'param1', 'param2', ... ]
 *                                 }
 *                                 
 * @param {function} callback  Function to be called to preocess the returned
 *                             response; in the form:
 *                             
 *                                 function(response) { ... }
 * 
 * @returns {undefined}
 */
function JSONRPCRequest(data, callback) {

  // Append RPC info to the data array to be sent to
  // the server
  data.id = "1";
  data.jsonrpc = "2.0";

  // Disable caching
  $.ajaxSetup ({  
    cache: false  
  });

  // Submit the Ajax call
  $.ajax(
    { 
      url: "ajax/json-rpc-server.php",
      type: "POST",
      dataType: "json",
      async: true,
      data: data,
      success: callback
    }
  );
}
