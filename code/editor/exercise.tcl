package require nx
namespace import -force ::nx::*

source [file join [file dirname [info script]] safe.tcl]

nx::Class create ExerciseBuilder {

  :property {steps {[dict create]}}

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
	      lappend :testScriptStructural [list if !\[[subst $script]\] [list lappend failures "Given $string"]]
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
  	      lappend :testScriptBehavioral [list if !\[[subst -nocommands $script]\] [list lappend failures "When $string"]]
        }
      }
    }  
  }
  
  :public method run {scriptUnderTest} { 
    SafeInterp create safeInterpreter
    safeInterpreter requirePackage {nsf}
    safeInterpreter requirePackage {nx}
        
    safeInterpreter eval $scriptUnderTest
    safeInterpreter eval {set failures ""}

    if {[info exists :testScriptStructural]} {
      foreach cmd ${:testScriptStructural} {
        safeInterpreter eval $cmd
      }
    }

    if {[info exists :testScriptBehavioral]} {
      foreach cmd ${:testScriptBehavioral} {
        safeInterpreter eval $cmd
      }
    }
    
    return [:generateFeedback [safeInterpreter eval {return $failures}] $scriptUnderTest]
  }
  
  :method generateFeedback {errors story} {
    #clear all previous feedback information
    regsub -all {#ooo} $story "ooo" story
    regsub -all {#fff} $story "fff" story
  
    foreach failure $errors {
      regsub -all $failure $story "\#fff $failure" story
    }

    set lines [split $story "\n"]  
    
    foreach line $lines {    
      regsub -all {# Given} $story {#ooo Given} story
      regsub -all {# When} $story {#ooo When} story      
    }

    regsub -all {# #} $story "#" story
  
    return $story
  }
}


ExerciseBuilder Given {there exists an object (.+)} {::nsf::object::exists $0}
ExerciseBuilder When {the procedure (.+) is called, (.+) is returned} {if {[$0] != "$1"} {set x 0} else {set x 1} }



