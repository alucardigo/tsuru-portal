#!/usr/bin/env bash
#
# figroup_autosync.sh
# Wrapper de cron para o autosync FI Group <-> Tsuru.
# Chamado pelo cron a cada 10min (ver crontab do usuario bellube.rodrigo.faria).
# Usamos cron (e NAO job runner/ActiveJob) porque em producao nao ha
# SolidQueue nem bin/jobs rodando; agendamento e feito server-side via cron.
#
set -euo pipefail

# flock: evita sobreposicao de execucoes (uma rodada por vez).
exec 9>/tmp/figroup_autosync.lock
flock -n 9 || { echo "[$(date -Is)] already running, exit"; exit 0; }

# Diretorio da app derivado da localizacao do script (script/ -> raiz).
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_DIR"

# Carrega variaveis de ambiente da app (DATABASE_URL, secrets, etc.).
set -a
source "$HOME/tsuru.env"
set +a

export RAILS_ENV=production

echo "[$(date -Is)] figroup_autosync iniciando (APP_DIR=$APP_DIR)"

# Executa o autosync via rbenv/bundler; trigger marcado como "cron".
"$HOME/.rbenv/bin/rbenv" exec bundle exec rails runner \
  'FiGroup::AutoSync.new.call(trigger: "cron")'

echo "[$(date -Is)] figroup_autosync concluido"
