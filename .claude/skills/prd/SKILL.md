---
name: prd
description: Gera um PRD (Product Requirements Document) em tasks/prd-<nome>.md com user stories pequenas o bastante para o loop Ralph e o converte em scripts/ralph/prd.json. Use quando o operador pedir um PRD, planejar uma fase ou funcionalidade, ou quebrar o trabalho em user stories.
---

# Gerar PRD

Objetivo: um PRD claro para humanos em `tasks/` e um `scripts/ralph/prd.json` pronto para o loop. **Não implemente nada.**

## 1. Definir o escopo

- Se existir `docs/requisitos.md`, o escopo normalmente é uma fase dele ("Fase 0") ou um conjunto de RFs. **Não leia arquivos grandes inteiros**: use `grep -n` para achar a seção e leia só o trecho necessário.
- Se não existir documentação, use a descrição do operador. Se for um projeto novo e a descrição for vaga, sugira rodar a skill `requisitos` antes.
- Leia a seção "Projeto" do `CLAUDE.md` da raiz (stack e comandos de qualidade).
- Verifique se já existe código com `ls` e `find . -maxdepth 2 -not -path './.git*' -not -path './node_modules*'` (o repositório git pode ainda não existir; o `ralph.sh` o cria depois). `CLAUDE.md`, `docs/`, `tasks/`, `.claude/` e `scripts/ralph/` são o esqueleto, não código do produto. Sem `package.json`, `src/`, `app/` ou equivalente, o projeto é novo e precisa de uma story de setup.

## 2. Perguntas de esclarecimento (só se necessário)

Se algo essencial estiver ambíguo, faça de 3 a 5 perguntas com opções (A, B, C...) para o operador responder rápido (ex.: "1A, 2C"). Se os docs já respondem, não pergunte.

## 3. Escrever `tasks/prd-<slug>.md`

```markdown
# PRD: [Nome]

## Introdução
## Objetivos
## User Stories
### US-001: [Título]
**Descrição:** Como [usuário], quero [funcionalidade] para [benefício].
**Critérios de aceite:**
- [ ] Critério verificável
- [ ] [comandos de qualidade] passam
## Requisitos funcionais (referenciando RF/RN dos docs)
## Fora de escopo
## Considerações técnicas (inclui o modelo de dados da fase: entidades, campos e relações, derivados dos RF/RN)
## Métricas de sucesso
## Questões em aberto
```

### Regras para as stories (o mais importante)

- **Cada story cabe em uma iteração**, ou seja, em uma única janela de contexto do agente. Se você não consegue descrever a mudança em 2 ou 3 frases, quebre a story.
  - Bom tamanho: uma tabela/migration, um endpoint, um componente de UI, um job, uma regra de negócio com testes.
  - Grande demais: "construir o dashboard", "implementar autenticação", "integrar com a API X" inteira.
- **Ordem por dependência**: setup → schema/dados → lógica/backend → UI. Uma story nunca depende de uma posterior.
- **Projeto sem código**: a US-001 é o setup. Ela cria a estrutura, as dependências, lint/typecheck/testes configurados com um teste trivial passando, o `.gitignore` e o comando de subir localmente, e atualiza a seção "Projeto" do `CLAUDE.md` da raiz com os comandos reais.
- **Critérios de aceite verificáveis**: nada de "funciona bem". Escreva "retorna 404 quando o id não existe", "RN-07 coberta por teste".
- Toda story termina com os comandos de qualidade do projeto passando (ex.: "`npm run typecheck` e `npm test` passam").
- Toda story que mexe em UI inclui: "Verificado no navegador com a skill `dev-browser`".
- Cite a origem quando houver: "(ver RN-12 em `docs/requisitos.md`)". Cite o documento por ID (RF/RN/RNF) ou nome de seção, nunca por número de seção.
- Story de schema lista nos critérios as tabelas e campos exatos do modelo de dados do PRD (`docs/requisitos.md` não tem modelo de dados).
- Integrações externas: cite `docs/apis/<provedor>.md` e peça testes com fixtures baseados nos exemplos de lá, sem chamar a API real nos testes.

## 4. Converter para `scripts/ralph/prd.json`

Siga a skill `ralph` (formato, regras de conversão e validação com `jq`).

## 5. Encerrar

Mostre ao operador:
- os caminhos do PRD e do `prd.json`, o número de stories e o `branchName`;
- as questões em aberto;
- como rodar: `./scripts/ralph/ralph.sh` (opções: `--model`, `--effort`, número máximo de iterações). O script faz o git sozinho.
