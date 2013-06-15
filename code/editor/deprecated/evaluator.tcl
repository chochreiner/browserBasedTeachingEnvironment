package require nx
namespace import -force ::nx::*

package require nx::test


source [file join [file dirname [info script]] safe.tcl]

#Notes
#why do i also require the nsf package?


Class create Tupel {
  :property {prefix member}
  :property -accessor public needle
  :property -accessor public code
  :property -accessor public result
}


#Tupel create t1 -needle 0 -code 1

#puts [t1 needle]

Object create evaluator {
  #strictStory = only evaluate the next sentence, iff the current sentence is valid
  :object variable strictStory {}
  :object variable terminateFlag {}
  :object variable story {}
  :object property -incremental {validators:0..n {}}
  :object variable counter 0

  : public object method init {} {
   set fp [open "validators.txt" r]
   set file_data [read $fp]
   close $fp
   set data [split $file_data "\n"]
   set counter 0

   foreach line $data {
     if {$counter=="0"} {
       set needle $line
     }
     if {$counter==1} {
       set code $line
     }
     if {$counter==2} {
       :registerValidator $needle $code $line
     }
     if {$counter==3} {
       set $counter 0
     }
     incr counter 1
   }
  }

  :public object method registerValidator {needle code result} {
    set validator [Tupel create ${:counter} -needle $needle -code $code -result $result]
    incr :counter 1
    :validators add $validator end 
  }
  
  :public object method iterateOverValidators {} {  
     foreach validator ${:validators} {
       :evaluatefancy [$validator needle] [$validator code] [$validator result] "TODOreplace"
     }
  }
  
   :object method evaluatefancy {needle code result sentenceToEvaluate} {
     SafeInterp create safeInterpreter
     safeInterpreter requirePackage {nsf}
     safeInterpreter requirePackage {nx}

     set regexScript "${:story} \n"
     append regexScript "\n set sentenceToEvaluate $sentenceToEvaluate \n"
     append regexScript "\ set param1 \"\" \n"
     append regexScript "\ set param2 \"\" \n"
     append regexScript "\ set param3 \"\" \n"          
     append regexScript "\n $needle"
     append regexScript "\{set x \"fail\" \} else \{set x \"ok|\$param1|\$param2|\$param3\"\}"
     
     set regexResult [safeInterpreter eval $regexScript]

     if {$regexResult == "fail"} {
       return
     }
     
     set validationScript "${:story} \n"
     set data [split $regexResult "|"]
     set counter 0
   
     foreach line $data {
       if {$counter=="0"} {
       }
       if {$counter==1} {
         append validationScript "\n set param1 $line \n"
       }
       if {$counter==2} {
         append validationScript "\n set param2 $line \n"
       }
       if {$counter==3} {
         append validationScript "\n set param3 $line \n"
       }
       incr counter 1
     }

     append validationScript "\n set sentenceToEvaluate $sentenceToEvaluate \n"
     append validationScript "\n $code \n"
     
     set validatorResult [safeInterpreter eval $validationScript]
     
     set returnValueScript "${:story} \n"
     append returnValueScript "\n set result $validatorResult \n"
     append returnValueScript "\n $result "
     append returnValueScript "\{set x \"fail\" \} else \{set x \"ok\"\}"

     if {[safeInterpreter eval $returnValueScript] == "fail"} {
        regsub -all $sentenceToEvaluate ${:story} "\#fff $sentenceToEvaluate" :story
        return "Failed: $sentence \n"  
     }

  }

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
        
    set script ""
    append script "set auditVariable \"\" \n"
    append script "\n ${:story} \n"

    if {[catch {set result [safeInterpreter eval $script]} msg x]} {    
      # the notification is already displayed below
      return 
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
