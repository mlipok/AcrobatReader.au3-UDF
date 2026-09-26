#include-once
; #INDEX# =======================================================================================================================
; Title .........: AcrobatReader.au3 UDF
; Description: ..: AutoIt UDF (version 2.0.0) for embedding and controlling Acrobat PDF previews in custom GUIs, with an optional standalone viewer.
; Repository ....: https://github.com/mlipok/AcrobatReader.au3-UDF
; Forum link ....: https://www.autoitscript.com/forum/index.php?showtopic=162195
; License .......: MIT
; License text ..: https://opensource.org/license/mit
; SPDX-License-Identifier: MIT
; ===============================================================================================================================

#AutoIt3Wrapper_Run_AU3Check=Y
#AutoIt3Wrapper_Au3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#Tidy_Parameters=/r_extra_empty_lines /Sort_Funcs /Sort_Funcs_Comment /End_With_NewLine /Skip_commentblock

#include <Constants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <Misc.au3>
#include <MenuConstants.au3>
#include <MsgBoxConstants.au3>
#include <WinAPI.au3>
#include <StaticConstants.au3>

#Region ; AcrobatReader.au3 - ACKNOWLEDGEMENTS
;~ Thanks to BrewManNH
;~ http://www.autoitscript.com/forum/topic/134878-guiregistermsg-replacement-for-guictrlsetonevent-and-guigetmsg/

;~ Thanks to mikell
;~ http://www.autoitscript.com/forum/topic/161985-how-to-close-gui-with-guiregistermsg/

;~ Thanks to Danyfirex and Argumentum
;~ https://www.autoitscript.com/forum/topic/205490-how-to-avoid-window-activation/

;~ Thanks to Danyfirex for "background" tip about using
;~ 			ObjCreate("Shell.Explorer.2")
;~ 		instead:
;~ 			ObjCreate("AcroPDF.PDF.1")

;~ Thanks To Authenticity
;~ https://www.autoitscript.com/forum/topic/98583-list-all-child-controls-of-a-given-window/?tab=comments#comment-709097

;~ Thanks To mLipok :)
;~ https://www.autoitscript.com/forum/topic/177368-how-to-get-reference-to-pdf-object-embeded-in-ie/?do=findComment&comment=1272692
#EndRegion ; AcrobatReader.au3 - ACKNOWLEDGEMENTS

Global Enum $ACROBATREADER_EMPTY, $ACROBATREADER_LOADING, $ACROBATREADER_ACCEPTED, $ACROBATREADER_ERROR
Global $__g_sAcrobatReader_Line_Watcher = ''
Global $_g_b_Acrobat_inside_Shell = False
Global $__g_hAcrobatReader_GUI = 0, $__g_mAcrobatReader_Legacy = Null

#Region ; AcrobatReader.au3 - CORE Functions

; #FUNCTION# ====================================================================================================================
; Name ..........: _AcrobatReader_Clear
; Description ...: Cancels navigation and removes the ActiveX control while retaining the context.
; Syntax ........: _AcrobatReader_Clear(ByRef $m)
; Parameters ....: $m                    - Preview context passed ByRef.
; Return values .: On Success - last requested PDF path with @error = 0.
;                  On Failure - empty string for invalid context or last PDF path for cleanup failure;
;                  sets @error to one of the following:
;                    2 = Invalid context.
;                    9 = ActiveX control cleanup failed.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: The caller GUI remains open; Clear also cancels a pending Shell request.
; Related .......: _AcrobatReader_Open, _AcrobatReader_Destroy
; Link ..........:
; Example .......: AcrobatReader_Example_2_UserGUI.au3
; ===============================================================================================================================
Func _AcrobatReader_Clear(ByRef $m)
	If Not __AcrobatReader_Valid($m) Then Return SetError(2, 0, '')
	Local $sFile = $m.file
	If $m.ctrl And _WinAPI_IsWindow($m.host) Then
		If _WinAPI_GetParent($m.host) <> $m.parent Then Return SetError(9, 0, $sFile)
		If Not GUICtrlDelete($m.ctrl) Then Return SetError(9, 0, $sFile)
	EndIf
	$m.pdf = Null
	$m.shell = Null
	$m.ctrl = 0
	$m.host = 0
	$m.file = ''
	$m.stage = 0
	$m.state = $ACROBATREADER_EMPTY
	$m.error = 0
	$m.extended = 0
	Return SetError(0, 0, $sFile)
EndFunc   ;==>_AcrobatReader_Clear

; #FUNCTION# ====================================================================================================================
; Name ..........: _AcrobatReader_Create
; Description ...: Creates a lazy PDF-preview context bound to a caller-owned GUI.
; Syntax ........: _AcrobatReader_Create($hGUI[, $iLeft = 0[, $iTop = 0[, $iWidth = 800[, $iHeight = 600[, $bShell = False]]]]])
; Parameters ....: $hGUI                 - Caller-owned GUI handle.
;                  $iLeft                - Client-area left position; default 0.
;                  $iTop                 - Client-area top position; default 0.
;                  $iWidth               - Preview or viewer width; default shown in syntax.
;                  $iHeight              - Preview or viewer height; default shown in syntax.
;                  $bShell               - True selects Shell.Explorer.2; False selects AcroPDF.PDF.1.
; Return values .: On Success - preview context map with @error = 0.
;                  On Failure - 0 and sets @error to one of the following:
;                    2 = Invalid preview position or dimensions.
;                    3 = Invalid or unavailable caller GUI.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: The caller owns the GUI; no ActiveX control is created until _AcrobatReader_Open().
;                  Pass live contexts ByRef; _AcrobatReader_Clear() and _AcrobatReader_Destroy() never delete the GUI.
; Related .......: _AcrobatReader_Open, _AcrobatReader_Destroy
; Link ..........:
; Example .......: AcrobatReader_Example_2_UserGUI.au3
; ===============================================================================================================================
Func _AcrobatReader_Create($hGUI, $iLeft = 0, $iTop = 0, $iWidth = 800, $iHeight = 600, $bShell = False)
	If Not IsHWnd($hGUI) Or Not WinExists($hGUI) Then Return SetError(3, 0, 0)
	If Not __AcrobatReader_RectValid($iLeft, $iTop, $iWidth, $iHeight) Then Return SetError(2, 0, 0)
	Local $hPrevious = GUISwitch($hGUI)
	If @error Then Return SetError(3, 0, 0)
	If IsHWnd($hPrevious) Then GUISwitch($hPrevious)
	Local $m[]
	$m.kind = 'AcrobatReader/2'
	$m.parent = $hGUI
	$m.left = $iLeft
	$m.top = $iTop
	$m.width = $iWidth
	$m.height = $iHeight
	$m.shellMode = $bShell
	$m.ctrl = 0
	$m.host = 0
	$m.pdf = Null
	$m.shell = Null
	$m.file = ''
	$m.state = $ACROBATREADER_EMPTY
	$m.stage = 0
	$m.error = 0
	$m.extended = 0
	$m.timer = 0
	$m.timeout = 10000
	Return SetError(0, 0, $m)
