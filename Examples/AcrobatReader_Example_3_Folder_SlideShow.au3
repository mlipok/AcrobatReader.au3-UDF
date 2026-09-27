#AutoIt3Wrapper_UseX64=N
#AutoIt3Wrapper_Run_AU3Check=Y
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#include "..\AcrobatReader.au3"

Opt('GUIOnEventMode', 0)
_Example()

Func _Example()
	Local $sFolder = FileSelectFolder('Choose folder with PDF files', @ScriptDir, 0, @ScriptDir)
	If @error Then Return
	Local $aFiles = _FileListToArray($sFolder, '*.pdf', $FLTA_FILES, True)
	If @error Then
		MsgBox($MB_ICONINFORMATION, 'PDF slideshow', 'No PDF files found or the folder cannot be read.')
		Return
	EndIf
	Local $hGUI = GUICreate('PDF slideshow', @DesktopWidth - 100, @DesktopHeight - 100, 50, 0, BitOR($GUI_SS_DEFAULT_GUI, $WS_CLIPCHILDREN), $WS_EX_TOPMOST)
	If Not @Compiled Then GUISetIcon('z:\!!!_SVN_AU3\ICONS\Work_black.ico') ; will change icon
	Local $mViewer = _AcrobatReader_Create($hGUI, 0, 0, @DesktopWidth - 100, @DesktopHeight - 100)
	Local $iCreateError = @error
	If $iCreateError Then
		MsgBox($MB_ICONERROR, 'PDF slideshow', 'Create error: ' & $iCreateError)
		GUIDelete($hGUI)
		Return
	EndIf
	GUISetState(@SW_SHOW, $hGUI)
	Local $bClose = False
	For $i = 1 To $aFiles[0]
		WinSetTitle($hGUI, '', 'Opening ' & $i & '/' & $aFiles[0] & ' - ' & $aFiles[$i])
		_AcrobatReader_Open($mViewer, $aFiles[$i])
		Local $iError = @error, $iExtended = @extended
		If $iError Then
			MsgBox($MB_ICONERROR, 'PDF slideshow', $aFiles[$i] & @CRLF & 'Error: ' & $iError & ', detail: ' & $iExtended, 0, $hGUI)
			ExitLoop
		EndIf
		Local $hTimer = 0
		While 1
			Local $aMsg = GUIGetMsg($GUI_EVENT_ARRAY)
			If $aMsg[0] = $GUI_EVENT_CLOSE And $aMsg[1] = $hGUI Then
				$bClose = True
				ExitLoop
			EndIf
			Local $iState = _AcrobatReader_Poll($mViewer)
			$iError = @error
			$iExtended = @extended
			If $iError Then
				MsgBox($MB_ICONERROR, 'PDF slideshow', 'Error: ' & $iError & ', detail: ' & $iExtended, 0, $hGUI)
				$bClose = True
				ExitLoop
			EndIf
			; The interval starts after command acceptance, not a render-complete signal.
			If $iState = $ACROBATREADER_ACCEPTED And $hTimer = 0 Then
				WinSetTitle($hGUI, '', 'Command accepted (rendering not confirmed) ' & $i & '/' & $aFiles[0] & ' - ' & $aFiles[$i])
				$hTimer = TimerInit()
			EndIf
			If $hTimer <> 0 And TimerDiff($hTimer) >= 2000 Then ExitLoop
			Sleep(10)
		WEnd
		If $bClose Then ExitLoop
	Next
	_AcrobatReader_Destroy($mViewer)
	Local $iDestroyError = @error, $iDestroyExtended = @extended
	If $iDestroyError Then MsgBox($MB_ICONERROR, 'PDF slideshow', 'Cleanup error: ' & $iDestroyError & ', detail: ' & $iDestroyExtended, 0, $hGUI)
	If Not GUIDelete($hGUI) Then MsgBox($MB_ICONERROR, 'PDF slideshow', 'Could not delete application GUI.')
EndFunc   ;==>_Example
