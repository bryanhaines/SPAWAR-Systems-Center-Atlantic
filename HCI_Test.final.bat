::HCI Test.bat
::This script can configure a computer to communicate with devices on an
::internal network, and perform connectivity tests by pinging user identified
::devices.
::v1.0, Bryan J. Haines, SSC LANT, 21 Jun 18

::Software Disclaimer
::"This software was developed at SPAWAR Systems Center Atlantic by employees of 
::the Federal Government in the course of their official duties. Pursuant to 
::17 USC 105 this software is not subject to copyright protection and is in the 
::public domain. The Government assumes no responsibility whatsoever for its use
::by other parties, and the software is provided "AS IS" without warranty or 
::guarantee of any kind, express or implied about its quality, reliability, or 
::any other characteristic. In no event shall the Government be liable for any 
::claim, damages or other liability, whether in an action of contract, tort or 
::other dealings in the software. The Government has no obligation hereunder to 
::provide maintenance, support, updates, enhancements, or modifications. This 
::software can be redistributed and/or modified freely provided that any 
::derivative works bear some notice that they are derived from it, and any 
::modified versions bear some notice that they have been modified." 
 


@ECHO OFF

SETLOCAL EnableDelayedExpansion

:initialInput
ECHO This script can configure a computer to communicate with devices and "ping" devices identified by the user.
SET userInput=""
SET /P userInput=Do you wish to view this computers' IP configuration? (Y/n)
ECHO.

::Check user input
IF /I "%userInput%"=="y" GOTO :viewConfig
IF /I "%userInput%"=="n" GOTO :setIpPrefix
ECHO Invalid input & ECHO.
GOTO :initialInput

:viewConfig
::Displays the computers IP settings
ipconfig & ECHO.

:configVerify
SET userInput=""
SET /P userInput=Are these settings correct? (Y/n, or enter "x" to exit)
ECHO.

::Check users input
IF /I "%userInput%"=="x" GOTO :endOfScript
IF /I "%userInput%"=="y" GOTO :setIpPrefix
IF /I "%userInput%"=="n" GOTO :confirmIp
ECHO Invalid input & ECHO.
GOTO :configVerify

:confirmIp
ECHO The default values are:
SET hciIp="192.168.10.100"
SET subnetMaskIp="255.255.255.0"
SET gatewayIp="192.168.10.0"
ECHO Default IP Address: !hciIp!
ECHO Default Subnet Mask: !subnetMaskIp!
ECHO Default Gateway: !gatewayIp! & ECHO.
SET userInput=""
SET /P userInput=Are these the adresses you want to use? (Y/n, or enter "x" to exit)
ECHO.

::Check users input
IF /I "%userInput%"=="x" GOTO :endOfScript
IF /I "%userInput%"=="y" GOTO :setConfig
IF /I "%userInput%"=="n" GOTO :customIP
ECHO Invalid input & ECHO.
GOTO :confirmIp

:customIP
START ncpa.cpl
ECHO Make your changes in the "Network Connections" window, and then 
PAUSE
GOTO :viewConfig

:setConfig
::Sets the computers IP configurations to the default values.
ECHO Setting IP configuration
::If the line below fails to alter the IP, comment it out and uncomment the second line down.
netsh interface ip set address name="Local Area Connection" static %hciIp% %subnetMaskIp% %gatewayIp%
::netsh interface ipv4 set address name="Local Area Connection" static %hciIp% %subnetMaskIp% %gatewayIp%
GOTO :viewConfig

::Parse the ipconfig to get the first three octets of the IP address.
::This will be used in the test device function to perform the ping test.
::Code from https://superuser.com/a/1034600
:setIpPrefix
FOR /F "usebackq tokens=*" %%a in (`ipconfig ^| findstr /i "ipv4"`) DO (
  ::Split on : and get 2nd token
  FOR /F delims^=^:^ tokens^=2 %%b in ('ECHO %%a') DO (
    ::Split on . and get 4 tokens
    FOR /F "tokens=1-4 delims=." %%c in ("%%b") DO (
      SET firstOctet=%%c
      SET secondOctet=%%d
      SET thirdOctet=%%e
      SET fourthOctet=%%f
      ::Strip leading space from first octet
      SET netIpPrefix=!firstOctet:~1!.!secondOctet!.!thirdOctet!.
    )
  )
)
GOTO :getDevice

:getDevice
SET userInput=""
SET /P userInput=Which device would you like to ping? (enter "x" to exit) 

::Check if user input an x to exit
IF /I "%userInput%"=="x" GOTO :endOfScript

::Use REGEX to ensure that the userInput an integer
@ECHO %userInput%|findstr /xr "[1-9][0-9]*$">nul && (
  GOTO :testDevice
) || (
  ECHO. & Please enter a valid integer & ECHO.
  GOTO :getDevice
)

:testDevice
::append userInput to netIpPrefix to complete the IP for device.
ping %netIpPrefix%%userInput%
ECHO.
GOTO :getDevice

:endOfScript
ENDLOCAL
EXIT /B %ERRORLEVEL%