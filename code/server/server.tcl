#Hochreiner Christoph, 0726292

package provide TinyWebServer 0.4


package require XOTcl
namespace import -force ::xotcl::*

array set opt {-port 8081 -root ./html}
array set opt $argv


#####
##### Definition of the Server Class 
#####
Class Httpd -parameter { 
  {port 80} 
  {root /home/httpd/html/} 
  {worker Httpd::Wrk} 
}
Httpd instproc init args {			;# constructor
  my instvar port listen
  my set count 0
  puts stderr "Starting Server; url= http://[info hostname]:$port/"
  set listen [socket -server [list [self] accept] $port]
}
Httpd instproc destroy {} {			;# destructor
  close [my set listen]				;# close listening port
  next
}
Httpd instproc accept {socket ipaddr port} {	;# est. new connection
  [my worker] [self]::w[my incr count] \
	-socket $socket -ipaddr $ipaddr -port $port
}

#####
##### Definition of the Worker Class 
#####
Class Httpd::Wrk -parameter {socket port ipaddr}
Httpd::Wrk array set codes {		;# we treat these status codes
  200 "Data follows" 
  400 "Bad Request"  404 "Not Found" 409 "Conflict"
  501 "Not Implemented"
}
Httpd::Wrk instproc Date secs {clock format $secs -format {%a, %d %b %Y %T %Z}}
Httpd::Wrk instproc close {} {		;# close a request
  puts stderr "[self] [self proc] [my socket] "
  close [my socket]
  my destroy
}
Httpd::Wrk instproc sendLine {msg} {	;# send a line
  puts stderr "[self] send: [my socket] <$msg>"
  puts [my socket] $msg
}
Httpd::Wrk instproc receiveLine {line n} {;# receive a line
  upvar $line received $n nrBytes
  set nrBytes [gets [my socket] received]
  puts stderr "[self] got:  <$received>"
}
Httpd::Wrk instproc fileevent {type method} {
  fileevent [my socket] $type [list [self] $method]
}

Httpd::Wrk instproc init args {		;# Constructor 
  my fileevent readable firstLine
  fconfigure [my socket] -blocking false
}
Httpd::Wrk instproc firstLine {} {	;# Read the first line of request
  my instvar method path fileName 
  my receiveLine line n
  if {[regexp {^(GET|POST) +([^ ]+) +HTTP/.*$} $line _ method path]} {
    set fileName [[my info parent] root]/$path   ;# construct filename
    regsub {/$} $fileName /index.html fileName
    my fileevent readable header
  } else {
    my replyCode 400
  }
}
Httpd::Wrk instproc header {} {	;# Read the header
  my receiveLine line n
  if {$n > 0} { 		;# process header lines
    if {[regexp {^([^:]+): *(.+)$} $line _ key value]} {
      my set meta([string tolower $key]) $value
    }
  } else {
    if {[my exists meta(content-length)]} {
      my set requestBody ""
      my fileevent readable body
    } else {
      my response-[my set method]
    }
  }
}
Httpd::Wrk instproc body {} {;# Read the request body
  my instvar meta requestBody socket
  append requestBody [read $socket]
  if {$meta(content-length) <= [string length $requestBody]} {
    my response-[my set method]
  }
}
Httpd::Wrk instproc response-GET {} {;# Respond to the GET-query
  puts stderr "[self] [self proc]"
  my instvar fileName
  if {[file readable $fileName]} {
    my replyCode 200
    switch [file extension $fileName] { 
      .xhtml { set c [subst [my readFile $fileName]]
	       my sendDynamicString $c }
      default { my sendFile  }
    }
  } else {
    my replyCode 404
  }
}
Httpd::Wrk instproc response-POST {} {;# POST method
  my instvar path asdfghjkl requestBody
#  regsub {\/} $path "" path

  set script $requestBody
#  set script [::base64::decode $script]
  concat "set asdfghjkl \"\"" script "\n return \$asdfghjkl"
  set i [interp create -safe]
  my replyCode 200
  interp alias $i puts {} my handlereturn $i
  
  if {[catch {set result [interp eval $i $script]} msg x]} {
    set result "Errormessage: $msg \n\n"
    append result "Stacktrace:\n  [dict get $x -errorinfo] \n\n"
    append result "on line: [dict get $x -errorline] \n\n"
  }
puts $result
  my sendDynamicString $result
  my close
}

Httpd::Wrk instproc handlereturn {i args} {
  my instvar asdfghjkl
    append asdfghjkl {*}$args
    append asdfghjkl "\n"
}





Httpd::Wrk instproc sendFile {} {
  my instvar fileName socket
  my sendLine "Last-Modified: [my Date [file mtime $fileName]]"
  my sendLine "Content-Type: [my guessContentType $fileName]"
  my sendLine "Content-Length: [file size $fileName]\n"
  set localFile [open $fileName r]
  fconfigure $localFile -translation binary
  fconfigure $socket -translation binary
  fcopy $localFile $socket -command [list [self] sendFile-end $localFile]
}
Httpd::Wrk instproc sendFile-end {localFile args} {
  puts stderr "[self] [self proc]"
  close $localFile
  my close
}
Httpd::Wrk instproc sendDynamicString {content {contentType text/html}} {
  my instvar socket
  my sendLine "Content-Type: $contentType"
  my sendLine "Content-Length: [string length $content]\n"
  fconfigure $socket -encoding [encoding system] -translation binary
  puts -nonewline $socket $content
  my close
}
Httpd::Wrk instproc readFile fn {
  set f [open $fn]
  fconfigure $f -translation binary
  set content [read $f]
  close $f
  return $content
}
Httpd::Wrk instproc guessContentType fn {# derive content type from ext.
  switch [file extension $fn] {
    .gif {return image/gif}   .jpg  {return image/jpeg}
    .htm {return text/html}   .html {return text/html} 
    .css {return text/css}    .ps   {return application/postscript}
    default {return text/plain}
  }
}
Httpd::Wrk instproc replyCode {code} {
  [self class] instvar codes
  my sendLine "HTTP/1.0 $code $codes($code)"
  my sendLine "Date: [my Date [clock seconds]]"
  if {$code >= 300} {
    my sendDynamicString "\n<title>Error: $code</title>\n\
      Error $code: <b>$codes($code)</b><br>\n\
      Url: [my set path]\n"
  }
}

proc bgerror {args} {
  puts stderr "$::argv0 background error: $args"
  puts stderr "\t$::errorInfo\nerrorCode = $::errorCode"
}

Httpd p1 -port $opt(-port) -root $opt(-root)
vwait forever