---
name: ralph
description: Converte um PRD em markdown (tasks/prd-*.md) para o formato scripts/ralph/prd.json usado pelo loop Ralph. Use quando o operador pedir para converter, gerar ou regenerar o prd.json, ou depois de editar um PRD à mão.
---

# Converter PRD para `prd.json`

## Formato

```json
{
  "project": "Nome do projeto",
  "branchName": "ralph/<slug-da-fase-ou-feature>",
  "description": "Resumo de uma linha do PRD",
  "sourcePrd": "tasks/prd-<slug>.md",
  "userStories": [
    {
      "id": "US-001",
      "title": "Título curto",
      "description": "Como [usuário], quero [funcionalidade] para [benefício].",
      "acceptanceCriteria": [
        "Critério verificável",
        "npm run typecheck e npm test passam"
      ],
      "priority": 1,
      "passes": false,
      "notes": ""
    }
  ]
}
```

Há um exemplo completo em `scripts/ralph/prd.example.json`.

## Regras

- Uma entrada por story do PRD, na mesma ordem. `priority` começa em 1 e segue a ordem de dependência (o script sempre pega a menor `priority` com `passes: false`).
- Copie os critérios de aceite **completos**, incluindo comandos de qualidade, referências (RN-xx, `docs/apis/...`) e "Verificado no navegador com a skill `dev-browser`" nas stories de UI. O agente só vê a story dele, então ela precisa se bastar.
- Se uma story parecer grande demais para uma iteração, quebre-a (US-004a, US-004b...) e avise o operador.
- `branchName`: um por PRD, em kebab-case com prefixo `ralph/`.
- Se já existir `scripts/ralph/prd.json`:
  - **Outro `branchName`**: pode sobrescrever. O `ralph.sh` arquiva sozinho o PRD e o progresso anteriores em `scripts/ralph/archive/`.
  - **Mesmo `branchName`** (regeração depois de editar o PRD): preserve `passes: true` e `notes` das stories com o mesmo `id`.
- Nunca apague nem edite `scripts/ralph/progress.txt`.

## Validar

```bash
jq -e '.branchName and (.userStories | length > 0) and all(.userStories[]; .id and .title and (.priority | type == "number") and (.passes | type == "boolean") and (.acceptanceCriteria | length > 0))' scripts/ralph/prd.json
jq -r '.userStories[] | "\(.priority)\t\(.id)\t\(.title)"' scripts/ralph/prd.json
```

O primeiro comando precisa imprimir `true`. Mostre a lista do segundo ao operador.
