#package require XOTcl
#namespace import ::xotcl::*

#proc functions + commands
puts "\n \n Commands:"
foreach {i} [info commands] {
  if {![info exists availablecommands]} {
    set availablecommands $i
  } else {
    set availablecommands "$availablecommands|$i"
  } 
}
foreach {i} [info functions] {
  if {![info exists availablecommands]} {
    set availablecommands $i
  } else {
    set availablecommands "$availablecommands|$i"
  } 
}

puts $availablecommands

#http://www.tcl.tk/man/tcl8.5/TclCmd/info.htm#M33

# TODO: constants, things like instvar, ...

#xotcl object info methods

#xotcl class info methods
