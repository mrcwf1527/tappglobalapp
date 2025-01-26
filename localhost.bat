@echo off
setlocal

REM Load environment variables
for /f "tokens=*" %%a in (.env) do set %%a

REM Run Flutter web app
flutter run -d chrome --web-port 50000 --web-hostname localhost