EndFunc   ;==>_AcrobatReader_Create

; #FUNCTION# ====================================================================================================================
; Name ..........: _AcrobatReader_Destroy
; Description ...: Clears a preview and invalidates its context.
; Syntax ........: _AcrobatReader_Destroy(ByRef $m)
; Parameters ....: $m                    - Preview context passed ByRef.
; Return values .: On Success - last requested PDF path with @error = 0; Null returns an empty string.
;                  On Failure - empty string or last PDF path and sets @error to one of the following:
;                    2 = Invalid context.
;                    9 = ActiveX control cleanup failed.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: Repeated Destroy with Null is harmless; never deletes the caller GUI.
; Related .......: _AcrobatReader_Clear
; Link ..........:
; Example .......: AcrobatReader_Example_2_UserGUI.au3
; ===============================================================================================================================
Func _AcrobatReader_Destroy(ByRef $m)
	If IsKeyword($m) = 2 Then Return SetError(0, 0, '')
	Local $sFile = _AcrobatReader_Clear($m)
	If @error Then Return SetError(@error, @extended, $sFile)
	$m = Null
	Return SetError(0, 0, $sFile)
EndFunc   ;==>_AcrobatReader_Destroy

; #FUNCTION# ====================================================================================================================
; Name ..........: _AcrobatReader_DisableToolbar
; Description ...: Moves selected legacy Acrobat application modules into Disabled folders.
; Syntax ........: _AcrobatReader_DisableToolbar([$sAcroAppDir = Default])
; Parameters ....: $sAcroAppDir          - Acrobat AcroApp directory; Default uses the legacy installation path.
; Return values .: On Success - 1 with @error = 0.
;                  On Failure - 0 and sets @error to one of the following:
;                    1 = Acrobat module directory could not be listed.
;                    2 = Disabled directory could not be created.
;                    3 = Destination exists or a module could not be moved.
;                  @extended is the number of modules already moved.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: Does not overwrite backups. Do not call at application startup to hide the preview toolbar.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _AcrobatReader_DisableToolbar($sAcroAppDir = Default)
	If $sAcroAppDir = Default Then $sAcroAppDir = @ProgramFilesDir & '\Adobe\Acrobat Reader DC\Reader\AcroApp'
	Local $aFolders = _FileListToArray($sAcroAppDir, '*', $FLTA_FOLDERS, True)
	If @error Then Return SetError(1, 0, 0)
	Local $aNames[3] = ['AppCenter_R.aapp', 'Home.aapp', 'Viewer.aapp'], $iMoved = 0
	For $i = 1 To $aFolders[0]
		For $sName In $aNames
			Local $sSource = $aFolders[$i] & '\' & $sName
			If Not FileExists($sSource) Then ContinueLoop
			Local $sDestination = $aFolders[$i] & '\Disabled\' & $sName
			If FileExists($sDestination) Then Return SetError(3, $iMoved, 0)
			If Not DirCreate($aFolders[$i] & '\Disabled') Then Return SetError(2, $iMoved, 0)
			If Not FileMove($sSource, $sDestination, 0) Then Return SetError(3, $iMoved, 0)
			$iMoved += 1
		Next
	Next
	Return SetError(0, $iMoved, 1)
EndFunc   ;==>_AcrobatReader_DisableToolbar

; #FUNCTION# ====================================================================================================================
; Name ..........: _AcrobatReader_GetInstaledVersion
; Description ...: Reads an installed Adobe Acrobat executable and version information.
; Syntax ........: _AcrobatReader_GetInstaledVersion()
; Parameters ....: None
; Return values .: On Success - map with exe, path, date, time, is64, lang and version.
;                  On Failure - map with default fields and sets @error to:
;                    1 = No Acrobat executable was found in the inspected registry entries.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: The historical spelling of Instaled is retained. is64 reports the matching registry view, not an independent EXE architecture test.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _AcrobatReader_GetInstaledVersion()
	Local $aKeys[2] = ["HKLM64\SOFTWARE\Adobe\Adobe Acrobat\DC\Installer", "HKLM\SOFTWARE\Adobe\Adobe Acrobat\DC\Installer"]
	If @OSArch <> 'X86' Then $aKeys[1] = "HKLM64\SOFTWARE\WOW6432Node\Adobe\Adobe Acrobat\DC\Installer"
	Local $mAcrobat[]
	$mAcrobat.exe = ''
	$mAcrobat.path = ''
	$mAcrobat.date = ''
	$mAcrobat.time = ''
	$mAcrobat.is64 = False
	$mAcrobat.lang = ''
	$mAcrobat.version = ''
	For $i = 0 To UBound($aKeys) - 1
		If $i = 0 And @OSArch = 'X86' Then ContinueLoop
		Local $sExe = RegRead($aKeys[$i], 'Acrobat.exe')
		If @error Then ContinueLoop
		If Not FileExists($sExe) Then ContinueLoop
		$mAcrobat.exe = $sExe
		$mAcrobat.path = RegRead($aKeys[$i], 'Path')
		$mAcrobat.date = RegRead($aKeys[$i], 'InstallDate')
		$mAcrobat.time = RegRead($aKeys[$i], 'InstallTime')
		$mAcrobat.is64 = ($i = 0)
		$mAcrobat.lang = RegRead($aKeys[$i], 'APP_LANG')
		$mAcrobat.version = FileGetVersion($sExe)
		Return SetError(0, 0, $mAcrobat)
	Next
	Return SetError(1, 0, $mAcrobat)
