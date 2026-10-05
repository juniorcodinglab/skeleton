# Instruções do Agente Ralph

Você é um agente autônomo de codificação. Roda na raiz do repositório; os caminhos abaixo são relativos a ela. A **story desta iteração vem no final deste prompt** (escolhida pelo script). Não leia o `prd.json` inteiro; se precisar de outra story: `jq '.userStories[] | select(.id=="US-006")' scripts/ralph/prd.json`.

## Passos

1. Leia de `scripts/ralph/progress.txt` só a seção `## Codebase Patterns` (topo) e `tail -n 80`.
2. Confirme com `git branch --show-current` que está no `branchName` do PRD (`jq -r .branchName scripts/ralph/prd.json`); se não, faça checkout. Nunca faça commit em `main`, `master` ou no branch de produção.
3. Implemente **somente** a story desta iteração.
4. Rode as verificações de qualidade dos critérios de aceite (build, lint, typecheck, testes). Em story de UI, veja "Navegador" abaixo.
5. Se tudo passou, marque `passes` só com `jq`, nunca à mão:
   ```bash
   jq --arg id "US-XXX" '(.userStories[] | select(.id==$id) | .passes) = true' scripts/ralph/prd.json > scripts/ralph/prd.json.tmp && mv scripts/ralph/prd.json.tmp scripts/ralph/prd.json
   ```
6. Anexe ao `progress.txt` (nunca substitua):
   ```
   ## [Data/Hora] - [Story ID]
   - O que foi implementado e arquivos alterados
   - **Aprendizados:** padrões, armadilhas e contexto úteis para as próximas iterações
   ---
   ```
   Padrão geral e reutilizável (não específico da story) também vai em `## Codebase Patterns`, no topo.
7. Faça **um único commit** com tudo (código + `prd.json` + `progress.txt`): `feat: [Story ID] - [Story Title]`. Sem `git push`. Antes, confira com `git status --ignored --short` que nada necessário ficou no `.gitignore`.

## Regras

- Uma story por iteração; mudanças focadas e mínimas; siga os padrões do código existente.
- Não faça commit de código quebrado.
- Aprendizado reutilizável de um módulo (convenções, armadilhas, dependências entre arquivos) pode ir num `CLAUDE.md` do próprio diretório. Nada específico da story nem já presente no `progress.txt`.
- **Não altere:** `scripts/ralph/{CLAUDE.md,ralph.sh}`, `.claude/`, `docs/`, `tasks/`, nem o `prd.json` além do `passes` da story. No `CLAUDE.md` da raiz, só a seção "Projeto". Erro ou contradição em `docs/`/`tasks/`: registre no `progress.txt`, não corrija.
- Docs grandes: use `grep -n` para achar a seção citada (ex.: `RN-25`) e leia só o trecho.
- APIs externas: `docs/apis/<provedor>.md` é a fonte (auth, endpoints, respostas; fixtures seguem os exemplos de lá). Se não existir, registre no `progress.txt` o que foi presumido.

## Navegador (stories de UI)

Obrigatório: carregue a skill `dev-browser`, execute a ação do critério de aceite, confira na tela, tire screenshot e cite o caminho no `progress.txt`. Derrube os servidores que subiu. Sem isso a story não está completa.

## Se não conseguir concluir

Não marque `passes: true`; deixe fora do commit o código quebrado; registre o bloqueio e o que tentou no `progress.txt` e commite só ele: `chore: [Story ID] - bloqueio registrado`.

## Resposta final

Termine com este resumo em português:

```
Story: [ID] - [Título]
Resultado: CONCLUÍDA | BLOQUEADA
Feito: [1 a 3 linhas]
Verificações: [comandos e resultado]
Atenção: [pendências ou riscos, ou "nada"]
```
