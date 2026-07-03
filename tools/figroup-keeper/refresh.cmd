@echo off
REM Renova o token FI Group e entrega ao Tsuru (modo silencioso/headless).
REM Chamado pela Tarefa Agendada do Windows a cada 30 min.
cd /d X:\figroup-keeper
node keeper.js
