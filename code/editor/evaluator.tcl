package require nx
namespace import -force ::nx::*

source [file join [file dirname [info script]] safe.tcl]


Object create evaluator {
  #strictStory = only evaluate the next sentence, iff the current sentence is valid
  :object variable strictStory {}
  :object variable terminateFlag {}
  :object variable story {}

  :object method andCase {sentence} {
    set subSentences [split $sentence "&"]
    set result ""
  
    foreach subSentence $subSentences {
      set subResult [evaluate $subSentence]
      set subResultLength [string length $subResult]

      if {$subResultLength > 1} {
        append result $subResult
        set :terminateFlag 1
      }
    }
  }

  :object method orCase {sentence} {
    set subSentences [split $sentence "|"]
    set result ""
    
  foreach subSentence $subSentences {
      set subResult [evaluate $subSentence]
      set subResultLength [string length $subResult]

      if {$subResultLength > 1} {
        append result $subResult
        set :terminateFlag 1
      } else {
        set :terminateFlag 0
        # at least one condition is ok
        return
      }
    }
  }

  :object method evaluate {sentence} {
    set sentenceToEvaluate [string trim $sentence]
        
   SafeInterp create safeInterpreter
   safeInterpreter requirePackage {nsf}
   safeInterpreter requirePackage {nx}
    
    set i [interp create]
    

    set script ""
#    append script "package require nx \n namespace import -force ::nx::* \n "
#    append script "package require nx \n namespace import -force ::nx::* \n "
    append script "set auditVariable \"\" \n"
    append script "\n ${:story} \n"

    if {[catch {set result [safeInterpreter eval $script]} msg x]} {    
      if {[regexp {The provided code is not executable. (.+)} ${:story} _ param1]} {
        # do nothing
      } else {
        set :story "\#fff The provided code is not executable. \n \# $msg \n \n  ${:story}"     
      }

      return "The provided code is not executable \n"
    }
 
    if {[regexp {Given there exists an object (.+) of the type (.+)} $sentenceToEvaluate _ param1 param2]} {
      append script "$param1 info has type $param2"

      catch {set result [safeInterpreter eval $script]} msg x
      
      if {$result == "0" || [regexp {expected class but got (.+)} $msg _ _] } {
        regsub -all $sentenceToEvaluate ${:story} "\#fff $sentenceToEvaluate" :story
        return "Failed: $sentence \n"  
      }
      return
    }  
 
 
    if {[regexp {Given there exists an object (.+)} $sentenceToEvaluate _ param1]} {
      append script "::nsf::object::exists $param1 \n"
 
      set result [safeInterpreter eval $script]
 
 
      
      if {$result == "0"} {
        regsub -all $sentenceToEvaluate ${:story} "\#fff $sentenceToEvaluate" :story
        return "Failed: $sentence \n"  
      }
      
      return
    }  
 
    if {[regexp {Given there exists a procedure (.+) for the object (.+)} $sentenceToEvaluate _ param1 param2]} {
      append script "$param2 info method exists $param1"
      
      catch {set result [safeInterpreter eval $script]} msg x

      if {$result == "0" || [regexp {invalid command name (.+)} $msg _ _] } {
        regsub -all $sentenceToEvaluate ${:story} "\#fff $sentenceToEvaluate" :story
        return "Failed: $sentence \n"  
      }
      return
    }  

    #FIXME what are the return possibilities of the this method call? also 0/1
    if {[regexp {Given there exists a procedure (.+) for the class (.+)} $sentenceToEvaluate _ param1 param2]} {
      append script "$param2 ?class? info method exists $param1"

      catch {set result [safeInterpreter eval $script]} msg x
    
      if {$result == "0"} {
        regsub -all $sentenceToEvaluate ${:story} "\#fff $sentenceToEvaluate" :story
        return "Failed: $sentence \n"  
      }
      return
    }  
 
    if {[regexp {Given there exists a procedure (.+) with the parameter (.+)} $sentenceToEvaluate _ param1 param2]} {
      append script "set x \[$param1 $param2]"
  
      if {[catch {set result [safeInterpreter eval $script]} msg x]} {
        if {[regexp {wrong # args: should be (.+)} $msg _ _]} {
          regsub -all $sentenceToEvaluate ${:story} "\#fff $sentenceToEvaluate" :story
          return "Failed: $sentence \n"
        }
      }
      return    
    }

    if {[regexp {Given there exists a procedure (.+)} $sentenceToEvaluate _ param1]} {
      append script "$param1"
  
      if {[catch {set result [safeInterpreter eval $script]} msg x]} {
        if {$msg == "invalid command name \"$param1\""} {
          regsub -all $sentenceToEvaluate ${:story} "\#fff $sentenceToEvaluate" :story
          return "Failed: $sentence \n"
        }
      }
      return    
    }
  
    if {[regexp {Given that the variable (.+) is assigned to the value (.+)} $sentenceToEvaluate _ param1 param2]} {
      append script "if {$$param1 != $param2} {append auditVariable \"failed\"}"
      append script "\n return \$auditVariable"
 
      set result [safeInterpreter eval $script]
        
      if {$result == "failed"} {
        regsub -all $sentenceToEvaluate ${:story} "\#fff $sentenceToEvaluate" :story
        return "Failed: $sentence \n"  
      }
      return
    }  
  
    if {[regexp {When the procedure (.+) is called, (.+) is returned} $sentenceToEvaluate _ param1 param2]} {
      append script "if {\[$param1\] != $param2} {append auditVariable \"failed\"}"
      append script "\n return \$auditVariable"
 
      set result [safeInterpreter eval $script]
    
      if {$result == "failed"} {
        regsub -all $sentenceToEvaluate ${:story} "\#fff $sentenceToEvaluate" :story
        return "Failed: $sentence \n"  
      }
      return
    }
  
    if {[regexp {When the procedure (.+) is called, the program does not terminate.} $sentenceToEvaluate _ param1]} {
      append script "$param1"
  
      if {[catch {set result [safeInterpreter eval $script]} msg x]} {
        if {[regexp {too many nested evaluations (.+)} $msg _ _]} {
          regsub -all $sentenceToEvaluate ${:story} "\#fff $sentenceToEvaluate" :story
          return "Failed: $sentence \n"
        }
      }
      return    
    }

  
# TBD 
# Structural:
  #* Given there exists a variable *variableName* in the object/class *concreteInstanceName/className*. 
#* Given there exists a class *classname* [that takes one parameter].
#* Given that the variable *concreteObjectName* is assigned to the value *variableName* [in the object *concreteInstanceName*].

# Behavioral:

#* When the procedure *procedureName* [of the object *concreteInstanceName*] [with the parmeter *parameter*] is called, then *result* is returned.
#* When the procedure *procedureName* [of the object *concreteInstanceName* is called] [with the parmeter *parameter*], then the procedure *procedureName2* [of the object *concreteInstanceName2* is called] is called.
#* When the procedure *procedureName* [of the object *concreteInstanceName* is called] [with the parmeter *parameter*], the program does not terminate.
#* When the procedure *procedureName* [of the object *concreteInstanceName*] is called, then *Result* is displayed on the command line.
    return 
  }

  :public object method evaluateSentences {story} {
    #clear previous information
    regsub -all {fff} $story "" story

    set :story $story

    #Split different sentences
    set sentences [split $story ".\n"]

    foreach sentence $sentences {

      if {${:strictStory} == 1 && ${:terminateFlag} == 1} {
        return ${:story}
      }

      if {[string first "&" $sentence] != -1} { 
        andCase $sentence
        continue
      }

      if {[string first "|" $sentence] != -1} { 
        orCase $sentence
        continue
      }

      if {[string length [:evaluate $sentence]] > 0} {
        set :terminateFlag 1
      }
    }

    regsub -all {ooo #} ${:story} "ooo" :story
    regsub -all {fff #} ${:story} "fff" :story

    return ${:story}
  }
}
