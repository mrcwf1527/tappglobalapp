@echo off
setlocal

REM Load environment variables from .env
for /f "tokens=*" %%a in (.env) do set %%a

REM Build with variables
flutter build web ^
--dart-define=FIREBASE_API_KEY_WEB=%FIREBASE_API_KEY_WEB% ^
--dart-define=AWS_ACCESS_KEY_ID=%AWS_ACCESS_KEY_ID% ^
--dart-define=AWS_SECRET_ACCESS_KEY=%AWS_SECRET_ACCESS_KEY% ^
--dart-define=AWS_REGION=%AWS_REGION% ^
--dart-define=AWS_BUCKET=%AWS_BUCKET% ^
--dart-define=AWS_DOMAIN=%AWS_DOMAIN%

REM Deploy
firebase deploy

echo Deployment complete!