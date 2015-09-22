@echo off
cls
set "toolspath=%~dp0tools\"
PATH %toolspath%;%PATH%
:LOOP
set filesmas=
if %1==-brute (
	set max="true"
	shift
	goto LOOP
)
set file="%~f1"
set filesize=%~z1
set filetype=%~x1

if (%filesize%) EQU 0 (
	echo no such file: %file%
	goto ENDLOOP
)
set isjpg=0
if /i %filetype%==.jpg  set isjpg=1
if /i %filetype%==.jpeg  set isjpg=1
if /i %filetype%==.jpe  set isjpg=1

echo.
echo ######Processing %file% of filetype %filetype% with filesize=%filesize%
echo.

if /i not %filetype%==.png goto END-PNG-ONLY
echo ######Starting Extreme. Non-interlaced; changing ColorType and BitDepth; Dirty Transparency.
set "kp="
set tmpfile="%~f1-extreme.png"
truepng -i0 -zc8-9 -zm3-9 -zs0-3 -fe -fs:7 -a1 -y -force -out %tmpfile%  "%~f1"
for /f "tokens=2 delims=/f " %%j in ('pngout -l %tmpfile%') do (	set filter=%%j	)
if %filter% neq "0" set "kp=-kp"
for %%i in (%tmpfile%) do set size1=%%~zi
pngout -s3 -k1 -y %tmpfile%
for %%i in (%tmpfile%) do set size2=%%~zi
if %size1% NEQ %size2% (for /l %%j in (1,1,8) do pngout -s3 -k1 -y -n%%j %tmpfile%) else (pngout -s0 -f6 -y -k1 -ks %kp% %tmpfile%)
advdef -z4 %tmpfile%
set filesmas=%filesmas% %tmpfile%
echo ######Ended Extreme
echo.
:END-PNG-ONLY

if %isjpg%==1  goto END-NO-JPG 
echo ######Starting pngOut script
set tmpfile="%~f1-pngOut.png"
If (%max%)==("true") set verbose=/v
pngout %verbose% /y "%~f1" %tmpfile%
set filesmas=%filesmas% %tmpfile%
echo ######Ended pngOut
echo.
:END-NO-JPG

if %isjpg%==0 goto END-JPG-ONLY
echo ######Starting Losslessly JPG script
set tmpfile="%~f1-pngOut-jpg-grayscale.png"
pngout -q -s4 -c0 "%~f1" %tmpfile%
if ERRORLEVEL 1 goto Losslessly-noGrayScale
set filesmas=%filesmas% %tmpfile%
set tmpfile="%~f1-jpegtran-grayscale%filetype%"
jpegtran -grayscale -optimize "%~f1" %tmpfile%
jscl -r -j -cp %tmpfile%
set filesmas=%filesmas% %tmpfile%
set tmpfile="%~f1-jpegtran-grayscale-progressive%filetype%"
jpegtran -grayscale -optimize -progressive "%~f1" %tmpfile%
jscl -r -j -cp %tmpfile%
set filesmas=%filesmas% %tmpfile%
If not (%max%)==("true") goto end-Losslessly-noGrayScale
:Losslessly-noGrayScale
set tmpfile="%~f1-jpegtran%filetype%"
jpegtran -optimize "%~f1" %tmpfile%
jscl -r -j -cp %tmpfile%
set filesmas=%filesmas% %tmpfile%
set tmpfile="%~f1-jpegtran-progressive%filetype%"
jpegtran -optimize -progressive "%~f1" %tmpfile%
jscl -r -j -cp %tmpfile%
set filesmas=%filesmas% %tmpfile%
:end-Losslessly-noGrayScale
echo ######Ended Losslessly JPG
:END-JPG-ONLY

if /i not %filetype%==.gif goto END-GIF-ONLY
echo ######Starting GIFSicle.
set tmpfile="%~f1-GIFSicle.gif"
gifsicle -O2 -v -w -o %tmpfile% "%~f1"
::set filesmas=%filesmas% %tmpfile%
echo ######Ended GIFSicle
echo.
:END-GIF-ONLY

If not (%max%)==("true") goto ENDADDITIONAL
if not %filetype%==.png goto END-PNG-ONLY2
echo ######Starting truepng. Non-interlaced
set tmpfile="%~f1-truepng.png"
truepng -i0 -zc9 -zm8-9 -zs0-1 -f0,5 -fs:7  -a0 -y -force -out %tmpfile% "%~f1"
advdef -z4 %tmpfile%
set filesmas=%filesmas% %tmpfile%
echo ######Ended truepng
echo.
:END-PNG-ONLY2

echo ######Starting pngcrush-brute script
set tmpfile="%~f1-pngcrush-brute.png"
If (%max%)==("true") set verbose=-v
pngcrush.exe -rem alla %verbose% -rem text -brute -force %file% %tmpfile%
set filesmas=%filesmas% %tmpfile%
echo ######Ended pngcrush-brute
echo.

echo ######Starting OptiPNG script
set tmpfile="%~f1-OptiPNG.png"
If (%max%)==("true") set verbose=-v
optipng %verbose% -clobber -out=%tmpfile% %file%
set filesmas=%filesmas% %tmpfile%
echo ######Ended OptiPNG
echo.

if %isjpg%==0 goto END-JPG-ONLY2
echo ######Starting Optimization JPG script
set tmpfile="%~f1-jpegoptim-90loss%filetype%"
set tmpfile2="%~f1-jpegoptim-90loss-progressive%filetype%"
copy /b /y "%~f1" %tmpfile% 1>nul 2>nul
jpegoptim -v -o -m90 %tmpfile%
jpegtran -optimize -progressive %tmpfile% %tmpfile2%
jscl -r -j -cp %tmpfile2%
set filesmas=%filesmas% %tmpfile2%
jpegtran -optimize %tmpfile% %tmpfile%
jscl -r -j -cp %tmpfile%
set filesmas=%filesmas% %tmpfile%
echo ######Ended Optimization JPG
:END-JPG-ONLY2

:ENDADDITIONAL

If (%max%)==("true") goto ENDLOOP
set filesizetmp=%filesize%
set /a prc=100
for %%I in (%filesmas%) do (
		IF EXIST %%I (
			echo Checking %%I of size %%~zI 
			if %%~zI GTR %filesizetmp%	(
				del %%I
				echo deleting nah %%I %%~zI
				) ELSE (
				set asd=%%~zI
				set /a prc = 100*asd/filesize
				for %%E in (%filesmas%) do (
					IF EXIST %%E (
						if not %%E==%%I (
							if %%~zE GEQ %%~zI (
								del %%E
								echo deleting  %%E %%~zE
								set filesizetmp=%%~zI
								)
							)	
						)
					)
				)
		) ELSE (
			echo %%I is missing.
		)
	)
echo.
echo Best filesize=%filesizetmp%  ( %prc%%% of original)
if (%prc%)==(100) echo There is no better smashing method for this picture. You can try  -brute option for additional methods.
:ENDLOOP
shift
if not (%1)==() goto LOOP
echo Please always check smashed pictures. If some corruptions detected you can try  -brute option and pick correct picture.
PAUSE

exit /b
