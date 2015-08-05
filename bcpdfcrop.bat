@echo off
echo bcpdfcrop v0.2.0 (2015-08-05) written by Hironobu YAMASHITA
setlocal enabledelayedexpansion
rem ====================================================================
rem You can set program names in this section.
rem Default values are "pdftex", "extractbb", "rungs" respectively.
rem Maybe useful when using "gswin32c" or "gswin64c" instead of "rungs".
set PDFTEXCMD=
set XBBCMD=
set GSCMD=
rem ====================================================================
set BATNAME=%~n0
set BCERROR=0
set BCWARN=0
if "%PDFTEXCMD%"=="" set PDFTEXCMD=pdftex
if "%XBBCMD%"=="" set XBBCMD=extractbb
if "%GSCMD%"=="" set GSCMD=rungs
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
  exit /B
)
if not exist "%FROMDIR%%FROM%.pdf" (
  echo Input file "%FROMDIR%%FROM%.pdf" not found. 1>&2
  exit /B
)
if not "%TEMP%"=="" cd /D "%TEMP%"
if "%TO%"=="" set TO=%FROM%-crop
if "%TODIR%"=="" set TODIR=%FROMDIR%
if "%TODIR%%TO%"=="%FROMDIR%%FROM%" set TO=%FROM%-crop
copy "%FROMDIR%%FROM%.pdf" "%CROPTEMP%.pdf" 1>nul
if exist "%CROPTEMP%.xbb" del "%CROPTEMP%.xbb"
set NUM=1
set VERSION=4
%XBBCMD% "%CROPTEMP%.pdf"
if exist "%CROPTEMP%.xbb" (
  type "%CROPTEMP%.xbb" | find "%%Pages: " >%CROPTEMP%-pages.txt
  set /P NUM=<"%CROPTEMP%-pages.txt"
  set NUM=!NUM:* =!
  type "%CROPTEMP%.xbb" | find "%%PDFVersion: " >%CROPTEMP%-version.txt
  set /P VERSION=<"%CROPTEMP%-version.txt"
  set VERSION=!VERSION:*.=!
  if %DEBUGLEV% equ 0 del "%CROPTEMP%.xbb" "%CROPTEMP%-pages.txt" "%CROPTEMP%-version.txt"
) else (
  echo Failed to run extractbb, setting default values... 1>&2
)
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
echo \def\procinclude#1{\pdfhorigin0bp \pdfvorigin0bp >>%TPX%n.tex
echo \setbox0=\hbox{\pdfximage page #1 mediabox{%CROPTEMP%.pdf}\pdfrefximage\pdflastximage} >>%TPX%n.tex
echo \pdfpagewidth\wd0\relax \pdfpageheight\dimexpr\ht0+\dp0\relax \shipout\hbox{\raise\dp0\box0\relax}} >>%TPX%n.tex
for /L %%i in (%FIRST%,1,%LAST%) do (
  %GSCMD% -dBATCH -dNOPAUSE -q -sDEVICE=bbox -dFirstPage=%%i -dLastPage=%%i "%CROPTEMP%.pdf" 2>%TPX%%%i.txt
  type %TPX%%%i.txt | find "%%%BBOX%: " >%TPX%%%i-box.txt
  for %%f in (%TPX%%%i.txt) do set SIZEGS=%%~zf
  for %%f in (%TPX%%%i-box.txt) do set SIZEBOX=%%~zf
  if !SIZEBOX! equ 0 (
    if not !SIZEGS! equ 0 (
      type %TPX%%%i.txt 1>&2
      echo Failed to run Ghostscript, so I cannot crop page %%i. 1>&2
      set BCWARN=2
    )
  )
  set PROCBBOX=%%%BBOX%: 0 0 0 0
  set /P PROCBBOX=<"%TPX%%%i-box.txt"
  set PROCBBOX=!PROCBBOX:* =!
  set VALIDBOX=0
  for /F "tokens=1-4 delims= " %%k in ("!PROCBBOX!") do (
    set LLX=%%k
    set LLY=%%l
    set URX=%%m
    set URY=%%n
  )
  if !LLX! lss !URX! (
    if !LLY! lss !URY! (
      set VALIDBOX=1
    )
  )
  if %SEPARATE% equ 1 (
    if !VALIDBOX! equ 1 (
      echo \input %TPX%n.tex \proc %%i [!PROCBBOX!] \end >%TPX%%%i.tex
    ) else (
      if !BCWARN! neq 2 echo Invalid %BBOX% is returned by Ghostscript on page %%i. 1>&2
      echo I will try to include this page in its original size... 1>&2
      echo \input %TPX%n.tex \procinclude %%i \end >%TPX%%%i.tex
      set BCWARN=1
    )
    %PDFTEXCMD% -no-shell-escape -interaction=batchmode %TPX%%%i.tex 1>nul
    if not exist "%TPX%%%i.log" (
      echo Failed to run pdfTeX, exiting... 1>&2
      if %DEBUGLEV% equ 0 for /L %%j in (%FIRST%,1,%%i) do del "%TPX%%%j.txt" "%TPX%%%j-box.txt" "%TPX%%%j.tex"
      if %DEBUGLEV% equ 0 del "%TPX%n.tex" "%CROPTEMP%.pdf"
      exit /B
    )
    if %DEBUGLEV% equ 0 del "%TPX%%%i.tex" "%TPX%%%i.log"
    if exist "%TPX%%%i.pdf" (
      if exist "%TODIR%%TO%-%%i.pdf" del "%TODIR%%TO%-%%i.pdf"
      if exist "%TODIR%%TO%-%%i.pdf" (
        echo Output file already exists, and cannot be overwritten because it seems to be locked. 1>&2
        set BCERROR=1
        del "%TPX%%%i.pdf"
      ) else (
        move "%TPX%%%i.pdf" "%TODIR%%TO%-%%i.pdf" 1>nul
      )
    ) else (
      echo Process of page %%i failed, skipping... 1>&2
      set BCERROR=1
    )
  ) else (
    if !VALIDBOX! equ 1 (
      echo \proc %%i [!PROCBBOX!] >>%TPX%n.tex
    ) else (
      if !BCWARN! neq 2 echo Invalid %BBOX% is returned by Ghostscript on page %%i. 1>&2
      echo I will try to include this page in its original size... 1>&2
      echo \procinclude %%i >>%TPX%n.tex
      set BCWARN=1
    )
  )
)
if %SEPARATE% equ 0 (
  echo \end >>%TPX%n.tex
  if exist "%TPX%n.log" del "%TPX%n.log"
  %PDFTEXCMD% -no-shell-escape -interaction=batchmode %TPX%n.tex 1>nul
  if not exist "%TPX%n.log" (
    echo Failed to run pdfTeX, exiting... 1>&2
    if %DEBUGLEV% equ 0 for /L %%i in (%FIRST%,1,%LAST%) do del "%TPX%%%i.txt" "%TPX%%%i-box.txt"
    if %DEBUGLEV% equ 0 del "%TPX%n.tex" "%CROPTEMP%.pdf"
    exit /B
  )
  if %DEBUGLEV% equ 0 del "%TPX%n.log"
  if exist "%TPX%n.pdf" (
    if exist "%TODIR%%TO%.pdf" del "%TODIR%%TO%.pdf"
    if exist "%TODIR%%TO%.pdf" (
      echo Output file already exists, and cannot be overwritten because it seems to be locked. 1>&2
      set BCERROR=1
      del "%TPX%n.pdf"
    ) else (
      move "%TPX%n.pdf" "%TODIR%%TO%.pdf" 1>nul
    )
  ) else (
    echo Process failed. 1>&2
    set BCERROR=1
  )
)
if %DEBUGLEV% equ 0 for /L %%i in (%FIRST%,1,%LAST%) do del "%TPX%%%i.txt" "%TPX%%%i-box.txt"
if %DEBUGLEV% equ 0 del "%TPX%n.tex" "%CROPTEMP%.pdf"
if %BCERROR% equ 1 exit /B
echo ==^> %FIRST%-%LAST% page(s) written on "%TODIR%%TO%.pdf".
if %BCWARN% equ 1 echo Some pages may not be cropped, because Ghostscript did not work properly. 1>&2
