package require nx
namespace import -force ::nx::*

source [file join [file dirname [info script]] safe.tcl]

nx::Class create TaskEvaluator {

  :property {steps {[dict create]}}
  # if set mode is 0, the validation aborts if one assertion is wrong
  :variable strictMode 0

  :public method setUp {story} {
    set lines [split $story "\n"]  
    
    foreach line $lines {    
      if {[regexp {Given (.+)\.} $line _ rule]} {
        :Given $rule
      }
      if {[regexp {When (.+)\.} $line _ rule]} {
        :When $rule
      }
    }
  }

  :object method getMatchVars {regExprStr} {
     set nParens [expr {
		      [string length $regExprStr] - 
		      [string length [string map [list "(" ""] $regExprStr]]
		    }]
    set vars [list]
    for {set i 0} {$i<$nParens} {incr i} {lappend vars $i}
    return $vars
  }

  :public object method Given {regExpr validationBlock} {
    set regExprArgs [list $regExpr [:getMatchVars $regExpr]]
    set step [list $regExprArgs $validationBlock]
    dict lappend :steps Given $step
  }

  :public object method When {regExpr validationBlock} {
    set regExprArgs [list $regExpr [:getMatchVars $regExpr]]
    set step [list $regExprArgs $validationBlock]
    dict lappend :steps When $step
  }


  :public method Given {string} {
    set steps [[current class] eval {set :steps}]
    if {[dict exists $steps Given] == 1} {
      foreach given [dict get $steps Given] {
        lassign $given regExpr script
        lassign $regExpr r vars
        if {[regexp $r $string _ {*}$vars]} {
	      lappend :testScriptStructural [list if !\[[subst $script]\] [list lappend outcome "F: Given $string"] [list lappend outcome "S: Given $string"]]
        }
      }
    }
  }  
  
  :public method When {string} {
    set steps [[current class] eval {set :steps}]
    if {[dict exists $steps When] == 1} {
      foreach given [dict get $steps When] {
        lassign $given regExpr script
        lassign $regExpr r vars
        if {[regexp $r $string _ {*}$vars]} {
  	      lappend :testScriptBehavioral [list if !\[[subst -nocommands $script]\] [list lappend outcome "F: When $string"] [list lappend outcome "S: When $string"]]
        }
      }
    }  
  }
  
  :public method run {scriptUnderTest} { 
    SafeInterp create safeInterpreter
    safeInterpreter requirePackage {nsf}
    safeInterpreter requirePackage {nx}
        
    safeInterpreter eval $scriptUnderTest
    safeInterpreter eval {set outcome ""}

    set outcome {}

    if {[info exists :testScriptStructural]} {
      foreach cmd ${:testScriptStructural} {
        if {${:strictMode}=="0"} {
          safeInterpreter eval $cmd                        
        } else {
          if {![regexp {F: } [safeInterpreter eval {return $outcome}] _ _]} {
            safeInterpreter eval $cmd 
          }
        }
      }
    }

    if {[info exists :testScriptBehavioral]} {
      foreach cmd ${:testScriptBehavioral} {
        if {${:strictMode}=="0"} {
          safeInterpreter eval $cmd                        
        } else {
          if {![regexp {F: } [safeInterpreter eval {return $outcome}] _ _]} {
            safeInterpreter eval $cmd 
          }
        }
      }
    }
    set outcome [:generateFeedback [safeInterpreter eval {return $outcome}] $scriptUnderTest]    
    return $outcome
  }
  
  :method generateFeedback {outcome story} {
    regsub -all {#ok} $story {#} story
    regsub -all {#fail} $story {#} story
    
    foreach result $outcome {
      if {[regexp {F: } $result _ _]} {
        regsub -all {F: } $result {} result
        regsub -all $result $story "\#fail $result" story
      } else {
        regsub -all {S: } $result {} result
        regsub -all $result $story "\#ok $result" story      
      }    
    }

    regsub -all {# #} $story "#" story
  
    return $story
  }
  
  :public method enableStrictMode {} {
    set :strictMode 1
  }
  
  :public method disableStrictMode {} {
    set :strictMode 0
  }
}

#TODO find a checking solution without trying to create an instance of the class and see how it works
TaskEvaluator Given {there exists a class (.+)} {set x 0}
# if object extsts ::C class --> dann ist c vom type class


#TODO replace with potentially easier structure like for objects
#TaskEvaluator Given {there exists a variable (.+) in the class (.+)} {if {[string length [$1 info variables $0]] < 1}  {set x 0} else {set x 1} }
TaskEvaluator Given {there exists a variable (.+) in the class (.+)} {set x 0}

#TODO find a construct to check this
TaskEvaluator Given {that the instance (.+) is assigned to variable (.+) in the instance (.+)} {set x 0}
# name eines objects --> dann ob das object extistiert

#TODO find an endless-loop detection
TaskEvaluator When {the procedure (.+) of the instance (.+) is called, the program does not terminate} {set x 0}
# abfragen in welcher stacketiefe bin ich: callsteck level; interp (level) frame

#TODO find callstack solution
TaskEvaluator When {the procedure (.+) of the instance (.+) is called, then the procedure (.+) of the instance (.+) is called} {set x 0}
TaskEvaluator When {the procedure (.+) of the object (.+) is called, then the procedure (.+) of the object (.+) is called} {set x 0}


TaskEvaluator Given {there exists an object (.+)} {::nsf::object::exists $0}
TaskEvaluator Given {there exists a variable (.+) in the object (.+)} {$1 eval {info exists :$0}}
TaskEvaluator Given {there exists a procedure (.+) for the object (.+)} {$1 info object method exists $0}
TaskEvaluator Given {there exists a procedure (.+) for the class (.+)} {$1 info method exists $0}
TaskEvaluator Given {that (.+) is an instance of the class (.+)} {$0 info has type $1}


TaskEvaluator When {the procedure (.+) of the object (.+) is called, then (.+) is returned} {if {[$1 $0] != "$2"} {set x 0} else {set x 1} }
TaskEvaluator When {the parametrized-procedure (.+) of the instance (.+) with the parameter (.+) is called, then (.+) is returned} {if {[$1 $0 $2] != "$3"} {set x 0} else {set x 1} }
TaskEvaluator When {the procedure (.+) of the instance (.+) is called, then (.+) is returned} {if {[$1 $0] != "$2"} {set x 0} else {set x 1} }