EndFunc   ;==>_AcrobatReader_GetInstaledVersion

; #FUNCTION# ====================================================================================================================
; Name ..........: _AcrobatReader_GUI_DELETE
; Description ...: Destroys the compatibility-adapter preview.
; Syntax ........: _AcrobatReader_GUI_DELETE()
; Parameters ....: None
; Return values .: On Success - last requested PDF path with @error = 0.
;                  On Failure - empty string or last PDF path and forwards @error = 2 or 9
;                  from _AcrobatReader_Destroy.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: Does not delete the caller-owned GUI.
; Related .......: _AcrobatReader_Destroy
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _AcrobatReader_GUI_DELETE()
	Local $sFile = _AcrobatReader_Destroy($__g_mAcrobatReader_Legacy)
	If @error Then Return SetError(@error, @extended, $sFile)
	$__g_hAcrobatReader_GUI = 0
	Return SetError(0, 0, $sFile)
EndFunc   ;==>_AcrobatReader_GUI_DELETE

; #FUNCTION# ====================================================================================================================
; Name ..........: _AcrobatReader_GUI_Poll
; Description ...: Polls Shell navigation started by the compatibility adapter.
; Syntax ........: _AcrobatReader_GUI_Poll()
; Parameters ....: None
; Return values .: On Success - preview state constant with @error = 0.
;                  On Failure - $ACROBATREADER_ERROR and forwards @error/@extended from _AcrobatReader_Poll.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: Call from the caller GUI loop when the adapter uses Shell mode.
; Related .......: _AcrobatReader_Poll
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _AcrobatReader_GUI_Poll()
	Return _AcrobatReader_Poll($__g_mAcrobatReader_Legacy)
EndFunc   ;==>_AcrobatReader_GUI_Poll

; #FUNCTION# ====================================================================================================================
; Name ..........: _AcrobatReader_GUI_ShowFile
; Description ...: Compatibility adapter for embedding a preview in a supplied GUI.
; Syntax ........: _AcrobatReader_GUI_ShowFile($sFile[, $sTitle = 'PDF'[, $x = 0[, $y = 0[, $w = 800[, $h = 600[, $hWnd = 0[, $bFreeze = False]]]]]]])
; Parameters ....: $sFile                - Full path to a local PDF file.
;                  $sTitle               - Window title; default PDF. Ignored by the compatibility adapter.
;                  $x                    - Client-area left position.
;                  $y                    - Client-area top position.
;                  $w                    - Control width.
;                  $h                    - Control height.
;                  $hWnd                 - Required caller GUI handle in the compatibility adapter; target window in child listing.
;                  $bFreeze              - Historical flag; ignored by the compatibility adapter.
; Return values .: On Success - caller GUI HWND for a PDF request; last PDF path when clearing or destroying.
;                  On Failure - 0 or last PDF path during cleanup, with @error set to one of the following:
;                    1 = Invalid or missing PDF file.
;                    2 = Invalid preview context, position or dimensions.
;                    3 = Caller GUI is invalid or unavailable.
;                    4 = COM control creation failed.
;                    5 = ActiveX host is invalid or could not be created or resized.
;                    6 = PDF load or Shell navigation failed.
;                    8 = PDF control configuration failed.
;                    9 = ActiveX control cleanup failed.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: Requires hWnd; coordinates are client coordinates. sTitle and bFreeze are ignored.
; Related .......: _AcrobatReader_Create, _AcrobatReader_Open
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _AcrobatReader_GUI_ShowFile($sFile, $sTitle = 'PDF', $x = 0, $y = 0, $w = 800, $h = 600, $hWnd = 0, $bFreeze = False)
	#forceref $sTitle, $bFreeze
	If IsKeyword($sFile) = 2 Then Return _AcrobatReader_GUI_DELETE()
	If IsString($sFile) And $sFile == '' Then
		If Not IsMap($__g_mAcrobatReader_Legacy) Then Return SetError(0, 0, '')
		Return _AcrobatReader_Clear($__g_mAcrobatReader_Legacy)
	EndIf
	If Not IsHWnd($hWnd) Or Not WinExists($hWnd) Then Return SetError(3, 0, 0)
	If IsMap($__g_mAcrobatReader_Legacy) Then
		If $__g_mAcrobatReader_Legacy.parent <> $hWnd Or $__g_mAcrobatReader_Legacy.shellMode <> $_g_b_Acrobat_inside_Shell Then
			_AcrobatReader_GUI_DELETE()
			If @error Then Return SetError(@error, @extended, 0)
		EndIf
	EndIf
	If Not IsMap($__g_mAcrobatReader_Legacy) Then
		$__g_mAcrobatReader_Legacy = _AcrobatReader_Create($hWnd, $x, $y, $w, $h, $_g_b_Acrobat_inside_Shell)
		If @error Then Return SetError(@error, @extended, 0)
	EndIf
	$__g_hAcrobatReader_GUI = $hWnd
	_AcrobatReader_Resize($__g_mAcrobatReader_Legacy, $x, $y, $w, $h)
	If @error Then Return SetError(@error, @extended, 0)
	_AcrobatReader_Open($__g_mAcrobatReader_Legacy, $sFile)
	If @error Then Return SetError(@error, @extended, 0)
	Return SetError(0, 0, $hWnd)
