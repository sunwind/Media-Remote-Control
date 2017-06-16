#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

script=KeyBoard.ahk

keys1 = Q,W,E,R,T,Y,U,I,O,P
keys2 = A,S,D,F,G,H,J,K,L
keys3 = Z,X,C,V,B,N,M
keysFuncional = SPACE,ENTER,BACKSPACE

;generate buttons
FileAppend,	;html start
(
KB_html =
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


), %script%


FileAppend, <p> `n
Loop, Parse, keys1, `,
{
<a href="/%A_LoopField%"> <button> %A_LoopField% </button> </a>
}
</p> 

Loop, Parse, keys2, `,
{

}

Loop, Parse, keys3, `,
{

}

Loop, Parse, keysFuncional, `,
{

}

FileAppend,	;html close
(
</body>
</html>
), %script%


;generate paths
Loop, Parse, keys1, `,
{

}

Loop, Parse, keys2, `,
{

}

Loop, Parse, keys3, `,
{

}

Loop, Parse, keysFuncional, `,
{

}


;generate functions
Loop, Parse, keys1, `,
{

}

Loop, Parse, keys2, `,
{

}

Loop, Parse, keys3, `,
{

}

Loop, Parse, keysFuncional, `,
{

}
