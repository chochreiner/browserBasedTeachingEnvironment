package require XOTcl
namespace import -force ::xotcl::*

package require nx
namespace import -force ::nx::*

array set opt {-port 8081 -root ./}
array set opt $argv

source [file join [file dirname [info script]] evaluator.tcl]

xotcl::Class Httpd -parameter { 
  {port 80} 
  {root /home/httpd/html/} 
  {worker Httpd::Wrk} 
}
Httpd instproc init args {			
  my instvar port listen
  my set count 0
  puts stderr "Starting Server; url= http://[info hostname]:$port/"
  set listen [socket -server [list [self] accept] $port]
}
Httpd instproc destroy {} {			
  close [my set listen]				
  next
}
Httpd instproc accept {socket ipaddr port} {
  [my worker] [self]::w[my incr count] \
	-socket $socket -ipaddr $ipaddr -port $port
}

xotcl::Class Httpd::Wrk -parameter {socket port ipaddr}
Httpd::Wrk array set codes { 200 "Data follows" 206 "Data follows part 1" 404 "Not Found" }
Httpd::Wrk instproc Date secs {clock format $secs -format {%a, %d %b %Y %T %Z}}
Httpd::Wrk instproc close {} {		
  puts stderr "[self] [self proc] [my socket] "
  close [my socket]
  my destroy
}
Httpd::Wrk instproc sendLine {msg} {	
  puts stderr "[self] send: [my socket] <$msg>"
  puts [my socket] $msg
}
Httpd::Wrk instproc receiveLine {line n} {
  upvar $line received $n nrBytes
  set nrBytes [gets [my socket] received]
  puts stderr "[self] got:  <$received>"
}
Httpd::Wrk instproc fileevent {type method} {
  fileevent [my socket] $type [list [self] $method]
}

Httpd::Wrk instproc init args {	
  my fileevent readable firstLine
  fconfigure [my socket] -blocking false
}

Httpd::Wrk instproc firstLine {} {	
  my instvar method path fileName 
  my receiveLine line n
  if {[regexp {^(GET|POST) +([^ ]+) +HTTP/.*$} $line _ method path]} {
    set fileName [[my info parent] root]/$path  
    regsub {/$} $fileName /index.html fileName
    my fileevent readable header
  } else {
    my replyCode 400
  }
}
Httpd::Wrk instproc header {} {	
  my receiveLine line n
  if {$n > 0} { 	
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
Httpd::Wrk instproc body {} {
  my instvar meta requestBody socket
  append requestBody [read $socket]
  if {$meta(content-length) <= [string length $requestBody]} {
    my response-[my set method]
  }
}
Httpd::Wrk instproc response-GET {} {
  puts stderr "[self] [self proc]"
  my instvar fileName path
  my modifyXOTclSyntax
  my modifyNextSyntax
  my insertAvailableScripts
  
  #special handling for scripts
  if { [regexp -nocase {script/} $path] } {
	#simple security measurement to restrict upward browsing
    regsub {[.][.][/]} $path "" path
    regsub "/" $path "" fileName
  }

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


Httpd::Wrk instproc response-POST {} {
  my instvar path asdfghjkl requestBody

  if {$path == "/validate"} {
   my replyCode 200
   my sendDynamicString [evaluator evaluateSentences $requestBody]
   my close
  }


  # FIXME
  puts stderr PATH=$path
  if {$path=="/execute"} {
   set script $requestBody
    #concat "set asdfghjkl \"\"" script "\n return \$asdfghjkl"
    set script {package req nx;}
   set i [interp create -safe]
   my replyCode 200
   interp alias $i puts {} my handlereturn $i  
   if {[catch {set result [interp eval $i $script]} msg x]} {
     set result "Errormessage: $msg \n\n"
     append result "Stacktrace:\n  [dict get $x -errorinfo] \n\n"
     append result "on line: [dict get $x -errorline] \n\n"
     puts stderr result=$result
   }
   my sendDynamicString $result
   my close
  }


#  my close
}

Httpd::Wrk instproc handlereturn {i args} {
  my instvar asdfghjkl
    append asdfghjkl {*}$args
    append asdfghjkl "\n"
}

Httpd::Wrk instproc modifyNextSyntax { } {
  set oldFile [my readFile "src/mode-next-pre.js"]
  set keywords [nx::Class info methods]
  append keywords [nx::Object info methods]
  my writeFile "src/mode-next.js" [my replaceKeywords $oldFile $keywords]
}

Httpd::Wrk instproc modifyXOTclSyntax { } {
  set oldFile [my readFile "src/mode-xotcl-pre.js"]
  set keywords [lsearch -glob -not -all -inline [::xotcl::Class info methods] {__*}]
  append keywords [lsearch -glob -not -all -inline [::xotcl::Object info methods] {__*}]
  my writeFile "src/mode-xotcl.js" [my replaceKeywords $oldFile $keywords]
}

Httpd::Wrk instproc replaceKeywords {oldFile keywords} {
  regsub -all " " $keywords "|" keywordsnew
  set keywordsnew [concat "builtinFunctions = lang.arrayToMap((\"" $keywordsnew "\").split(\"|\"));"]
  regsub -all " " $keywordsnew "" keywordsnew
  regsub "builtinFunctions;" $oldFile $keywordsnew  newFile
  return $newFile
}

Httpd::Wrk instproc insertAvailableScripts { } {
  set oldFile [my readFile "index-pre.html"]
  set contents [glob -directory "script/" *]
  set scripts ""
  foreach item $contents {
        regsub "script/" $item ""  item
        if {$item eq "none"} {
          append scripts [concat "<option selected=\"selected\" value=\"" $item "\">" $item "</option>"]
        } else {
          append scripts [concat "<option value=\"" $item "\">" $item "</option>"]
        }
  }
  regsub -all "\" " $scripts "\""  scripts
  regsub -all " \"" $scripts "\""  scripts
  regsub "MISSINGSCRIPTS" $oldFile $scripts  newFile

  my writeFile "index.html" $newFile
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
#  my close
}
Httpd::Wrk instproc readFile fn {
  set f [open $fn]
  fconfigure $f -translation binary
  set content [read $f]
  close $f
  return $content
}

Httpd::Wrk instproc writeFile {fn content} {
  set f [open $fn "w"]
  fconfigure $f -translation binary
  puts -nonewline $f $content
  close $f
}

Httpd::Wrk instproc guessContentType fn {# derive content type from ext.
  switch [file extension $fn] {
    .htm {return text/html}   .html {return text/html} 
    .css {return text/css}    default {return text/plain}
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