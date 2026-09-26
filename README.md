# AcrobatReader.au3 UDF

Embed and manage an Adobe PDF preview in an AutoIt GUI.

The caller creates and owns the GUI. `_AcrobatReader_Create()` attaches a lazy preview context; `_AcrobatReader_Open()` creates the embedded control when a PDF is first opened. `_AcrobatReader_Clear()` and `_AcrobatReader_Destroy()` never delete the caller's GUI. `_AcrobatReader_SimpleViewer()` is available when a ready-made, blocking viewer window is preferable.

## Requirements

- Windows and AutoIt 3.3.18.0 (the version used for static validation).
- For direct mode, an installed Adobe Acrobat or Reader installation exposing the `AcroPDF.PDF.1` ActiveX control.
- The included examples select 32-bit AutoIt with `#AutoIt3Wrapper_UseX64=N`.

The UDF depends only on standard AutoIt includes. Shell mode (`$bShell = True`) uses `Shell.Explorer.2` and the local PDF integration; its availability depends on the machine's configuration.

## Files

| File | Purpose |
| --- | --- |
| `AcrobatReader.au3` | The UDF. |
| `Examples/AcrobatReader_Example_1_SimpleViewer.au3` | Select a PDF, then open `_AcrobatReader_SimpleViewer()`. |
| `Examples/AcrobatReader_Example_2_UserGUI.au3` | Create an application-owned GUI; choose a PDF with its **Open PDF** button. |
| `Examples/AcrobatReader_Example_3_Folder_SlideShow.au3` | Show PDFs from a selected folder in an application-owned GUI. |

Run an example in place so its relative `#include "..\AcrobatReader.au3"` resolves. Each example asks you to select a PDF or folder; no PDF sample is required.

## Basic lifecycle

1. Create your GUI with `GUICreate()`.
2. Call `_AcrobatReader_Create($hGUI, ...)` to obtain a context.
3. Call `_AcrobatReader_Open($mContext, $sPDF)` and check `@error`.
4. In Shell mode, call `_AcrobatReader_Poll($mContext)` from the GUI loop; call it in direct mode too if you want a common state-handling path.
5. Resize the preview with `_AcrobatReader_Resize()` when your GUI changes size.
6. Call `_AcrobatReader_Clear()` to remove the current preview or `_AcrobatReader_Destroy()` when finished, then delete your GUI yourself.

Pass a live context `ByRef` to the lifecycle functions. `$ACROBATREADER_ACCEPTED` means the COM control accepted the commands; it does **not** prove that the PDF was rendered or validated. Check each function's `Return values` header for its `@error` codes.

`_AcrobatReader_WinListChildren()` lists all descendants of a supplied window. It returns the first child HWND and fills an output array with HWND/title pairs; the first child is not guaranteed to be the PDF preview host.

## Validation

The UDF and examples are checked with Tidy and Au3Check using `-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7`. Static checks do not verify Acrobat installation or visual PDF rendering on another machine.

## License

MIT. See [LICENSE](LICENSE).
