@echo off
echo bcpdfcrop v0.3.5 (2016-01-17) written by Hironobu YAMASHITA
setlocal enabledelayedexpansion
rem ====================================================================
rem You can set program names in this section.
rem Default values are "pdftex", "extractbb", "rungs" respectively.
rem Maybe useful when using "gswin32c" or "gswin64c" instead of "rungs".
rem  e.g. To set full-path for Ghostscript win32 executable:
rem    set GSCMD=C:\Program Files (x86)\gs\gs9.16\bin\gswin32c.exe
set PDFTEXCMD=
set XBBCMD=
set GSCMD=
rem ====================================================================
set BATNAME=%~n0
set BCERROR=0
set BCWARN=0
if "%PDFTEXCMD%"=="" set PDFTEXCMD=pdftex.exe
if "%XBBCMD%"=="" set XBBCMD=extractbb.exe
if "%GSCMD%"=="" set GSCMD=rungs.exe
for %%f in ("%PDFTEXCMD%","%XBBCMD%","%GSCMD%") do (
  if "%%~$PATH:f"=="" (
    echo %%f not found. 1>&2
    set BCERROR=1
  )
)
if %BCERROR% equ 1 (
  echo Programs listed above are necessary for %BATNAME%. 1>&2
  echo Make sure that they can be found in PATH, or give me full-path for them. 1>&2
  exit /B
)
set OPTIONEND=0
set DEBUGLEV=0
set BBOX=BoundingBox
set SEPARATE=0
set MARGINTRUE=0
for %%f in (%*) do (
  if !OPTIONEND! equ 0 (
    set TEMPARG=%%~f
    if "!TEMPARG:~0,1!"=="/" (
      if !MARGINTRUE! equ 1 (
        echo Invalid format for option /m. 1>&2
        set MARGINTRUE=0
      )
      if /I "!TEMPARG!"=="/d" (
        set DEBUGLEV=1
        shift
      ) else (
        if /I "!TEMPARG!"=="/h" (
          set BBOX=HiResBoundingBox
          shift
        ) else (
          if /I "!TEMPARG!"=="/s" (
            set SEPARATE=1
            shift
          ) else (
            if /I "!TEMPARG!"=="/m" (
              set MARGINTRUE=1
              shift
            ) else (
              echo Unknown option: "!TEMPARG!" 1>&2
              shift
            )
          )
        )
      )
    ) else (
      if !MARGINTRUE! equ 1 (
        set MARGINS=%%~f
        if "!MARGINS!"=="" echo Invalid format for option /m. 1>&2
        for /F "tokens=1-4 delims= " %%k in ("!MARGINS!") do (
          set LMARGIN=%%k
          set TMARGIN=%%l
          set RMARGIN=%%m
          set BMARGIN=%%n
        )
        if "!LMARGIN!"=="" set LMARGIN=0
        if "!TMARGIN!"=="" set TMARGIN=!LMARGIN!
        if "!RMARGIN!"=="" set RMARGIN=!LMARGIN!
        if "!BMARGIN!"=="" set BMARGIN=!TMARGIN!
        set MARGINTRUE=0
        shift
      ) else (
        set OPTIONEND=1
      )
    )
  )
)
set FROMDIR=%~dp1
set FROM=%~n1
set FROMEXT=%~x1
set TODIR=%~dp2
set TO=%~n2
set TOEXT=%~x2
set RANGE=%~3
set TPX=_bcpc
set CROPTEMP=_croptemp
if "%FROM%"=="" (
  echo Usage: %BATNAME% [^<options^>] in.pdf [out.pdf] [^<additional arguments^>]
  echo   Options:
  echo     /d      Do NOT delete temporary files for debug.       ^(default: false^)
  echo     /h      Use HiResBoundingBox instead of BoundingBox.   ^(default: false^)
  echo     /s      Save multipage PDF into separate PDF files.    ^(default: false^)
  echo     /m "<left> <top> <right> <bottom>"                 ^(default: "0 0 0 0"^)
  echo             Add extra margins, unit is bp. If only one number is given,
  echo             then it is used for all margins. In the case of two numbers,
  echo             they are also used for right and bottom.
  echo   Additional arguments:
  echo     #3      Specify page range to be processed.              ^(default: all^)
  echo               "3-10" : from page 3 to page 10
  echo               "3-*"  : from page 3 to the last page
  echo               "*-10" : from the first page to page 10
  echo               "*-*"  : all pages
  echo               "*"    : all pages
  echo               "3"    : only page 3
  echo   Notice: margins can be specified using additional arguments #4-#7,
  echo           and these specifications supersedes for backward compatibility.
  exit /B
)
if "%FROMEXT%"=="" set FROMEXT=.pdf
if /I not "%FROMEXT%"==".pdf" echo Input file should be a PDF file, using ".pdf" instead. 1>&2
if not exist "%FROMDIR%%FROM%.pdf" (
  echo Input file "%FROMDIR%%FROM%.pdf" not found. 1>&2
  exit /B
)
if not "%TEMP%"=="" cd /D "%TEMP%"
if "%TOEXT%"=="" set TOEXT=.pdf
if /I not "%TOEXT%"==".pdf" echo Output file should be a PDF file, using ".pdf" instead. 1>&2
if "%TO%"=="" set TO=%FROM%-crop
if "%TODIR%"=="" set TODIR=%FROMDIR%
if "%TODIR%%TO%"=="%FROMDIR%%FROM%" set TO=%FROM%-crop
copy "%FROMDIR%%FROM%.pdf" "%CROPTEMP%.pdf" 1>nul
if exist "%CROPTEMP%.xbb" del "%CROPTEMP%.xbb"
set NUM=1
set VERSION=4
"%XBBCMD%" "%CROPTEMP%.pdf"
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
if "%LAST%"=="" (
  if "%RANGE%"=="" (
    set LAST=%NUM%
  ) else (
    set LAST=%FIRST%
  )
)
if "%FIRST%"=="*" set FIRST=1
if "%LAST%"=="*" set LAST=%NUM%
if %FIRST% lss 1 (
  echo Invalid page number, should be ^>= 1. 1>&2
  set FIRST=1
)
if %LAST% gtr %NUM% (
  echo Page %LAST% does not exist, should be ^<= %NUM%. 1>&2
  set LAST=%NUM%
)
if not "%~4"=="" set LMARGIN=%~4
if not "%~5"=="" set TMARGIN=%~5
if not "%~6"=="" set RMARGIN=%~6
if not "%~7"=="" set BMARGIN=%~7
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
echo \def\procinclude#1 {\pdfhorigin0bp \pdfvorigin0bp >>%TPX%n.tex
echo \setbox0=\hbox{\pdfximage page #1 mediabox{%CROPTEMP%.pdf}\pdfrefximage\pdflastximage} >>%TPX%n.tex
echo \pdfpagewidth\wd0\relax \pdfpageheight\dimexpr\ht0+\dp0\relax \shipout\hbox{\raise\dp0\box0\relax}} >>%TPX%n.tex
for /L %%i in (%FIRST%,1,%LAST%) do (
  "%GSCMD%" -dBATCH -dNOPAUSE -q -sDEVICE=bbox -dFirstPage=%%i -dLastPage=%%i "%CROPTEMP%.pdf" 2>%TPX%%%i.txt
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
  if "!PROCBBOX!"=="0 0 0 0" (
    set VALIDBOX=0
  ) else (
    if "!PROCBBOX!"=="0.000000 0.000000 0.000000 0.000000" (
      set VALIDBOX=0
    ) else (
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
    "%PDFTEXCMD%" -no-shell-escape -interaction=batchmode %TPX%%%i.tex 1>nul
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
  "%PDFTEXCMD%" -no-shell-escape -interaction=batchmode %TPX%n.tex 1>nul
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
