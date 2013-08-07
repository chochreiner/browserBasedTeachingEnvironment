package require XOTcl
namespace import -force ::xotcl::*

package require nx
namespace import -force ::nx::*

array set opt {-port 8081}
array set opt $argv

source [file join [file dirname [info script]] taskEvaluator.tcl]

Class create Httpd {
  :property {port 80}
  :variable worker Httpd::Wrk

  :public method init args {
    set :count 0
    puts stderr "Starting Server; url= http://[info hostname]:${:port}/"
    set :listen [socket -server [list [self] accept] ${:port}]
  }
  
  :public method destroy { } {
    close ${:listen}				
    next
  }  
  
  :public method accept {socket ipaddr port} {
      [${:worker}] create [self]::w[incr :count] -socket $socket -ipaddr $ipaddr -port $port
  }
}

Class create Httpd::Wrk {
  :property socket
  :property port
  :property ipaddr
  
  :public method init args {
    :fileevent readable firstLine
    fconfigure ${:socket} -blocking false  
  }
  
  :method Date secs {
    clock format $secs -format {%a, %d %b %Y %T %Z}
  }
  
  :public method close {} {
    puts stderr "[self] [current method] ${:socket} "
    close ${:socket}
    :destroy    
  }
  
  :public method sendLine {msg} {
    puts stderr "[self] send: ${:socket} <$msg>"
    puts ${:socket} $msg
  }
  
  :public method receiveLine {line n} {
    upvar $line received $n nrBytes
    set nrBytes [gets ${:socket} received]
    puts stderr "[self] got:  <$received>"
  }
  
  :public method fileevent {type method} {
    fileevent ${:socket} $type [list [self] $method]  
  }  

  :public method firstLine {} {
    :receiveLine line n  
    if {[regexp {^(GET|POST) +([^ ]+) +HTTP/.*$} ${line} _ :method :path]} {
      set :fileName ./${:path}
      regsub {/$} ${:fileName} /index.html :fileName
      :fileevent readable header
    } else {
      :replyCode 400
    }
  }

  :public method header {} {
    :receiveLine :line :n  
    if {${:n} > 0} { 	
      if {[regexp {^([^:]+): *(.+)$} ${:line} _ key value]} {
        set :meta([string tolower $key]) $value
      }
    } else {
      if {[::nx::var exists [self] meta(content-length)]} {
        set :requestBody ""
        :fileevent readable body
      } else {
        :response-[set :method]
      }
    }
  }

  :public method body {} {
    append :requestBody [read ${:socket}]
    if {${:meta(content-length)} <= [string length ${:requestBody}]} {
      :response-[set :method]
    }
  }
  
  :public method response-GET {} {
    puts stderr "[self] [current method]"
    if { [regexp -nocase {script/} ${:path}] } {
      regsub {[.][.][/]} ${:path} "" :path
      regsub "/" ${:path} "" :fileName
    }

    if {[file readable ${:fileName}]} {
      :replyCode 200
      switch [file extension ${:fileName}] { 
        .xhtml { set c [subst [:readFile ${:fileName}]]
	         :sendDynamicString $c }
        default { :sendFile  }
      }
    } else {
      :replyCode 404
    }
  }
  
  :public method response-POST {} {
    if {${:path} == "/validate"} {
      :replyCode 200
      set e [TaskEvaluator new]
      $e setUp ${:requestBody}
      :sendDynamicString [$e run ${:requestBody}]   
      :close
    }

    if {${:path}=="/execute"} {
     set script ${:requestBody}
     SafeInterp create safeInterpreter
     safeInterpreter requirePackage {nsf}
     safeInterpreter requirePackage {nx}

     :replyCode 200
     if {[catch {set result [safeInterpreter eval $script]} msg x]} {
       set result "Errormessage: $msg \n\n"
       append result "Stacktrace:\n [dict get $x -errorinfo] \n\n"       
       append result "on line: [dict get $x -errorline] \n\n"
       puts stderr result=$result
     }
     :sendDynamicString $result
     :close
    }
  }

  :method modifyNextSyntax {} {
    set oldFile [:readFile "src/mode-next-pre.js"]
    set keywords [nx::Class info methods]
    append keywords [nx::Object info methods]
    :writeFile "src/mode-next.js" [:replaceKeywords $oldFile $keywords]
  }

  :method modifyXOTclSyntax {} {
    set oldFile [:readFile "src/mode-xotcl-pre.js"]
    set keywords [lsearch -glob -not -all -inline [::xotcl::Class info methods] {__*}]
    append keywords [lsearch -glob -not -all -inline [::xotcl::Object info methods] {__*}]
    :writeFile "src/mode-xotcl.js" [:replaceKeywords $oldFile $keywords]  
  }
  
  :method replaceKeywords {oldFile keywords} {
    regsub -all " " $keywords "|" keywordsnew
    set keywordsnew [concat "builtinFunctions = lang.arrayToMap((\"" $keywordsnew "\").split(\"|\"));"]
    regsub -all " " $keywordsnew "" keywordsnew
    regsub "builtinFunctions;" $oldFile $keywordsnew  newFile
    return $newFile
  }

  :method insertAvailableScripts {} {
    set oldFile [:readFile "index-pre.html"]
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

    :writeFile "index.html" $newFile
  }

  :method sendFile {} {
    :sendLine "Last-Modified: [:Date [file mtime ${:fileName}]]"
    :sendLine "Content-Type: [:guessContentType ${:fileName}]"
    :sendLine "Content-Length: [file size ${:fileName}]\n"
    set localFile [open ${:fileName} r]
    fconfigure $localFile -translation binary
    fconfigure ${:socket} -translation binary
    fcopy $localFile ${:socket} -command [list [self] sendFile-end $localFile]
  }

  :public method sendFile-end {localFile args} {
    puts stderr "[self] [current method]"
    close $localFile
    :close
  }

  :method sendDynamicString {content {contentType text/html}} {
    :sendLine "Content-Type: $contentType"
    :sendLine "Content-Length: [string length $content]\n"
    fconfigure ${:socket} -encoding [encoding system] -translation binary
    puts -nonewline ${:socket} $content
  }

  :method readFile {fn} {
    set f [open $fn]
    fconfigure $f -translation binary
    set content [read $f]
    close $f
    return $content  
  }

  :method writefile {fn content} {
    set f [open $fn "w"]
    fconfigure $f -translation binary
    puts -nonewline $f $content
    close $f
  }

  :method guessContentType {fn} {
    switch [file extension $fn] {
      .htm {return text/html}   .html {return text/html} 
      .css {return text/css}    default {return text/plain}
    }
  }

  :method replyCode {code} {
    :sendLine "HTTP/1.0 $code [:getCode $code]"
    :sendLine "Date: [:Date [clock seconds]]"
    if {$code >= 300} {
      :sendDynamicString "\n<title>Error: $code</title>\n\
        Error $code: <b>[:getCode $code]</b><br>\n"
    }
  }
  
  :method getCode {code} {
    if {$code=="200"} {
      return "Data follows"
    }    
    if {$code=="404"} {
      return "Not Found"
    }
    if {$code=="400"} {
      return "Bad Request"
    }
    return "Code not found"
  }
}  

proc bgerror {args} {
  puts stderr "$::argv0 background error: $args"
  puts stderr "\t$::errorInfo\nerrorCode = $::errorCode"
}

Httpd create p1 -port $opt(-port)
vwait forever