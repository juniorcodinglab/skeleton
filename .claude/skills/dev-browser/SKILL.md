---
name: dev-browser
description: Verifica mudanças de UI num navegador real (Playwright/Chromium headless) e tira screenshots. Use em toda story que altera interface, antes de marcá-la como concluída.
---

# Verificação no navegador

## 1. Subir a aplicação

- O comando e a porta estão na seção "Projeto" do `CLAUDE.md` da raiz ("Como subir localmente").
- Suba em background guardando o PID e espere a porta responder:
  ```bash
  <comando de subir> > /tmp/ralph-app.log 2>&1 &
  echo $! > /tmp/ralph-app.pid
  for i in $(seq 1 60); do curl -s -o /dev/null http://localhost:<porta> && break; sleep 1; done
  ```
- Se não subir, leia `/tmp/ralph-app.log`.

## 2. Preparar o Playwright (fora do repositório, uma vez por máquina)

```bash
BROWSER_DIR="${TMPDIR:-/tmp}/ralph-browser"
if [ ! -d "$BROWSER_DIR/node_modules/playwright" ]; then
  mkdir -p "$BROWSER_DIR"
  (cd "$BROWSER_DIR" && npm init -y >/dev/null && npm i playwright >/dev/null && npx playwright install chromium)
fi
```

O `cd` fica dentro de um subshell `( ... )` de propósito: o shell do agente mantém o diretório entre comandos, e sair da raiz do repositório quebraria os `git` e os caminhos seguintes.

Não adicione o Playwright às dependências do projeto só por causa desta verificação.

## 3. Escrever e rodar o roteiro

Crie `$BROWSER_DIR/check.mjs` com o fluxo do critério de aceite (ele fica fora do repositório):

```js
import { chromium } from 'playwright';
import { mkdirSync } from 'node:fs';

const OUT = process.env.OUT_DIR; // <raiz do repo>/scripts/ralph/screenshots
mkdirSync(OUT, { recursive: true });
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
const errors = [];
page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
page.on('pageerror', (e) => errors.push(e.message));

try {
  await page.goto('http://localhost:3000/rota');
  // await page.getByLabel('Email').fill('teste@exemplo.com');
  // await page.getByRole('button', { name: 'Salvar' }).click();
  // await page.getByText('Salvo com sucesso').waitFor({ timeout: 5000 });
  await page.screenshot({ path: `${OUT}/US-XXX-descricao.png`, fullPage: true });
} catch (e) {
  await page.screenshot({ path: `${OUT}/US-XXX-falha.png`, fullPage: true });
  console.error('FALHOU:', e.message);
  process.exitCode = 1;
} finally {
  if (errors.length) console.error('Erros no console:', errors);
  await browser.close();
}
```

```bash
OUT_DIR="$(git rev-parse --show-toplevel)/scripts/ralph/screenshots" node "$BROWSER_DIR/check.mjs"
```

- Prefira seletores por papel/texto/label (`getByRole`, `getByText`, `getByLabel`).
- Abra o screenshot com a ferramenta de leitura de arquivos e confira visualmente se o resultado bate com o critério de aceite.
- Erros no console contam como falha, a menos que não tenham relação com a story (registre no `progress.txt`).

## 4. Encerrar

- Derrube o que você subiu: `kill $(cat /tmp/ralph-app.pid)` e confira que a porta liberou.
- Cite o caminho do screenshot no `progress.txt`. A pasta `scripts/ralph/screenshots/` é ignorada pelo git.