EndFunc   ;==>_AcrobatReader_GUI_ShowFile

; #FUNCTION# ====================================================================================================================
; Name ..........: _AcrobatReader_IsActiveWindow
; Description ...: Reports whether the legacy adapter GUI is active.
; Syntax ........: _AcrobatReader_IsActiveWindow($sComment[, $iErr = @error[, $iExt = @extended]])
; Parameters ....: $sComment             - Historical diagnostic comment; ignored.
;                  $iErr                 - Error code to preserve; defaults to current @error.
;                  $iExt                 - Extended value to preserve; defaults to current @extended.
; Return values .: Boolean result; preserves the supplied @error and @extended values.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: The historical signature is retained for existing callers.
; Related .......: _AcrobatReader_GUI_ShowFile
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _AcrobatReader_IsActiveWindow($sComment, $iErr = @error, $iExt = @extended)
	#forceref $sComment
	Return SetError($iErr, $iExt, WinActive($__g_hAcrobatReader_GUI) <> 0)
EndFunc   ;==>_AcrobatReader_IsActiveWindow

; #FUNCTION# ====================================================================================================================
; Name ..........: _AcrobatReader_Open
; Description ...: Opens a PDF in an existing preview context.
; Syntax ........: _AcrobatReader_Open(ByRef $m, $sFile[, $iTimeout = 10000])
; Parameters ....: $m                    - Preview context passed ByRef.
;                  $sFile                - Full path to a local PDF file.
;                  $iTimeout             - Shared Shell timeout in milliseconds; default 10000.
; Return values .: On Success - 1 with @error = 0; Shell mode may still be loading.
;                  On Failure - 0 and sets @error to one of the following:
;                    1 = Invalid or missing PDF file.
;                    2 = Invalid context, file argument or timeout.
;                    3 = Caller GUI is unavailable.
;                    4 = COM control creation failed.
;                    5 = ActiveX host is invalid or could not be created.
;                    6 = PDF load or Shell navigation failed.
;                    8 = PDF control configuration failed.
;                    9 = Cleanup of the preceding request failed.
;                  @extended carries the underlying error when available.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: Direct mode uses .src; Shell mode starts asynchronous navigation.
;                  $ACROBATREADER_ACCEPTED means COM accepted the commands, not that the PDF was rendered or validated.
; Related .......: _AcrobatReader_Poll, _AcrobatReader_Clear
; Link ..........:
; Example .......: AcrobatReader_Example_2_UserGUI.au3
; ===============================================================================================================================
Func _AcrobatReader_Open(ByRef $m, $sFile, $iTimeout = 10000)
	If Not __AcrobatReader_Valid($m) Then Return SetError(2, 0, 0)
	If Not IsString($sFile) Or Not IsNumber($iTimeout) Or $iTimeout <= 0 Then Return SetError(2, 0, 0)
	If $sFile = '' Or Not FileExists($sFile) Or StringInStr(FileGetAttrib($sFile), 'D') Then Return SetError(1, 0, 0)
	If Not WinExists($m.parent) Then Return SetError(3, 0, 0)
	; Replacing a pending Shell navigation releases its host; stale events cannot win.
	If $m.state = $ACROBATREADER_LOADING Or $m.state = $ACROBATREADER_ERROR Then
		_AcrobatReader_Clear($m)
		If @error Then Return SetError(@error, @extended, 0)
	EndIf
	__AcrobatReader_CreateControl($m)
	If @error Then Return __AcrobatReader_Fail($m, @error, @extended)
	$m.file = _PathFull($sFile)
	$m.error = 0
	$m.extended = 0
	$m.timer = TimerInit()
	$m.timeout = $iTimeout
	Local $oLocal_COM_Error_Handler = ObjEvent('AutoIt.Error', __AcrobatReader_COM_ErrorFunction)
	#forceref $oLocal_COM_Error_Handler
	If $m.shellMode Then
		$m.pdf = Null
		$m.state = $ACROBATREADER_LOADING
		$m.stage = 1
		$m.shell.navigate('about:blank')
		If @error Then Return __AcrobatReader_Fail($m, 6, @error)
	Else
		; Some Acrobat installations reject LoadFile but accept src.
		$m.pdf.src = $m.file
		If @error Then Return __AcrobatReader_Fail($m, 6, @error)
		__AcrobatReader_Configure($m.pdf)
		If @error Then Return __AcrobatReader_Fail($m, @error, @extended)
		$m.state = $ACROBATREADER_ACCEPTED
	EndIf
	Return SetError(0, 0, 1)
EndFunc   ;==>_AcrobatReader_Open

