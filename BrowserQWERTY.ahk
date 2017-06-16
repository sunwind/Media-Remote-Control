#SingleInstance, force





;COMMENT OUT SEGMENT BELOW!
;segment below is Solely for scripting assistance(to generate functions for buttons) and has no use in the scripts functionality.
;generate functions for keys	- Every input needs to append to an 'InputFeedBack' variable & reset the variable when 'Enter' is pressed & remove from variable using string trim when 'backspace' is pressed.
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



QWERTY(ByRef req, ByRef res) {
Global

;SetPaths
keys = Q,W,E,R,T,Y,U,I,O,P,A,S,D,F,G,H,J,K,L,Z,X,C,V,B,N,M,ENTER,SPACE,BACKSPACE
Loop, Parse, keys, `,	;load the path for all keys
{
loopPath=/%A_LoopField%
paths[loopPath] := Func(A_LoopField)
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
  font-size: 20px;
}

h1 {
	padding: 20px; width: auto; font-family: Sans-Serif; font-size: 22pt;
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
`%InputFeedBack`%
</h1>

<p>
<a href="/Q"> <button> Q </button> </a> 
<a href="/W"> <button> W </button> </a> 
<a href="/E"> <button> E </button> </a> 
<a href="/R"> <button> R </button> </a> 
<a href="/T"> <button> T </button> </a> 
<a href="/Y"> <button> Y </button> </a> 
<a href="/U"> <button> U </button> </a> 
<a href="/I"> <button> I </button> </a> 
<a href="/O"> <button> O </button> </a> 
<a href="/P"> <button> P </button> </a> 
</p>

<p>
<a href="/A"> <button> A </button> </a> 
<a href="/S"> <button> S </button> </a> 
<a href="/D"> <button> D </button> </a> 
<a href="/F"> <button> F </button> </a> 
<a href="/G"> <button> G </button> </a> 
<a href="/H"> <button> H </button> </a> 
<a href="/J"> <button> J </button> </a> 
<a href="/K"> <button> K </button> </a> 
<a href="/L"> <button> L </button> </a> 
</p>

<p>
<a href="/Z"> <button> Z </button> </a> 
<a href="/X"> <button> X </button> </a> 
<a href="/C"> <button> C </button> </a> 
<a href="/V"> <button> V </button> </a> 
<a href="/B"> <button> B </button> </a> 
<a href="/N"> <button> N </button> </a> 
<a href="/M"> <button> M </button> </a> 
</p>

<p>
<a href="/ENTER"> <button> ENTER </button> </a> 
<a href="/SPACE"> <button> SPACE </button> </a> 
<a href="/BACKSPACE"> <button> BACKSPACE </button> </a> 
</p>

</body>
</html>
)

    res.SetBodyText(QWERTY_html)
    res.status := 200
}


QWERTY_exec:
if InputFeedBack
{
SetTimer, QWERTY_exec, off
StringSplit, InputFeedBack_array, InputFeedBack, %A_Space%	;split input string by space to find any file that has all the substrings of the input string, i.e if 'meg myers' was input,it will look for files with 'meg' & 'myers',instead of just a 'meg myers',which should allow getting more matches.
	;Build Playlist
;playlistTemplate - file format '.pls'
/*
[playlist]
File1=C:\CROSSBOW\#youTubeDLDownloads\Uploads from ARMA2official\30 - Arma 2 - DevDiary - No.1 Basic Controls.mp4
Title1=30 - Arma 2 - DevDiary - No.1 Basic Controls.mp4
NumberOfEntries=1
Version=2
*/
PLS_playlist .= "[playlist]`n"
Loop, 5
	{
	this_folder = folder%A_Index%folder	;cycle through provided media folder paths.
	Loop, %this_folder%\*.*, , 1	;recurse into provided media folder
		{
		if (InputFeedBack_array0=1)	;if single string was provided
			{
			if A_LoopFileFullPath contains %InputFeedBack1%
				{
				entry++	;increment playlist entry numbering,for every new entry this is incremented.
				this_PLSentry=File%entry%
				SplitPath, A_LoopFileFullPath, OutFileName
				PLS_playlist .= "File" entry "=" A_LoopFileFullPath "`n"
				PLS_playlist .= "Title" entry "=" OutFileName "`n"
				}
			}
		if (InputFeedBack_array0=2)	;if two strings were provided
			{
			if A_LoopFileFullPath contains %InputFeedBack1%,%InputFeedBack2%
				{
				entry++	;increment playlist entry numbering,for every new entry this is incremented.
				this_PLSentry=File%entry%
				SplitPath, A_LoopFileFullPath, OutFileName
				PLS_playlist .= "File" entry "=" A_LoopFileFullPath "`n"
				PLS_playlist .= "Title" entry "=" OutFileName "`n"
				}
			}
		if (InputFeedBack_array0=3)	;if three strings were provided
			{
			if A_LoopFileFullPath contains %InputFeedBack1%,%InputFeedBack2%,%InputFeedBack3%
				{
				entry++	;increment playlist entry numbering,for every new entry this is incremented.
				this_PLSentry=File%entry%
				SplitPath, A_LoopFileFullPath, OutFileName
				PLS_playlist .= "File" entry "=" A_LoopFileFullPath "`n"
				PLS_playlist .= "Title" entry "=" OutFileName "`n"
				}
			}
		if (InputFeedBack_array0>3)	;if more than three strings were provided treat them as if a single string was provided
			{
			if A_LoopFileFullPath contains %InputFeedBack1%
				{
				entry++	;increment playlist entry numbering,for every new entry this is incremented.
				this_PLSentry=File%entry%
				SplitPath, A_LoopFileFullPath, OutFileName
				PLS_playlist .= "File" entry "=" A_LoopFileFullPath "`n"
				PLS_playlist .= "Title" entry "=" OutFileName "`n"
				}
			}
		}
	}
PLS_playlist .= "NumberOfEntries=" entry "`nVersion=2"
if entry	;if at least one media file was matched and added to playlist,append playlist to file and run it with VLC.
{
FileDelete, %A_Temp%\Tmp_MRC.pls
FileAppend, %PLS_playlist%, %A_Temp%\Tmp_MRC.pls
Run, %vlc% %A_Temp%\Tmp_MRC.pls
}
InputFeedBack=""	;reset InputFeedBack after input string has been used.
}
Return



