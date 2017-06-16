#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


/*
brutus_skywalker

Media Remote Control POWERED BY AHKhttp SERVER	[Refactored,Refined,Overhauled & Updated]
https://autohotkey.com/boards/viewtopic.php?f=6&t=4890
https://github.com/Skiouros/AHKhttp
https://github.com/jleb/AHKsock

Look at the about section in the browser interface for a list of features...

 KNOWN ISSUES:
Icon buttons wont load so,text buttons were used. To attempt to use Icon button simply remove text from button & use sth like this '<button> <input type="image" src ="buttonIcon.png" /> </button>'
Fwd/Rwd buttons are context sensitive to vlc & kmplayer at the moment,feel free to add the context sensitive keys for any preferred media player.
Had to resort to reloading the page every time a button is pressed,because i was too lazy to figure out how to close the connection with out the browser loading a blank page.
Reloading a page with browser reload,resends the last sent instruction,handy when fast forwarding/rewinding,though it is so,because of issue above.
The MASSIVE BUTTON FONT SIZE is such that when viewed on a mobile browser,no zooming is required...
VLC has a problem playing playing files INSIDE playlists with 'Accent' characters,both bookmarks/search&play functionality create playlists as of now,so that might be problematic for some.
	>Exploring Using Folders with shortcuts to files,instead of playlists,bit messy,but makes VLC work with out problems.
*/



#Persistent
#SingleInstance, force
#NoTrayIcon

SetBatchLines, -1

Msg("brutus_skywalker[ameXumm]", " MediaRemoteControl:AHKhttp Server ")

;VLC init to run folders or files using vlc 
IfExist, C:\Program Files\VideoLAN\VLC\vlc.exe
	vlc = "C:\Program Files\VideoLAN\VLC\vlc.exe" --video-on-top --interact --qt-minimal-view
IfExist, C:\C:\Program Files (x86)\VideoLAN\VLC\vlc.exe
	vlc = "C:\C:\Program Files (x86)\VideoLAN\VLC\vlc.exe" --video-on-top --interact --qt-minimal-view

configFileName=MediaRemoteControl
IfNotExist, %configFileName%.ini
{
;write default server config values
wINI("serverConfig","buttonSize", "40px")
; wINI("serverConfig","buttonSize", "33px")
wINI("serverConfig","serverPort", "8000")
wINI("serverConfig","textFontSize", "18px")
wINI("serverConfig","pagePadding", "50px")
; wINI("serverConfig","pagePadding", "20px")
Loop, 5	;write a template file for the supported number of folders
	{
	wINI("MediaFolders", "folder" . A_Index . "name", "folder button name goes here")
	wINI("MediaFolders", "folder" . A_Index . "folder", "folder path goes here")
	}
wINI("controlConfig","soundIncDecValue", 5)	;sound increment/decrement value
wINI("controlConfig","monitorButtonForceActive", 0)	;button disabled by default but,if no config entry is defined button is activated.
}
Else
{
Loop, 5	;read all defined folders,assign all defined folders to buttons except the template config entries.
	{
	f%A_Index%n := rINI("MediaFolders", "folder" . A_Index . "name")
	f%A_Index%f := rINI("MediaFolders", "folder" . A_Index . "folder")
	if (f%A_Index%n != "folder button name goes here" AND f%A_Index%f != "folder path goes here")
		{
		folder%A_Index%name := rINI("MediaFolders", "folder" . A_Index . "name")
		folder%A_Index%folder := rINI("MediaFolders", "folder" . A_Index . "folder")
		}
	}
}

buttonSize:=rINI("serverConfig","buttonSize")
serverPort:=rINI("serverConfig","serverPort")
textFontSize:=rINI("serverConfig","textFontSize")
pagePadding:=rINI("serverConfig","pagePadding")

mOn:=1
scheduleDelay:=0	;time before a standby/hibernate command is executed
SHT:=scheduleDelay//60000	;standby/hibernate timer abstracted in minutes

standbyButtonColor=red	;initilise button,when inactive it is red,when activated with a timer & it's scheduled it is green.
hibernateButtonColor=red	;initilise button,when inactive it is red,when activated with a timer & it's scheduled it is green.

SetTimer, indexMediaFolders, 2500

indexInit:
;to update based on config value
soundIncDecValue:=rINI("controlConfig","soundIncDecValue", 5)
monitorButtonForceActive:=rINI("controlConfig","monitorButtonForceActive", 1)

; HtmlButtonGenerate(buttonName,buttonImage, buttonPath, buttonColor, buttonFontSize, buttonWidth, buttonHeight, paragraphButton, first_lastButtonInParagraph, registerPathInServer)
if (rINI("controlConfig","demoFoldersActivation", 0) AND !demoFolderButtons)	;generate demo folder buttons
	{
	demoFolderButtons.=
	demoFolderButtons.=HtmlButtonGenerate("Meg Myers(DemoFolder)", , "/megMyers", , systemControlButtonsSize, , , , 1)
	demoFolderButtons.=HtmlButtonGenerate("Indila(DemoFolder)", , "/indila", , systemControlButtonsSize, ,  , , 2)
	}
if !rINI("controlConfig","demoFoldersActivation", 0)
	demoFolderButtons:=""

if !primaryControlButtons
	{
	primaryControlButtonsSize:=buttonSize
	primaryControlButtons.="`r <p> `r"
	primaryControlButtons.=HtmlButtonGenerate("Previous", , "/previous", , primaryControlButtonsSize)
	primaryControlButtons.=HtmlButtonGenerate("Rwd", , "/rwd", , primaryControlButtonsSize)
	primaryControlButtons.=HtmlButtonGenerate("Play/Pause", , "/pause_play", , primaryControlButtonsSize)
	primaryControlButtons.=HtmlButtonGenerate("Stop", , "/stop", , primaryControlButtonsSize)
	primaryControlButtons.=HtmlButtonGenerate("Fwd", , "/fwd", , primaryControlButtonsSize)
	primaryControlButtons.=HtmlButtonGenerate("Next", , "/next", , primaryControlButtonsSize)

	primaryControlButtons.="`r </p> `r <p> `r"	;separate the volume and playback controls

	primaryControlButtons.=HtmlButtonGenerate("Vol[+]", , "/vp", , primaryControlButtonsSize)
	primaryControlButtons.=HtmlButtonGenerate("Vol[-]", , "/vm", , primaryControlButtonsSize)
	primaryControlButtons.=HtmlButtonGenerate("Un/Mute", , "/u_m", , primaryControlButtonsSize)
	primaryControlButtons.=HtmlButtonGenerate("20`%", , "/vLow", , primaryControlButtonsSize)
	primaryControlButtons.=HtmlButtonGenerate("50`%", , "/vMed", , primaryControlButtonsSize)
	primaryControlButtons.=HtmlButtonGenerate("80`%", , "/vHigh", , primaryControlButtonsSize)
	primaryControlButtons.=HtmlButtonGenerate("100`%", , "/vMax", , primaryControlButtonsSize)
	primaryControlButtons.="`r </p> `r"
	}

systemControlButtons:=""	;reset to rebuild buttons with refreshed button values
if !systemControlButtons
	{
	systemControlButtonsSize:=buttonSize
	systemControlButtons.="`r <p> `r"
	systemControlButtons.=HtmlButtonGenerate("Reset Timer", , "/resetTimer", , systemControlButtonsSize)
	systemControlButtons.=HtmlButtonGenerate("Timer[+]", , "/TimerInc", , systemControlButtonsSize)
	systemControlButtons.=HtmlButtonGenerate("Timer[-]", , "/TimerDec", , systemControlButtonsSize)
	systemControlButtons.=HtmlButtonGenerate("[ " . SHT . "min ]", , "/", , systemControlButtonsSize)

	systemControlButtons.="`r </p> `r <p> `r"	;separate the timer & 'system' controls

	systemControlButtons.=HtmlButtonGenerate("StandBy", , "/standby", standbyButtonColor, systemControlButtonsSize)
	systemControlButtons.=HtmlButtonGenerate("Hibernate", , "/hibernate", hibernateButtonColor, systemControlButtonsSize)
	systemControlButtons.=HtmlButtonGenerate("Monitor On/Off", , "/monitorOnOff", , systemControlButtonsSize)
	systemControlButtons.=HtmlButtonGenerate("RELOAD", , "/serverReload", , systemControlButtonsSize)
	systemControlButtons.="`r </p> `r"

	systemControlButtons.=HtmlButtonGenerate("[Refresh/Reset page to Index]", , "/", , systemControlButtonsSize, "100`%", "100`%", 1)	
	}

SysGet, MonitorCountVar, MonitorCount
if (MonitorCountVar > 1 OR monitorButtonForceActive)	; Activate button only if more than one monitor is detected. DOESN'T WORK WITH HDMI MONITORS,so use config to manually enable buttons.
	{
	monitorSelectButtons:=""
	monitorSelectButtons.=HtmlButtonGenerate("Monitor[1]", , "/monitor1", , systemControlButtonsSize, "45`%", "100`%", , 1)
	monitorSelectButtons.=HtmlButtonGenerate("Monitor[2]", , "/monitor2", , systemControlButtonsSize, "45`%", "100`%", , 2)
	}
else	;if only one monitor is connected or secondary monitor was disconnected, remove button
	monitorSelectButtons:=""

if !vlcBookmarkButtons
	{
	vlcBookmarkButtons.=HtmlButtonGenerate("Bookmark[+]", , "/vlcBookmark", , systemControlButtonsSize, , , , 1)
	vlcBookmarkButtons.=HtmlButtonGenerate("PlayBookmarked", , "/vlcPlayBookmarked", , systemControlButtonsSize)
	vlcBookmarkButtons.=HtmlButtonGenerate("Bookmark[-]", , "/vlcDeleteBookmarked", , systemControlButtonsSize, , , , 2)
	}

if !aboutButton
	aboutButton.=HtmlButtonGenerate("About", , "/about", , , , , 1)
	
	
