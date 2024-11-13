@echo off

if "%2"=="" (
	set hashFunct=SHA256
) else (
	set hashFunct=%2
)

if "%hashFunct%"=="MD2" goto begin
if "%hashFunct%"=="MD4" goto begin
if "%hashFunct%"=="MD5" goto begin
if "%hashFunct%"=="SHA1" goto begin
if "%hashFunct%"=="SHA256" goto begin
if "%hashFunct%"=="SHA384" goto begin
if "%hashFunct%"=="SHA512" goto begin
if "%hashFunct%"=="SHA512" goto begin

goto error

:begin
echo Begin Scan Directory: %1 ...
echo "FilePath","FileName","%hashFunct%">ScanHashResult.csv
for /r %1\ %%i in (*.*) do (
	echo Scan File Hash^(%hashFunct%^): %%i ...
	for /f "skip=1 tokens=1" %%j in ('certutil -hashfile "%%i" %hashFunct%') do (
		if not "%%j"=="CertUtil:" echo "%%~dpi","%%~nxi","%%j">>ScanHashResult.csv
	)
)
echo Out Result: ScanHashResult.csv.
echo End Scan.

exit /B 0

:error
echo Unkown Hash Function: %2.
exit /B 1
