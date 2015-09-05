@echo off
echo bcpdfcrop-multi v0.0.3 (2015-09-05) written by Hironobu YAMASHITA
setlocal
set BATDIR=%~dp0
set BATNAME=%~n0
set BCERROR=0
set BCWARN=0
set PATH=%PATH%;%BATDIR%
if "%~n1"=="" (
  echo Drag and drop PDF files onto this %BATNAME%.bat.
  echo You will get cropped PDF files [bcpdfcrop.bat is required].
)
for %%f in (bcpdfcrop.bat) do (
  if "%%~$PATH:f"=="" (
    echo Error: bcpdfcrop not found. 1>&2
    set BCERROR=1
  )
)
if "%~n1"=="" (
  echo Press [Enter] to exit.
  pause 1>nul
  exit /B
)
if %BCERROR% equ 1 exit /B
set FILENUM=0
set FILESUCCESS=0
for %%f in (%*) do (
  echo Processing "%%~dpnxf".
  call bcpdfcrop "%%~dpnxf" 1>nul
  if exist "%%~dpnf-crop.pdf" (
    set /A FILESUCCESS+=1
  ) else (
    echo Process failed. 1>&2
    echo Press [Enter] to continue. 1>&2
    pause 1>nul
    set BCWARN=1
  )
  set /A FILENUM+=1
)
echo ==^> %FILESUCCESS% out of %FILENUM% files are processed by bcpdfcrop.
if %BCWARN% equ 0 exit /B
echo Some files could not be cropped. Please read error messages printed above. 1>&2
echo Press [Enter] to continue. 1>&2
pause 1>nul