Index_Html =
(
<!doctype html>
<html>
<head>
<title> MediaRemoteControl </title>
<style>
p {
  font-family: Arial,Helvetica,sans-serif;
  font-size: %textFontSize%;
}

pre {
  font-family: Arial,Helvetica,sans-serif;
  font-size: %textFontSize%;
}

center {
  font-family: Arial,Helvetica,sans-serif;
  font-size: %textFontSize%;
}

button {
  font-family: Arial,Helvetica,sans-serif;
  font-size: %buttonSize%;
}

h1 {
	padding: %pagePadding%; width: auto; font-family: Sans-Serif; font-size: 22pt;
}

body {
	background-color : black ;
	color : yellow ;
	padding: %pagePadding%; width: auto; font-family: Sans-Serif; font-size: 10pt;
}
</style>
</head>
<body>

<h1>
%NowPlaying%	%master_volume_now%
</h1>

%primaryControlButtons%

<p> &nbsp; </p>

<pre> &Tab;&Tab;&Tab;  </pre>
<center>	Timer+/- adds/subtracts 30min delay to StandBy/Hibernate	</center> 


%systemControlButtons%

<p> &nbsp; </p>

<center>	Extended VLC Controls	</center> 

<p> 
<a href="/vlcAutoSkip"> <button style="width:100`%; height: 100`%; color:OrangeRed"> VLC - AlwaysAutoSkipCurrentTrack </button> </a>
</p> 
<p> 
<a href="/QWERTY"> <button style="width:100`%; height: 100`%; color:black"> Search and Play StringMatched Files/Paths </button> </a>
</p> 

%vlcBookmarkButtons%

<p> &nbsp; </p>


<p> 
<a href="/vlcFullScreen"> <button> VLC/KMPlayer FullScreen </button> </a>
<a href="/vlcContinue"> <button> VLC - Continue </button> </a>
</p>
<p> 
<a href="/music"> <button> Music </button> </a> 
<a href="/videos"> <button> Videos </button> </a>
<a href="/vlcOff"> <button> VLC - OFF  </button> </a>
<a href="/vlcFocus"> <button> VLC - BringToFront </button> </a>
</p>

%demoFolderButtons%

<p>
<a href="/folder1"> <button> %folder1name% </button> </a>
<a href="/folder2"> <button> %folder2name% </button> </a>
<a href="/folder3"> <button> %folder3name% </button> </a>
<a href="/folder4"> <button> %folder4name% </button> </a>
<a href="/folder5"> <button> %folder5name% </button> </a>
</p>

<h1>
%NowPlaying%
</h1>

<p>
%monitorSelectButtons%
<a href="/config"> <button style="width:100`%; height: 100`%; color:blue"> config </button> </a> 
<center>	%aboutButton%	</center> 
</p>


</body>
</html>
)
if indexInit_activated
	Return	;to return only after first initilisation,i.e from a 'Gosub'
indexInit_activated++



IfNotExist, mime.types
{
FileAppend,
(
text/html                             html htm shtml
text/css                              css
text/xml                              xml
image/gif                             gif
image/jpeg                            jpeg jpg
application/x-javascript              js
application/atom+xml                  atom
application/rss+xml                   rss

text/mathml                           mml
text/plain                            txt
text/vnd.sun.j2me.app-descriptor      jad
text/vnd.wap.wml                      wml
text/x-component                      htc

image/png                             png
image/tiff                            tif tiff
image/vnd.wap.wbmp                    wbmp
image/x-icon                          ico
image/x-jng                           jng
image/x-ms-bmp                        bmp
image/svg+xml                         svg svgz
image/webp                            webp

application/java-archive              jar war ear
application/mac-binhex40              hqx
application/msword                    doc
application/pdf                       pdf
application/postscript                ps eps ai
application/rtf                       rtf
application/vnd.ms-excel              xls
application/vnd.ms-powerpoint         ppt
application/vnd.wap.wmlc              wmlc
application/vnd.google-earth.kml+xml  kml
application/vnd.google-earth.kmz      kmz
application/x-7z-compressed           7z
application/x-cocoa                   cco
application/x-java-archive-diff       jardiff
application/x-java-jnlp-file          jnlp
application/x-makeself                run
application/x-perl                    pl pm
application/x-pilot                   prc pdb
application/x-rar-compressed          rar
application/x-redhat-package-manager  rpm
application/x-sea                     sea
application/x-shockwave-flash         swf
application/x-stuffit                 sit
application/x-tcl                     tcl tk
application/x-x509-ca-cert            der pem crt
application/x-xpinstall               xpi
application/xhtml+xml                 xhtml
application/zip                       zip

application/octet-stream              bin exe dll
application/octet-stream              deb
application/octet-stream              dmg
application/octet-stream              eot
application/octet-stream              iso img
application/octet-stream              msi msp msm

audio/midi                            mid midi kar
audio/mpeg                            mp3
audio/ogg                             ogg
audio/x-m4a                           m4a
audio/x-realaudio                     ra

video/3gpp                            3gpp 3gp
video/mp4                             mp4
video/mpeg                            mpeg mpg
video/quicktime                       mov
video/webm                            webm
video/x-flv                           flv
video/x-m4v                           m4v
video/x-mng                           mng
video/x-ms-asf                        asx asf
video/x-ms-wmv                        wmv
video/x-msvideo                       avi
), mime.types
}




paths := {}
paths["/"] := Func("Index")
paths["/logo"] := Func("Logo")
paths["404"] := Func("NotFound")