; #FUNCTION# ====================================================================================================================
; Name ..........: _AcrobatReader_Poll
; Description ...: Advances pending Shell navigation and reports the preview state.
; Syntax ........: _AcrobatReader_Poll(ByRef $m)
; Parameters ....: $m                    - Preview context passed ByRef.
; Return values .: On Success - $ACROBATREADER_EMPTY, $ACROBATREADER_LOADING or $ACROBATREADER_ACCEPTED.
;                  On Failure - $ACROBATREADER_ERROR and sets @error to one of the following:
;                    2 = Invalid context.
;                    3 = Caller GUI is unavailable.
;                    4 = COM control creation failed during an earlier Open.
;                    5 = ActiveX host failed during an earlier Open.
;                    6 = PDF load, Shell navigation or COM polling failed.
;                    7 = Navigation timed out.
;                    8 = PDF control configuration failed.
;                  @extended carries the underlying COM error when available.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: Call from the GUI loop; both navigation steps share one timeout.
;                  $ACROBATREADER_ACCEPTED means COM accepted the commands, not that the PDF was rendered or validated.
; Related .......: _AcrobatReader_Open, _AcrobatReader_Clear
; Link ..........:
; Example .......: AcrobatReader_Example_3_Folder_SlideShow.au3
; ===============================================================================================================================
Func _AcrobatReader_Poll(ByRef $m)
	If Not __AcrobatReader_Valid($m) Then Return SetError(2, 0, $ACROBATREADER_ERROR)
	If $m.state = $ACROBATREADER_ERROR Then Return SetError($m.error, $m.extended, $m.state)
	If $m.state <> $ACROBATREADER_LOADING Then Return SetError(0, 0, $m.state)
	If Not WinExists($m.parent) Then
		__AcrobatReader_Fail($m, 3)
		Return SetError(3, 0, $ACROBATREADER_ERROR)
	EndIf
	If TimerDiff($m.timer) >= $m.timeout Then
		__AcrobatReader_Fail($m, 7)
		Return SetError(7, 0, $ACROBATREADER_ERROR)
	EndIf
	Local $oLocal_COM_Error_Handler = ObjEvent('AutoIt.Error', __AcrobatReader_COM_ErrorFunction)
	#forceref $oLocal_COM_Error_Handler
	Local $bBusy = $m.shell.Busy
	If @error Then Return __AcrobatReader_PollFail($m, 6, @error)
	Local $iReady = $m.shell.readyState
	If @error Then Return __AcrobatReader_PollFail($m, 6, @error)
	If $bBusy Or $iReady <> 4 Then Return SetError(0, 0, $m.state)
	Local $sLocation = $m.shell.LocationURL
	If @error Then Return __AcrobatReader_PollFail($m, 6, @error)
	If $m.stage = 1 Then
		If $sLocation <> 'about:blank' Then Return SetError(0, 0, $m.state)
		Local $sURL = StringReplace(StringReplace(StringReplace($m.file, '%', '%25'), '#', '%23'), '?', '%3F')
		$sURL = StringReplace($sURL, '\', '/')
		If StringLeft($sURL, 2) = '//' Then
			$sURL = 'file:' & $sURL
		Else
			$sURL = 'file:///' & $sURL
		EndIf
		$m.stage = 2
		$m.shell.navigate($sURL & '#view=FitH&toolbar=0')
		If @error Then Return __AcrobatReader_PollFail($m, 6, @error)
		Return SetError(0, 0, $m.state)
	EndIf
	If $sLocation = 'about:blank' Or $sLocation = '' Then Return SetError(0, 0, $m.state)
	$m.pdf = $m.shell.document
	If @error Then Return __AcrobatReader_PollFail($m, 6, @error)
	If Not IsObj($m.pdf) Then Return SetError(0, 0, $m.state)
	__AcrobatReader_Configure($m.pdf)
	If @error Then Return __AcrobatReader_PollFail($m, @error, @extended)
	$m.state = $ACROBATREADER_ACCEPTED
	Return SetError(0, 0, $m.state)
EndFunc   ;==>_AcrobatReader_Poll

; #FUNCTION# ====================================================================================================================
; Name ..........: _AcrobatReader_Resize
; Description ...: Moves and resizes only the embedded ActiveX control.
; Syntax ........: _AcrobatReader_Resize(ByRef $m, $x, $y, $w, $h)
; Parameters ....: $m                    - Preview context passed ByRef.
;                  $x                    - Client-area left position.
;                  $y                    - Client-area top position.
;                  $w                    - Control width.
;                  $h                    - Control height.
; Return values .: On Success - 1 with @error = 0.
;                  On Failure - 0 and sets @error to one of the following:
;                    2 = Invalid context, position or dimensions.
;                    3 = Caller GUI is unavailable.
;                    5 = ActiveX host is invalid or could not be resized.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: Coordinates refer to the client area of the caller GUI.
; Related .......: _AcrobatReader_Create
; Link ..........:
; Example .......: AcrobatReader_Example_2_UserGUI.au3
; ===============================================================================================================================
Func _AcrobatReader_Resize(ByRef $m, $x, $y, $w, $h)
	If Not __AcrobatReader_Valid($m) Then Return SetError(2, 0, 0)
	If Not __AcrobatReader_RectValid($x, $y, $w, $h) Then Return SetError(2, 0, 0)
	If Not WinExists($m.parent) Then Return SetError(3, 0, 0)
	If $m.ctrl Then
		If Not _WinAPI_IsWindow($m.host) Or _WinAPI_GetParent($m.host) <> $m.parent Then Return SetError(5, 0, 0)
		If Not GUICtrlSetPos($m.ctrl, $x, $y, $w, $h) Then Return SetError(5, 0, 0)
	EndIf
	$m.left = $x
	$m.top = $y
	$m.width = $w
	$m.height = $h
	Return SetError(0, 0, 1)
EndFunc   ;==>_AcrobatReader_Resize

; #FUNCTION# ====================================================================================================================
; Name ..........: _AcrobatReader_SimpleViewer
; Description ...: Shows a blocking PDF viewer in a GUI owned by this function.
; Syntax ........: _AcrobatReader_SimpleViewer($sFile[, $sTitle = 'PDF'[, $iWidth = 900[, $iHeight = 700[, $bShell = False[, $hParentHWND = 0]]]]])
; Parameters ....: $sFile                - Full path to a local PDF file.
;                  $sTitle               - Window title; default PDF. Ignored by the compatibility adapter.
;                  $iWidth               - Preview or viewer width; default shown in syntax.
;                  $iHeight              - Preview or viewer height; default shown in syntax.
;                  $bShell               - True selects Shell.Explorer.2; False selects AcroPDF.PDF.1.
;                  $hParentHWND          - Optional GUI handle in this process; 0 leaves other windows enabled.
; Return values .: On Success - 1 after normal close with @error = 0.
;                  On Failure - 0 and sets @error to one of the following:
;                    1 = Invalid or missing PDF file.
;                    2 = Invalid viewer dimensions or preview context.
;                    3 = Parent or viewer GUI is invalid or unavailable.
;                    4 = COM control creation failed.
;                    5 = ActiveX host is invalid or could not be created or resized.
;                    6 = PDF load, Shell navigation or COM polling failed.
;                    7 = Navigation timed out.
;                    8 = PDF control configuration failed.
;                    9 = Viewer or ActiveX cleanup failed.
;                   10 = GUIOnEventMode is enabled.
;                  @extended carries the underlying error when available.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: Requires GUIGetMsg mode. Optional parent GUI is disabled during viewing and restored on exit; viewer is topmost.
; Related .......: _AcrobatReader_Create, _AcrobatReader_Open, _AcrobatReader_Poll
; Link ..........:
; Example .......: AcrobatReader_Example_1_SimpleViewer.au3
; ===============================================================================================================================
Func _AcrobatReader_SimpleViewer($sFile, $sTitle = 'PDF', $iWidth = 900, $iHeight = 700, $bShell = False, $hParentHWND = 0)
	If Opt('GUIOnEventMode') Then Return SetError(10, 0, 0)
	If Not IsString($sFile) Or Not FileExists($sFile) Or StringInStr(FileGetAttrib($sFile), 'D') Then Return SetError(1, 0, 0)
	If Not __AcrobatReader_RectValid(0, 0, $iWidth, $iHeight) Then Return SetError(2, 0, 0)
	Local $bHasParent = IsHWnd($hParentHWND) Or $hParentHWND <> 0
	If $bHasParent Then
		If Not IsHWnd($hParentHWND) Or Not WinExists($hParentHWND) Then Return SetError(3, 0, 0)
		If WinGetProcess($hParentHWND) <> @AutoItPID Then Return SetError(3, 0, 0)
	EndIf
	Local $hPrevious = __AcrobatReader_CurrentGUI()
	Local $hGUI = GUICreate($sTitle, $iWidth, $iHeight, -1, -1, BitOR($GUI_SS_DEFAULT_GUI, $WS_SIZEBOX, $WS_MAXIMIZEBOX, $WS_CLIPCHILDREN), $WS_EX_TOPMOST)
	If Not @Compiled Then GUISetIcon('z:\!!!_SVN_AU3\ICONS\Work_black.ico') ; will change icon
	If Not IsHWnd($hGUI) Then Return SetError(3, 0, 0)
	Local $m = _AcrobatReader_Create($hGUI, 0, 0, $iWidth, $iHeight, $bShell)
	Local $iError = @error, $iExtended = @extended
	If Not $iError Then
		_AcrobatReader_Open($m, $sFile)
		$iError = @error
		$iExtended = @extended
	EndIf
	Local $bRestoreParent = False
	If Not $iError And $bHasParent And Not WinExists($hParentHWND) Then $iError = 3
	If Not $iError And $bHasParent And _WinAPI_IsWindowEnabled($hParentHWND) Then
		_WinAPI_EnableWindow($hParentHWND, False)
		Local $iDisableError = @error
		$bRestoreParent = Not _WinAPI_IsWindowEnabled($hParentHWND)
		If $iDisableError Or Not $bRestoreParent Then
			$iError = 3
			$iExtended = $iDisableError
		EndIf
	EndIf
	If Not $iError Then
		If Not GUISetState(@SW_SHOW, $hGUI) Then $iError = 3
	EndIf
	While Not $iError
		Local $aMsg = GUIGetMsg($GUI_EVENT_ARRAY)
		If $aMsg[1] = $hGUI Then
			If $aMsg[0] = $GUI_EVENT_CLOSE Then ExitLoop
			If $aMsg[0] = $GUI_EVENT_RESIZED Or $aMsg[0] = $GUI_EVENT_MAXIMIZE Or $aMsg[0] = $GUI_EVENT_RESTORE Then
				Local $aSize = WinGetClientSize($hGUI)
				If IsArray($aSize) And $aSize[0] > 0 And $aSize[1] > 0 Then _AcrobatReader_Resize($m, 0, 0, $aSize[0], $aSize[1])
				$iError = @error
				$iExtended = @extended
			EndIf
		EndIf
		If $iError Then ExitLoop
		_AcrobatReader_Poll($m)
		$iError = @error
		$iExtended = @extended
		Sleep(10)
	WEnd
	If IsMap($m) Then
		_AcrobatReader_Destroy($m)
		If @error And Not $iError Then
			$iError = @error
			$iExtended = @extended
		EndIf
	EndIf
	If Not GUIDelete($hGUI) And Not $iError Then $iError = 9
	If $bRestoreParent And WinExists($hParentHWND) Then
		_WinAPI_EnableWindow($hParentHWND, True)
		If (@error Or Not _WinAPI_IsWindowEnabled($hParentHWND)) And Not $iError Then $iError = 9
	EndIf
	If IsHWnd($hPrevious) And WinExists($hPrevious) Then GUISwitch($hPrevious)
	Return SetError($iError, $iExtended, $iError = 0)
EndFunc   ;==>_AcrobatReader_SimpleViewer

; #FUNCTION# ====================================================================================================================
; Name ..........: _AcrobatReader_WinListChildren
; Description ...: Lists descendant HWNDs and titles of the supplied window.
; Syntax ........: _AcrobatReader_WinListChildren($hWnd, ByRef $avArr)
; Parameters ....: $hWnd                 - Existing parent window handle.
;                  $avArr                - Output array of child HWNDs and titles, passed ByRef.
; Return values .: On Success - first child HWND with @error = 0.
;                  On Failure - 0 with @error = 1 for an invalid parent window or empty child list.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: $avArr[0][0] holds the count; subsequent rows hold each descendant HWND and title.
;                  The first child is not guaranteed to be the PDF preview host.
; Related .......: __AcrobatReader_AppendChildren
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _AcrobatReader_WinListChildren($hWnd, ByRef $avArr)
	Local $aEmpty[1][2] = [[0, '']]
	$avArr = $aEmpty
	If Not IsHWnd($hWnd) Or Not WinExists($hWnd) Then Return SetError(1, 0, 0)
	__AcrobatReader_AppendChildren($hWnd, $avArr)
	If $avArr[0][0] = 0 Then Return SetError(1, 0, 0)
	Return SetError(0, 0, $avArr[1][0])
EndFunc   ;==>_AcrobatReader_WinListChildren
#EndRegion ; AcrobatReader.au3 - CORE Functions

#Region ; AcrobatReader.au3 - INTERNAL Functions

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __AcrobatReader_AppendChildren
; Description ...: Recursively appends child HWNDs and titles to an array.
; Syntax ........: __AcrobatReader_AppendChildren($hWnd, ByRef $avArr)
; Parameters ....: $hWnd                 - Parent window handle whose descendants are appended.
;                  $avArr                - Output array of child HWNDs and titles, passed ByRef.
; Return values .: None; modifies avArr ByRef.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......:
; Related .......: _AcrobatReader_WinListChildren
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __AcrobatReader_AppendChildren($hWnd, ByRef $avArr)
	Local $hChild = _WinAPI_GetWindow($hWnd, $GW_CHILD)
	While $hChild
		$avArr[0][0] += 1
		Local $i = $avArr[0][0]
		ReDim $avArr[$i + 1][2]
		$avArr[$i][0] = $hChild
		$avArr[$i][1] = _WinAPI_GetWindowText($hChild)
		__AcrobatReader_AppendChildren($hChild, $avArr)
		$hChild = _WinAPI_GetWindow($hChild, $GW_HWNDNEXT)
	WEnd
EndFunc   ;==>__AcrobatReader_AppendChildren

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __AcrobatReader_COM_ErrorFunction
; Description ...: Records the AutoIt line of a COM error without showing a dialog.
; Syntax ........: __AcrobatReader_COM_ErrorFunction($oError)
; Parameters ....: $oError               - AutoIt COM error object.
; Return values .: SetError with the COM error number.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: Registered through ObjEvent as the COM error callback.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __AcrobatReader_COM_ErrorFunction($oError)
	$__g_sAcrobatReader_Line_Watcher = $oError.scriptline
	; No modal dialog in a library. The caller receives @error/@extended.
	Return SetError($oError.number)
EndFunc   ;==>__AcrobatReader_COM_ErrorFunction

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __AcrobatReader_Configure
; Description ...: Applies page, layout, toolbar, scrollbar and fit settings to Acrobat COM.
; Syntax ........: __AcrobatReader_Configure($oPDF)
; Parameters ....: $oPDF                 - Acrobat COM object reference.
; Return values .: On Success - 1 with @error = 0.
;                  On Failure - 0 with @error = 8 when PDF control configuration fails.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: The object argument is a COM reference; ByRef is unnecessary because it is not reassigned.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __AcrobatReader_Configure($oPDF)
	Local $oLocal_COM_Error_Handler = ObjEvent('AutoIt.Error', __AcrobatReader_COM_ErrorFunction)
	#forceref $oLocal_COM_Error_Handler
	$oPDF.GotoFirstPage()
	If @error Then Return SetError(8, @error, 0)
	$oPDF.SetLayoutMode('SinglePage')
	If @error Then Return SetError(8, @error, 0)
	$oPDF.SetPageMode('none')
	If @error Then Return SetError(8, @error, 0)
	$oPDF.SetShowToolbar(False)
	If @error Then Return SetError(8, @error, 0)
	$oPDF.SetShowScrollbars(True)
	If @error Then Return SetError(8, @error, 0)
	$oPDF.SetView('FitBH')
	If @error Then Return SetError(8, @error, 0)
	$oPDF.SetViewScroll('FitBH', 1)
	If @error Then Return SetError(8, @error, 0)
	Return SetError(0, 0, 1)
EndFunc   ;==>__AcrobatReader_Configure

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __AcrobatReader_CreateControl
; Description ...: Creates an Acrobat or Shell COM control in the context GUI.
; Syntax ........: __AcrobatReader_CreateControl(ByRef $m)
; Parameters ....: $m                    - Preview context passed ByRef.
; Return values .: On Success - 1 with @error = 0.
;                  On Failure - 0 and sets @error to one of the following:
;                    3 = Caller GUI could not be selected.
;                    4 = COM control creation failed.
;                    5 = ActiveX host is invalid or could not be created.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: Restores the previously selected GUI and records the direct host HWND.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __AcrobatReader_CreateControl(ByRef $m)
	If $m.ctrl Then
		If _WinAPI_IsWindow($m.host) And _WinAPI_GetParent($m.host) = $m.parent Then Return SetError(0, 0, 1)
		Return SetError(5, 0, 0)
	EndIf
	Local $oLocal_COM_Error_Handler = ObjEvent('AutoIt.Error', __AcrobatReader_COM_ErrorFunction)
	#forceref $oLocal_COM_Error_Handler
	Local $oControl = Null
	If $m.shellMode Then
		$oControl = ObjCreate('Shell.Explorer.2')
	Else
		$oControl = ObjCreate('AcroPDF.PDF.1')
	EndIf
	Local $iError = @error
	If Not IsObj($oControl) Then Return SetError(4, $iError, 0)
	Local $hPrevious = GUISwitch($m.parent)
	If @error Then Return SetError(3, 0, 0)
	; GUICtrlGetHandle is not reliable for GUICtrlCreateObj: find the new direct host.
	Local $mChildren[], $hChild = _WinAPI_GetWindow($m.parent, $GW_CHILD)
	While $hChild
		$mChildren[String($hChild)] = True
		$hChild = _WinAPI_GetWindow($hChild, $GW_HWNDNEXT)
	WEnd
	$m.ctrl = GUICtrlCreateObj($oControl, $m.left, $m.top, $m.width, $m.height)
	If $m.ctrl Then GUICtrlSetResizing($m.ctrl, $GUI_DOCKALL)
	$hChild = _WinAPI_GetWindow($m.parent, $GW_CHILD)
	While $hChild
		If Not MapExists($mChildren, String($hChild)) Then
			$m.host = $hChild
			ExitLoop
		EndIf
		$hChild = _WinAPI_GetWindow($hChild, $GW_HWNDNEXT)
	WEnd
	If Not $m.ctrl Or Not $m.host Then
		If $m.ctrl Then GUICtrlDelete($m.ctrl)
		$m.ctrl = 0
		If IsHWnd($hPrevious) Then GUISwitch($hPrevious)
		Return SetError(5, 0, 0)
	EndIf
	If IsHWnd($hPrevious) Then GUISwitch($hPrevious)
	If $m.shellMode Then
		$m.shell = $oControl
	Else
		$m.pdf = $oControl
	EndIf
	Return SetError(0, 0, 1)
EndFunc   ;==>__AcrobatReader_CreateControl

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __AcrobatReader_CurrentGUI
; Description ...: Finds the currently selected GUI in this process.
; Syntax ........: __AcrobatReader_CurrentGUI()
; Parameters ....: None
; Return values .: Previous GUI HWND, or 0 if none can be found.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: Used to restore GUI selection after SimpleViewer closes.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __AcrobatReader_CurrentGUI()
	Local $aWindows = WinList()
	For $i = 1 To $aWindows[0][0]
		If WinGetProcess($aWindows[$i][1]) <> @AutoItPID Then ContinueLoop
		Local $hPrevious = GUISwitch($aWindows[$i][1])
		If @error Then ContinueLoop
		If IsHWnd($hPrevious) Then GUISwitch($hPrevious)
		Return $hPrevious
	Next
	Return 0
EndFunc   ;==>__AcrobatReader_CurrentGUI

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __AcrobatReader_Fail
; Description ...: Stores an error state and releases the failed preview control.
; Syntax ........: __AcrobatReader_Fail(ByRef $m, $iError[, $iExtended = 0])
; Parameters ....: $m                    - Preview context passed ByRef.
;                  $iError               - Error code to store.
;                  $iExtended            - Extended error value.
; Return values .: 0 with the supplied @error and @extended.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: Retains the requested path for diagnostics.
; Related .......: _AcrobatReader_Clear
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __AcrobatReader_Fail(ByRef $m, $iError, $iExtended = 0)
	Local $sFile = $m.file
	_AcrobatReader_Clear($m)
	$m.file = $sFile
	$m.state = $ACROBATREADER_ERROR
	$m.error = $iError
	$m.extended = $iExtended
	Return SetError($iError, $iExtended, 0)
EndFunc   ;==>__AcrobatReader_Fail

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __AcrobatReader_PollFail
; Description ...: Converts a Shell polling failure into the ERROR state.
; Syntax ........: __AcrobatReader_PollFail(ByRef $m, $iError, $iExtended)
; Parameters ....: $m                    - Preview context passed ByRef.
;                  $iError               - Error code to store.
;                  $iExtended            - Extended error value.
; Return values .: ACROBATREADER_ERROR with supplied @error and @extended.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: Releases the failed preview through __AcrobatReader_Fail.
; Related .......: __AcrobatReader_Fail
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __AcrobatReader_PollFail(ByRef $m, $iError, $iExtended)
	__AcrobatReader_Fail($m, $iError, $iExtended)
	Return SetError($iError, $iExtended, $ACROBATREADER_ERROR)
EndFunc   ;==>__AcrobatReader_PollFail

; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __AcrobatReader_RectValid
; Description ...: Checks numeric, nonnegative position and positive size.
; Syntax ........: __AcrobatReader_RectValid($x, $y, $w, $h)
; Parameters ....: $x                    - Client-area left position.
;                  $y                    - Client-area top position.
;                  $w                    - Control width.
;                  $h                    - Control height.
; Return values .: Boolean result.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __AcrobatReader_RectValid($x, $y, $w, $h)
	Return IsNumber($x) And IsNumber($y) And IsNumber($w) And IsNumber($h) And $x >= 0 And $y >= 0 And $w > 0 And $h > 0
EndFunc   ;==>__AcrobatReader_RectValid
; #INTERNAL_USE_ONLY# ===========================================================================================================
; Name ..........: __AcrobatReader_Valid
; Description ...: Checks the preview-context marker.
; Syntax ........: __AcrobatReader_Valid(ByRef $m)
; Parameters ....: $m                    - Preview context passed ByRef.
; Return values .: True for a recognized context; otherwise False.
; Author ........: mLipok
; Modified ......: Codex
; Remarks .......: Does not validate the parent window lifetime.
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __AcrobatReader_Valid(ByRef $m)
	If Not IsMap($m) Then Return False
	If Not MapExists($m, 'kind') Then Return False
	Return $m.kind == 'AcrobatReader/2'
EndFunc   ;==>__AcrobatReader_Valid
#EndRegion ; AcrobatReader.au3 - INTERNAL Functions
