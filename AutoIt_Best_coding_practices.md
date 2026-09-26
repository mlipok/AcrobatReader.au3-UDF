# AutoIt Best Coding Practices

Source: https://www.autoitscript.com/wiki/Best_coding_practices
Retrieved: 2026-09-26

Outlined in this section is a detailed explanation of what are to be considered the good coding practices within AutoIt. These recommendations are based on accepted coding practices common to a number of other programming languages. You do not need to follow them, but it is recommended that you do.

**Note**: You must use AutoIt v3.3.10.0 or above to run the examples below.

## Using Functions

If a function sets the @error flag, you should always check it before using a return value - if @error indicates an error then the function return value is generally undefined.

Learn more about using Functions by reading "[Function Notes](https://www.autoitscript.com/autoit3/docs/function_notes.htm)" from HelpFile.

## Names of Variables

The variable naming convention used in AutoIt is based on [Hungarian notation](http://en.wikipedia.org/wiki/Hungarian_notation). The prefix defines the logical data type rather than the physical data type: in this way, it gives a hint as to what the variable's purpose is, or what it represents. The prefix does not encode the actual data type: this occurs during assignment. See the table below for accepted standards.

| prefix | covering type | example |
| --- | --- | --- |
| a | Arrays | $aArray[0] |
| b | Booleans | $bBool = True |
| d | Binaries | $dBinary = Binary("0x80000000") |
| e | Constant variable | Local Const $eEulersConstant = 2.7182818284590452 |
| f | Floating point | $fFloat = 0.123 |
| h | Handles (and GUI handles) | $hGUI = GUICreate("My GUI") |
| i | Integer | $iInteger = 10 |
| id | An AutoIt controlID | $idButton\_Ok = GUICtrlCreateButton("OK", 5, 5) |
| m | Maps | $mMap[] |
| n | General number (no preference) | $nNumber = 0 |
| o | Objects | $oExcel = ObjCreate("Excel.Application") |
| p | Pointers | $pRect = DllStructGetPtr($tRECT) |
| s | Strings (chars included) | $sString = "Hello world" |
| t | Structures | $tSTRUCT = DllStructCreate($tagSTRUCT) |
| tag | Structures definition | $tagDATE = "struct; word Year;word Month;word Day; endstruct" |
| v | Variant | $vData = ClipGet() |

Variables are named following this schema:

| dollar prefix | type (lower case) | [optional] subtype (lower case) | var name (first letter in upper case) |
| --- | --- | --- | --- |
| $ | a | h | Handles |

Examples:

```autoit
; Assign a local variable the integer 7
Local $iWeekDays = 7

; Assign a local variable the value of Pi
Local $fPi = 3.14159265358979

; Assign a local variable an array of strings
Local $asArray[7] = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun']

; Assign a local variable an array of numbers
Local $anArray[4] = [0, 0.25, 3 / 4, 12]
```

## Variable Initialization

When initializing variables there are several points to consider. It is bad practice to hog memory by assigning data which is not immediately required. It is therefore recommended that you declare and initialize variables immediately prior to use. If you wish to assign a default value to a variable which you intend to overwrite later, then the data should be of the same (or the most logical representation of its) type and use as little memory as possible.

Examples:

```autoit
; Inconsistent data types are considered bad
Local $iInteger = "0"
Local $sString = False

; Correct initialization
Local $iInteger = 0
Local $sString = ''
```

In the following table, recommended default values are shown for each data type. Some data types have more than one possibile default value which can be used for initialization.

| Default Value | covering type |
| --- | --- |
| Binary("") | $d |
| "" | $s, $v |
| 0 | $a, $h, $i, $id, $m, $n, $o, $p, $t, $tag, $v |
| 0.0 | $f |
| Null | $o, $s, $v |
| False (or True) | $b |

Example:

```autoit
; Declare and initialize a variable with the recommended default value
Local $vUndefined = Null ; This does not require much memory

; Some time later:
$vUndefined = 0xB0AD1CEA ; Assign an appropriate value as and when needed
```

To reduce bloat, multiple variables can be declared on a single line. When declaring multiple variables on the same line, it is generally recommended that you stick to declaring one data type on each line. The intention here is to make the code easier to follow and manage in a future, however the best layout will vary according to circumstance.

Example:

```autoit
; Not recommended
Local $sString = "", $iInteger = 0, $asArray = ["a","b","c"] ; Mixed data types

; Recommended
Local $iLeft = 10, $iTop = 10 ; Integers
Local $idButton_Go = GUICtrlCreateButton("Go", $iLeft, $iTop) ; ControlIds
Local $idButton_Quit = GUICtrlCreateButton("Quit", 50, 10) ; ControlIds
```

In some languages it is essential to initialize variables on declaration, but this is not the case with AutoIt. Regarding data type, variables declared without being initialized should be considered as being undefined.

## Scopes of Variables

Variables should also be named according to their scope.

| Global UDF variable | Global variable | Local variable |
| --- | --- | --- |
| $\_\_g\_iSomeVar | $g\_iSomeVar | $iSomeVar |

With this method, you will avoid unwanted re-assignments.

Example:

```autoit
#include <MsgBoxConstants.au3>

; Assign a Global variable the number 0
Global $iSomeVar1 = 0
; Assign a Global variable the number 5
Global $g_iSomeVar2 = 5

SomeFunc()

Func SomeFunc()
    ; Assign Local variables respectively the numbers 3 and 4
    Local $iSomeVar1 = 3, $iSomeVar2 = 4

    ; Note: The user inadvertently re-assigned the global variable $iSomeVar1, because this one is not named as "global"

    ; Display the value of $iSomeVar1
    MsgBox($MB_SYSTEMMODAL, "", "Value of $iSomeVar1: " & $iSomeVar1)

    ; Display the value of $iSomeVar2
    MsgBox($MB_SYSTEMMODAL, "", "Value of $iSomeVar2: " & $iSomeVar2)

    ; Display the value of $g_iSomeVar2
    MsgBox($MB_SYSTEMMODAL, "", "Value of $g_iSomeVar2: " & $g_iSomeVar2)
EndFunc
```

- A variable declared globally (with the Global keyword) is visible anywhere in the script.  
  Always declare your global variables in the global scope, not in a function. It will prevent another function from using it before its declaration and the declaration is implicit (see [examples](#jumpsec1)).

- A variable declared locally (with the Local keyword), has a visibility which depends on the scope where it's declared.

:   Declaration in the global scope: the variable is visible everywhere; declare it as Local if this one is only to be used in the same scope, i.e. outside of any functions. A variable declared as Local in the Global scope is still a Global variable, it's only for the sake of code clarity that you'd use the Local declaration in the Global scope.
:   Declaration in a function: the variable is visible by the function itself and nowhere else.

Structure of a code scope:

```autoit
; Global scope

; Include the Constants file, it contains various constants; it's needed here for the $MB_SYSTEMMODAL flag of the MsgBox function)
#include <MsgBoxConstants.au3>

; This scope is either Global or Local, depending on where you use the variables

; Assign a Global variable the number 0 (which corresponds to an initialization of a variable number), its scope is Global because it's used in at least one function
Global $g_iVar1 = 0

; Assign a Local variable the string "foo", its scope is Local because its use is used only in this scope
Local $sVar2 = "foo"

; Display the content of $sVar2
MsgBox($MB_SYSTEMMODAL, "", "Value of $sVar2: " & $sVar2)

; Re-assign a Local variable the string returned by the function MyFunc
$sVar2 = MyFunc()

; Re-Display the content of $sVar2
MsgBox($MB_SYSTEMMODAL, "", "Value of $sVar2: " & $sVar2)

; Declare a function (its main utility is described later in Functions, we can see one here which is to create a Local scope)
Func MyFunc()
    ; Local scope

    ; Display the content of $g_iVar1
    MsgBox($MB_SYSTEMMODAL, "", "Value of $g_iVar1: " & $g_iVar1)

    ; Assign a Local variable the string "bar", its scope is Local because its use is restricted to the function's scope
    Local $sVar3 = "bar"

    ; Display the content of $sVar3
    MsgBox($MB_SYSTEMMODAL, "", "Value of $sVar3: " & $sVar3)

    ; Return the $sVar3 content, it will be visible (if used) to the scope where the function is called
    Return $sVar3
EndFunc   ;==>MyFunc
```

Concerning the Dim keyword, its recommended usage is limited to empty an existing array (Example 1) or to redeclare a function parameter (Example 2).

Example 1:

```autoit
; Include the Array UDF, it's needed here for the _ArrayDisplay function
#include <Array.au3>
 
; Assign a Local variable an array containing numbers with a size of 5
; Note that an array is 0 based, so to access the first element the code is: $aiArray[0]
Local $aiArray[5] = [1, 2, 3, 4, 5]
 
; Display the contents
_ArrayDisplay($aiArray)
 
; Empty the array (and keep its size)
Dim $aiArray[5]
 
; Display the contents
_ArrayDisplay($aiArray)
```

Remark: The variable type of an emptied array is a string, every non initialized variable is a string.

Example 2:

```autoit
#include <Array.au3>

; Call MyFunc with default parameters ($vParam1 = 0)
MyFunc()

; Assign a Local variable an array containing integers
Local $aiArray[3] = [3, 4, 5]
; Call MyFunc with $aiArray as parameter ($vParam1 = $aiArray)
MyFunc($aiArray)

Func MyFunc($vParam1 = 0)
    ; If $vParam1 is NOT an array then redeclare it to an array
    If Not IsArray($vParam1) Then
        Dim $vParam1[3] = [0, 1, 2]
    EndIf

    ; Display the array
    _ArrayDisplay($vParam1)
EndFunc   ;==>MyFunc
```

And for the ReDim keyword, limit its use to resize an array when you want to keep its content:

```autoit
; Include the Array UDF, it's needed here for the _ArrayDisplay function
#include <Array.au3>
 
; Assign a Local variable an array containing numbers with a size of 5
; Note than an array is 0 based, so to access the first element the code is: $aiArray[0]
Local $aArray[5] = [1, 2, 3, 4, 5]
 
; Display the contents
_ArrayDisplay($aArray)
 
; Resize the array (and keep its content)
ReDim $aArray[3]
 
; Display the contents
_ArrayDisplay($aArray)
```

Why using Dim over Local/Global is not always a good option:

```autoit
#include <MsgBoxConstants.au3>
 
Dim $g_vVariableThatIsGlobal = "This is a variable that has ""Program Scope"" aka Global."
 
MsgBox($MB_SYSTEMMODAL, "", "An example of why Dim can cause more problems than solve them.")
 
Example()
 
Func Example()
    MsgBox($MB_SYSTEMMODAL, "", $g_vVariableThatIsGlobal) ; That looks alright to me as it displays the following text: This is a variable that has "Program Scope" aka Global
 
    Local $vReturn = SomeFunc() ; Call some random function
 
    MsgBox($MB_SYSTEMMODAL, $vReturn, $g_vVariableThatIsGlobal) ; The Global variable ($g_vVariableThatIsGlobal) changed because I totally forgot I had a duplicate variable name in "SomeFunc"
EndFunc   ;==>Example
 
Func SomeFunc()
    ; This should create a variable in Local scope if the variable name doesn"t already exist
    ; For argument sake I totally forgot that I declared a variable already with the same name
    ; Well I only want this to be changed in the function and not the variable at the top of the script
    ; Should be OK right? Think again
    Dim $g_vVariableThatIsGlobal = ""
 
    For $i = 1 To 10
        $g_vVariableThatIsGlobal &= $i ; This will return 12345678910 totally wiping the previous contents of $g_vVariableThatIsGlobal
    Next
    Return $g_vVariableThatIsGlobal
EndFunc   ;==>SomeFunc
```

Declaring Global variables in a Function is never a good idea:

```autoit
#include <MsgBoxConstants.au3>

; Calling Example() first will initialise the Global variable $g_vVariableThatIsGlobal and therefore calling SomeFunc() won't return an error
; Now look at Example 2
Example()
 
Func Example()
    ; Declaring a variable in a function can cause serious problems, hence why all Global variables should be declared at the top of a script
    Global $g_vVariableThatIsGlobal = 'This is a variable that has ''File Scope'' aka Global.'
    SomeFunc()
EndFunc   ;==>Example
 
Func SomeFunc()
    MsgBox($MB_SYSTEMMODAL, '', $g_vVariableThatIsGlobal) ; As the variable was initialised this will not return an error
EndFunc   ;==>SomeFunc
```

Example 2:

```autoit
#include <MsgBoxConstants.au3>

; Calling SomeFunc() first will bypass the Global variable $g_vVariableThatIsGlobal being initialised and therefore AutoIt has no idea of what data the variable
; $g_vVariableThatIsGlobal contains
SomeFunc()
 
Func Example()
    ; Declaring a variable in a function can cause serious problems, hence why all Global variables should be declared at the top of a script
    Global $g_vVariableThatIsGlobal = 'This is a variable that has ''File Scope'' aka Global.'
    SomeFunc()
EndFunc   ;==>Example
 
Func SomeFunc()
    MsgBox($MB_SYSTEMMODAL, '', $g_vVariableThatIsGlobal) ; As the variable wasn't initialised this will return an error of "variable used without being declared."
EndFunc   ;==>SomeFunc
```

Declaring variables in loops (For, While, Do etc..) can have an affect on efficiency:

```autoit
#include <MsgBoxConstants.au3>

; Declaring variables inside loops should be avoided as the variable is re-declared on each repetition
For $i = 1 To 10 ; $i is in 'loop scope.'
    Local $iInt = $i
Next
MsgBox($MB_SYSTEMMODAL, '', $iInt) ; This will display 10
```

```autoit
#include <MsgBoxConstants.au3>

; Declaring variables outside of loops is more efficient in the long run
Local $iInt = 0
For $i = 1 To 10 ; $i is in 'loop scope.'
    $iInt = $i
Next
MsgBox($MB_SYSTEMMODAL, '', $iInt) ; This will display 10
```

There is no requirement to declare the iteration count variable in a loop:

```autoit
; Correct
Local Const $iCount = 99
Local $aArray[$iCount]
For $i = 0 To UBound($iCount) - 1 ; $i is only used in the loop, so there is no requirement to declare it
    $aArray[$i] = $i
Next

; Incorrect
Local Const $iCount = 99
Local $aArray[$iCount]
Local $i ; This is only used to store the iteration count value in the loop and therefore doesn't need to be declared. 
For $i = 0 To UBound($iCount) - 1
    $aArray[$i] = $i
Next
```

As you can see, there is the Const keyword in the example, we are going to talk about it.

## Const, Static, Enum

### Const

We won't talk about the advantages of using a constant variable, they are neglibible (for your information, an AutoIt constant variable is marked as read-only and remains a read-only variable when compiled).

The Const keyword may be used first by some of you to avoid re-assignments.
The best way to use them is for real static values, meaning that these values won't change regardless of the instance of the program.

Example:

```autoit
; Not recommended
Local Const $hGUI = GUICreate("MyGUI")
; The handle of the window is unique, it's generated by Windows and changes.
; To be exact: It is constant for the lifetime of the currently running script. But when you run the script again you get a different handle from Windows.

; Recommended
Local Const $fPi = 3.1415926 ; Archimedes' constant
```

### Static

Static variables are the solution to global variables being used in only one function.
e.g: Retain variable data once returned from a Function and only use that variable in that particular Function.

```autoit
Example()

Func Example()
    SomeFunc() ; This will display a message box of 1, 1
    SomeFunc() ; This will display a message box of 1, 2
    SomeFunc() ; This will display a message box of 1, 3
EndFunc   ;==>Example

Func SomeFunc()
    ; This initialises a Static variable in Local scope. When a variable is declared just in Local scope (within a Function,)
    ; it's destroyed when the Function ends/returns. This isn't the case for a Static variable. Also, the variable can't be
    ; accessed from anywhere else in the script apart from the Function it was declared in
    Local Static $vVariableThatIsStatic = 0
    Local $vVariableThatIsLocal = 0
    $vVariableThatIsLocal += 1 ; This will always be 1 as it is destroyed once returned from SomeFunc
    $vVariableThatIsStatic += 1 ; This will increase by 1
    MsgBox(4096, $vVariableThatIsLocal, $vVariableThatIsStatic)
EndFunc   ;==>SomeFunc
```

### Enum

This statement is often practical in certain situations:

```autoit
#include <MsgBoxConstants.au3>

Example()

Func Example()
    ; Create variables in Local scope and enumerate through the variables. Default is to start from 0
    Local Enum $eCat, $eDog, $eMouse, $eHamster ; $eHamster is equal to the value 3, not 4

    ; Create an array in Local scope with 4 elements
    Local $aAnimalNames[4]

    ; Assign each array element with the name of the respective animal. For example the name of the cat is Jasper
    $aAnimalNames[$eCat] = 'Jasper' ; $eCat is equal to 0, similar to using $aAnimalNames[0]
    $aAnimalNames[$eDog] = 'Beethoven' ; $eDog is equal to 1, similar to using $aAnimalNames[1]
    $aAnimalNames[$eMouse] = 'Pinky' ; $eMouse is equal to 2, similar to using $aAnimalNames[2]
    $aAnimalNames[$eHamster] = 'Fidget' ; $eHamster is equal to 3, similar to using $aAnimalNames[3]

    ; Display the values of the array
    MsgBox($MB_SYSTEMMODAL, '', '$aAnimalNames[$eCat] = ' & $aAnimalNames[$eCat] & @CRLF & _
            '$aAnimalNames[$eDog] = ' & $aAnimalNames[$eDog] & @CRLF & _
            '$aAnimalNames[$eMouse] = ' & $aAnimalNames[$eMouse] & @CRLF & _
            '$aAnimalNames[$eHamster] = ' & $aAnimalNames[$eHamster] & @CRLF)

    ; Sometimes using this approach for accessing an element is more practical than using a numerical value, due to the fact changing the index value of
    ; the enum constant has no effect on its position in the array. Therefore changing the location of $eCat in the array is as simple as changing the order
    ; it appears in the initial declaration e.g

    ; Local Enum $eDog, $eMouse, $eCat, $eHamster

    ; Now $eCat is the 2nd element in the array. If you were using numerical values, you would have to manually change all references of $aAnimalNames[0] to
    ; $aAnimalNames[2], as well as for the other elements which have now shifted
EndFunc   ;==>Example
```

## Au3Check directive

As you may know (and we hope), the Au3Check tool checks your code for syntax errors, variables used without being declared etc. which is a good thing to fix your script.

With the official custom directive used to check the helpfile examples/includes, you can apply the good coding practices listed above:

```autoit
#AutoIt3Wrapper_Au3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w- 4 -w 5 -w 6 -w- 7
```

|Note: this directive is only used if you've installed the full version of [Scite4AutoIt3](https://www.autoitscript.com/cgi-bin/getfile.pl?../autoit3/scite/download/SciTE4AutoIt3.exe)

## Magic Numbers

Magic numbers are arbitrary numbers interspersed throughout a program's source code which do not have an associated identifier. The downside to this is not being able to derive a meaning from the number.

For example:

```autoit
MsgBox(262144, "Magic Numbers", "It's Adventure Time!")
```

In this example, the magic number is 262144 with the identifier being $MB\_TOPMOST according to the helpfile.

The corrected example:

```autoit
#include <MsgBoxConstants.au3>
MsgBox($MB_TOPMOST, "Magic Numbers", "It's Adventure Time!")
```

Example 2:

```autoit
; Imagine you're a new user to AutoIt and you come across this code, where would you find -3, -4 or -5 in the help file?
; Since AutoIt is relatively a new concept to you, your first thought isn't to search through all the include files, I mean
; why would you, the help file is there for a reason
Example()

Func Example()
    Local $hGUI = GUICreate('')
    GUICtrlCreateLabel('Why magic numbers are counter productive.', 5, 5)
    GUICtrlSetState(Default, 128) ; Does this hide, show or disable it?
    GUICtrlSetState(Default, 64) ; Does this hide, show or disable it?
    GUISetState(@SW_SHOW, $hGUI)

    While 1
        Switch GUIGetMsg()
            Case -3 ; Doesn't really tell much about what it does
                ExitLoop

            Case -4, -5 ; Again, no idea what these are. MouseMove? MouseClick? Restore?
                MsgBox(4096, '', 'Do something when this action takes place.')

        EndSwitch
    WEnd

    GUIDelete($hGUI)
EndFunc   ;==>Example
```

Did you understand the numbers were these:

```autoit
#include <GUIConstantsEx.au3>

Example()

Func Example()
    Local $hGUI = GUICreate('')
    GUICtrlCreateLabel('Why magic numbers are counter productive.', 5, 5)
    GUICtrlSetState(Default, $GUI_DISABLE) ; Better, this is documented in the help file
    GUICtrlSetState(Default, $GUI_ENABLE) ; Better, this is documented in the help file
    GUISetState(@SW_SHOW, $hGUI)

    While 1
        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE ; Better, this is documented in the help file. Ah, it's the close action
                ExitLoop

            Case $GUI_EVENT_MINIMIZE, $GUI_EVENT_RESTORE ; Better, this is documented in the help file
                MsgBox($MB_SYSTEMMODAL, '', 'Do something when this action takes place.') 

        EndSwitch
    WEnd

    GUIDelete($hGUI)
EndFunc   ;==>Example
```

[Magic number (programming)](http://en.wikipedia.org/wiki/Magic_number_(programming))

## Include-once directive

This one is designed for standard includes and UDFs, it's highly recommended to use it only for that.

Those includes may be used in more than one file of your project because they are needed for some includes or your script itself.
In that case, the code would be duplicated, which is not a good thing especially if you have constants declared in those files, in so far as the constants cannot be redeclared/reassigned you will get error messages about trying to redeclare them; same thing for functions, you can't use a function name more than once.

Put the directive at the top of your UDF (library) to avoid it from being included more than once :

```autoit
#include-once
```

For discussion please visit: [Forum: Good coding practices in AutoIt](http://www.autoitscript.com/forum/index.php?showtopic=146866)
