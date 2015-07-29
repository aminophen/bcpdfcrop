@echo off
echo bcpdfcrop v0.1.2 (2015-07-30) written by @aminophen
set BATNAME=%~n0
set ERROR=0
setlocal enabledelayedexpansion
if /I "%1"=="/d" (
  set DEBUGLEV=1
  shift
) else (
  set DEBUGLEV=0
)
if /I "%1"=="/h" (
  set BBOX=HiResBoundingBox
  shift
) else (
  set BBOX=BoundingBox
)
if /I "%1"=="/s" (
  set SEPARATE=1
  shift
) else (
  set SEPARATE=0
)
set FROMDIR=%~dp1
set FROM=%~n1
set TODIR=%~dp2
set TO=%~n2
set RANGE=%~3
set TPX=_bcpc
set CROPTEMP=_croptemp
if "%FROM%"=="" (
  echo Usage: %BATNAME% [/d] [/h] [/s] in.pdf [out.pdf] [page-range] [left-margin] [top-margin] [right-margin] [bottom-margin]
  echo   Options:
  echo     /d    Do NOT delete temporary files for debug.
  echo     /h    Use HiResBoundingBox instead of BoundingBox.
  echo     /s    Save multipage PDF into separate PDF files.
)
if not exist "%FROMDIR%%FROM%.pdf" exit /B
if not "%TEMP%"=="" cd "%TEMP%"
copy "%FROMDIR%%FROM%.pdf" "%CROPTEMP%.pdf" 1>nul
if "%TO%"=="" set TO=%FROM%-crop
if "%TODIR%"=="" set TODIR=%FROMDIR%
if "%TODIR%%TO%"=="%FROMDIR%%FROM%" set TO=%FROM%-crop
if exist "%TODIR%%TO%.pdf" del "%TODIR%%TO%.pdf"
if exist "%TODIR%%TO%.pdf" exit /B
extractbb "%CROPTEMP%.pdf"
type "%CROPTEMP%.xbb" | find "%%Pages: " > "%CROPTEMP%-pages.txt"
set /P NUM=<"%CROPTEMP%-pages.txt"
set NUM=%NUM:* =%
type "%CROPTEMP%.xbb" | find "%%PDFVersion: " > "%CROPTEMP%-version.txt"
set /P VERSION=<"%CROPTEMP%-version.txt"
set VERSION=%VERSION:*.=%
if %DEBUGLEV% equ 0 del "%CROPTEMP%.xbb" "%CROPTEMP%-pages.txt" "%CROPTEMP%-version.txt"
for /F "tokens=1,2 delims=-" %%m in ("%RANGE%") do (
  set FIRST=%%m
  set LAST=%%n
)
if "%FIRST%"=="" set FIRST=1
if "%FIRST%"=="*" set FIRST=1
if "%LAST%"=="" (
  if "%RANGE%"=="" (
    set LAST=%NUM%
  ) else (
    set LAST=%FIRST%
  )
)
if "%LAST%"=="*" set LAST=%NUM%
if %FIRST% lss 1 (
  echo Invalid page number, should be ^>= 1.
  set FIRST=1
)
if %LAST% gtr %NUM% (
  echo Page %LAST% does not exist, should be ^<= %NUM%.
  set LAST=%NUM%
)
set LMARGIN=%~4
set TMARGIN=%~5
set RMARGIN=%~6
set BMARGIN=%~7
if "%LMARGIN%"=="" set LMARGIN=0
if "%TMARGIN%"=="" set TMARGIN=0
if "%RMARGIN%"=="" set RMARGIN=0
if "%BMARGIN%"=="" set BMARGIN=0
echo \pdfoutput=1 >%TPX%n.tex
echo \pdfminorversion=%VERSION% >>%TPX%n.tex
echo \def\proc #1 [#2 #3 #4 #5]{\pdfhorigin-#2bp \pdfvorigin#3bp \pdfpagewidth\dimexpr#4bp-#2bp\relax \pdfpageheight\dimexpr#5bp-#3bp\relax >>%TPX%n.tex
echo \advance\pdfhorigin by %LMARGIN%bp\relax \advance\pdfpagewidth by %LMARGIN%bp\relax \advance\pdfpagewidth by %RMARGIN%bp\relax >>%TPX%n.tex
echo \advance\pdfvorigin by -%BMARGIN%bp\relax \advance\pdfpageheight by %BMARGIN%bp\relax \advance\pdfpageheight by %TMARGIN%bp\relax >>%TPX%n.tex
echo \setbox0=\hbox{\pdfximage page #1 mediabox{%CROPTEMP%.pdf}\pdfrefximage\pdflastximage} >>%TPX%n.tex
echo \ht0=\pdfpageheight \shipout\box0\relax} >>%TPX%n.tex
for /L %%i in (%FIRST%,1,%LAST%) do (
  rungs -dBATCH -dNOPAUSE -q -sDEVICE=bbox -dFirstPage=%%i -dLastPage=%%i "%CROPTEMP%.pdf" 2>&1 | find "%%%BBOX%: " >%TPX%%%i.txt
  set PROCBBOX=%%%BBOX%: 0 0 0 0
  set /P PROCBBOX=<"%TPX%%%i.txt"
  set PROCBBOX=!PROCBBOX:* =!
  if %SEPARATE% equ 1 (
    echo \input %TPX%n.tex \proc %%i [!PROCBBOX!] \end >%TPX%%%i.tex
    pdftex -no-shell-escape -interaction=batchmode %TPX%%%i.tex 1>nul
    if %DEBUGLEV% equ 0 del %TPX%%%i.tex %TPX%%%i.log
    if exist %TPX%%%i.pdf (
      move "%TPX%%%i.pdf" "%TODIR%%TO%-%%i.pdf" 1>nul
    ) else (
      echo Process of page %%i failed, skipping ...
      set ERROR=1
    )
  ) else (
    echo \proc %%i [!PROCBBOX!] >>%TPX%n.tex
  )
)
if %SEPARATE% equ 0 (
  echo \end >>%TPX%n.tex
  pdftex -no-shell-escape -interaction=batchmode %TPX%n.tex 1>nul
  if %DEBUGLEV% equ 0 del %TPX%n.log
  if exist %TPX%n.pdf (
    move "%TPX%n.pdf" "%TODIR%%TO%.pdf" 1>nul
  ) else (
    echo Process failed.
    set ERROR=1
  )
)
if %DEBUGLEV% equ 0 for /L %%i in (%FIRST%,1,%LAST%) do del %TPX%%%i.txt
if %DEBUGLEV% equ 0 del %TPX%n.tex %CROPTEMP%.pdf
if %ERROR% equ 1 exit /B
echo ==^> %FIRST%-%LAST% page(s) written on "%TODIR%%TO%.pdf".
