# UDF-spec

Source: https://www.autoitscript.com/wiki/UDF-spec
Retrieved: 2026-09-26

> The source page is marked as a work in progress. This is a local copy for checking the specification, not an additional set of repository rules.

*This page is still a work in progress.*

This page is still under construction.

---

A library is a collection of one or more User Defined Functions (UDFs). However, the term UDF is often used to describe the collection as a whole. If a UDF is to be considered for inclusion in the standard set distributed with AutoIt then it must meet all the criteria detailed here, but it's also good practice to always write in conformance with at least the majority of this document, as that is what will be expected by people reading your code later.

## Basic Requirements

Firstly, the code itself should meet the following basic requirements:

- Be tidied. Just hit `Ctrl+T` from SciTE or run Tidy manually. The only flag needed is `/sf`.
- Pass Au3Check with no errors using the strictest settings: `-q -d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7`
- Support everything AutoIt supports. In some cases features may not be able to support everything, in which case this should be checked for and return errors appropriately. This applies to: windows OS versions (AutoIt has support for all OS' from windows 2000), unicode and ansi strings, 64 and 32 bit machines.
- Not use any magic numbers. Ever. None. At all. No excuses.

## UDF Outline

The library itself has a header that details important information such as the minimum OS and AutoIt versions, and what system dlls are required. There is also a number of other sections that are required that list what is present in the UDF.

### Includes

Since a UDF is designed to define functions, it should only be included once. As a result, the `#include-once` directive should be used. This is typically the first line of the UDF, followed by the includes used by the UDF. Include statements should use the double quoted form, as the library is expected to work in the same directory as libraries it depends on. Non standard libraries can be used if necessary, but this should be documented and linked to so users can download it as well. It goes without saying that a UDF based on non-standard UDFs cannot itself become a standard.

### Index

The index follows the following template (taken from `WinAPI.au3`):

```autoit
; #INDEX# =======================================================================================================================
; Title .........: Windows API
; AutoIt Version : 3.2
; Description ...: Windows API calls that have been translated to AutoIt functions.
; Author(s) .....: Paul Campbell (PaulIA), gafrost, Siao, Zedna, arcker, Prog@ndy, PsaltyDS, Raik, jpm
; Dll ...........: kernel32.dll, user32.dll, gdi32.dll, comdlg32.dll, shell32.dll, ole32.dll, winspool.drv
; ===============================================================================================================================
```

The only required element in the index header is `Title`. All others are ignored by the processor, but should be included for reference, remember that you can add some custom fields like `Links` too.

The `Dll` field can remain empty in many cases where no dlls are called directly. This header must be defined.

### Other Sections

Other sections, in order of appearance, are as follows.

#### Variables

All global variables needed to be declared in the UDF are defined in this section. They should follow the variable rules for globals. Individual variables do not need to be documented, as it is assumed they are for internal use only. Any globals designed to be accessible for the user should instead be wrapped by a function (or multiple functions if globals must be retrieved and set). The template for this section is:

```autoit
; #VARIABLES# ===================================================================================================================
Global $__g_vMyGlobal = 0
; ===============================================================================================================================
```

If no globals are needed then this section may be ommitted. Please consider the use of global variables carefully, and read through the section on global variables.

#### Constants

Any global constant values are defined in this section. This should be constants only designated for use within the library itself. Constants that may be needed by the user should be defined in a separate file, named `UDFConstants.au3` where `UDF` is the name of the parent file. For example `File.au3` uses constants defined in `FileConstants.au3`. The exception to that rule is control UDFs which miss out the prepended 'GUI' when naming constant files, so `GUIButton.au3` uses constants from `ButtonConstants.au3`. The template for this section is:

```autoit
; #CONSTANTS# ===================================================================================================================
Global Const $__MYUDFCONSTANT_FOOBAR = 42
; ===============================================================================================================================
```

If no constants are needed in this section, either because none are used or because they are stored in a separate file, then it may be ommitted. Please read the section on global constants for specific info on naming and definition of constants.

#### Listing

This defines all functions and structures currently used in the library. It MUST be the second defined header item after <#Index>. It is a simple list with each function on a line where the functions and structures appear in the same order as they do in the code, which is alphabetical order and structures first. A simple way to generate this list is to create a small script that searches for function definitions and outputs them in the correct format, an example of which is [here](http://www.autoitscript.com/forum/topic/120820-function-name-lister/). In addition there is a second section that lists functions and structures for internal use only, this does not need to appear if none are defined.

The template for these sections are:

```autoit
; #CURRENT# =====================================================================================================================
;$tagSTRUCT
;_MyUDF_Function
; ===============================================================================================================================

; #INTERNAL_USE_ONLY# ===========================================================================================================
;$tagINTERNALSTRUCT
;__MyUDF_InternalFunction
; ===============================================================================================================================
```

This section still needs to be defined for files that only define constants. It should also be noted that there MUST NOT be a space between the `;` and the function/structure name.

#### Undocumented Listing

There is a final kind of listing that lists functions for which no documentation exists, or they have been deprecated and are only included for backwards compatibility. These are listed in a section with the header `NO_DOC_FUNCTION`. This is very rarely used, and is reserved only for functions that can be utilised by the user, or that would have been in the past, as opposed to those for internal use only.

Template:

```autoit
; #NO_DOC_FUNCTION# =============================================================================================================
;_MyUDF_Function
; ===============================================================================================================================
```

#### Renamed Functions

Although it should not be the case in new UDFs, many of the older ones (particularly to do with controls) have had script breaking name changes to functions. These are documented in the UDF to ensure updating old scripts is as easy as possible. The basic format for this is:

```autoit
; #NO_DOC_FUNCTION# =============================================================================================================
;_MyUDF_OldFunction                        ; --> _MyUDF_NewFunction
; ===============================================================================================================================
```

The space padding is optional. This section is ignored as far as the docs are concerned, and is usually omitted.

## Functions

### Naming

Function names must start with an underscore, and the first word is the library name. There is then usually another underscore before the rest of the function name. The library name should be consistent across all the functions in the library, and can be shortened if a logical abbreviation is available (e.g. `Window` ==> `Win`). Each word should be capitalized, but no underscores are placed in the rest of the name, for example `_WinAPI_GetWindowLong`.

For control libraries, the first part of the function name is changed slightly. For example the UDF for listviews would use `_GUICtrlListview_*`. When a function wraps a dll call, then the second part should closely resemble the function name as it appears in other languages. This also applies to functions acting as a wrapper to `SendMessage`.

Functions are defined in alphabetical order by name, which is the same as using `Tidy` with the `/sf` flag set.

### Parameters

Parameters should follow the variable naming scheme ([here](#Naming_2)). All parameters must be checked to ensure they are valid, and return unique and documented error codes if they are not. For functions involving a specific type of control, this includes checking the class name using `_WinAPI_IsClassName`.

Parameters that are optional or byref should be documented as such, and the effect these have explicitly stated. For example a byref parameter should detail exactly what the expected output is as well as the input.

### Headers

All functions have a documentation header that describes the function. This uses the following template:

```autoit
; #FUNCTION# ====================================================================================================================
; Name...........: _WinAPI_GetMousePos
; Description ...: Returns the current mouse position
; Syntax.........: _WinAPI_GetMousePos([$bToClient = False[, $hWnd = 0]])
; Parameters ....: $bToClient   - If True, the coordinates will be converted to client coordinates
;                  $hWnd        - Window handle used to convert coordinates if $fToClient is True
; Return values .: Success      - $tagPOINT structure with current mouse position
;                  Failure      - 0
; Author ........: Paul Campbell (PaulIA)
; Modified.......:
; Remarks .......: This function takes into account the current MouseCoordMode setting when  obtaining  the  mouse  position.
;                  It will also convert screen to client coordinates based on the parameters passed.
; Related .......: $tagPOINT, _WinAPI_GetMousePosX, _WinAPI_GetMousePosY
; Link ..........: 
; Example .......: Yes
; ===============================================================================================================================
Func _WinAPI_GetMousePos($bToClient = False, $hWnd = 0)
```

Some of the parameters in the header are optional, in which case they should remain, but be left empty (for example the `Link` and `Modified` lines in the above header). In others, they are needed, but can be empty or not used such as `Parameters` or `Return Values`. In this case the value should be 'None', as they will still be present in the documentation.

There are some flags that can be used within function headers:

- **+** in column 20 is the continuation flag for the previous line (used in Parameters, Return Values)
- **|** in column 20 is a new line in the right side of the table when the help file is generated (used in Parameters, Return Values)
- **-** in column 20 will create new row in the table, used for things like Defaults for a style (used in Parameters, Return Values)
- **+** in column 2 of Remarks is a blank line

Name

:   Specifies the name of the function. This will be identical to how it appeas in the Func statement in the code itself.

Description

:   Gives a short summary of what the function does. This should only be a single line, as it is only designed to give a short impression of what is happening. For the standard set of includes distributed with AutoIt3, this value is also used in the SciTE calltips.

Syntax

:   Describes the syntax of the function call. This differs slightly from what appears in the code itself for optional parameters, which are enclosed in square brackets ("[ ]"). Since subsequent parameters must also be optional, and cannot be defined unless all the previous ones have been given, these brackets are nested in the form: Function([param1[, param2[,param3]]]). Note that the opening bracket appears before the comma seperator.

Parameters

:   This is a list of the arguments accepted by the function. Each is listed, followed by a dash ("-") and a description of what it is. The dash can be padded for neatness, although the amount of padding depends on how long the parameter names are. If the parameter is optional then the meaning of the default value should be given, similarly if it's used to pass data back to the program in the form of byref then the changes made should also be detailed. For more information on parameters see Parameters.

Return values

:   Details what is returned by the function. This often comes in the form of Success and Failure values, but this is not always the case. Any setting of the @error of @extended flags should be detailed, along with their meanings, in some cases it is enough to say that @error is set to non-zero in the event of an error, in most cases though a list of values for @error should be given.

Author

:   This is the original writer of the function. It should contain the username, so that any queries about the code can be made through the forum, but you can give as much or little information as you feel appropriate.

Modified

:   This is a list of modifications made. At its most basic this is just a list of users who have made changes, but ideally it includes some information about what they did, in which cases it follows the same form as other multi-value lines, with the username and description of modifications seperated by a dash.

Remarks

:   This is anything the user should know about a function in order to use it. For example exceptional cases and recommended ways to handle the function should all be detailed here, as well as additional info about possible reasons for failure and how to deal with them.

Related

:   A comma seperated list of functions or structures related to the function.

Link

:   A link to additional information about the function. For many system function wrappers, this will be `@@MsdnLink@@ FunctionName`, which represents that the user should search MSDN for the function.

Example

:   A simple yes or no value specifying whether the function has an example. If this is no then your UDF is not ready to be released. The <#Examples> section has more information on the format and location of examples.

The easiest way to generate the header is to copy and paste the following blank template in:

```autoit
; #FUNCTION# ====================================================================================================================
; Name...........: 
; Description ...: 
; Syntax.........: 
; Parameters ....: 
; Return values .: 
; Author ........: 
; Modified.......: 
; Remarks .......: 
; Related .......: 
; Link ..........: 
; Example .......: 
; ===============================================================================================================================
```

There are also a number of plugins for SciTE that will generate a header and maybe fill in certain known values for you such as Name, Syntax and Parameters. The most complete one that conforms to these standards is [here](http://code.google.com/p/m-a-t/wiki/UDFHeaderGenerator), but there are two others [here](http://www.autoitscript.com/forum/topic/28270-lua-script-for-udf-header/) and [here](http://www.autoitscript.com/forum/topic/28270-lua-script-for-udf-header/page__view__findpost__p__200823).

### Internal use only

Functions can also be marked for use only within the library and not to be documented for use by the user. These are named according to the same rules as normal functions but begin with a double underscore ("\_\_"). The header is exactly the same except with the first line replaced, to make the blank template:

```autoit
; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: 
; Description ...: 
; Syntax.........: 
; Parameters ....: 
; Return values .: 
; Author ........: 
; Modified.......: 
; Remarks .......: 
; Related .......: 
; Link ..........: 
; Example .......: 
; ===============================================================================================================================
```

## Structures

Structures are defined as global constants, and follow the naming pattern `$tagSTRUCTNAME`. The struct name should be as it appears on MSDN if it's used in the windows API, or follow a similar pattern if not. It should go without saying that they must work for both 32 and 64 bit machines, including resolving any alignment issues. Elements should also be named as they appear on MSDN if they are taken from there, which includes the hungarian notation prefix. Although many standard UDFs do not follow that rule, importantly `StructureConstants.au3`, the rule still stands.

### Headers

Structures need a header similar to functions, but with some minor differences. The same rules apply in terms of wrapping and line length however. The header follow this standard template:

```autoit
; #STRUCTURE# ===================================================================================================================
; Name...........: $tagPOINT
; Description ...: Defines the x and y coordinates of a point
; Fields ........: X - Specifies the x-coordinate of the point
;                  Y - Specifies the y-coordinate of the point
; Author ........: Paul Campbell (PaulIA)
; Remarks .......: 
; Related .......: 
; ===============================================================================================================================
Global Const $tagPOINT = "long X;long Y"
```

It is essentially a shortened header, with the only thing new is the Fields line, which effectively replaces the Parameters field in terms of usage. All the same rules apply as listed [here](#Function_Header_Fields).

The blank template is:

```autoit
; #STRUCTURE# ===================================================================================================================
; Name...........: 
; Description ...: 
; Fields ........: 
; Author ........: 
; Remarks .......: 
; Related .......: 
; ===============================================================================================================================
```

Structures may also be marked for internal use only. In this case the header ramains the same, but the sections first line changes. The blank template is:

```autoit
; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name...........: 
; Description ...: 
; Fields ........: 
; Author ........: 
; Remarks .......: 
; Related .......: 
; ===============================================================================================================================
```

## Variables

For code readability, there are special rules dealing with variables, particularly naming. All variables should be declared at the beginning of their scope, which usually means at the start of the function in which they are used, but could mean the top of the UDF itself in the [Variables section](#Variables).

### Naming

A variable's first letter signifies the expected scope and type of the variable. See [Names of Variables](https://www.autoitscript.com/wiki/Best_coding_practices#Names_of_Variables "Best coding practices")

### Globals

The use of globals in a UDF is generally frowned upon, and byref parameters and static variables should be used where possible instead. However, in cases where this is not possible and a global must be used they should be defined using the following naming pattern: `$__g_<VARNAME>` where `<VARNAME>` is the name as it would usually appear according to the variable naming rules above. This ensures there will never be a conflict with user variables of other UDF globals. They should be declared at the top of the UDF in the Variables section.

Globals are always private. If they need to be accessed by the user then functions need to be written wrapping that operation and values should be checked. Notable exceptions are debug variables, which are designed for developer purposes and may be used by some users in extreme cases. These are named `$Debug_<UDF>` although the `<UDF>` part is often shortened so `GUIEdit.au3` uses `$Debug_Ed`. It is not required that a UDF has debugging symbols, but they are allowed to remain in releases.

### Constants

There are two types of constants, internal and public. Public constants are designed to be utilised by the user, and are referenced in functions that use them. They include styles and flags. Internal constants are designed for use only within the library, so that values used fairly often can be held in one place to allow for easy updating. Both kinds of constant are always typed in all upper case. Constants taken from the windows API should appear exactly as they are defined there, but internal constants follow the naming pattern: `$__<UDF>CONSTANT_<NAME>`.

### The `Dim` statement

Should not be used.

## Examples

All functions and structures that are made public to the user need to have a good quality example. This means that it should:

- Be simple. Ideally the only functions used are basic functions like ConsoleWrite and MsgBox and the function that the example is written for. Writing a single example that covers a wide range of functions is not nearly as easy to use as writing an example per function that clearly demonstrates its use.
- Be readable. Everything should be explained step by step in comments.
- Be correct. In addition to passing the same Au3Check flags as the UDF itself (`-q -d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7`) it should always be written with best practice being the main consideration. This takes preference over the first point, just because code is shorter and looks easier doesn't mean it's right.
- Examples should represent all the functionality. If there is more than one way of using a function then include more than one example of how to use it.
- Not make any permanent changes to the users computer. For example, if demonstrating a File function, be sure to delete the file after it has been used. The same applies for any function that makes a change to the environment: the changes MUST be undone.

Always remember, the readability of code in an example is MORE important than the readability of code inside the UDF itself.

Examples are stored in script files called `<FUNCTION>.au3`. The files should be kept in a folder called `Examples`. To remain correct all examples should be wrapped in functions, such that the only code executed in the global scope is calling the function. This is usually named `Example`.

```autoit
#include <Constants.au3>
#include <GUIConstantsEx.au3>

Opt("MustDeclareVars", 1)

Example()

Func Example()
	Local $idButton_Run, $idButton_Test, $iMsg, $hGUI_MyApp
	
	$hGUI_MyApp = GUICreate("My GUI Button") ; Will create a dialog box that when displayed is centered

	$idButton_Run = GUICtrlCreateButton("Run Notepad", 4, 4, 80, 30)
	$idButton_Test = GUICtrlCreateButton("Button Test", 4, 38, 80, 30)

	GUISetState() ; will display a dialog box with 2 button

	; Run the GUI until the dialog is closed
	While 1
		$iMsg = GUIGetMsg()
		Select
			Case $iMsg = $GUI_EVENT_CLOSE
				ExitLoop
			Case $iMsg = $idButton_Run
				Run("Notepad.exe") ; Will Run/Open Notepad
			Case $iMsg = $idButton_Test
				MsgBox($MB_SYSTEMMODAL, "Testing", "Button 2 was pressed") ; Will demonstrate Button 2 being pressed
		EndSelect
	WEnd
	GUIDelete($hGUI_MyApp)
EndFunc   ;==>Example
```

### Multiple Examples

The helpfile now supports multiple examples per function. In order to maintain backwards compatibility with any other tools that use examples, the first file is still named `<FUNCTION>.au3`, but any additional examples are named `<FUNCTION>[n].au3` where n is an integer counter starting at 2.

## Template UDF

Here is an example of a UDF called `MyUDF.au3`:

```autoit
; AU3Check settings
#AutoIt3Wrapper_Run_AU3Check=Y
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#AutoIt3Wrapper_AU3Check_Stop_OnWarning=Y
#include-once

#include "MyUDFConstants.au3"
#include "AnInclude.au3"

; #INDEX# =======================================================================================================================
; Title .........: MyUDF
; AutoIt Version : 3.3.10.2
; Language ......: English
; Author(s) .....: 
; Modifiers .....: 
; Forum link ....: a link to the main forum topic (if aplicable)
; Description ...: An example UDF that does very little.
; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
;$tagMYSTRUCT
;_MyUDF_Function
; ===============================================================================================================================

; #STRUCTURE# ===================================================================================================================
; Name...........: $tagMYSTRUCT
; Description ...: An example of a structure.
; Fields ........: hFoo       - A handle to foo that does something.
;                  iBar       - An integer that does something.
; Author ........: Matt Diesel (Mat)
; Remarks .......:
; Related .......: _MyUDF_Function
; ===============================================================================================================================
Global Const $tagMYSTRUCT = "ptr hFoo; int iBar"

; #FUNCTION# ====================================================================================================================
; Name...........: _MyUDF_Function
; Description ...: A function that does something.
; Syntax.........: _MyUDF_Function(ByRef $avAnArray, $iAnInt[, $hAHandle = 0[, $nSomeNumber = 42]])
; Parameters ....: $avAnArray       - [byref] An array of anything. The value of anything is changed and passed out using this
;                                     parameter. The array should only have one dimension
;                  $iAnInt          - An integer that does very little.
;                  $hAHandle        - [optional] A handle. Default is zero.
;                  $nSomeNumber     - [optional] A number of some kind. Default is 42.
; Return values .: Success          - A MYSTRUCT structure.
;                  Failure          - Returns zero and sets the @error flag:
;                                   |1 - The $avAnArray is invalid.
; Author ........: Matt Diesel (Mat)
; Modified.......:
; Remarks .......:
; Related .......: $tagMYSTRUCT
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _MyUDF_Function(ByRef $avAnArray, $iAnInt, $hAHandle = 0, $nSomeNumber = 42)
	; 1 - Error Checking for parameters.
	If Not IsArray($avAnArray) Or UBound($avAnArray, 0) <> 1 Then Return SetError(1, 0, 0) ; The $avAnArray is invalid.

	; 2 - Declaration of locals.
	Local $tMS = DllStructCreate($tagMYSTRUCT)

	; 3 - Function code
	DllStructSetData($tMS, "hFoo", $hAHandle)
	DllStructSetData($tMS, "iBar", $iAnInt * $nSomeNumber)

	Return $tMS
EndFunc   ;==>_MyUDF_Function
```