;the name of the paths defined here must be the same as the name of the functions they point to.
pathsList=previous,rwd,pause_play,stop,fwd,next,vp,vm,u_m,vMax,vHigh,vMed,vLow,TimerInc,TimerDec,resetTimer,standby,hibernate,monitorOnOff,serverReload,vlcOff,vlcFocus,vlcContinue,vlcFullScreen,music,videos,indila,megMyers,folder1,folder2,folder3,folder4,folder5,vlcAutoSkip,config,QWERTY,monitor1,monitor2,vlcBookmark,vlcDeleteBookmarked,vlcPlayBookmarked,about
Loop, Parse, pathsList, `,	;load the path for all buttons
{
loopPath=/%A_LoopField%
paths[loopPath] := Func(A_LoopField)
}


server := new HttpServer()
server.LoadMimes(A_ScriptDir . "/mime.types")
server.SetPaths(paths)
server.Serve(serverPort)
return

Logo(ByRef req, ByRef res, ByRef server) {
    server.ServeFile(res, A_ScriptDir . "/logo.png")
    res.status := 200
}

Index(ByRef req, ByRef res) {
Global
;Get Title from Active vlc/kmplayer window
indexStart:
SetTimer, autoSkipCheck, 2000	;check if NowPlaying is an AUTOSKIP flagged track,for when the media player cycles finished media.
IfWinActive, ahk_exe vlc.exe
	{
	Sleep, 500	;To make sure returned title is from the current 'track' and not the 'previous' one.
	WinGetActiveTitle, NowPlaying
	StringReplace, NowPlaying, NowPlaying, VLC media player, , All
	StringTrimRight, NowPlaying, NowPlaying, 3
	

	Loop
		{
		if boolINI("AUTOSKIP", "flagged" . A_Index)	;loop through all existing AUTOSKIP entries	- boolINI returns true if specified INI entry exists & false if it doesn't
			{
			this_flaggedEntry := rINI("AUTOSKIP", "flagged" . A_Index)
			IfInString, NowPlaying, %this_flaggedEntry%
				{
				if (indexCaller = "Next")	;where current function was called from so that if previous was the trigger then it would skip the file backwards instead of forwards as it would for next.
					Send {Media_Next}	;  skip to the next track
				if (indexCaller = "Previous")	;where current function was called from so that if previous was the trigger then it would skip the file backwards instead of forwards as it would for next.
					Send {Media_Prev}	;  skip to the previous track
				else	;track finished and reached AUTOSKIP track
					Send {Media_Next}	;  skip to the next track					
				indexCaller:=""
				Goto indexStart	;to check if succeding track is not flagged & exit if so
				}
			}
		else Break	;non existent ini entry
		}
	}
Else IfWinActive, ahk_exe KMPlayer.exe
		{
		Sleep, 1000	;To make sure returned title is from the current 'track' and not the 'previous' one.
		WinGetActiveTitle, NowPlaying
		}
Else if NowPlaying ;if no active media player is detected but NowPlaying still contains a value,reset it.
	NowPlaying:=""

	Gosub, indexInit	;to refresh page
    res.SetBodyText(Index_Html)
    res.status := 200
}



autoSkipCheck:
IfWinActive, ahk_exe vlc.exe
	{
	WinGetActiveTitle, NowPlaying
	StringReplace, NowPlaying, NowPlaying, VLC media player, , All
	StringTrimRight, NowPlaying, NowPlaying, 3
	Loop
		{
		if boolINI("AUTOSKIP", "flagged" . A_Index)	;loop through all existing AUTOSKIP entries	- boolINI returns true if specified INI entry exists & false if it doesn't
			{
			this_flaggedEntry := rINI("AUTOSKIP", "flagged" . A_Index)
			IfInString, NowPlaying, %this_flaggedEntry%
				{
				Send {Media_Next}	;  skip to the next track					
				Sleep, 500
				Goto autoSkipCheck	;to check if succeding track is not flagged & exit if so
				}
			}
		else Break	;non existent ini entry
		}
	}

;vlcExceptionHandler
if ( rINI("serverConfig","vlcExceptionHandler", 0) AND WinExist(ahk_exe vlc.exe) AND WinExist("Errors") )	;if suppression is activated
	{
	WinActivate, Errors
	WinClose
	}
if ( rINI("serverConfig","vlcExceptionHandler", 0) AND WinExist(ahk_exe vlc.exe) AND WinExist("Broken or missing AVI Index") )	;if suppression is activated
	{
	WinSet, AlwaysOnTop, On, Broken or missing AVI Index
	WinActivate, Broken or missing AVI Index
	CoordMode, Mouse, Client
	Click, 365, 115	;click 'play as is'
	Sleep, 1000
	IfWinExist, Broken or missing AVI Index	;if window is still active just close it.
		WinClose
	}

Return

indexMediaFolders:
SetTImer, indexMediaFolders, off
if (!mediaFoldersIndex OR !indexingComplete)
	vlcIndexMediaFolders()
Return



resetTimer(ByRef req, ByRef res){
Global
scheduleDelay := 0
SHT:=scheduleDelay//60000	;standby/hibernate timer abstracted in minutes
SetTimer, scheduledStandby, off
SetTimer, scheduledHibernate, off
hibernateButtonColor=red
standbyButtonColor=red
Msg(, "Timer Reset,all scheduled StandBy/Hibernate timers also disabled.")
	Index(req, res)
}

TimerInc(ByRef req, ByRef res){
Global
scheduleDelay+=1800000	;add 30 minutes
SHT:=scheduleDelay//60000	;standby/hibernate timer abstracted in minutes
Msg(, "StandBy/Hibernate Timer Added 30min, NOW: " . SHT . "min")
	Index(req, res)
}

TimerDec(ByRef req, ByRef res){
Global
if !scheduleDelay	;if already zero,don't go down to negative numbers!
	{
	Index(req, res)
	Return
	}
scheduleDelay-=1800000	;subtract 30 minutes
SHT:=scheduleDelay//60000	;standby/hibernate timer abstracted in minutes
Msg(, "StandBy/Hibernate Timer Decreased 30min, NOW: " . SHT . "min")
	Index(req, res)
}


standby(ByRef req, ByRef res){
Global
if scheduleDelay
	{
	hibernateButtonColor=red
	standbyButtonColor=green
	SetTimer, scheduledHibernate, off
	SetTimer, scheduledStandby, %scheduleDelay%
	Msg(, "StandBy Scheduled after, " . SHT . "min")
	Index(req, res)
	Return
	}
else
	Index(req, res)
; Call the Windows API function "SetSuspendState" to have the system suspend or hibernate.
; Parameter #1: Pass 1 instead of 0 to hibernate rather than suspend.
; Parameter #2: Pass 1 instead of 0 to suspend immediately rather than asking each application for permission.
; Parameter #3: Pass 1 instead of 0 to disable all wake events.
DllCall("PowrProf\SetSuspendState", "int", 0, "int", 0, "int", 0)
}

hibernate(ByRef req, ByRef res){
Global
if scheduleDelay
	{
	hibernateButtonColor=green
	standbyButtonColor=red
	SetTimer, scheduledStandby, off
	SetTimer, scheduledHibernate, %scheduleDelay%
	Msg(, "Hibernation Scheduled after, " . SHT . "min")
	Index(req, res)
	Return
	}
else
	Index(req, res)
; Call the Windows API function "SetSuspendState" to have the system suspend or hibernate.
; Parameter #1: Pass 1 instead of 0 to hibernate rather than suspend.
; Parameter #2: Pass 1 instead of 0 to suspend immediately rather than asking each application for permission.
; Parameter #3: Pass 1 instead of 0 to disable all wake events.
DllCall("PowrProf\SetSuspendState", "int", 1, "int", 0, "int", 0)
}

monitorOnOff(ByRef req, ByRef res){
Global
	Index(req, res)
; Turn Monitor Off:
if mOn
	{
	SendMessage, 0x112, 0xF170, 2,, Program Manager  ; 0x112 is WM_SYSCOMMAND, 0xF170 is SC_MONITORPOWER.
	mOn:=0
	return
	}
; Turn Monitor On:
if !mOn
	{
	Msg(, "Monitor On")
	SendMessage, 0x112, 0xF170, -1,, Program Manager  ; 0x112 is WM_SYSCOMMAND, 0xF170 is SC_MONITORPOWER.
	mOn:=1
	return
	}
; Note for the above: Use -1 in place of 2 to turn the monitor on.
; Use 1 in place of 2 to activate the monitor's low-power mode.
}

serverReload(ByRef req, ByRef res){
	Index(req, res)
Reload
}

previous(ByRef req, ByRef res){
Global
SetTimer, autoSkipCheck, off	;so that autoSkipCheck timer doesn't send duplicate signals,which at times it for some reason does.
indexCaller=Previous
Msg(, "Previous")
	Send {Media_Prev} ;  go to the previous track
	Index(req, res)
}
rwd(ByRef req, ByRef res){
frM:=rINI("controlConfig", "fwdRwdMultiplier", 1)
Msg(, "Rewind")
IfWinActive, ahk_exe vlc.exe
	Loop, %frM%
		Send +{Left}
IfWinActive, ahk_exe KMPlayer.exe
	Loop, %frM%
		Send {Left}
	Index(req, res)
}
pause_play(ByRef req, ByRef res){
Msg(, "Play/Pause")
	Send {Media_Play_Pause} ;  play/pause
	Index(req, res)
}
stop(ByRef req, ByRef res){
	Index(req, res)
Msg(, "Stop")
	Send {Media_Stop} ;  stop
}
fwd(ByRef req, ByRef res){
frM:=rINI("controlConfig", "fwdRwdMultiplier", 1)
Msg(, "Fast Forward")
IfWinActive, ahk_exe vlc.exe
	Loop, %frM%
		Send +{Right}
IfWinActive, ahk_exe KMPlayer.exe
	Loop, %frM%
		Send {Right}
	Index(req, res)
}
next(ByRef req, ByRef res){
Global
SetTimer, autoSkipCheck, off	;so that autoSkipCheck timer doesn't send duplicate signals,which at times it for some reason does.
indexCaller=Next
Msg(, "Next")
	Send {Media_Next} ;  go to the next track
	Index(req, res)
}


fwdMultiplierPlus(ByRef req, ByRef res){
frM:=rINI("controlConfig", "fwdRwdMultiplier", 1)
frM++
wINI("controlConfig", "fwdRwdMultiplier", frM)
	config(req, res)
}
fwdMultiplierMinus(ByRef req, ByRef res){
frM:=rINI("controlConfig", "fwdRwdMultiplier", 1)
if (frM > 1)
	frM--
wINI("controlConfig", "fwdRwdMultiplier", frM)
	config(req, res)
}
fwdMultiplierReset(ByRef req, ByRef res){
wINI("controlConfig", "fwdRwdMultiplier", 1)
	config(req, res)
}


vp(ByRef req, ByRef res){
Global
	; Send {Volume_Up} ;  increase volume
	SoundSet +%soundIncDecValue%
SoundGet, masterVolumeLevel
masterVolumeLevel := Round(masterVolumeLevel)
Msg(, "Volume Up - " . masterVolumeLevel)
master_volume_now=[VOL:%masterVolumeLevel%]
	Index(req, res)
	master_volume_now:=""	;render value null,value need only exist for v+/- button press feedback
}
vm(ByRef req, ByRef res){
Global
	; Send {Volume_Down} ;  lower volume
	SoundSet -%soundIncDecValue%
SoundGet, masterVolumeLevel
masterVolumeLevel := Round(masterVolumeLevel)
Msg(, "Volume Down - " . masterVolumeLevel)
master_volume_now=[VOL:%masterVolumeLevel%]
	Index(req, res)
	master_volume_now:=""	;render value null,value need only exist for v+/- button press feedback
}
vMax(ByRef req, ByRef res){
	Index(req, res)
Msg(, "Volume : 100")
	SoundSet, 100  ; Set the master volume to 100%
}
vHigh(ByRef req, ByRef res){
	Index(req, res)
Msg(, "Volume : 80")
	SoundSet, 80  ; Set the master volume to 80%
}
vMed(ByRef req, ByRef res){
	Index(req, res)
Msg(, "Volume : 50")
	SoundSet, 50  ; Set the master volume to 50%
}
vLow(ByRef req, ByRef res){
	Index(req, res)
Msg(, "Volume : 20")
	SoundSet, 20  ; Set the master volume to 20%
}
u_m(ByRef req, ByRef res){
Global
	Index(req, res)
Msg(, "Un/Mute")
	Send {Volume_Mute} ;  mute volume toggle
}



vlcFullScreen(ByRef req, ByRef res){	;also works with kmplayer,just coz i use it.
Msg(, "FullScreen")
; IfWinExist,  ahk_exe vlc.exe
	; WinActivate
; IfWinExist, ahk_exe KMPlayer.exe
	; WinActivate
IfWinActive, ahk_exe vlc.exe
	{
	Send f
	Index(req, res)
	Return	;only activate one media player,incase both vlc & kmp are running.
	}
IfWinActive, ahk_exe KMPlayer.exe
	Send {Enter}
	Index(req, res)
}

vlcFocus(ByRef req, ByRef res){
Msg(, "Bring Media Player To Front")
IfWinExist, ahk_exe vlc.exe
	{
	WinActivate, ahk_exe vlc.exe
		Index(req, res)
		Return	;only bring to front one media player,incase both vlc & kmp are running.
	}
IfWinExist, ahk_exe KMPlayer.exe
	{
	WinActivate, ahk_exe KMPlayer.exe
		Index(req, res)
	}
Else Index(req, res)
}

vlcOff(ByRef req, ByRef res){
Msg(, "Media Player Off")
IfWinActive, ahk_exe vlc.exe
	{
	Process, Close, vlc.exe
		Index(req, res)
		Return	;only close the active media player,incase both vlc & kmp are running.
	}
IfWinActive, ahk_exe KMPlayer.exe
	{
	Process, Close, KMPlayer.exe
		Index(req, res)
		Return	;only close the active media player,incase both vlc & kmp are running.
	}
Else Index(req, res)
}

vlcContinue(ByRef req, ByRef res){
IfWinActive, ahk_exe vlc.exe
	{
	WinGetPos, X, Y, Width, Height, A
	CoordMode, Mouse, Client
	if (A_ScreenWidth != Width, A_ScreenHeight != Height)	;means not fullscreen, so if on windowed mode.
	{
	x := Width - 62
	y := Height - 10
	y := Height - y
	Click %x%, %y%
	}
	Else	;if full screen
	{
	x := A_ScreenWidth - 62
	y := A_ScreenHeight - 10
	y := A_ScreenHeight - y
	Click %x%, %y%
	}
}

Index(req, res)
}

vlcAutoSkip(ByRef req, ByRef res){
Global
IfWinActive, ahk_exe vlc.exe
	{
	Sleep, 500	;To make sure returned title is from the current 'track' and not the 'previous' one.
	WinGetActiveTitle, NowPlaying
	StringReplace, NowPlaying, NowPlaying, VLC media player, , All
	StringTrimRight, NowPlaying, NowPlaying, 3
	this_NowPlaying:=NowPlaying
	
	Loop
		{
		if !boolINI("AUTOSKIP", "flagged" . A_Index)	;loop ini values until non undefined/non-existing ini value is detected and add the current entry to ini.
			{
			wINI("AUTOSKIP","flagged" . A_Index, NowPlaying)
			Send {Media_Next} ;  go to the next track
			Break
			}
		}
		
	}
Index(req, res)
PulsarNotify(2, this_NowPlaying . " Flagged to Be skipped Automatically", 1000)
}



vlcBookmark(ByRef req, ByRef res){
Global
IfWinActive, ahk_exe vlc.exe
	{
	if (!mediaFoldersIndex OR !indexingComplete)
		{
		PulsarNotify(1, "MEDIA FOLDER INDEXING NOT COMPLETE,TRY AGAIN IN A MOMENT", 1000)
		Index(req, res)
		Return
		}
	WinGetActiveTitle, NowPlaying
	StringReplace, NowPlaying, NowPlaying, VLC media player, , All
	StringTrimRight, NowPlaying, NowPlaying, 3
	
	NowPlayingPath:=GetMediaFolderIndexPath(NowPlaying)

	;CHECK FILE WASN't BOOKMARKED BEFORE
	bookmarkCount:=keyCountINI("Bookmarks")
	if bookmarkCount	;if at least one bookmark entry was found,check NowPlaying file wasn't bookmarked before
		{
		Loop, Parse, lastSectionKeyList, `n
			{
			this_KeyPath:=rINI("Bookmarks", A_LoopField)
			IfInString, this_KeyPath, %NowPlaying%
				{
				PulsarNotify(1, "File is Already BookMarked!", 1000)
				Index(req, res)
				Return
				}
			}		
		}

	if NowPlayingPath
		Loop
			if !rINI("Bookmarks", "bookmark" . A_Index)	;if bookmark index doesn't exist
				{
				wINI("Bookmarks", "bookmark" . A_Index, NowPlayingPath)	;write bookmarked track path to config
				PulsarNotify(1, "Bookmarked NowPlaying", 1000)
				Break
				}
	}
