#AutoIt3Wrapper_UseX64=N
#AutoIt3Wrapper_Run_AU3Check=Y
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#include "..\AcrobatReader.au3"

Opt('GUIOnEventMode', 0)
_Example()

Func _Example()
	Local $sFile = FileOpenDialog('Choose PDF', @ScriptDir, 'PDF (*.pdf)', $FD_FILEMUSTEXIST)
	If @error Then Return
	_AcrobatReader_SimpleViewer($sFile)
	If @error Then MsgBox($MB_ICONERROR, 'SimpleViewer', 'Error: ' & @error & ', detail: ' & @extended)
EndFunc   ;==>_Example
