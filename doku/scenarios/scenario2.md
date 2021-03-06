# Description:
In this example you will create a class *C* that takes one parameter and has one variable as well as a procedure *foo*.
You will create instances of this class and learn how to avoid endless loops, while calling methods of two syntactic indetical instances.

**Task 1:**
Define a class named *C* that takes one parameter and has one variable named *ref*.

- Given there exists a class *C* that takes one parameter.
- Given there exists a variable *ref* in the class *C*. 

**Task 2:**
Define the procedure *foo* of the class *C* that calls again a procedure *foo* of an instance of the class *C* and prints the string *called*.

Prerequisites:
Task 1

- Given there exists a procedure *foo* for the class *C*.

**Task 3:**
Create two instances of the class *C* (*instanceA* and *instanceB*) and assign *instanceA* to the variable *ref* in *instanceB* and assign *instanceB* to the variable *ref* in *instanceA*.

Prerequisites:
Task 2

- Given there exists an object *instanceA* of the type *C*.
- Given there exists an object *instanceB* of the type *C*.
- Given that the object *instanceB* is assigned to variable *ref* in the object *instanceA*.
- Given that the object *instanceA* is assigned to variable *ref* in the object *instanceB*.

**Task 4:**
Execute the procedure *foo* of *instanceA*.

Prerequisites:
Task 3

- When the procedure *foo* of the object *instanceA* is called, the program does not terminate.

**Task 5:**
Introduce a mechanism that stopps the endless loop and ensures that the method foo only prints the string *called* twice.

Prerequisites:
Task 3

- When the procedure *foo* of the object *instanceA* is called, then *called \n called* is displayed on the commandline.


--------------------------------------

Desired code output (until Task 4):

```tcl

package require XOTcl
namespace import ::xotcl::*

#Task 1

Class create C -parameter {
  ref
}

#Task 2

C instproc foo {} {
  my instvar ref
  set x [$ref foo]
  puts "called"
}

#Task 3

C create instanceA
C create instanceB

instanceA ref instanceB
instanceB ref instanceA

#Task 4

set result [instanceA foo]

------------

```

Desired final code:

```tcl

package require XOTcl
namespace import ::xotcl::*

#Task 1

Class create C -parameter {
  ref
  already_called
}

#Task 2

C instproc foo {} {
  my instvar ref
  my instvar already_called
  if {$already_called==0} {
    set already_called 1
    set x [$ref foo]
    puts "called"
  }
}

#Task 3

C create instanceA
C create instanceB

instanceA ref instanceB
instanceA already_called 0

instanceB ref instanceA
instanceB already_called 0

#Task 5

set result [instanceA foo]

```
