// Guardião de token FI Group (LeidoBem) para o Tsuru.
//
// Mantém a integração viva: abre o portal da FI num perfil persistente, deixa a
// sessão do IdentityServer renovar o token silenciosamente (sem 2FA), lê o token
// novo do sessionStorage e entrega ao Tsuru via API. Roda de tempos em tempos
// pela Agendador de Tarefas do Windows.
//
// Uso:
//   node keeper.js login     -> abre janela VISÍVEL; você loga UMA vez (usuário+senha+OTP).
//                               Assim que logar, ele já entrega o token e fecha.
//   node keeper.js           -> modo silencioso (headless): renova e entrega. É o do agendador.
//
// Config em config.json (mesma pasta): { tsuruUrl, tsuruApiToken, profileDir }

const path = require("path");
const fs = require("fs");
const { chromium } = require("playwright");

const CFG = JSON.parse(fs.readFileSync(path.join(__dirname, "config.json"), "utf8"));
const APP_URL = "https://app.leidobem.com/ldb/bypass";
const SS_KEY = "YXBwLmxkbS5maWdyb3Vw"; // base64 de "app.ldm.figroup"

function log(msg) {
  const line = `[${new Date().toISOString()}] ${msg}`;
  console.log(line);
  try { fs.appendFileSync(path.join(__dirname, "keeper.log"), line + "\n"); } catch (_) {}
}

function jwtExpSec(token) {
  try {
    const p = JSON.parse(Buffer.from(token.split(".")[1], "base64").toString("utf8"));
    return p.exp || null;
  } catch (_) { return null; }
}

async function readToken(page) {
  return await page.evaluate((key) => {
    try {
      const raw = sessionStorage.getItem(key);
      if (!raw) return null;
      const obj = JSON.parse(decodeURIComponent(escape(atob(raw))));
      return obj.access_token || null;
    } catch (e) { return null; }
  }, SS_KEY);
}

// Espera um token válido (exp com folga) aparecer, recarregando no meio do caminho.
async function waitForToken(page, { tries, intervalMs, reloadAt }) {
  for (let i = 0; i < tries; i++) {
    const t = await readToken(page);
    const exp = t && jwtExpSec(t);
    if (t && exp && exp * 1000 - Date.now() > 120000) return t; // >2min de folga
    if (i === reloadAt) { try { await page.reload({ waitUntil: "networkidle", timeout: 45000 }); } catch (_) {} }
    await page.waitForTimeout(intervalMs);
  }
  return null;
}

async function postToTsuru(token) {
  const res = await fetch(`${CFG.tsuruUrl}/api/v1/admin/figroup/refresh_token`, {
    method: "POST",
    headers: { Authorization: `Bearer ${CFG.tsuruApiToken}`, "Content-Type": "application/json" },
    body: JSON.stringify({ token }),
  });
  return { status: res.status, body: await res.text() };
}

(async () => {
  const mode = process.argv[2] === "login" ? "login" : "refresh";
  const headless = mode !== "login";
  const profileDir = CFG.profileDir || path.join(__dirname, "profile");

  log(`iniciando modo=${mode} headless=${headless}`);
  const ctx = await chromium.launchPersistentContext(profileDir, {
    headless,
    args: ["--no-sandbox"],
    viewport: { width: 1280, height: 900 },
  });
  const page = ctx.pages()[0] || (await ctx.newPage());

  try {
    await page.goto(APP_URL, { waitUntil: "networkidle", timeout: 60000 }).catch(() => {});

    let token;
    if (mode === "login") {
      log("FAÇA LOGIN na janela aberta (usuário + senha + código do e-mail). Aguardando até 5 min...");
      token = await waitForToken(page, { tries: 100, intervalMs: 3000, reloadAt: -1 });
    } else {
      token = await waitForToken(page, { tries: 16, intervalMs: 2500, reloadAt: 4 });
    }

    if (!token) {
      log("FALHA: nenhum token válido obtido — a sessão da FI provavelmente expirou. Rode: node keeper.js login");
      await ctx.close();
      process.exit(2);
    }

    const secs = Math.round(jwtExpSec(token) - Date.now() / 1000);
    const r = await postToTsuru(token);
    if (r.status === 200) {
      log(`OK: token renovado (expira em ~${secs}s) e entregue ao Tsuru. Resposta: ${r.body}`);
      await ctx.close();
      process.exit(0);
    } else {
      log(`ERRO ao entregar no Tsuru: HTTP ${r.status} ${r.body}`);
      await ctx.close();
      process.exit(3);
    }
  } catch (e) {
    log("ERRO inesperado: " + e.message);
    try { await ctx.close(); } catch (_) {}
    process.exit(1);
  }
})();