Index(req, res)
}


vlcPlayBookmarked(ByRef req, ByRef res){
bookmarkCount:=keyCountINI("Bookmarks")
Global vlc,lastSectionKeyList
if bookmarkCount	;if at least one bookmark entry was found
	{
	bookmark_PLS_playlist .= "[playlist]`r"
	
	Loop, Parse, lastSectionKeyList, `n
		{
		this_KeyPath:=rINI("Bookmarks", A_LoopField)
		entry++	;increment playlist entry numbering,for every new entry this is incremented.
		bookmark_PLS_playlist .= "File" entry "=" this_KeyPath "`r"			
		}
	bookmark_PLS_playlist .= "NumberOfEntries=" entry "`rVersion=2"

	FileDelete, bookmark.pls
	FileAppend, %bookmark_PLS_playlist%, bookmark.pls

	Run, %vlc% bookmark.pls
	PulsarNotify(1, "Playing Bookmarked Files", 1000)
	}
else
	PulsarNotify(1, "No Bookmark Found", 1000)

Index(req, res)
}

vlcDeleteBookmarked(ByRef req, ByRef res){
Global
IfWinActive, ahk_exe vlc.exe
	{
	if (!mediaFoldersIndex OR !indexingComplete)
		{
		PulsarNotify(1, "MEDIA FOLDER INDEXING NOT COMPLETE,TRY AGAIN IN A MOMENT", 1000)
		Index(req, res)
		Return
		}
	WinGetActiveTitle, NowPlaying
	StringReplace, NowPlaying, NowPlaying, VLC media player, , All
	StringTrimRight, NowPlaying, NowPlaying, 4
	
	
	;FATTER THAN IT NEEDS TO BE TO MAKE SURE NON-SEQUNTIALLY ENTERED BOOKMARKS MAY BE REMOVED!
	bookmarkCount:=keyCountINI("Bookmarks")
	if bookmarkCount	;if at least one bookmark entry was found
		{
		Loop, Parse, lastSectionKeyList, `n
			{
			this_KeyPath:=rINI("Bookmarks", A_LoopField)
			IfInString, this_KeyPath, %NowPlaying%
				{
				dINI("Bookmarks", A_LoopField)
				PulsarNotify(1, "Removed NowPlaying From Bookmark", 1000)
				Index(req, res)
				Return
				}
			}
			PulsarNotify(1, "NowPlaying File is Not Bookmarked!", 1000)
		}
	else
		PulsarNotify(1, "No Bookmark Found,Nothing To Remove!", 1000)		
	}
Index(req, res)
}

GetMediaFolderIndexPath(searchString){	;returns a single path from index based on specified search string. To allow the path of the NowPlaying track to quickly be retrieved.
Global
Loop, Parse, mediaFoldersIndex, `n
	IfInString, A_LoopField, %searchString%
		Return, %A_LoopField%
}

vlcIndexMediaFolders(){
Global
if (mediaFoldersIndex AND indexingComplete)
	Return True
Loop, 5
{
this_folder:=f%A_Index%f
Loop, %this_folder%\*.*, , 1
	mediaFoldersIndex.=A_LoopFileFullPath "`n"
}
indexingComplete++	;for indexing completion verification,incase indexing is interrupted by a timer,'pseudothread'
}


music(ByRef req, ByRef res){
Global
Msg(, "Media Folder : Music")
Run, %vlc% "C:\Users\%A_Username%\Music"
	Index(req, res)
}

videos(ByRef req, ByRef res){
Global
Msg(, "Media Folder : Videos")
Run, %vlc% "C:\Users\%A_Username%\Videos"
	Index(req, res)
}

megMyers(ByRef req, ByRef res){	;example
Global
Msg(, "Media Folder(Prototype) : Meg Myers")
Run, %vlc% "C:\CROSSBOW\[MUUZyk]\MUSIC VIDEOS\@MEG MYERS"
	Index(req, res)
}

indila(ByRef req, ByRef res){	;example
Global
Msg(, "Media Folder(Prototype) : INDILA")
Run, %vlc% "C:\CROSSBOW\[MUUZyk]\MUSIC VIDEOS\@INDILA"
	Index(req, res)
}

;folder functions for config defined media folders
folder1(ByRef req, ByRef res){
Global
Msg(, "Media Folder : " . folder1name)
Run, %vlc% "%folder1folder%"
	Index(req, res)
}
folder2(ByRef req, ByRef res){
Global
Msg(, "Media Folder : " . folder2name)
Run, %vlc% "%folder2folder%"
	Index(req, res)
}
folder3(ByRef req, ByRef res){
Global
Msg(, "Media Folder : " . folder3name)
Run, %vlc% "%folder3folder%"
	Index(req, res)
}
folder4(ByRef req, ByRef res){
Global
Msg(, "Media Folder : " . folder4name)
Run, %vlc% "%folder4folder%"
	Index(req, res)
}
folder5(ByRef req, ByRef res){
Global
Msg(, "Media Folder : " . folder5name)
Run, %vlc% "%folder5folder%"
	Index(req, res)
}




monitor1(ByRef req, ByRef res){
SysGet, isPrimaryMonitorVar, MonitorPrimary
if (isPrimaryMonitorVar = 2 OR rINI("controlConfig","monitorButtonForceActive"))	;if primary monitor is the second monitor switch to first or if manual switching is activated
	{
	Send {LWin down}p
	Send {LWin up}
	WinWait, ahk_class DisplaySwitchUIWnd	;ahk_exe DisplaySwitch.exe
	Send {Left 3}
	Send {Enter}
	}
	Index(req, res)
}
monitor2(ByRef req, ByRef res){
SysGet, isPrimaryMonitorVar, MonitorPrimary
if (isPrimaryMonitorVar = 1)	;if primary monitor is the first monitor switch to second
	{
	Send {LWin down}p
	Send {LWin up}
	WinWait, ahk_class DisplaySwitchUIWnd	;ahk_exe DisplaySwitch.exe
	Send {Right 3}
	Send {Enter}
	}
	Index(req, res)
}


config(ByRef req, ByRef res){
Global

if rINI("controlConfig","monitorButtonForceActive", 0)
	monitorSwitchButtonColor=Green
else
	monitorSwitchButtonColor=Red

if rINI("controlConfig","demoFoldersActivation", 0)
	demoFoldersActivationButtonColor=Green
else
	demoFoldersActivationButtonColor=Red

if rINI("serverConfig","vlcExceptionHandler", 0)
	vlcExceptionHandlerActivationButtonColor=Green
else
	vlcExceptionHandlerActivationButtonColor=Red


; HtmlButtonGenerate(buttonName,buttonImage, buttonPath, buttonColor, buttonFontSize, buttonWidth, buttonHeight, paragraphButton, first_lastButtonInParagraph, registerPathInServer)
config_html_buttons:=""
bSize=40px
config_html_buttons.=HtmlButtonGenerate("Add Folder As Media Folder", , "/ConfigFileAddFolder", , bSize, "100`%", "100`%", 1, , 1)
config_html_buttons.=HtmlButtonGenerate("Open Working Directory", , "/OpenWorkingDir", , bSize, "100`%", "100`%", 1, , 1)
config_html_buttons.=HtmlButtonGenerate("Open Configuration File", , "/OpenConfigFile", , bSize, "100`%", "100`%", 1, , 1)
config_html_buttons.=HtmlButtonGenerate("Monitor Switching ON_OFF", , "/monitorSwitchButtonOnOff", monitorSwitchButtonColor, bSize, "100`%", "100`%", , 1, 1)
config_html_buttons.=HtmlButtonGenerate("Enable/Disable Demo Folders", , "/demoFoldersActivation", demoFoldersActivationButtonColor, bSize, "100`%", "100`%", , 1, 1)
config_html_buttons.=HtmlButtonGenerate("Suppress VLC Error Messages", , "/vlcExceptionHandlerActivation", vlcExceptionHandlerActivationButtonColor, bSize, "100`%", "100`%", , 1, 1)
config_html_buttons.="<p> Fwd/Rwd MULTIPLIER:"
config_html_buttons.=HtmlButtonGenerate(" RESET ", , "/fwdMultiplierReset", , bSize, , , , , 1)
config_html_buttons.=HtmlButtonGenerate("[ + ]", , "/fwdMultiplierPlus", , bSize, , , , , 1)
config_html_buttons.=HtmlButtonGenerate("[ - ]", , "/fwdMultiplierMinus", , bSize, , , , , 1)
frM:=rINI("controlConfig", "fwdRwdMultiplier", 1)
config_html_buttons.=HtmlButtonGenerate("[ " . frM . " ]", , "/config", , bSize)
config_html_buttons.="</p>"

config_html_buttons.=HtmlButtonGenerate("Back", , "/", "indigo", bSize, "50`%", "100`%", 1)


config_html =
(
<!doctype html>
<html>
<head>
<title> MediaRemoteControl - CONFIG </title>
<style>
p {
  font-family: Arial,Helvetica,sans-serif;
  font-size: 40px;
}

body {
	background-color : black ;
	color : yellow ;
	padding: 25px; width: auto; font-family: Sans-Serif; font-size: 10pt;
}
</style>
</head>
<body>

%config_html_buttons%

</body>
</html>
)

    res.SetBodyText(config_html)
    res.status := 200
}

monitorSwitchButtonOnOff(ByRef req, ByRef res){
;if off turn on
if !rINI("controlConfig","monitorButtonForceActive", 0)
	wINI("controlConfig","monitorButtonForceActive", 1)
else
	wINI("controlConfig","monitorButtonForceActive", 0)
config(req, res)
}

demoFoldersActivation(ByRef req, ByRef res){
;if off turn on
if !rINI("controlConfig","demoFoldersActivation", 0)
	wINI("controlConfig","demoFoldersActivation", 1)
else
	wINI("controlConfig","demoFoldersActivation", 0)
config(req, res)
}

vlcExceptionHandlerActivation(ByRef req, ByRef res){
if !rINI("serverConfig","vlcExceptionHandler", 0)
	wINI("serverConfig","vlcExceptionHandler", 1)
else
	wINI("serverConfig","vlcExceptionHandler", 0)
config(req, res)

config(req, res)
}


ConfigFileAddFolder(ByRef req, ByRef res){
SetTimer, AddMediaFolder, 1500
config(req, res)
}

AddMediaFolder:
SetTimer, AddMediaFolder, off
FileSelectFolder, SelectedFolder, , , Select Folder to Use as a Media Source
if SelectedFolder
	{
	InputBox, ButtonName, MediaRemoteControl, Input button name to assign to specified folder:, , 399, 137, , , , , Assigned Button Name will be what is shown in the browser interface.
	if ErrorLevel
		Return
	if !ButtonName
		{
		MsgBox, 0x40010, MediaRemoteControl, Invalid input`,Aborting!
		Return
		}
	InputBox, FolderID, MediaRemoteControl, Input folder ID to assign selected folder to`,, , 399, 137, , , , , 1-5 Are the Only Valid ID's`,maximum 5 folders supported.
	if ErrorLevel
		Return
	if (!FolderID OR FolderID > 5 OR FolderID < 1)
		{
		MsgBox, 0x40010, MediaRemoteControl, Invalid input`,Aborting!
		Return
		}
	wINI("MediaFolders", "folder" . FolderID . "name", ButtonName)	
	wINI("MediaFolders", "folder" . FolderID . "folder", SelectedFolder)
	MsgBox, 0x40040, %A_ScriptName%, RELOADING!, 2
	Reload
	}
else MsgBox, 0x40010, MediaRemoteControl, No Folder Was Selected`,Aborting!
Return


OpenWorkingDir(ByRef req, ByRef res){
Run, %A_ScriptDir%
config(req, res)
}

OpenConfigFile(ByRef req, ByRef res){
Global
Run, %configFileName%.ini
config(req, res)
}



; HtmlButtonGenerate("Button1", , "/404", "blue", "20px", "100`%", "100`%", 1)	;basic button
; HtmlButtonGenerate(buttonName,buttonImage, buttonPath, buttonColor, buttonFontSize, buttonWidth, buttonHeight, paragraphButton, first_lastButtonInParagraph, registerPathInServer)
HtmlButtonGenerate(buttonName:="buttonName",buttonImage:="", buttonPath:="/", buttonColor:="black", buttonFontSize:="16px", buttonWidth:="", buttonHeight:="", paragraphButton:="", first_lastButtonInParagraph:="", regPath:=""){
StringReplace, buttonPathFnc, buttonPath, /, , All	;remove'/'
Global paths
if regPath	;register path with http server
	paths[buttonPath] := Func(buttonPathFnc)
	
if paragraphButton	;PragraphButton=1, button is assigned it's own paragraph
	{
	p=<p>
	_p=</p>
	}
if (first_lastButtonInParagraph = 1)	;first button
	p:="<p>`r"
if (first_lastButtonInParagraph = 2)	;last button
	_p:="`r</p>"
	
if buttonImage
	btnImg=<input type="image" src ="%buttonImage%" />

if (buttonWidth AND buttonHeight)
	{
	if buttonWidth contains `%
		if buttonHeight contains `%
			buttonWH=width:%buttonWidth%; height: %buttonHeight%;			
	if buttonWidth contains px
		if buttonHeight contains px
			buttonWH=width:%buttonWidth%; height:%buttonHeight%;		
	}

htmlButton=%p% <a href="%buttonPath%"> <button style="color:%buttonColor%; font-family: Arial,Helvetica,sans-serif; font-size: %buttonFontSize%; %buttonWH%"> %buttonName% %btnImg% </button> </a> %_p%
Return %htmlButton%
}




/*
;FUNCTION GENERATOR FOR 'KEYS'	- Every input needs to append to an 'InputFeedBack' variable & reset the variable when 'Enter' is pressed & remove from variable using string trim when 'backspace' is pressed.
keys = Q,W,E,R,T,Y,U,I,O,P,A,S,D,F,G,H,J,K,L,Z,X,C,V,B,N,M,ENTER,SPACE,BACKSPACE
Loop, Parse, keys, `,	;all keys must return their parent page with the 'InputFeedBack' variable updated,except enter which exits the QWERTY page.
{
if A_LoopField not contains Enter,Space,BackSpace	;if a character key button was pressed
	fncs .= A_LoopField "(ByRef req, ByRef res){`nGlobal`n InputFeedBack.=""" A_LoopField """`nQWERTY(req, res)`n} `n`n"	;add to the input feedback display on the browser what has been written so far.
if (A_LoopField = "Enter")	;set timer to act on 'InputFeedBack' to then reset it and load index.
	fncs .= A_LoopField "(ByRef req, ByRef res){`nGlobal`n SetTimer, QWERTY_exec, 1500 `n`Index(req, res)`n} `n`n"	;using a timer to avoid page hanging,this allows the server to separate page loading from other activities.
if (A_LoopField = "Space")
	fncs .= A_LoopField "(ByRef req, ByRef res){`nGlobal`n InputFeedBack.=A_Space`nQWERTY(req, res)`n} `n`n"
if (A_LoopField = "BackSpace")	;remove last character from InputFeedBack
	fncs .= A_LoopField "(ByRef req, ByRef res){`nGlobal`n StringTrimRight, InputFeedBack, InputFeedBack, 1`nQWERTY(req, res)`n} `n`n"
}
MsgBox, %fncs%
Clipboard:=fncs
*/


QWERTY(ByRef req, ByRef res) {
Global

;SetPaths
keys = Q,W,E,R,T,Y,U,I,O,P,A,S,D,F,G,H,J,K,L,Z,X,C,V,B,N,M,ENTER,SPACE,BACKSPACE
Loop, Parse, keys, `,	;load the path for all keys
{
loopPath=/%A_LoopField%
paths[loopPath] := Func(A_LoopField)
}

if !QWERTY_html_buttons
	Loop, Parse, keys, `,	;generate button for all keys
	{
	if (A_LoopField = "Q")
		QWERTY_html_buttons.="<p>`r <a href=/" A_LoopField "> <button> " A_LoopField " </button> </a>`r"
	if isOneLikeAnyOther(A_LoopField, "A", "Z", "ENTER")
		QWERTY_html_buttons.="</p>`r<p>`r <a href=/" A_LoopField "> <button> " A_LoopField " </button> </a>`r"
	if !isOneLikeAnyOther(A_LoopField, "Q", "A", "Z", "ENTER", "BACKSPACE")	;if OneIsLikeNoOther
		QWERTY_html_buttons.="<a href=/" A_LoopField "> <button> " A_LoopField " </button> </a>`r"
	if (A_LoopField = "BACKSPACE")
		QWERTY_html_buttons.="`r <a href=/" A_LoopField "> <button> bSPACE </button> </a> </p>"
	}

searchHistoryButtons:=""
Loop, 20
{
if rINI("SearchHistory", "searchString" . A_Index)
	{
	this_searchString:=rINI("SearchHistory", "searchString" . A_Index)
	searchHistoryButtons.=HtmlButtonGenerate(this_searchString, , "/searchString" . A_Index, , bSize, , , 1, , 1)
	}
}



QWERTY_html =
(
<!doctype html>
<html>
<head>
<title> MediaRemoteControl - QWERTY </title>
<style>
p {
  font-family: Arial,Helvetica,sans-serif;
  font-size: 20px;
}

button {
  font-family: Arial,Helvetica,sans-serif;
  font-size: 80px;
}

h1 {
	padding: 40px; width: auto; font-family: Sans-Serif; font-size: 22pt;
}

body {
	background-color : black ;
	color : yellow ;
	padding: 20px; width: auto; font-family: Sans-Serif; font-size: 10pt;
}
</style>
</head>
<body>

<h1>
%InputFeedBack%
</h1>

%QWERTY_html_buttons%

<p> &nbsp; </p>
<p> &nbsp; </p>

<p>  <a href="/"> <button style="width:50`%; height: 100`%; color:black"> Back </button> </a> </p> 

<p> &nbsp; </p>
<p> &nbsp; </p>
<h1>Search History: </h1>
%searchHistoryButtons%

</body>
</html>
)

    res.SetBodyText(QWERTY_html)
    res.status := 200
}




Q(ByRef req, ByRef res){
Global
 InputFeedBack.="Q"
QWERTY(req, res)
} 

W(ByRef req, ByRef res){
Global
 InputFeedBack.="W"
QWERTY(req, res)
} 

E(ByRef req, ByRef res){
Global
 InputFeedBack.="E"
QWERTY(req, res)
} 

R(ByRef req, ByRef res){
Global
 InputFeedBack.="R"
QWERTY(req, res)
} 

T(ByRef req, ByRef res){
Global
 InputFeedBack.="T"
QWERTY(req, res)
} 

Y(ByRef req, ByRef res){
Global
 InputFeedBack.="Y"
QWERTY(req, res)
} 

U(ByRef req, ByRef res){
Global
 InputFeedBack.="U"
QWERTY(req, res)
} 

I(ByRef req, ByRef res){
Global
 InputFeedBack.="I"
QWERTY(req, res)
} 

O(ByRef req, ByRef res){
Global
 InputFeedBack.="O"
QWERTY(req, res)
} 

P(ByRef req, ByRef res){
Global
 InputFeedBack.="P"
QWERTY(req, res)
} 

A(ByRef req, ByRef res){
Global
 InputFeedBack.="A"
QWERTY(req, res)
} 

S(ByRef req, ByRef res){
Global
 InputFeedBack.="S"
QWERTY(req, res)
} 

D(ByRef req, ByRef res){
Global
 InputFeedBack.="D"
QWERTY(req, res)
} 

F(ByRef req, ByRef res){
Global
 InputFeedBack.="F"
QWERTY(req, res)
} 

G(ByRef req, ByRef res){
Global
 InputFeedBack.="G"
QWERTY(req, res)
} 

H(ByRef req, ByRef res){
Global
 InputFeedBack.="H"
QWERTY(req, res)
} 

J(ByRef req, ByRef res){
Global
 InputFeedBack.="J"
QWERTY(req, res)
} 

K(ByRef req, ByRef res){
Global
 InputFeedBack.="K"
QWERTY(req, res)
} 

L(ByRef req, ByRef res){
Global
 InputFeedBack.="L"
QWERTY(req, res)
} 

Z(ByRef req, ByRef res){
Global
 InputFeedBack.="Z"
QWERTY(req, res)
} 

X(ByRef req, ByRef res){
Global
 InputFeedBack.="X"
QWERTY(req, res)
} 

C(ByRef req, ByRef res){
Global
 InputFeedBack.="C"
QWERTY(req, res)
} 

V(ByRef req, ByRef res){
Global
 InputFeedBack.="V"
QWERTY(req, res)
} 

B(ByRef req, ByRef res){
Global
 InputFeedBack.="B"
QWERTY(req, res)
} 

N(ByRef req, ByRef res){
Global
 InputFeedBack.="N"
QWERTY(req, res)
} 

M(ByRef req, ByRef res){
Global
 InputFeedBack.="M"
QWERTY(req, res)
} 

ENTER(ByRef req, ByRef res){
Global
 SetTimer, QWERTY_exec, 1000 
Index(req, res)
} 

SPACE(ByRef req, ByRef res){
Global
 InputFeedBack.=A_Space
QWERTY(req, res)
} 

BACKSPACE(ByRef req, ByRef res){
Global
 StringTrimRight, InputFeedBack, InputFeedBack, 1
QWERTY(req, res)
} 




QWERTY_exec:
if InputFeedBack
{
SetTimer, QWERTY_exec, off
StringSplit, InputFeedBack_array, InputFeedBack, %A_Space%	;split input string by space to find any file that has all the substrings of the input string, i.e if 'meg myers' was input,it will look for files with 'meg' & 'myers',instead of just a 'meg myers',which should allow getting more matches.
	;Build Playlist
PLS_playlist .= "[playlist]`r"

if (!mediaFoldersIndex OR !indexingComplete)
	{
	PulsarNotify(1, "MEDIA FOLDER INDEXING NOT COMPLETE,TRY AGAIN IN A MOMENT", 1000)
	Index(req, res)
	Return
	}
	
;IF INDEXING IS COMPLETE USE INDEX

if (mediaFoldersIndex AND indexingComplete)
	{
	Loop, Parse, mediaFoldersIndex, `n	; cycle and recurse through index of media folder paths.
		{
		SplitPath, A_LoopField, , , OutExtension
		if OutExtension contains lnk,txt,description,lrc
			Goto badExtensionJump
		if (InputFeedBack_array0=1)	;if single string was provided
			{
			if A_LoopField contains %InputFeedBack_array1%
				{
				entry++	;increment playlist entry numbering,for every new entry this is incremented.
				this_PLSentry=File%entry%
				SplitPath, A_LoopField, OutFileName
				PLS_playlist .= "File" entry "=" A_LoopField "`r"
				PLS_playlist .= "Title" entry "=" OutFileName "`r"
				}
			}
		if (InputFeedBack_array0=2)	;if two strings were provided
			{
			if A_LoopField contains %InputFeedBack_array1%
				if A_LoopField contains %InputFeedBack_array2%
					{
					entry++	;increment playlist entry numbering,for every new entry this is incremented.
					this_PLSentry=File%entry%
					SplitPath, A_LoopField, OutFileName
					PLS_playlist .= "File" entry "=" A_LoopField "`r"
					PLS_playlist .= "Title" entry "=" OutFileName "`r"
					}
			}
		if (InputFeedBack_array0=3)	;if three strings were provided
			{
			if A_LoopField contains %InputFeedBack_array1%
				if A_LoopField contains %InputFeedBack_array2%
					if A_LoopField contains %InputFeedBack_array3%
						{
						entry++	;increment playlist entry numbering,for every new entry this is incremented.
						this_PLSentry=File%entry%
						SplitPath, A_LoopField, OutFileName
						PLS_playlist .= "File" entry "=" A_LoopField "`r"
						PLS_playlist .= "Title" entry "=" OutFileName "`r"
						}
			}
		if (InputFeedBack_array0>3)	;if more than three strings were provided treat them as if a single string was provided
			{
			if A_LoopField contains %InputFeedBack_array1%
				{
				entry++	;increment playlist entry numbering,for every new entry this is incremented.
				this_PLSentry=File%entry%
				SplitPath, A_LoopField, OutFileName
				PLS_playlist .= "File" entry "=" A_LoopField "`r"
				PLS_playlist .= "Title" entry "=" OutFileName "`r"
				}
			}
		badExtensionJump:
		}
	}


PLS_playlist .= "NumberOfEntries=" entry "`rVersion=2"
if entry	;if at least one media file was matched and added to playlist,append playlist to file and run it with VLC.
{
FileCreateDir, mrcBookmarks
FileDelete, %A_ScriptDir%\mrcBookmarks\Tmp_MRC.pls
FileAppend, %PLS_playlist%, %A_ScriptDir%\mrcBookmarks\Tmp_MRC.pls
Run, %vlc% %A_ScriptDir%\mrcBookmarks\Tmp_MRC.pls
}
if !entry	;if no match found
	{
	PulsarNotify(4, " NO MATCH FOUND!", 1000)
	Return
	}

;SEARCH HISTORY
;read all 19 items into variable and append that variable to the bottom of the newest search string variable,then write back to ini with current search string at very top.
Loop, 20	;last one always gets otmitted because of new entry
	{
	if A_Index = 20	;delete the saved playlist of the last history entry & exit loop with 19entries maximum in the sHistory var.
		{
		FileDelete, %A_LoopField%.pls
		Break
		}
	if rINI("SearchHistory", "searchString" . A_Index)
		{
		this_HistoryItem := rINI("SearchHistory", "searchString" . A_Index)
		if ( this_HistoryItem != InputFeedBack)	;add previous search string to current history only if it doesn't match current search string,this avoids duplicate history entries and the most recent entry,i.e the current entry will be the only entry for that search string.
			{
			sHistory.=rINI("SearchHistory", "searchString" . A_Index)
			sHistory.="`n"
			}
		}
	}
sHistoryCurrent.=InputFeedBack "`n"
sHistoryCurrent.=sHistory

Loop, Parse, sHistoryCurrent, `n
	wINI("SearchHistory", "searchString" . A_Index, A_LoopField)
FileCopy, %A_ScriptDir%\mrcBookmarks\Tmp_MRC.pls, %A_ScriptDir%\mrcBookmarks\%InputFeedBack%.pls, 1	;the playlist created is backed up to be played back if button is pressed again.

InputFeedBack:=""	;reset InputFeedBack after input string has been used.
sHistory:=""
sHistoryCurrent:=""
PLS_playlist:=""
entry:=""
}
Exit


/*
;FUNCTION GENERATOR USED FOR SEQUENCE OF FUNCTIONS BELOW
Loop, 20
{
fncs.=
(
"searchString" A_Index "(ByRef req, ByRef res){
Global
sString:=rINI(""SearchHistory"", ""searchString" A_Index """ )
Run, `%vlc`% `%A_ScriptDir`%\mrcBookmarks\`%sString`%.pls
Index(req, res)
}`n`n"
)
}	

