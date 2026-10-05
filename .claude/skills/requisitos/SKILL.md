---
name: requisitos
description: Entrevista o operador em rodadas curtas de múltipla escolha e escreve o documento de requisitos do projeto (ou de uma entrega nova) em docs/requisitos.md, para humanos, com RF/RN/RNF e fases de entrega; depois gera docs/apis/*.md e preenche a seção "Projeto" do CLAUDE.md da raiz. Use quando o operador pedir para iniciar, especificar ou descrever o projeto, fechar o escopo, levantar requisitos ou criar os docs, inclusive quando ele colar um briefing pronto.
---

# Requisitos do projeto

Objetivo: entrevistar o operador e fechar o documento de requisitos. Ele é lido por humanos (o operador, um sócio, um designer) e serve de entrada para a skill `prd`. **Aqui não se gera PRD, código nem tarefas de implementação.**

## 1. Levantar o que já existe

- Leia o que houver no repositório: `CLAUDE.md`, `README*`, `docs/`, código existente. Em arquivo grande, use `grep -n` e leia só o trecho.
- Leia o que o operador já disse na conversa. Se ele colou um briefing ou apontou um arquivo, ele é a fonte principal do **conteúdo**. Caminho do arquivo e estrutura do documento seguem esta skill, mesmo que o briefing peça outra coisa, porque a skill `prd` depende deles.
- Monte, só para você, duas listas:
  - **Decidido**: tudo o que o operador já afirmou. Não pergunte de novo, mesmo que você faria diferente. Se ver um problema real numa decisão (custo, regra de loja, lei, contradição), registre em "Riscos e pendências" e avise no resumo final, sem reabrir a entrevista por isso.
  - **Em aberto**: os pontos que o operador listou como abertos, mais as lacunas reais que você achar com o checklist abaixo.
- Se já existir `docs/requisitos.md`, pergunte: revisar o atual, acrescentar uma entrega nova ou começar do zero. Ao revisar ou acrescentar, preserve os IDs e continue a numeração.
- Se já existe código funcionando, o escopo é a entrega nova, não o produto inteiro: resuma o que já existe em até 5 linhas no "Resumo", use o nome da entrega no título (ex.: "Requisitos: Faturamento") e leia stack e comandos do código em vez de perguntar.

### Checklist de lacunas

Pergunte só o que se aplica ao produto e ainda não foi decidido. Lacuna real é aquilo sem o qual não dá para escrever uma regra ou um critério de aceite.

- **Produto:** problema, para quem, o que torna o produto diferente, roadmap depois desta entrega.
- **Quem usa:** papéis (ex.: visitante sem login, usuário logado, admin) e o que cada um pode fazer.
- **Escopo:** o que entra no escopo e o que fica de fora; limites do plano gratuito, se houver.
- **Contas:** formas de login, sair, excluir conta, o que acontece com os dados na exclusão.
- **Multiempresa (B2B):** conta da empresa, convite de membros, isolamento de dados entre clientes, permissões por papel.
- **Conteúdo inicial:** quem cadastra os dados, quanto conteúdo precisa existir antes de lançar.
- **Onboarding:** quais passos, o que perguntar, se dá para pular.
- **Notificações:** canais (push, e-mail, web push, WhatsApp, SMS), eventos, quem recebe, antecedência, horário de silêncio, limite por dia.
- **Monetização e cobrança:** o que entra no escopo (anúncios, plano pago, assinatura, afiliados) e o custo de cada canal pago; se há cobrança, planos, trial, meio de pagamento, inadimplência e nota fiscal.
- **Datas e horários:** fusos, formato, datas "a confirmar".
- **Plataformas e lançamento:** web, Android, iOS, bot, CLI; exigências das lojas (ex.: Sign in with Apple quando há login social no iOS, exclusão de conta dentro do app, teste fechado no Google Play para contas pessoais novas); domínio.
- **Legal:** lei de dados aplicável (LGPD; GDPR se atender a UE), termos de uso e política de privacidade (quem escreve, onde ficam), consentimento. Pule se o produto não guarda dado pessoal.
- **Integrações externas:** quais e para quê, incluindo as que ninguém citou mas o produto precisa (ex.: provedor de e-mail para envio de código de login).
- **Operação:** disponibilidade esperada, backups, monitoramento.
- **Sucesso:** 2 a 4 métricas simples para saber se a entrega deu certo.
- **Técnico:** só stack e infraestrutura, se ainda não estiverem decididas. Detalhe de implementação fica para o PRD.

## 2. Entrevistar em rodadas curtas

- Use a ferramenta de perguntas com opções (`AskUserQuestion`). **No máximo 4 perguntas por rodada**, cada uma com 2 a 4 opções.
- A **opção recomendada vem primeiro**, com "(Recomendado)" no rótulo. Na descrição de cada opção, diga em uma frase a consequência (custo, prazo, complexidade, regra de loja). O operador sempre pode responder em texto livre.
- Se o operador deu só uma ideia curta, sem escopo: antes das rodadas, proponha em texto um rascunho com papéis, 5 a 10 funcionalidades candidatas e o que fica fora, e peça para ele cortar ou acrescentar. Só depois siga com as rodadas.
- Ordem das rodadas: primeiro o que muda o escopo (o que entra no escopo, monetização, canais), depois as regras (limites, horários, onboarding), por fim lançamento, legal e métricas.
- **Ponto que o operador listou como aberto sempre vira pergunta.** Escopo e funcionalidades também precisam da confirmação dele. Só as lacunas menores que você mesmo achou podem ser resolvidas com um padrão sensato: escolha, registre como decisão e mostre no resumo final.
- Quando o operador responder "segue sua sugestão" (ou equivalente), registre a opção recomendada como decisão. Se ele não especificar a pergunta, vale para a rodada inteira.
- Antes de cada nova rodada, diga em uma linha o que ficou decidido na anterior.
- Pare quando todos os pontos abertos do operador tiverem resposta e não houver lacuna real. Normalmente são de 2 a 5 rodadas.

## 3. Escrever `docs/requisitos.md`

O caminho é sempre `docs/requisitos.md`, mesmo que o briefing cite outro nome: a skill `prd` lê dali.

### Regras de escrita

- Escreva em português do Brasil, para um humano, não para a IA.
- Linguagem simples, frases curtas. Nada de jargão de implementação fora da seção "Decisões técnicas" (ex.: escreva "o alerta não é enviado duas vezes", não "o job é idempotente"). Se o usuário do produto é técnico (API, CLI, SDK), os termos da interface que ele usa (comando, flag, endpoint, status HTTP, formato do payload) são permitidos nas regras e critérios.
- Breve: no máximo cerca de 5 páginas. Sem introdução genérica, sem repetição, sem justificativa longa. Agrupe funcionalidades pequenas num RF só (ex.: seguir artista, seguir cidade e favoritar = um RF). Escreva critério de aceite para as regras que importam, não para todas.
- Cada funcionalidade tem um ID (RF-01, RF-02...), 1 a 2 linhas dizendo o que é, as regras em tópicos e os critérios de aceite.
- Cada regra tem um ID próprio (RN-01, RN-02...), porque PRDs e stories vão citá-las (ex.: "ver RN-12"). Cada regra fica escrita num lugar só; os outros lugares citam o ID.
- IDs são estáveis: na primeira versão, numere em sequência. Depois, item novo recebe o próximo número livre, mesmo fora de ordem, e ID removido não é reaproveitado. Vale para RF, RN e RNF.
- Critério de aceite no formato **"Dado que… quando… então…"**: verificável, sem ambiguidade, com números e nomes concretos. Proibido: "rápido", "bonito", "intuitivo", "fácil", "adequado", "amigável", "etc.".
- Use tabela quando comparar coisas (ex.: quem recebe qual notificação, o que cada papel pode fazer).
- Deixe explícito o que está **fora do escopo**. O roadmap posterior aparece só ali.
- Decisão que não vira funcionalidade nem é técnica vai em uma linha no lugar certo, sem criar seção nova: design e identidade em "Requisitos gerais"; monetização e acordos comerciais em "Escopo" (o que entra ou fica fora do escopo).
- Seções que não se aplicam ao produto (ex.: notificações) saem do documento, sem escrever "não se aplica". Renumere as seções restantes; por isso, cite o documento sempre por ID ou nome de seção, nunca por número.

### Estrutura

```markdown
# [Nome do produto]: Requisitos

## 1. Resumo
Até 5 linhas: o que é, para quem, que dor resolve.

## 2. Objetivo e como saber se deu certo
Objetivo em 1 a 2 frases. Métricas simples, com meta e prazo quando houver (ex.: "500 usuários com alerta ligado em 60 dias").

## 3. Quem usa
Um tópico por papel (ex.: Visitante sem login, Usuário logado, Admin) com o que ele pode fazer. Tabela se ficar mais claro.

## 4. Escopo
### Entra no escopo
Lista curta, citando os RF.
### Fora do escopo
Uma linha por item. Agrupe por versão (V2, V3, depois) só se o operador deu um roadmap; não invente versões.

## 5. Funcionalidades
### RF-01: [Nome]
O que é, em 1 a 2 linhas.

**Regras**
- RN-01: ...
- RN-02: ...

**Critérios de aceite**
- Dado que ..., quando ..., então ...

## 6. Regras de notificação
| Evento | Quem recebe | Quando | Canal | Regra |
Resumo para consulta. A coluna "Regra" cita a RN onde a regra está escrita (ex.: RN-14).

## 7. Telas e interfaces
Agrupadas por canal: telas (app, web, admin), comandos (CLI), fluxos do bot ou endpoints (API), conforme o produto. Uma linha por item: nome e o que mostra ou faz.

## 8. Requisitos gerais
- RNF-01: ... (só o que se aplica: privacidade e lei de dados, exigências das lojas, horários e fusos, disponibilidade, acessibilidade, compatibilidade, limites de uso, design e identidade)

## 9. Decisões técnicas
| Tema | Decisão |
Uma linha por decisão. Única seção onde termo técnico de implementação é permitido. Inclua uma linha por serviço externo que o produto chama (login social, push, e-mail, pagamento, mensageria...), citando o RF que o usa.

## 10. Riscos e pendências
Riscos com o que fazer a respeito; pendências com dono ou prazo; suposições feitas sem confirmação do operador; decisões do operador com problema que você apontou.

## 11. Fases de entrega
Como o escopo vai ser construído, em fatias para os PRDs. Fase 0 = a menor coisa útil que roda de ponta a ponta (numa entrega sobre código existente, ponta a ponta sobre o sistema atual). Para cada fase: objetivo em 1 linha, RFs e RNFs incluídos, critério de pronto em 1 linha.
```

### Antes de mostrar

Releia o documento e confira:
- toda decisão da entrevista e do briefing aparece em algum lugar;
- todo RF tem pelo menos um critério de aceite, e todo RF e RNF está numa fase de entrega;
- toda linha da tabela de notificações cita uma RN que existe;
- nenhum critério usa palavra proibida nem depende de opinião;
- não há jargão de implementação fora de "Decisões técnicas";
- não há nada do roadmap posterior fora de "Fora do escopo";
- o tamanho está dentro do limite. Se passou, corte justificativas e repetições e agrupe RFs. Se ainda passar, mantenha regras e critérios e informe o tamanho no resumo.

## 4. Revisar com o operador

Mostre um resumo curto: as decisões tomadas na entrevista (destacando as que você assumiu por padrão), as fases de entrega (uma linha cada, com os RFs), os riscos e decisões com problema que merecem atenção, e as pendências. Pergunte se ajusta algo antes de considerar pronto. Aplique os ajustes no documento e repita até ele aprovar.

## 5. Depois da aprovação

1. **`docs/apis/<provedor>.md`**, um por API que o código do produto chama em tempo de execução (ex.: login social, push, envio de e-mail, pagamentos, mensageria). Infraestrutura, deploy e monitoramento não entram. Siga o modelo de `docs/apis/README.md`: autenticação, endpoints usados, **exemplos reais de request e response** (os fixtures de teste vão segui-los), limites de taxa, erros comuns e link da documentação oficial. Se houver ferramenta de busca ou fetch, consulte a documentação oficial. Marque como `> Não verificado` tudo o que for presumido. Se o provedor não foi decidido, use o padrão que você registrou em "Riscos e pendências" e marque o arquivo inteiro como `> Não verificado`. Esses arquivos são técnicos e ficam fora do limite de páginas.
2. **Seção "Projeto" do `CLAUDE.md` da raiz.** Substitua os `_a definir_` por nome, resumo de uma linha, stack, comandos de qualidade previstos (ex.: `npm run lint`, `npm test`) e como subir localmente. Se ainda não há código, escreva os comandos previstos e indique que a story de setup vai confirmá-los. Mantenha a seção curta.
3. Encerre listando os arquivos gerados e sugira o próximo passo: "peça o PRD da Fase 0".
