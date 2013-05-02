# Overall structure

Description:
(textual description of the example; is not evaluated)

Task 1:
(textual description of a task; is not evaluated)

- Given ...
- Given ...


Task 2:
(textual description of a task; is not evaluated)

Prerequisites:
- Task 1

- When ...
- When ...


# Structural:

* Given there exists an object *concreteObjectName* [of the type *className*].
* Given there exists a variable *variableName* in the object/class *concreteInstanceName/className*. 
* Given there exists a procedure *procedureName* [for the class/object *className/concreteInstanceName*].
* Given there exists a class *classname* [that takes one parameter].
* Given that the object *concreteObjectName* is assigned to variable *variableName* [in the object *concreteInstanceName*].
* Given there exists a class *classname*.

# Behavioral:

* When the procedure *procedureName* [of the object *concreteInstanceName*] [with the parmeter *parameter*] is called, then *result* is returned.
* When the procedure *procedureName* [of the object *concreteInstanceName* is called] [with the parmeter *parameter*], then the procedure *procedureName2* [of the object *concreteInstanceName2* is called] is called.
* When the procedure *procedureName* [of the object *concreteInstanceName* is called] [with the parmeter *parameter*], the program does not terminate.
* When the procedure *procedureName* [of the object *concreteInstanceName*] is called, then *Result* is displayed on the command line.
* When the procedure *procedureName* [of the object *concreteInstanceName*] is called, then *result* is returned.


* When the procedure *procedureName* [of the object *concreteInstanceName*] is called, then *result* has to be smaller/greater 0 returned.
* When the procedure *procedureName* [of the object *concreteInstanceName*] is called, then *result* must be between *lowerBound* and *upperBound*.
* When the procedure *procedureName* [of the object *concreteInstanceName*] is called, then *result* must not be null.


[...]    = optional fragments

.../...  = alternative

*...*    = concrete name of object/variable/result 