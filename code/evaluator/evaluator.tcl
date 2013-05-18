#known issues
#
#
#

#switch -regexp -matchvar foo -- $bar {
#    a(b*)c {
#        puts "Found [string length [lindex $foo 1]] 'b's"
#    }
#    d(e*)f(g*)h {
#        puts "Found [string length [lindex $foo 1]] 'e's and\
#                [string length [lindex $foo 2]] 'g's"
#    }
#}


package require XOTcl
namespace import -force ::xotcl::*

# definitons to test the script
set story "Given there exists an object objectD & Given there exists an object objectC.
\Given there exists an object objectE | Given there exists an object objectC.
\Given there exists an object objectB."

set submittedCode "Object create objectA
\Object create objectB"


#Configuration
#strictStory = only evaluate the next sentence, iff the current sentence is valid
set ::strictStory "1"

proc andCase {sentence} {
	set subSentences [split $sentence "&"]
	set result ""
	
	foreach subSentence $subSentences {
	    set subResult [evaluate $subSentence]
	    set subResultLength [string length subResult]
		if {$subResultLength > 1} {
		  append result $subResult
		}
	}
    return $result
}

proc orCase {sentence} {
	set subSentences [split $sentence "|"]
	set result ""
	
	foreach subSentence $subSentences {
	    set subResult [evaluate $subSentence]
	    set subResultLength [string length subResult]
		if {$subResultLength > 1} {
		  append result $subResult
		} else {
		  # at least one condition is ok
		  return ""
		}
	}
    return $result

}

proc evaluate {sentence} {
  set sentenceToEvaluate [string trim $sentence]
  
 
  
  puts $sentenceToEvaluate
    return -1
}


proc handleConjuctResults {result} {
  set resultLength [string length result]
  append overallFeedback $result
  if {$resultLength > 1 && $::strictStory == 1 } {
    set terminateFlag 1
  }
}

#Split different sentences
set sentences [split $story ".\n"]

set terminateFlag 0
set overallFeedback ""

foreach sentence $sentences {


if {$terminateFlag == 1} {
  break
}

if {[string first "&" $sentence] != -1} { 
  #puts "its the AND case: $sentence "  
  handleConjuctResults [andCase $sentence]
  continue
}

if {[string first "|" $sentence] != -1} { 
  #puts "its the OR case: $sentence "
  handleConjuctResults [orCase $sentence]
  continue
}

evaluate $sentence


}
