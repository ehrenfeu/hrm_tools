#!/usr/bin/env tclsh

package require http 2.0

proc tclPost {url keyValueList} {

  # TODO Add support for proxy?

  # Use a known user agent
  ::http::config -useragent \
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:11.0)\
    Gecko/20100101 Firefox/11.0"

  # Create and pass the query and check the numerical code
  set query [::http::formatQuery {*}$keyValueList]
  set token [::http::geturl $url -query $query]
  set ncode [::http::ncode $token]

  # Cleanup
  ::http::cleanup $token

  # Check the numeric code for success
  if {$ncode == 200} {
    return 1
  }
  return 0
}