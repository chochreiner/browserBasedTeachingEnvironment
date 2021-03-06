# Description:
In this example you will implement the class *Stack*, that provides the methods *push*, *pull* and *size*, whereas push returns the pushed element, pull returns the last pushed element and sizes returns the amount of items on the stack.

**Task 1:**
Define the class *Stack* and implement the methods *push*, *pull* and *size*.

- Given there exists a class *Stack*.
- Given there exists a procedure push for the class *Stack*.
- Given there exists a procedure pull for the class *Stack*.
- Given there exists a procedure size for the class *Stack*.


**Task 2:**
Create a instance of *Stack* named *stack* and push the three characters *a*, *b*, *c* onto the stack.

Prerequisites:
Task 1

- When the procedure *size* of the object *stack* is called, then *3* is returned.
- When the procedure *pop* of the object *stack* is called, then *c* is returned.
- When the procedure *pop* of the object *stack* is called, then *b* is returned.
- When the procedure *size* of the object *stack* is called, then *1* is returned.
- When the procedure *push* of the object *stack* with the parameter *d* is called, then *d* is returned.

--------------------------------------

Desired final code:

```tcl

package require XOTcl
namespace import ::xotcl::*

#Task 1

Class create Stack 

Stack instproc init {} {
  my instvar things
  my instvar size
  set things ""
}

Stack instproc push {thing} {
  my instvar things
  my instvar size  
  set things [concat [list $thing] $things]
  my incr size
  return $thing
}
  
Stack instproc pop {} {
  my instvar things
  my instvar size
  set top [lindex $things 0]
  set things [lrange $things 1 end]
  my incr size -1
  return $top
}

Stack instproc size {} {
  my instvar size
  return $size
}  

#Task 2

Stack create stack
stack push a
stack push b
stack push c

```