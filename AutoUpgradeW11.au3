#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\sbg.ico
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Description=Auto Upgrade W11
#AutoIt3Wrapper_Res_ProductName=Auto Upgrade W11
#AutoIt3Wrapper_Res_CompanyName=Société Biblique de Genève
#AutoIt3Wrapper_Res_LegalCopyright=2022 Société Biblique de Genève
#AutoIt3Wrapper_Run_Tidy=y
#Tidy_Parameters=/reel
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/mo
#AutoIt3Wrapper_Res_ProductVersion=1.0.1.2
#AutoIt3Wrapper_Res_Fileversion=1.0.1.2
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.16.0
	Author:         Cramaboule
	Date:		December 2022

	Script Function: Auto Upgrade to W11

	Source: https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-setup-command-line-options?view=windows-11

	Bug: 	Not known

	To do:
	V1.0.1.2	10.11.2023:
				Added an ini file to be able to change the ISO verion
	V1.0.1.1	14.02.2023:
				Fixed: Mounting ISO with spaces in path in now fixed.
				Changed: Alwayas unzipp and always install TPM with the 'install' argument.
				Fixed: Small bugs
	V1.0.1.0	17.01.2023:
				Changed: Get drive letter by loop!
	V1.0.0.1	29.12.2022:
				Changed: Get drive letter from powershell
				Changed: Check if zip is already expended
				Changed: Check if iso file is mounted
				Changed: Display message
	V1.0.0.0	28.12.2022:
				Inital relase

#ce ----------------------------------------------------------------------------
#RequireAdmin

#include <Array.au3>
#include <AutoItConstants.au3>
#include <MsgBoxConstants.au3>

Global $Title = 'Auto Upgrade W11'
Global $font = 'Segoe UI Light', $sFinalMessage
Global $sFileIni = @ScriptDir & '\version.ini'
$sIsoFile = IniRead($sFileIni, 'Version', 'iso', 'error')
If $sIsoFile = 'error' Then
	MsgBox(16, 'Error', 'There is no version.ini file or it is in the wrong format' & @CRLF & 'The program will exit')
	Exit
EndIf
$sIsoFile = @ScriptDir & '\' & $sIsoFile
SplashTextOn($Title, '', 300, 400, -1, -1, $DLG_TEXTLEFT, $font, 14, 400)
_Splash('Checking free space')
$iFreeSpace = DriveSpaceFree(@HomeDrive & "\") ; usualy C:\
If Round(Number($iFreeSpace) / 1024, 2) < 15 Then
	If (MsgBox($MB_ICONERROR + $MB_YESNO, 'No free space', 'You must have at least 15 Go free on your hard disk.' & @CRLF & 'You have: ' & Round(Number($iFreeSpace) / 1024, 2) & ' Go' & @CRLF & @CRLF & 'Would you like to continue ?') = $IDNO) Then Exit
EndIf
_Splash('Done')

_Splash('Unzipping zip file')
RunWait(@ComSpec & ' /c ' & 'powershell -command "Expand-Archive -Path W11bypassTPM.zip -Force"')
_Splash('Done')

_Splash('Skipping TPM')
RunWait(@ComSpec & ' /c ' & 'W11bypassTPM\MediaCreationTool.bat-main\bypass11\Skip_TPM_Check_on_Dynamic_Update.cmd install')
_Splash('Done')

_Splash('Mounting ISO')
If Not (_GetDriveLetter()) Then
	RunWait(@ComSpec & ' /c ' & 'powershell -command "Mount-DiskImage -ImagePath \"' & $sIsoFile & '\""')
EndIf
$sDrive = _GetDriveLetter()
_Splash('Done')

If $sDrive Then
	_Splash('Running setup.exe')
	Run(@ComSpec & ' /c ' & 'start ' & $sDrive & ':\setup.exe /auto upgrade /dynamicupdate disable /eula accept')
	Sleep(10000) ; 10 secondes
	Exit
Else
	_Splash('Error: No Setup found')
	MsgBox($MB_TOPMOST + $MB_ICONERROR, 'Error', 'No "Setup.exe" found' & @CRLF & 'Error: ' & $sDrive)
	Exit
EndIf

Func _GetDriveLetter()
	Local $sOutput = ''
	For $i = 1 To 26
		; A = 65
		$Letter = Chr($i + 64)
		If FileExists($Letter & ':\sources\install.wim') Then
			Return $Letter
		EndIf
	Next
	Return False
EndFunc   ;==>_GetDriveLetter

Func _Splash($message)
	$sFinalMessage = $sFinalMessage & $message & @CRLF
	ControlSetText($Title, "", "Static1", $sFinalMessage)
EndFunc   ;==>_Splash
