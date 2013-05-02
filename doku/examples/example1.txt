Description:
In this example you will create objects and procedures and you will call them.

Task 1:
Define the objects named objectA and objectB.

- Given there exists and object objectA.
- Given there exists and object objectB.

Task 2:
Define the instance variables refA for objectB and refB for objectA and assign objectA to refA and objectB to refB.

Prerequisites:
- Task 1

* Given there exists an variable refB in the object objectA.
* Given there exists an variable refA in the object objectB.

Task 3:
Define the procedures foo and bar, where foo is defined for objectA and calls the procedure bar that is defined for objectB.
The procedure bar should return the string "foobar".

Prerequisites:
- Task 2

* Given there exists a procedure foo for the object objectA.
* Given there exists a procedure bar for the object objectB.

Task 4:
Execute the procedure foo of objectA and store the returnvalue to the variable result.

Prerequisites:
- Task 3

* When the procedure foo of the object objectA is called, then "foobar" is returned.
* When the procedure foo of the object object is called, then the procedure bar of the object objectB is called.

--------------------------------------

Desired code output:

```tcl

package require XOTcl
namespace import ::xotcl::*

#Task 1

Object create objectA
Object create objectB

#Task 2

objectA set refB objectB
objectB set refA objectA

#Task 3

objectA proc foo {} {
  my instvar refB
  set x [$refB bar]
}

objectB proc bar {} {
  set x "foobar"
}

#Task 4

set result [objectA foo]

```
