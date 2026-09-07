# Rastreio de leads (nome, WhatsApp, palavra-chave, gclid)

Implementado em 07/09/2026. Resolve: Google Ads/GA4 só mostram contagens agregadas de
conversão, nunca o nome/WhatsApp de quem converteu — e não há como cruzar automaticamente
"esse lead veio dessa palavra-chave" sem isso.

## Como funciona

1. **Google Ads** — a campanha `BRAVOLOC | LOCAÇÃO | VENDA | 001` tem um **sufixo de URL
   final** (Configurações da campanha → Opções de URL) que anexa parâmetros ValueTrack em
   todo clique pago:
   ```
   utm_source=google&utm_medium=cpc&utm_campaign={campaignname}&utm_term={keyword}&matchtype={matchtype}&gclid={gclid}&device={device}
   ```
   `{keyword}` é a palavra-chave cadastrada que deu match (não o texto exato digitado — isso
   só existe no relatório de Termos de Pesquisa dentro do próprio Ads).

2. **`src/layouts/Layout.astro`** — um script lê esses parâmetros da URL na chegada e guarda em
   `sessionStorage` (chave `bravoloc_lead_source`), pra sobreviver até o visitante preencher o
   formulário ou clicar no WhatsApp, mesmo em outra página. Também define
   `window.sendBravoLocLead(extra)`, usada pelos dois pontos de conversão do site.

3. **`QuoteForm.astro`** (formulário "Solicitar Orçamento") e **`FloatingWhatsApp.astro`**
   (botão flutuante) chamam `window.sendBravoLocLead(...)` no clique/submit — envio
   fire-and-forget (`fetch` com `mode: 'no-cors'`) que nunca atrasa nem bloqueia o
   redirecionamento pro WhatsApp, mesmo se falhar.

4. **Backend** — Google Apps Script vinculado à planilha **"BravoLoc - Leads Rastreados"**
   (Google Drive da conta SevenLike). Recebe o POST em `doPost(e)`, confere o campo `secret`
   contra `PUBLIC_LEADS_SECRET`, e grava uma linha com Data/Hora, Nome, WhatsApp,
   Palavra-chave, Campanha, Tipo de Correspondência, Dispositivo, GCLID, Origem, Página e
   Formulário. Código-fonte do Apps Script: ver o próprio projeto em
   script.google.com (nome "BravoLoc - Leads (Backend)"), não versionado neste repositório.

## Variáveis de ambiente

`PUBLIC_LEADS_ENDPOINT` e `PUBLIC_LEADS_SECRET` — ver `.env.example`. Precisam do prefixo
`PUBLIC_` porque são lidas em código que roda no navegador do visitante (o envio do lead é
client-side, direto pro Apps Script — não passa por um servidor nosso).

**Limite conhecido:** por ser client-side, a URL do endpoint e a chave secreta ficam visíveis
pra qualquer um que inspecionar o código da página — o `.env` evita que fiquem no histórico do
Git, mas não as esconde de um visitante. Risco aceito: o pior cenário de vazamento é alguém
mandar linhas falsas pra planilha, não um problema de dados sensíveis.

**Produção (Vercel):** as mesmas duas variáveis precisam ser configuradas em
Project Settings → Environment Variables no painel da Vercel — o `.env` local não é lido em
produção.

## Pendências conhecidas

- Se a chave (`PUBLIC_LEADS_SECRET` / `SECRET` no Apps Script) precisar ser trocada, os dois
  lados (site e Apps Script) precisam ser atualizados juntos.
- Se a URL de implantação do Apps Script mudar (nova implantação em vez de atualizar a
  existente), `PUBLIC_LEADS_ENDPOINT` precisa ser atualizada no `.env` local e na Vercel.
