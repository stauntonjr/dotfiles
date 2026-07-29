@echo off
REM trust-mcp-srv-ca-windows.sh
REM Adds the mcp-srv CA certificate to the Windows trusted root store
REM Usage: trust-mcp-srv-ca-windows.sh [path-to-ca.crt]

SETLOCAL
set "CA_PATH=%~1"
if "%CA_PATH%"=="" set "CA_PATH=%USERPROFILE%\dotfiles\mcp-srv\ca.crt"

if not exist "%CA_PATH%" (
    echo CA certificate not found at %CA_PATH%
    exit /b 1
)

REM Import the CA into the Local Machine Trusted Root store
REM Requires Administrator privileges
certutil -addstore -f "Root" "%CA_PATH%"
if %ERRORLEVEL%==0 (
    echo CA installed. You may need to restart applications.
) else (
    echo Failed to install CA. Run this script as Administrator.
    exit /b 2
)
ENDLOCAL
