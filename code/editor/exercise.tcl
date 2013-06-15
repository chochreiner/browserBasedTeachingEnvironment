package require nx
namespace import -force ::nx::*

source [file join [file dirname [info script]] safe.tcl]


nx::Class create ExerciseBuilder {

  :property {steps {[dict create]}}

  :public method init {} {
    set fp [open "script/scenario1implemented" r]
    set file_data [read $fp]
    close $fp
    set data [split $file_data "\n"]

   foreach line $data {
     if {[regexp {Given (.+)\.} $line _ rule]} {
       :Given $rule
     }
   }  
  
  
    # fetch Given/Then/... sentence definitions and evaluate in the context of
    # this instance
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

  #
  # The per-object interface allows for specifying sentence definitions
  #

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


  #
  # The per-instance interface allows for collecting sentences used in
  # an exercise script ... and to collect the validation blocks to be
  # executed.
  #

  :public method Given {string} {
    set steps [[current class] eval {set :steps}]
    if {[dict exists $steps Given] == 1} {
      foreach given [dict get $steps Given] {
        lassign $given regExpr script
        lassign $regExpr r vars
        if {[regexp $r $string _ {*}$vars]} {
	      lappend :testScriptStructural [list if !\[[subst $script]\] [list lappend errors "FAILED: $string"]]
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
  	      lappend :testScriptBehavioral [list if !\[[subst -nocommands $script]\] [list lappend errors "FAILED: $string"]]
        }
      }
    }  
  }
  
  :public method run {scriptUnderTest} { 
     SafeInterp create safeInterpreter
     safeInterpreter requirePackage {nsf}
     safeInterpreter requirePackage {nx}
        
     safeInterpreter eval $scriptUnderTest

    puts [safeInterpreter eval {set errors ""}]


    if {[info exists :testScriptStructural]} {
      foreach cmd ${:testScriptStructural} {
        safeInterpreter eval $cmd
        puts $cmd
      }
    }

    if {[info exists :testScriptBehavioral]} {
      foreach cmd ${:testScriptBehavioral} {
        safeInterpreter eval $cmd
      }
    }
    
    puts [safeInterpreter eval {return $errors}]
  }
}


#need to return 0 in case of failure and 1 in case of sucess

ExerciseBuilder Given {there exists an object (.+)} {::nsf::object::exists $0}
#ExerciseBuilder When {the procedure (.+) is called, (.+) is returned} {[$0] != "$1"}
ExerciseBuilder When {the procedure (.+) is called, (.+) is returned} {if {[$0] != "$1"} {set x 0} else {set x 1} }

#TODO replace by parsing script
set e [ExerciseBuilder new {
#  :Given {there exists an object ::o1}
#  :Given {there exists an object ::o2}  
#  :Given {there exists an object ::o3}
#  :When {the procedure foo is called, bar is returned}
  
}]

#set e [ExerciseBuilder new]

#
# 3a) run a "script under test", which completes
#
$e run {proc foo { } {return "bar"}; nx::Object create ::o2; nx::Object create ::o1; }

