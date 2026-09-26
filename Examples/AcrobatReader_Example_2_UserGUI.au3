#AutoIt3Wrapper_UseX64=N
#AutoIt3Wrapper_Run_AU3Check=Y
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#include "..\AcrobatReader.au3"

Opt('GUIOnEventMode', 0)
_Example()

Func _Example()
	Local $hGUI = GUICreate('AcrobatReader - UserGUI', 900, 700, -1, -1, BitOR($GUI_SS_DEFAULT_GUI, $WS_SIZEBOX, $WS_MAXIMIZEBOX, $WS_CLIPCHILDREN), $WS_EX_TOPMOST)
	If Not @Compiled Then GUISetIcon('z:\!!!_SVN_AU3\ICONS\Work_black.ico') ; will change icon
	Local $idOpen = GUICtrlCreateButton('Open PDF', 10, 10, 110, 28)
	GUICtrlSetResizing($idOpen, $GUI_DOCKALL)
	Local $idClear = GUICtrlCreateButton('Clear / Cancel', 130, 10, 120, 28)
	GUICtrlSetResizing($idClear, $GUI_DOCKALL)
	Local $idStatus = GUICtrlCreateLabel('Choose a file using Open PDF.', 265, 16, 610, 22)
	GUICtrlSetResizing($idStatus, $GUI_DOCKALL)
	Local $mViewer = _AcrobatReader_Create($hGUI, 0, 48, 900, 652)
	If @error Then
		MsgBox($MB_ICONERROR, 'UserGUI', 'Create error: ' & @error)
		GUIDelete($hGUI)
		Return
	EndIf
	GUISetState(@SW_SHOW, $hGUI)
	; No startup dialog and no automatic document: the application owns its GUI.
	Local $iLastState = $ACROBATREADER_EMPTY
	While 1
		Local $aMsg = GUIGetMsg($GUI_EVENT_ARRAY)
		If $aMsg[1] = $hGUI Then
			Switch $aMsg[0]
				Case $GUI_EVENT_CLOSE
					ExitLoop
				Case $idOpen
					Local $sFile = FileOpenDialog('Choose PDF', @ScriptDir, 'PDF (*.pdf)', $FD_FILEMUSTEXIST, '', $hGUI)
					If Not @error Then
						_AcrobatReader_Open($mViewer, $sFile)
						If @error Then MsgBox($MB_ICONERROR, 'UserGUI', 'Open error: ' & @error & ', detail: ' & @extended, 0, $hGUI)
						$iLastState = -1
					EndIf
				Case $idClear
					_AcrobatReader_Clear($mViewer)
					If @error Then MsgBox($MB_ICONERROR, 'UserGUI', 'Clear error: ' & @error, 0, $hGUI)
				Case $GUI_EVENT_RESIZED, $GUI_EVENT_MAXIMIZE, $GUI_EVENT_RESTORE
					Local $aSize = WinGetClientSize($hGUI)
					If IsArray($aSize) And $aSize[0] > 0 And $aSize[1] > 48 Then
						_AcrobatReader_Resize($mViewer, 0, 48, $aSize[0], $aSize[1] - 48)
						If @error Then GUICtrlSetData($idStatus, 'Resize error: ' & @error)
					EndIf
			EndSwitch
		EndIf
		Local $iState = _AcrobatReader_Poll($mViewer), $iError = @error, $iExtended = @extended
		If $iState <> $iLastState Then
			Switch $iState
				Case $ACROBATREADER_EMPTY
					GUICtrlSetData($idStatus, 'No document. Choose Open PDF.')
				Case $ACROBATREADER_LOADING
					GUICtrlSetData($idStatus, 'Opening... Clear / Cancel stops navigation.')
				Case $ACROBATREADER_ACCEPTED
					GUICtrlSetData($idStatus, $mViewer.file)
				Case $ACROBATREADER_ERROR
					GUICtrlSetData($idStatus, 'Error: ' & $iError & ', detail: ' & $iExtended)
			EndSwitch
			$iLastState = $iState
		EndIf
		Sleep(10)
	WEnd
	_AcrobatReader_Destroy($mViewer)
	If @error Then MsgBox($MB_ICONERROR, 'UserGUI', 'Cleanup error: ' & @error, 0, $hGUI)
	If Not GUIDelete($hGUI) Then MsgBox($MB_ICONERROR, 'UserGUI', 'Could not delete application GUI.')
EndFunc   ;==>_Example
