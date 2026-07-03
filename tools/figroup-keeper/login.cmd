@echo off
REM Bootstrap: abre uma janela do navegador para você logar UMA vez na FI.
REM Assim que logar (usuario + senha + codigo do e-mail), ele entrega o token e fecha.
cd /d X:\figroup-keeper
node keeper.js login
echo.
echo Se apareceu "OK: token renovado", o guardiao esta configurado.
pause
