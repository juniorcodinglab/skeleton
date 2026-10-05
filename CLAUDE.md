# CLAUDE.md

Este repositório usa o esqueleto Ralph: o projeto é especificado em `docs/`, quebrado em user stories num PRD (`tasks/`) e implementado story a story pelo loop `scripts/ralph/ralph.sh`.

## Fluxo de trabalho

1. **Requisitos**: quando o operador pedir para iniciar, especificar ou descrever o projeto, ou para construir os docs, use a skill `requisitos`. Ela gera `docs/requisitos.md` e `docs/apis/*.md`, e preenche a seção "Projeto" abaixo.
2. **PRD**: quando o operador pedir um PRD (de uma fase ou de uma funcionalidade), use a skill `prd`. Ela gera `tasks/prd-<nome>.md` e já converte para `scripts/ralph/prd.json`.
3. **Loop**: o operador roda `./scripts/ralph/ralph.sh`. O script cuida sozinho do git (init, commit dos docs e do PRD, criação do branch).

Se o PRD em markdown for editado à mão depois, use a skill `ralph` para regenerar o `prd.json`.

## Estrutura

- `docs/requisitos.md`: requisitos do projeto (RF-xx, RN-xx, RNF-xx, fases).
- `docs/apis/<provedor>.md`: referência de cada API externa (autenticação, endpoints, exemplos de resposta).
- `tasks/prd-*.md`: PRDs em markdown, um por fase ou funcionalidade.
- `scripts/ralph/`: loop autônomo (`ralph.sh`, instruções do agente, `prd.json`, `progress.txt`).
- `.claude/skills/`: skills `requisitos`, `prd`, `ralph` e `dev-browser`.

## Projeto

<!-- Preenchido pela skill `requisitos` e atualizado pela story de setup. Mantenha curto: é lido em toda iteração do loop. -->

- **Nome:** _a definir_
- **Resumo:** _a definir_
- **Stack:** _a definir_
- **Comandos de qualidade:** _a definir_ (build, lint, typecheck, testes)
- **Como subir localmente:** _a definir_ (comando e URL/porta)
