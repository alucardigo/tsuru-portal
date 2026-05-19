# OCI Provisioning — Portal Tsuru

> Checklist de provisionamento manual no Oracle Cloud Infrastructure.
> Executado por Rodrigo de Souza Faria.

---

## Especificações da VM (Task 0.1)

| Recurso | Especificação |
|---|---|
| Shape | VM.Standard.E5.Flex |
| vCPUs | 4 (AMD) |
| RAM | 24 GB |
| Boot Volume | 200 GB SSD NVMe |
| SO | Oracle Linux 9 x86_64 |
| Região | sa-saopaulo-1 |

---

## Checklist de provisionamento

### 1. Compute

- [ ] Criar instância VM.Standard.E5.Flex (4vCPU / 24GB / 200GB)
- [ ] Anotar IP público: `_______________`
- [ ] Anotar OCID da instância: `ocid1.instance.oc1.sa-saopaulo-1._______________`
- [ ] Configurar chave SSH (adicionar pub key)
- [ ] Testar acesso: `ssh ubuntu@<IP>`

### 2. Security List

- [ ] Porta 22 (SSH) — apenas IP do bastion / máquina de dev
- [ ] Porta 80 (HTTP) — 0.0.0.0/0
- [ ] Porta 443 (HTTPS) — 0.0.0.0/0
- [ ] Porta 5432 (PG) — apenas subnet interna OCI

### 3. Object Storage

- [ ] Criar bucket `tsuru-attachments` (Standard)
- [ ] Namespace: `_______________`
- [ ] Gerar Customer Secret Key (Access Key + Secret Key para S3-compat)
  - Access Key: `_______________`
  - Secret Key: salvar no OCI Vault
- [ ] Endpoint S3-compat: `https://<namespace>.compat.objectstorage.sa-saopaulo-1.oraclecloud.com`

### 4. OCI Vault

- [ ] Criar Vault `tsuru-vault` (FREE tier)
- [ ] Criar secrets:
  - `DATABASE_URL` — `postgresql://tsuru:<password>@localhost:5432/tsuru_portal_production`
  - `SECRET_KEY_BASE` — `bin/rails secret` (gerar após Task 0.2)
  - `SANKHYA_OAUTH_CLIENT_ID` — (obtido com time Sankhya)
  - `SANKHYA_OAUTH_CLIENT_SECRET` — (idem)
  - `SANKHYA_X_TOKEN` — (idem)
  - `OCI_ACCESS_KEY_ID` — Customer Secret Key
  - `OCI_SECRET_ACCESS_KEY` — Customer Secret

### 5. DNS

- [ ] Domínio escolhido: `tsuru.bellube.com.br` (sugestão)
- [ ] Record A apontando para IP da VM
- [ ] Certificado TLS via Let's Encrypt (Kamal provisiona automaticamente com `traefik`)

### 6. Monitoramento

- [ ] Ativar OCI Monitoring na instância
- [ ] Criar alarm: CPU > 80% por 5 min → notificação e-mail
- [ ] UptimeRobot configurado para `https://tsuru.bellube.com.br/up`

---

## Perguntas em aberto (preencher antes do Sprint 1)

| ID | Pergunta | Resposta |
|---|---|---|
| Q-01 | SSO Azure AD ou e-mail+senha+2FA? | **Padrão adotado: e-mail+senha+2FA Devise** |
| Q-02 | SMTP corporativo (host, porta, user)? | `_______________` |
| Q-03 | Sankhya-W on-premise ou Om cloud? URL base da API? | `_______________` |
| Q-04 | Sandbox Sankhya disponível? | `_______________` |
| Q-05 | Centros de custo do piloto? | `_______________` |
| Q-06 | Logotipo SVG corporativo? | **Usando paleta Tsuru até receber brand book** |
| Q-07 | Empresa já optante Lei do Bem ou primeira fruição? | `_______________` |
| Q-08 | Contrato FI Group ativo? | `_______________` |
| Q-09 | Retenção de anexos: 5 anos mínimo (RFB)? | **Padrão adotado: 5 anos** |
| Q-10 | Shape OCI confirmado? | **E5 Flex 4vCPU/24GB conforme acima** |
