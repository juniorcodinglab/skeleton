# Esqueleto Ralph

Copie para a raiz de um projeto novo (ou existente): `CLAUDE.md`, `.claude/`, `docs/`, `tasks/` e `scripts/ralph/`. Não precisa preparar nada no repositório.

## Uso

1. Abra o Claude Code na raiz e descreva o projeto: *"inicie os docs do projeto: <ideia>"* (skill `requisitos`).
2. Peça o PRD: *"crie o PRD da Fase 0"* (skill `prd`). Ele gera `tasks/prd-*.md` e `scripts/ralph/prd.json`.
3. Rode o loop: `./scripts/ralph/ralph.sh [--model opus] [--effort high] [max_iterações]`

O `ralph.sh` cuida sozinho de:
- `git init` (se ainda não for um repositório) e do commit inicial;
- commit dos docs, do PRD e das instruções antes de começar;
- criar ou retomar o branch `branchName` do PRD a partir do branch atual;
- adicionar ao `.gitignore` os logs, screenshots e temporários do loop;
- arquivar em `scripts/ralph/archive/` o PRD e o progresso anteriores quando o `branchName` muda.

Para o próximo PRD, volte ao branch base (ex.: `main`, depois de fazer merge da fase anterior) e repita os passos 2 e 3.

## Pré-requisitos da máquina

`git` (com `user.name` e `user.email` configurados), `jq`, `claude` e, para stories de UI, `node`/`npm` (o Playwright é instalado sozinho fora do repositório).
