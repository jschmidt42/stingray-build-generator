@ECHO OFF

REM Generate a build from the current HEAD of the Stingray repo
ruby generate-build.rb -r ../stingray -v --zip

REM Pause so the user can look at the latest status
PAUSE
