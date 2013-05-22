package require nx
namespace import -force ::nx::*


# definitons to test the script
set ::story "Given there exists an object objectA of the type C."
#\Given there exists a procedure test2.|Given there exists a procedure test3 with the parameter asdf.
#\Given that the variable asdf is assigned to the value -1.
#\When the procedure test is called, 1 is returned.
#\When the procedure test is called, 2 is returned&Given there exists an object objectC of the type qwert.
#\Given there exists an object objectE | Given there exists an object objectC.
#\Given there exists an object objectB."




set ::submittedCode "proc test {} {return 1}
\proc test1 {asdf} {return \$asdf}
\set asdf -1
\Class create C {}
\C create objectA"


#Configuration
#strictStory = only evaluate the next sentence, iff the current sentence is valid
set ::strictStory 0
set ::::terminateFlag 0
set ::overallFeedback ""

proc andCase {sentence} {
  set subSentences [split $sentence "&"]
  set result ""
  
  foreach subSentence $subSentences {
      set subResult [evaluate $subSentence]
      set subResultLength [string length $subResult]
    if {$subResultLength > 1} {
      append result $subResult
      set ::terminateFlag 1
    }
  }
}

proc orCase {sentence} {
  set subSentences [split $sentence "|"]
  set result ""
    
  foreach subSentence $subSentences {
      set subResult [evaluate $subSentence]
      set subResultLength [string length $subResult]
    if {$subResultLength > 1} {
      append result $subResult
      set ::terminateFlag 1
    } else {
      set ::terminateFlag 0
      # at least one condition is ok
      return
    }
  }
}

proc evaluate {sentence} {
  set sentenceToEvaluate [string trim $sentence]
# package require does not work in safe mode
# set i [interp create -safe]
  set i [interp create]

  set script ""
  append script "package require nx \n namespace import -force ::nx::* \n "
  append script "set auditVariable \"\" \n"

  append script "\n $::submittedCode \n"
  
  if {[catch {set result [interp eval $i $script]} msg x]} {
    set result "Errormessage: $msg \n\n"
    append result "Stacktrace:\n  [dict get $x -errorinfo] \n\n"
    append result "on line: [dict get $x -errorline] \n\n"
    append ::overallFeedback "The provided code is not executable: \n $result \n"
    return "The provided code is not executable \n"
  }
 

   if {[regexp {Given there exists an object (.+) of the type (.+)} $sentenceToEvaluate _ param1 param2]} {
    append script "$param1 info has type $param2"

    catch {set result [interp eval $i $script]} msg x
    if {$result == "0" || [regexp {expected class but got (.+)} $msg _ _] } {
      append ::overallFeedback "Failed: $sentence \n"
      return "Failed: $sentence \n"  
    }
    return
  }  
 
  if {[regexp {Given there exists an object (.+)} $sentenceToEvaluate _ param1]} {
    append script "::nsf::object::exists $param1 \n"
 
    set result [interp eval $i $script]
    if {$result == "0"} {
      append ::overallFeedback "Failed: $sentence \n"
      return "Failed: $sentence \n"  
    }
    return
  }  
 
  if {[regexp {Given there exists a procedure (.+) with the parameter (.+)} $sentenceToEvaluate _ param1 param2]} {
  append script "set x \[$param1 $param2]"
  
    if {[catch {set result [interp eval $i $script]} msg x]} {
      if {[regexp {wrong # args: should be (.+)} $msg _ _]} {
        append ::overallFeedback "Failed: $sentence \n"
        return "Failed: $sentence \n"
      }
    }
    return    
  }

  if {[regexp {Given there exists a procedure (.+)} $sentenceToEvaluate _ param1]} {
  append script "$param1"
  
    if {[catch {set result [interp eval $i $script]} msg x]} {
      if {$msg == "invalid command name \"$param1\""} {
        append ::overallFeedback "Failed: $sentence \n"
        return "Failed: $sentence \n"
      }
    }
    return    
  }
  
  if {[regexp {Given that the variable (.+) is assigned to the value (.+)} $sentenceToEvaluate _ param1 param2]} {
    append script "if {$$param1 != $param2} {append auditVariable \"failed\"}"
    append script "\n return \$auditVariable"
 
 
    set result [interp eval $i $script]
        
    if {$result == "failed"} {
      append ::overallFeedback "Failed: $sentence \n"
      return "Failed: $sentence \n"  
    }
    return
  }  
  
  if {[regexp {When the procedure (.+) is called, (.+) is returned} $sentenceToEvaluate _ param1 param2]} {
    append script "if {\[$param1\] != $param2} {append auditVariable \"failed\"}"
    append script "\n return \$auditVariable"
 
    set result [interp eval $i $script]
    
    if {$result == "failed"} {
      append ::overallFeedback "Failed: $sentence \n"
      return "Failed: $sentence \n"  
    }
    return
  }
  
  if {[regexp {When the procedure (.+) is called, the program does not terminate.} $sentenceToEvaluate _ param1]} {
  append script "$param1"
  
    if {[catch {set result [interp eval $i $script]} msg x]} {
      if {[regexp {too many nested evaluations (.+)} $msg _ _]} {
        append ::overallFeedback "Failed: $sentence \n"
        return "Failed: $sentence \n"
      }
    }
    return    
  }


  
 
# Structural:

#* Given there exists a variable *variableName* in the object/class *concreteInstanceName/className*. 
#* Given there exists a procedure *procedureName* [for the class/object *className/concreteInstanceName*].
#* Given there exists a class *classname* [that takes one parameter].
#* Given that the variable *concreteObjectName* is assigned to the value *variableName* [in the object *concreteInstanceName*].

# Behavioral:

#* When the procedure *procedureName* [of the object *concreteInstanceName*] [with the parmeter *parameter*] is called, then *result* is returned.
#* When the procedure *procedureName* [of the object *concreteInstanceName* is called] [with the parmeter *parameter*], then the procedure *procedureName2* [of the object *concreteInstanceName2* is called] is called.
#* When the procedure *procedureName* [of the object *concreteInstanceName* is called] [with the parmeter *parameter*], the program does not terminate.
#* When the procedure *procedureName* [of the object *concreteInstanceName*] is called, then *Result* is displayed on the command line.


  return 
}



#Split different sentences
set sentences [split $story ".\n"]

foreach sentence $sentences {

if {$strictStory == 1 && $::terminateFlag == 1} {
  puts $::overallFeedback
  return
}

if {[string first "&" $sentence] != -1} { 
  #puts "its the AND case: $sentence "  
  andCase $sentence
  continue
}

if {[string first "|" $sentence] != -1} { 
  #puts "its the OR case: $sentence "
  orCase $sentence
  continue
}

if {[string length [evaluate $sentence]] > 0} {
  set ::terminateFlag 1
}


}

puts $::overallFeedback