MsgBox, %fncs%
Clipboard:=fncs
*/


searchString1(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString1" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString2(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString2" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString3(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString3" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString4(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString4" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString5(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString5" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString6(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString6" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString7(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString7" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString8(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString8" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString9(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString9" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString10(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString10" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString11(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString11" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString12(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString12" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString13(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString13" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString14(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString14" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString15(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString15" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString16(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString16" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString17(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString17" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString18(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString18" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString19(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString19" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}

searchString20(ByRef req, ByRef res){
Global
sString:=rINI("SearchHistory", "searchString20" )
Run, %vlc% %A_ScriptDir%\mrcBookmarks\%sString%.pls
Index(req, res)
}










NotFound(ByRef req, ByRef res) {
    res.SetBodyText("Page not found")
}

HelloWorld(ByRef req, ByRef res) {
    res.SetBodyText("Hello World")
    res.status := 200
}








;====================================================================
;=======================Comparison FUNCTIONS=========================
;====================================================================





; x=nova
; y=mya
; z=elle
; MsgBox, % isOneLikeAllOthers(x, y, z)
; MsgBox, % isOneLikeAnyOther(x, y, z)
; MsgBox, % "possibleMatches: " no_of_possibleValueMatches
; MsgBox, % isOneLikeNoOther(x, y, z)
isOneLikeAllOthers(varIn, possibleValue*){	;returns true if all possibleValue's match varIn
; Choices.MaxIndex() contains the number of provided variables,and it can it self be referred as a variable
; Choices[Index] contains the value of a variable,with index specifying the n-th variable,this should be assigned to a variable with a corresponding index value specified
numberOf_possibleValues:=possibleValue.MaxIndex()
Loop, %numberOf_possibleValues%
{
lValue := possibleValue[A_Index]
if (varIn = lValue)
	i++
}
if (i = numberOf_possibleValues)	;if increment matches the number of possibleValue's,then every possibleValue was a match to varIn
 Return true
}
isOneLikeAnyOther(varIn, possibleValue*){	;returns true if any possibleValue matches varIn
; Choices.MaxIndex() contains the number of provided variables,and it can it self be referred as a variable
; Choices[Index] contains the value of a variable,with index specifying the n-th variable,this should be assigned to a variable with a corresponding index value specified
numberOf_possibleValues:=possibleValue.MaxIndex()
Loop, %numberOf_possibleValues%
{
lValue := possibleValue[A_Index]
if (varIn = lValue)
	i++
}
Global no_of_possibleValueMatches	;to also provide additional information about how many matches were detected
no_of_possibleValueMatches := i

if i	;if not null then at least one possibleValue matches varIn
 Return true
}
isOneLikeNoOther(varIn, possibleValue*){	;returns true if no possibleValue matches varIn	-	REDUNDANT function to the 'isOneLikeAnyOther()' returning false
; Choices.MaxIndex() contains the number of provided variables,and it can it self be referred as a variable
; Choices[Index] contains the value of a variable,with index specifying the n-th variable,this should be assigned to a variable with a corresponding index value specified
numberOf_possibleValues:=possibleValue.MaxIndex()
Loop, %numberOf_possibleValues%
{
lValue := possibleValue[A_Index]
if (varIn = lValue)
	i++
}
if !i	;if not null then at least one possibleValue matches varIn
 Return true
}





;====================================================================
;=========================INI FUNCTIONS==============================			;defaults for keynames are specified because ahk won't allow preceding params to have defaults and others not.
;====================================================================
wINI(sectionName:="MediaFolders", keyName:=0, keyValue:=0)	;write to ini
{
Global
FileAppend, `n, %configFileName%.ini
IniWrite, %keyValue%, %configFileName%.ini, %sectionName%, %keyName%
}


rINI(sectionName:="MediaFolders", keyName:=0, defaultKeyValue:=0)	;read from ini
{
Global
if !defaultKeyValue
	IniRead, keyVariableOut_var, %configFileName%.ini, %sectionName%, %keyName%
else
	IniRead, keyVariableOut_var, %configFileName%.ini, %sectionName%, %keyName%, %defaultKeyValue%
if (keyVariableOut_var = "ERROR")
	Return False

return %keyVariableOut_var%
}


dINI(sectionName:="MediaFolders", keyName:=0)	;delete ini key or section
{
Global
if !keyName
	IniDelete, %configFileName%.ini, %sectionName%
Else
	IniDelete, %configFileName%.ini, %sectionName%, %keyName%
}


boolINI(sectionName:="MediaFolders", keyName:=0)	;to check if an ini value exists so as to proceed to read it's value if does
{
Global
IniRead, currentKeyValue, %configFileName%.ini, %sectionName%, %keyName%

IfEqual, currentKeyValue, Error
	Return, False
Else Return, True
}



; MsgBox, % keyCountINI("Bookmarks")
; MsgBox, % lastSectionKeyList
; MsgBox, % lastSectionKeyValueList
keyCountINI(sectionName){	;returns the number of keys in a section & resets global variables with `n delimited list of keys & their values belonging with in a section
Global
keyCount:=""
lastSectionKeyList:=""
lastSectionKeyValueList:=""
Local sectionStart
Loop, Read, %configFileName%.ini
{
if sectionStart
	{
	if (A_LoopReadLine != "" AND sectionStart)
		{
		keyCount++
		StringSplit, keyStringArray, A_LoopReadLine, `=

		if lastSectionKeyList	;if previous entry,set line break,to avoid null lines
			lastSectionKeyList.= "`n"
		lastSectionKeyList.= keyStringArray1

		if lastSectionKeyValueList	;if previous entry,set line break,to avoid null lines
			lastSectionKeyValueList.= "`n"
		lastSectionKeyValueList.= keyStringArray2
		}
	
	if A_LoopReadLine Contains [,]	;If new section start,break
		if A_LoopReadLine not contains =
			Break
	}

IfInString, A_LoopReadLine, %sectionName%
	sectionStart:=1
}
Return, %keyCount%
}



;====================================================================
;=========================PulsarNotifcation==========================
;====================================================================





; PulsarNotify(2, " ALERT!", 100)
PulsarNotify(pulses, msgText, pulseDelay:=500, x:="", y:="")
{
/*
-COLOR CHART-
Black 000000
Silver C0C0C0 
Gray 808080 
White FFFFFF 
Maroon 800000 (Brown-ish)
Red FF0000 
Purple 800080 
Fuchsia FF00FF (Pink-ish)
Green 008000 
Lime 00FF00 
Olive 808000 
Yellow FFFF00 
Navy 000080 
Blue 0000FF 
Teal 008080 
Aqua 00FFFF 
*/
Gui, +AlwaysOnTop +Disabled -SysMenu +Owner  ; +Owner avoids a taskbar button.
Gui, Margin, 0, 0
Gui, Color, 080808	;soft black background
Gui, Font, c808080	;silver text
Gui, Font, s20, Verdana  ; Set 10-point Verdana.
Gui, Font, wBold
Gui, Add, Text,, `n%msgText%
Gui, Show, Hide, PulsarNotifcation  ; NoActivate avoids deactivating the currently active window.
DetectHiddenWindows, On
WinSet, Style, -0xC00000, PulsarNotifcation   ; Remove the active window's title bar (WS_CAPTION).
; WinSet, TransColor, EEAA99 150, PulsarNotifcation
WinSet, TransColor, EEAA99 0, PulsarNotifcation
if (x != "" AND y != "")
	WinMove, PulsarNotifcation, , %x%, %y%
Gui, Show, NoActivate, PulsarNotifcation

Loop, %pulses%
{
counter = 255
Loop 255
	{
	WinSet, Transparent, %A_Index%, PulsarNotifcation
	; Sleep, 1
	}
Sleep, %pulseDelay%
Loop
	{
	WinSet, Transparent, %counter%, PulsarNotifcation
	counter -= 1
	IfEqual, counter, 0
	Break
	; Sleep, 1
	}
}
Gui, Destroy
}




;========================================================================================================================================================================================
;---------------------------------------------------------------
; Msg Monolog
; http://www.autohotkey.com/board/topic/94458-msgbox-or-traytip-replacement-monolog-non-modal-transparent-msg-cornernotify/
;---------------------------------------------------------------

Msg(title="Media Remote Control", body="", loc="bl", fixedwidth=0, time=0) {
	global msgtransp, hwndmsg, MonBottom, MonRight
	SetTimer, MsgStay, Off
	SetTimer, MsgFadeOut, Off
	Gui,77:Destroy
	Gui,77:+AlwaysOnTop +ToolWindow -SysMenu -Caption +LastFound
	hwndmsg := WinExist()
	WinSet, ExStyle, +0x20 ; WS_EX_TRANSPARENT make the window transparent-to-mouse
	WinSet, Transparent, 160
	msgtransp := 160
	Gui,77:Color, 000000 ;background color
	Gui,77:Font, c5C5CF0 s17 wbold, Arial
	Gui,77:Add, Text, x20 y12, %title%
	If(body) {
		Gui,77:Font, cF0F0F0 s15 wnorm
		Gui,77:Add, Text, x20 y56, %body%
	}
	If(fixedwidth) {
		Gui,77:Show, NA W700
	} else {
		Gui,77:Show, NA
	}
	WinGetPos,ix,iy,w,h, ahk_id %hwndmsg%
	; SysGet, Mon, MonitorWorkArea ; already called
	if(loc) {
		x := InStr(loc,"l") ? 0 : InStr(loc,"c") ? (MonRight-w)/2 : InStr(loc,"r") ? A_ScreenWidth-w : 0
		y := InStr(loc,"t") ? 0 : InStr(loc,"m") ? (MonBottom-h)/2 : InStr(loc,"b") ? MonBottom - h : MonBottom - h
	} else { ; bl
		x := 0
		y := MonBottom - h
	}
	WinMove, ahk_id %hwndmsg%,,x,y
	If(time) {
		time *= 1000
		SetTimer, MsgStay, %time%
	} else {
		SetTimer, MsgFadeOut, 25
	}
}

MsgStay:
	SetTimer, MsgStay, Off
	SetTimer, MsgFadeOut, 1
Return

MsgFadeOut:
	If(msgtransp > 0) {
		msgtransp -= 4
		WinSet, Transparent, %msgtransp%, ahk_id %hwndmsg%
	} Else {
		SetTimer, MsgFadeOut, Off
		Gui,77:Destroy
	}
Return


about(ByRef req, ByRef res){

backButton.=HtmlButtonGenerate("Back", , "/", "indigo", bSize, "50`%", "100`%", 1)

about_html =
(
<!doctype html>
<html>
<head>
<title> MediaRemoteControl - About </title>
<style>
p {
  font-family: Arial,Helvetica,sans-serif;
  font-size: 20px;
}

body {
	background-color : Silver ;
	color : Black ;
	padding: 25px; width: auto; font-family: Sans-Serif; font-size: 10pt;
}
</style>
</head>
<body>

%backButton%

<h2>
brutus_skywalker:
</h2>
<blockquote>
"Initially conceived as a Browser based remote control,it actually ended up providing more control over media files,than even most media players. It's the little things that make the world go round & round,
and the little things like <strong>'autoskip' </strong> , <strong> 'bookmark file|play bookmarked file'</strong> , <strong> 'file/path search & play + keep history' </strong> , <strong> 'multiplier based fwd/rwd' </strong>, <strong> 'volume presets' </strong>, <strong> 'standby/hibernate timed|instant' </strong>, <strong> 'quick play media directories'</strong> 
& of course a <strong> 'browser interface'</strong> , not exactly revolutionary shit,but allows you to control media back when you just can't/don't want to get to the keyboard,just good enough for me!"
</blockquote> 


<h1>Features:</h1>

<p>
Previous,Pause/Play,Stop,Next
</p>

<p>
VLC/KMPlayer only Forward/Rewind with Multiplier in config.
</p>

<p>
VolumeUp/Down/MuteToggle AND 20/50/80/100`% Presets //20-30-30-20 increments//|//VolumeUp/Down Dec/Increments by 5`%//.
</p>

<p>
standby/hibernate with a timer,timer default is '0',timer can be inc/decreased by 30min inc/decrements or reset,if timer is reset any timer delayed standby/hibernate action will be reset.
</p>

<p>
Monitor_On/Off.
</p>

<p>
[c]mrcexit[/c] hotstring to kill the server.
</p>

<p>
VLC Bring To Front/Turn off VLC/FullScreen Toggle.
</p>

<p>
VLC/KMPlayer/MPlayer Display NowPlaying File Notification on browserInterface.
</p>

<p>
VLC - Continue to resume playback. If it is enabled in vlc settings & the 'continue playback' floating panel is active,i.e If The 'Continue' Notification is visible.
</p>
	
<p>
Quick launch media folders,Each media folder is assigned a button on the browser interface. Media folders can be added using config section on browserInterface or manually in the iniFile.
<strong>Quick Launch folders are run with an always-on-top,qt-minimal-view vlc instance.</strong>
</p>

<p>
Bi-directional AUTOSKIP, skips file automatically with respect to Next/Previous button press. Also actively checks if NowPlaying file is flagged for autoSkip,for when playback ends & next file comes up.
</p>

<p>
Search And Play Files/Paths button, to allow input of search string in browser UI,to only play files/paths that match search string.Preserves Search history for 20 of the last search strings.
Up to three space delimited strings can be provided where each space is considered an 'AND' logical operator,if more than three spaces are in given search string,entire sequence will be considered a single search term.
</p>

<p>
Un/Bookmark now playing file, to play back only bookmarked files at a later time.
</p>

<p>
Config - section/button for easy addition of media folders,monitor switching buttons on/off,fwd/rwd multiplier settings,demo folders on/off,error message suppression on/off & quick access to config file/working dir.
</p>

<p>
OSD for on-screen notification.
</p>

<p>
Browser Interface NowPlaying notification, with context sensitive CurrentVolume notification only when volume is in/decreased.
</p>

<p>
Monitor Switching,buttons appear only when two monitors are detected,can be manually enabled from config,if display is not automatically detected.
</p>

<p>
VLC Error Message automatic suppression,can be disable or enabled in config. Includes suppression of 'Broken AVI Index files',tries to play the file with out building index.
</p>

%backButton%

</body>
</html>
)

    res.SetBodyText(about_html)
    res.status := 200
}

Goto, unintendedStdBy_Hib_JUMP	;so that standby/hibernate is not activated on script exit & labels can only be reached if called
scheduledStandby:
	SetTimer, scheduledStandby, off
	scheduleDelay:=0	;reset timer to allow going into standby/hibernate
	standby(req, res)
Return
scheduledHibernate:
	SetTimer, scheduledHibernate, off
	scheduleDelay:=0	;reset timer to allow going into standby/hibernate
	hibernate(req, res)
Return
unintendedStdBy_Hib_JUMP:


::mrcexit::
ExitApp




#include <AHKsock>






/*
AHKhttp by Skiouros

https://autohotkey.com/boards/viewtopic.php?f=6&t=4890
https://github.com/Skiouros/AHKhttp
*/


class Uri
{
    Decode(str) {
        Loop
            If RegExMatch(str, "i)(?<=%)[\da-f]{1,2}", hex)
                StringReplace, str, str, `%%hex%, % Chr("0x" . hex), All
            Else Break
        Return, str
    }

    Encode(str) {
        f = %A_FormatInteger%
        SetFormat, Integer, Hex
        If RegExMatch(str, "^\w+:/{0,2}", pr)
            StringTrimLeft, str, str, StrLen(pr)
        StringReplace, str, str, `%, `%25, All
        Loop
            If RegExMatch(str, "i)[^\w\.~%]", char)
                StringReplace, str, str, %char%, % "%" . Asc(char), All
            Else Break
        SetFormat, Integer, %f%
        Return, pr . str
    }
}

class HttpServer
{
    static servers := {}

    LoadMimes(file) {
        if (!FileExist(file))
            return false

        FileRead, data, % file
        types := StrSplit(data, "`n")
        this.mimes := {}
        for i, data in types {
            info := StrSplit(data, " ")
            type := info.Remove(1)
            ; Seperates type of content and file types
            info := StrSplit(LTrim(SubStr(data, StrLen(type) + 1)), " ")

            for i, ext in info {
                this.mimes[ext] := type
            }
        }
        return true
    }

    GetMimeType(file) {
        default := "text/plain"
        if (!this.mimes)
            return default

        SplitPath, file,,, ext
        type := this.mimes[ext]
        if (!type)
            return default
        return type
    }

    ServeFile(ByRef response, file) {
        f := FileOpen(file, "r")
        length := f.RawRead(data, f.Length)
        f.Close()

        response.SetBody(data, length)
        res.headers["Content-Type"] := this.GetMimeType(file)
    }

    SetPaths(paths) {
        this.paths := paths
    }

    Handle(ByRef request) {
        response := new HttpResponse()
        if (!this.paths[request.path]) {
            func := this.paths["404"]
            response.status := 404
            if (func)
                func.(request, response, this)
            return response
        } else {
            this.paths[request.path].(request, response, this)
        }
        return response
    }

    Serve(port) {
        this.port := port
        HttpServer.servers[port] := this

        AHKsock_Listen(port, "HttpHandler")
    }
}

HttpHandler(sEvent, iSocket = 0, sName = 0, sAddr = 0, sPort = 0, ByRef bData = 0, bDataLength = 0) {
    static sockets := {}

    if (!sockets[iSocket]) {
        sockets[iSocket] := new Socket(iSocket)
        AHKsock_SockOpt(iSocket, "SO_KEEPALIVE", true)
    }
    socket := sockets[iSocket]

    if (sEvent == "DISCONNECTED") {
        socket.request := false
        sockets[iSocket] := false
    } else if (sEvent == "SEND") {
        if (socket.TrySend()) {
            socket.Close()
        }

    } else if (sEvent == "RECEIVED") {
        server := HttpServer.servers[sPort]

        text := StrGet(&bData, "UTF-8")
        request := new HttpRequest(text)

        ; Multipart request
        if (request.IsMultipart()) {
            length := request.headers["Content-Length"]
            request.bytesLeft := length + 0

            if (request.body) {
                request.bytesLeft -= StrLen(request.body)
            }
            socket.request := request
        } else if (socket.request) {
            ; Get data and append it to the request body
            socket.request.bytesLeft -= StrLen(text)
            socket.request.body := socket.request.body . text
        }

        if (socket.request) {
            request := socket.request
            if (request.bytesLeft <= 0) {
                request.done := true
            }
        }

        response := server.Handle(request)
        if (response.status) {
            socket.SetData(response.Generate())

            if (socket.TrySend()) {
                if (!request.IsMultipart() || (request.IsMultipart() && request.done)) {
                    socket.Close()
                }
            }
        }
    }
}

class HttpRequest
{
    __New(data = "") {
        if (data)
            this.Parse(data)
    }

    GetPathInfo(top) {
        results := []
        while (pos := InStr(top, " ")) {
            results.Insert(SubStr(top, 1, pos - 1))
            top := SubStr(top, pos + 1)
        }
        this.method := results[1]
        this.path := Uri.Decode(results[2])
        this.protocol := top
    }

    GetQuery() {
        pos := InStr(this.path, "?")
        query := StrSplit(SubStr(this.path, pos + 1), "&")
        if (pos)
            this.path := SubStr(this.path, 1, pos - 1)

        this.queries := {}
        for i, value in query {
            pos := InStr(value, "=")
            key := SubStr(value, 1, pos - 1)
            val := SubStr(value, pos + 1)
            this.queries[key] := val
        }
    }

    Parse(data) {
        this.raw := data
        data := StrSplit(data, "`n`r")
        headers := StrSplit(data[1], "`n")
        this.body := LTrim(data[2], "`n")

        this.GetPathInfo(headers.Remove(1))
        this.GetQuery()
        this.headers := {}

        for i, line in headers {
            pos := InStr(line, ":")
            key := SubStr(line, 1, pos - 1)
            val := Trim(SubStr(line, pos + 1), "`n`r ")

            this.headers[key] := val
        }
    }

    IsMultipart() {
        length := this.headers["Content-Length"]
        expect := this.headers["Expect"]

        if (expect = "100-continue" && length > 0)
            return true
        return false
    }
}

class HttpResponse
{
    __New() {
        this.headers := {}
        this.status := 0
        this.protocol := "HTTP/1.1"

        this.SetBodyText("")
    }

    Generate() {
        FormatTime, date,, ddd, d MMM yyyy HH:mm:ss
        this.headers["Date"] := date

        headers := this.protocol . " " . this.status . "`n"
        for key, value in this.headers {
            headers := headers . key . ": " . value . "`n"
        }
        headers := headers . "`n"
        length := this.headers["Content-Length"]

        buffer := new Buffer((StrLen(headers) * 2) + length)
        buffer.WriteStr(headers)

        buffer.Append(this.body)
        buffer.Done()

        return buffer
    }

    SetBody(ByRef body, length) {
        this.body := new Buffer(length)
        this.body.Write(&body, length)
        this.headers["Content-Length"] := length
    }

    SetBodyText(text) {
        this.body := Buffer.FromString(text)
        this.headers["Content-Length"] := this.body.length
    }


}

class Socket
{
    __New(socket) {
        this.socket := socket
    }

    Close(timeout = 5000) {
        AHKsock_Close(this.socket, timeout)
    }

    SetData(data) {
        this.data := data
    }

    TrySend() {
        if (!this.data || this.data == "")
            return false

        p := this.data.GetPointer()
        length := this.data.length

        this.dataSent := 0
        loop {
            if ((i := AHKsock_Send(this.socket, p, length - this.dataSent)) < 0) {
                if (i == -2) {
                    return
                } else {
                    ; Failed to send
                    return
                }
            }

            if (i < length - this.dataSent) {
                this.dataSent += i
            } else {
                break
            }
        }
        this.dataSent := 0
        this.data := ""

        return true
    }
}

class Buffer
{
    __New(len) {
        this.SetCapacity("buffer", len)
        this.length := 0
    }

    FromString(str, encoding = "UTF-8") {
        length := Buffer.GetStrSize(str, encoding)
        buffer := new Buffer(length)
        buffer.WriteStr(str)
        return buffer
    }

    GetStrSize(str, encoding = "UTF-8") {
        encodingSize := ((encoding="utf-16" || encoding="cp1200") ? 2 : 1)
        ; length of string, minus null char
        return StrPut(str, encoding) * encodingSize - encodingSize
    }

    WriteStr(str, encoding = "UTF-8") {
        length := this.GetStrSize(str, encoding)
        VarSetCapacity(text, length)
        StrPut(str, &text, encoding)

        this.Write(&text, length)
        return length
    }

    ; data is a pointer to the data
    Write(data, length) {
        p := this.GetPointer()
        DllCall("RtlMoveMemory", "uint", p + this.length, "uint", data, "uint", length)
        this.length += length
    }

    Append(ByRef buffer) {
        destP := this.GetPointer()
        sourceP := buffer.GetPointer()

        DllCall("RtlMoveMemory", "uint", destP + this.length, "uint", sourceP, "uint", buffer.length)
        this.length += buffer.length
    }

    GetPointer() {
        return this.GetAddress("buffer")
    }

    Done() {
        this.SetCapacity("buffer", this.length)
    }
}

