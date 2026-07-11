@echo off
title UniWamp Cmder
color 0A
set "UNIWAMP_ROOT=D:\ketan\github\uniservernxt\uniwamp"
set "UNIWAMP_DOCROOT=D:\ketan\github\uniservernxt\uniwamp\www"
set "UNIWAMP_MARIADB_BIN=D:\ketan\github\uniservernxt\uniwamp\runtime\mariadb\bin"
set "UNIWAMP_PHP_VERSION=php85"
set "UNIWAMP_NODE_VERSION=node-v22.23.1-win-x64"
set "PHP_HOME=D:\ketan\github\uniservernxt\uniwamp\runtime\php\php85"
set "PHP_BIN=D:\ketan\github\uniservernxt\uniwamp\runtime\php\php85"
set "PATH=D:\ketan\github\uniservernxt\uniwamp\runtime\php\php85;%PATH%"
set "NODE_HOME=D:\ketan\github\uniservernxt\uniwamp\runtime\nodejs\node-v22.23.1-win-x64"
set "NODE_BIN=D:\ketan\github\uniservernxt\uniwamp\runtime\nodejs\node-v22.23.1-win-x64"
set "PATH=D:\ketan\github\uniservernxt\uniwamp\runtime\nodejs\node-v22.23.1-win-x64;%PATH%"
set "PATH=D:\ketan\github\uniservernxt\uniwamp\runtime\mariadb\bin;%PATH%"
echo  PHP: %UNIWAMP_PHP_VERSION%  -  %PHP_HOME%
if "%UNIWAMP_NODE_VERSION%"=="" (
  echo  Node: not selected
) else (
  echo  Node: %UNIWAMP_NODE_VERSION%  -  %NODE_HOME%
)
echo  Working path: %UNIWAMP_DOCROOT%
echo  MariaDB bin: %UNIWAMP_MARIADB_BIN%
echo.
cd /d "D:\ketan\github\uniservernxt\uniwamp\www"
