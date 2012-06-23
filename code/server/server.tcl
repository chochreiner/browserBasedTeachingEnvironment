
package require base64
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
Httpd instproc init args {		;# constructor
  my instvar port listen
  puts stderr "Starting Server; url= http://[info hostname]:$port/"
  set listen [socket -server [list [self] accept] $port]
}
Httpd instproc destroy {} {		;# destructor
  close [my set listen]			;# close listening port
  next
}
Httpd instproc accept {socket ipaddr port} {	;# est. new connection
  [my worker] [self]::w0 -socket $socket -ipaddr $ipaddr -port $port
}

#####
##### Definition of the Worker Class 
#####
Class Httpd::Wrk -parameter {socket port ipaddr}
Httpd::Wrk array set codes {		;# we treat these status codes
  200 "Data follows"  400 "Bad Request"  404 "Not Found"
}
Httpd::Wrk instproc Date secs {clock format $secs -format {%a, %d %b %Y %T %Z}}
Httpd::Wrk instproc close {} {		;# close a request
  puts stderr [self proc]
  close [my socket]
  my destroy
}
Httpd::Wrk instproc sendLine {msg} {	;# send a line
  puts stderr "send: <$msg>"
  puts [my socket] $msg
}
Httpd::Wrk instproc receiveLine {line n} {;# receive a line
  upvar $line received $n nrBytes
  set nrBytes [gets [my socket] received]
  puts stderr "got:  <$received>"
}
Httpd::Wrk instproc init args {		;# Constructor 
  my firstLine
}
Httpd::Wrk instproc firstLine {} {	;# Read the first line of request
  my instvar method path fileName 
  my receiveLine line n
  if {[regexp {^(GET) +([^ ]+) +HTTP/.*$} $line _ method path]} {
    set fileName [[my info parent] root]/$path         ;# construct filename
    regsub {/$} $fileName /index.html fileName
    my header
  } else {
    my replyCode 400
  }
}
Httpd::Wrk instproc header {} {	;# Read the header
  my receiveLine line n
  while {$n > 0} { 		;# process header lines (ignore here)
    my receiveLine line n	;# read next header line
  }
  my response
}
Httpd::Wrk instproc response {} {;# Respond to the GET-query
  my instvar fileName
  if {[file readable $fileName]} {
    set content [my readFile $fileName]
    my replyCode 200
    switch [file extension $fileName] { 
      .xhtml   { set c [subst $content]
	         my sendDynamicString $c }
      default { my sendFile $content }
    }
    my close
  } else {
    my replyCode 404
  }
}
Httpd::Wrk instproc sendFile {content} {
  my instvar fileName socket
  my sendLine "Last-Modified: [my Date [file mtime $fileName]]"
  my sendLine "Content-Type: [my guessContentType $fileName]"
  my sendLine "Content-Length: [string length $content]\n"
  fconfigure $socket -translation binary
  puts -nonewline $socket $content  ;# send the complete file
}
Httpd::Wrk instproc sendDynamicString {content {contentType text/html}} {
  my instvar socket
  my sendLine "Content-Type: $contentType"
  my sendLine "Content-Length: [string bytelength $content]\n"
  puts -nonewline $socket $content
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
    my close
  }
}
Httpd::Wrk instproc pageCount {} {
  my instvar fileName
  if {![[self class] exists counter($fileName)]} {
    [self class] set counter($fileName) 1
  } else {
    [self class] incr counter($fileName)
  }
}



Class Httpd::PortfolioWrk -superclass Httpd::Wrk
Httpd::PortfolioWrk instproc response {} {;# Respond to the GET-query
  my instvar path asdfghjkl
  regsub {\/} $path "" path

  set script $path
  set script [::base64::decode $script]
  concat "set asdfghjkl \"\"" script "\n return \$asdfghjkl"
  set i [interp create -safe]
  my replyCode 200
  interp alias $i puts {} my handlereturn $i
  
  if {[catch {set result [interp eval $i $script]} msg x]} {
    set result "Errormessage: $msg \n\n"
    append result "Stacktrace:\n  [dict get $x -errorinfo] \n\n"
    append result "on line: [dict get $x -errorline] \n\n"
    append result "xxxxxxxxxxxx"
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

Httpd h1 -port $opt(-port) -root $opt(-root) -worker Httpd::PortfolioWrk
vwait forever