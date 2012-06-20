package require XOTcl
namespace import ::xotcl::*

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
puts ""

foreach {i} [xotcl::Object info methods] {
  if {![info exists availablecommands1]} {
    set availablecommands1 $i
  } else {
    set availablecommands1 "$availablecommands1|$i"
  } 
}

foreach {i} [xotcl::Class info methods] {
  if {![info exists availablecommands1]} {
    set availablecommands1 $i
  } else {
    set availablecommands1 "$availablecommands1|$i"
  } 
}

puts $availablecommands1

#http://www.tcl.tk/man/tcl8.5/TclCmd/info.htm#M33

# TODO: constants, things like instvar, ...

#xotcl::Object info methods
#xotcl::Class info methods
