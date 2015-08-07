@echo off
echo bcpdfcrop-multi v0.0.2 (2015-08-08) written by Hironobu YAMASHITA
setlocal
set BATDIR=%~dp0
set BATNAME=%~n0
set PATH=%PATH%;%BATDIR%
if "%~n1"=="" (
  echo Drag and drop PDF files onto this %BATNAME%.bat.
  echo You will get cropped PDF files [bcpdfcrop.bat is required].
  echo Press [Enter] to exit.
  pause 1>nul
  exit /B
)
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
  )
  set /A FILENUM+=1
)
echo ==^> %FILESUCCESS% out of %FILENUM% files are processed by bcpdfcrop.
