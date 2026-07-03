# Guardião de token FI Group → Tsuru

Mantém a integração do Tsuru com o portal da FI (LeidoBem) **viva sem intervenção**.
O token da FI expira a cada ~1h; este guardião renova sozinho e entrega ao Tsuru.

## Como funciona
- Abre o portal da FI num **perfil de navegador persistente** (guarda a sessão).
- Enquanto a sessão do login da FI estiver viva (dura **dias/semanas**), o token
  se renova **sem 2FA** — o guardião só lê o token novo e manda pro Tsuru.
- Quando a sessão da FI finalmente expira, o guardião avisa (no log e o Tsuru
  notifica os admins). Aí você faz **1 login manual** e volta a rodar sozinho.

## Setup (uma vez)
1. **Bootstrap do login** — dê 2 cliques em **`login.cmd`** (ou rode `node keeper.js login`).
   Abre uma janela do navegador. **Faça login na FI** (projetos@bellube.com.br +
   senha + o código que chega no e-mail). Quando aparecer *"OK: token renovado"*, feche.
2. **Agendamento** — já registrado na Tarefa Agendada do Windows (`FIGroupKeeper`,
   a cada 30 min). Para conferir: `schtasks /query /tn FIGroupKeeper`.

## Rodar na mão
- Renovar agora (silencioso): **`refresh.cmd`** ou `node keeper.js`
- Refazer login (se a sessão expirou): **`login.cmd`** ou `node keeper.js login`

## Arquivos
- `keeper.js` — o guardião. `config.json` — URL do Tsuru + token de API + pasta do perfil.
- `keeper.log` — histórico de execuções. `profile/` — sessão do navegador (NÃO apagar).

## Config (`config.json`)
- `tsuruUrl` — base do Tsuru (produção: http://136.248.107.175)
- `tsuruApiToken` — api_token de um usuário admin do Tsuru
- `profileDir` — pasta do perfil persistente do navegador
