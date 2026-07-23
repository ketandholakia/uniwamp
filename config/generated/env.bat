@echo off
title UniWamp Cmder
color 0A
set "UNIWAMP_ROOT=D:\ketan\github\uniwamp"
set "UNIWAMP_DOCROOT=D:\ketan\github\vittixCMS"
set "UNIWAMP_MARIADB_BIN=D:\ketan\github\uniwamp\runtime\mariadb\bin"
set "UNIWAMP_PHP_VERSION=php84"
set "PHPRC=D:\ketan\github\uniwamp\config\generated"
set "UNIWAMP_NODE_VERSION=node-v22.23.1-win-x64"
set "PHP_HOME=D:\ketan\github\uniwamp\runtime\php\php84"
set "PHP_BIN=D:\ketan\github\uniwamp\runtime\php\php84"
set "PATH=D:\ketan\github\uniwamp\runtime\php\php84;%PATH%"
set "NODE_HOME=D:\ketan\github\uniwamp\runtime\nodejs\node-v22.23.1-win-x64"
set "NODE_BIN=D:\ketan\github\uniwamp\runtime\nodejs\node-v22.23.1-win-x64"
set "PATH=D:\ketan\github\uniwamp\runtime\nodejs\node-v22.23.1-win-x64;%PATH%"
set "COMPOSER_HOME=D:\ketan\github\uniwamp\runtime\tools\composer"
set "PATH=D:\ketan\github\uniwamp\runtime\tools\composer;%PATH%"
set "GIT_HOME=D:\ketan\github\uniwamp\runtime\tools\git"
set "PATH=D:\ketan\github\uniwamp\runtime\tools\git\cmd;%PATH%"
set "PATH=D:\ketan\github\uniwamp\runtime\mariadb\bin;%PATH%"
echo  PHP: %UNIWAMP_PHP_VERSION%  -  %PHP_HOME%
if "%UNIWAMP_NODE_VERSION%"=="" (
  echo  Node: not selected
) else (
  echo  Node: %UNIWAMP_NODE_VERSION%  -  %NODE_HOME%
)
echo  Composer: %COMPOSER_HOME%
echo  Git: %GIT_HOME%
echo  Working path: %UNIWAMP_DOCROOT%
echo  MariaDB bin: %UNIWAMP_MARIADB_BIN%
echo.
cd /d "D:\ketan\github\vittixCMS"
