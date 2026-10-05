#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop
# Usage: ./ralph.sh [--model MODEL] [--effort low|medium|high|xhigh|max] [max_iterations]
#
# O script escolhe a próxima story (maior prioridade com passes=false),
# injeta só ela no prompt, mostra ao vivo o que o agente está fazendo e imprime um
# resumo ao fim de cada iteração. Logs brutos ficam em scripts/ralph/logs/.

set -e

# Parse arguments
MAX_ITERATIONS=150
MODEL="${RALPH_MODEL:-opus}"
EFFORT="${RALPH_EFFORT:-high}"
MAX_ATTEMPTS_PER_STORY=3     # mesma story sem concluir N vezes seguidas → para o loop
MAX_CONSECUTIVE_ERRORS=3     # erros do CLI (não de limite) seguidos → para o loop
LIMIT_WAIT_SECONDS=1800      # espera quando bate limite de uso do plano
ERROR_WAIT_SECONDS=120

while [[ $# -gt 0 ]]; do
  case $1 in
    --model)
      MODEL="$2"
      shift 2
      ;;
    --model=*)
      MODEL="${1#*=}"
      shift
      ;;
    --effort)
      EFFORT="$2"
      shift 2
      ;;
    --effort=*)
      EFFORT="${1#*=}"
      shift
      ;;
    *)
      # Assume it's max_iterations if it's a number
      if [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

for cmd in jq git claude; do
  if ! command -v "$cmd" >/dev/null; then
    echo "Error: '$cmd' não encontrado no PATH."
    exit 1
  fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"
LOG_DIR="$SCRIPT_DIR/logs"

if [ ! -f "$PRD_FILE" ]; then
  echo "Error: $PRD_FILE não existe."
  echo "   Abra o Claude Code na raiz do projeto e peça o PRD (skill prd). Exemplo de formato: $SCRIPT_DIR/prd.example.json"
  exit 1
fi
if ! jq empty "$PRD_FILE" 2>/dev/null; then
  echo "Error: $PRD_FILE não é um JSON válido. Peça para regenerá-lo com a skill ralph."
  exit 1
fi
if ! jq -e '
  (.branchName | type == "string" and length > 0)
  and (.userStories | type == "array" and length > 0)
  and all(.userStories[]; (.id | type == "string" and length > 0) and (.title | type == "string")
        and (.priority | type == "number") and (.passes | type == "boolean")
        and (.acceptanceCriteria | type == "array" and length > 0))
  and ([.userStories[].id] | length == (unique | length))
' "$PRD_FILE" >/dev/null 2>&1; then
  echo "Error: $PRD_FILE inválido. Precisa de branchName e, em cada story: id (único), title, priority (número), passes (booleano) e acceptanceCriteria (lista não vazia)."
  echo "   Peça para regenerá-lo com a skill ralph."
  exit 1
fi

# Repositório git: usa o existente ou cria um na raiz do esqueleto (dois níveis acima deste script)
if ! REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"; then
  REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
  echo "Inicializando repositório git em $REPO_ROOT"
  git -C "$REPO_ROOT" init -q -b main
fi
if [ -z "$(git -C "$REPO_ROOT" config user.email)" ]; then
  echo "Error: git sem identidade. Rode: git config --global user.name \"Seu Nome\" && git config --global user.email voce@exemplo.com"
  exit 1
fi
REL_DIR="${SCRIPT_DIR#"$REPO_ROOT"/}"

# O agente sempre roda a partir da raiz do repositório (caminhos do CLAUDE.md são relativos a ela)
cd "$REPO_ROOT"
mkdir -p "$LOG_DIR"

# Mantém o Mac acordado enquanto o loop rodar
if command -v caffeinate >/dev/null; then
  caffeinate -dimsu -w $$ &
fi

# Arquivos do loop que não vão para o git
[ -s .gitignore ] && [ -n "$(tail -c1 .gitignore)" ] && echo >> .gitignore
for p in "/$REL_DIR/logs/" "/$REL_DIR/screenshots/" "/$REL_DIR/.last-branch" "/$REL_DIR/prd.json.tmp" ".DS_Store"; do
  grep -qxF "$p" .gitignore 2>/dev/null || echo "$p" >> .gitignore
done

# Archive previous run if branch changed
if [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    # Archive the previous run
    DATE=$(date +%Y-%m-%d)
    # Strip "ralph/" prefix from branch name for folder
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    # O prd.json atual já é o novo; a versão final da execução anterior está no branch antigo
    for f in prd.json progress.txt; do
      git show "$LAST_BRANCH:$REL_DIR/$f" > "$ARCHIVE_FOLDER/$f" 2>/dev/null \
        || { rm -f "$ARCHIVE_FOLDER/$f"; [ "$f" = progress.txt ] && [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"; }
    done
    echo "   Archived to: $ARCHIVE_FOLDER"

    # Reset progress file for new run
    rm -f "$PROGRESS_FILE"
  fi
fi

# Track current branch
jq -r '.branchName' "$PRD_FILE" > "$LAST_BRANCH_FILE"

# Initialize progress file if it doesn't exist
if [ ! -s "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

# ---------- git: commit do planejamento e branch do PRD ----------

if ! git rev-parse --verify -q HEAD >/dev/null; then
  echo "Repositório sem commits: criando o commit inicial com o esqueleto."
  git add -A
  git commit -q -m "chore: esqueleto inicial do projeto"
fi

# Docs, PRD e instruções escritos pelo operador entram num commit próprio antes do loop
PLANNING_PATHS=()
for p in CLAUDE.md .gitignore .claude docs tasks "$REL_DIR"; do
  [ -e "$p" ] && PLANNING_PATHS+=("$p")
done
git add -A -- "${PLANNING_PATHS[@]}"
if ! git diff --cached --quiet; then
  git commit -q -m "chore: docs e PRD para $(jq -r .branchName "$PRD_FILE")"
  echo "Commit dos arquivos de planejamento (docs, PRD, instruções) criado."
fi

PRD_BRANCH=$(jq -r '.branchName' "$PRD_FILE")
GIT_BRANCH=$(git branch --show-current)
if [ "$GIT_BRANCH" != "$PRD_BRANCH" ]; then
  if git show-ref --verify -q "refs/heads/$PRD_BRANCH"; then
    git checkout -q "$PRD_BRANCH"
    echo "Retomando o branch existente $PRD_BRANCH"
  else
    git checkout -q -b "$PRD_BRANCH"
    echo "Branch $PRD_BRANCH criado a partir de $GIT_BRANCH"
  fi
fi

OTHER_DIRTY=$(git status --porcelain | wc -l | tr -d ' ')
if [ "$OTHER_DIRTY" != "0" ]; then
  echo "⚠️  $OTHER_DIRTY arquivo(s) alterado(s) fora do planejamento. O agente vai incluí-los no primeiro commit."
  git status --short | head -n 10 | sed 's/^/   /'
  echo "   Ctrl+C em 10s para cancelar."
  sleep 10
fi

# ---------- helpers ----------

next_story() {
  jq -c '[.userStories[] | select(.passes != true)] | sort_by(.priority) | .[0] // empty' "$PRD_FILE"
}
count_done()  { jq '[.userStories[] | select(.passes == true)] | length' "$PRD_FILE"; }
count_total() { jq '.userStories | length' "$PRD_FILE"; }
story_passes() { jq -r --arg id "$1" '.userStories[] | select(.id == $id) | .passes' "$PRD_FILE"; }

fmt_duration() {
  local s=$1
  if [ "$s" -ge 3600 ]; then
    printf '%dh%02dm' $((s / 3600)) $((s % 3600 / 60))
  else
    printf '%dm%02ds' $((s / 60)) $((s % 60))
  fi
}

# Uma linha por ação do agente, com hora local
STREAM_FILTER='
  def short: tostring | gsub("\\s+"; " ") | sub("^\($root)/"; "") | .[0:170];
  def arg:
    if .name == "Bash" then (.input.command // "")
    elif .name == "TodoWrite" then
      ((.input.todos // []) | map(select(.status == "in_progress") | .content) | join("; "))
    elif .input.file_path then .input.file_path
    elif .input.pattern then .input.pattern
    elif .input.skill then .input.skill
    elif .input.description then .input.description
    elif .input.url then .input.url
    else "" end;
  def icon:
    if .name == "Bash" then "▶️ "
    elif .name == "Read" then "📖"
    elif (.name == "Edit" or .name == "Write" or .name == "MultiEdit" or .name == "NotebookEdit") then "✏️ "
    elif (.name == "Grep" or .name == "Glob") then "🔎"
    elif .name == "Skill" then "🧩"
    elif .name == "TodoWrite" then "📝"
    else "🔧" end;
  fromjson? // empty
  | (now | strflocaltime("%H:%M:%S")) as $t
  | if .type == "assistant" then
      .message.content[]?
      | if .type == "text" and ((.text // "") | test("\\S")) then "\($t) 💬 \(.text | short)"
        elif .type == "tool_use" then "\($t) \(icon) \(.name): \(arg | short)"
        else empty end
    elif .type == "user" then
      .message.content[]?
      | select(type == "object" and .type == "tool_result" and .is_error == true)
      | "\($t) ⚠️  \((.content | if type == "array" then map(.text? // "") | join(" ") else . end) | short)"
    else empty end
'

# ---------- loop ----------

TOTAL=$(count_total)
echo "Starting Ralph - Model: $MODEL - Effort: $EFFORT - Max iterations: $MAX_ITERATIONS"
echo "Progresso inicial: $(count_done)/$TOTAL stories concluídas"

RUN_START=$(date +%s)
i=0
LAST_STORY=""
ATTEMPTS=0
ERRORS=0
DONE_THIS_RUN=0

while [ "$i" -lt "$MAX_ITERATIONS" ]; do
  if ! jq empty "$PRD_FILE" 2>/dev/null; then
    echo "❌ $PRD_FILE não é um JSON válido (o agente pode tê-lo corrompido). Parando."
    echo "   Veja: git diff -- $REL_DIR/prd.json"
    exit 1
  fi

  STORY=$(next_story)
  if [ -z "$STORY" ]; then
    echo ""
    echo "🎉 Ralph completed all tasks! ($TOTAL/$TOTAL stories) em $(fmt_duration $(( $(date +%s) - RUN_START )))"
    exit 0
  fi
  STORY_ID=$(echo "$STORY" | jq -r .id)
  STORY_TITLE=$(echo "$STORY" | jq -r .title)

  if [ "$STORY_ID" = "$LAST_STORY" ]; then
    ATTEMPTS=$((ATTEMPTS + 1))
  else
    ATTEMPTS=1
    LAST_STORY="$STORY_ID"
  fi
  if [ "$ATTEMPTS" -gt "$MAX_ATTEMPTS_PER_STORY" ]; then
    echo ""
    echo "🛑 $STORY_ID não foi concluída em $MAX_ATTEMPTS_PER_STORY tentativas seguidas. Parando para você olhar."
    echo "   Veja o fim de $PROGRESS_FILE e os logs em $LOG_DIR"
    exit 1
  fi

  i=$((i + 1))
  DONE_BEFORE=$(count_done)
  TAG=$(printf 'iter-%03d-%s' "$i" "$STORY_ID")

  echo ""
  echo "==============================================================="
  echo "  Ralph Iteration $i of $MAX_ITERATIONS — $(date '+%d/%m %H:%M')"
  echo "  Story: $STORY_ID - $STORY_TITLE (tentativa $ATTEMPTS/$MAX_ATTEMPTS_PER_STORY)"
  echo "  Progresso: $DONE_BEFORE/$TOTAL concluídas"
  echo "==============================================================="

  START_SHA=$(git rev-parse HEAD)
  START_TS=$(date +%s)
  RESULT_TEXT=""
  RESULT_JSON=""

  PROMPT_FILE="$LOG_DIR/$TAG.prompt.md"
  LOG_FILE="$LOG_DIR/$TAG.jsonl"
  ERR_FILE="$LOG_DIR/$TAG.stderr"
  {
    cat "$SCRIPT_DIR/CLAUDE.md"
    printf '\n\n---\n\n## Story desta iteração (escolhida pelo script)\n\n'
    printf 'Progresso: %s de %s stories concluídas. Esta é a tentativa %s desta story.\n\n' "$DONE_BEFORE" "$TOTAL" "$ATTEMPTS"
    printf '```json\n'
    echo "$STORY" | jq .
    printf '```\n'
  } > "$PROMPT_FILE"

  # Claude Code: --dangerously-skip-permissions para rodar sozinho; stream-json para acompanhar ao vivo
  claude --dangerously-skip-permissions --print \
    --output-format stream-json --verbose \
    --model "$MODEL" --effort "$EFFORT" \
    < "$PROMPT_FILE" 2> "$ERR_FILE" \
    | tee "$LOG_FILE" \
    | jq -rR --unbuffered --arg root "$REPO_ROOT" "$STREAM_FILTER" || true

  RESULT_JSON=$(jq -cR 'fromjson? | select(.type == "result")' "$LOG_FILE" 2>/dev/null | tail -1)
  RESULT_TEXT=$(echo "$RESULT_JSON" | jq -r '.result // empty' 2>/dev/null)
  IS_ERROR=$(echo "$RESULT_JSON" | jq -r '.is_error // false' 2>/dev/null)

  if [ -z "$RESULT_JSON" ] || [ "$IS_ERROR" = "true" ]; then
    ERR_TEXT="$RESULT_TEXT $(tail -c 3000 "$ERR_FILE" 2>/dev/null)"
    if echo "$ERR_TEXT" | grep -qiE 'usage limit|hit your limit|limit reached|limit will reset|resets (at|in) '; then
      echo ""
      echo "⏸️  Limite de uso do plano atingido ($(date '+%H:%M')). Esperando $((LIMIT_WAIT_SECONDS / 60)) min e tentando a mesma story de novo."
      echo "   Mensagem: $(echo "$ERR_TEXT" | tr -s '[:space:]' ' ' | cut -c1-200)"
      i=$((i - 1))
      ATTEMPTS=$((ATTEMPTS - 1))
      sleep "$LIMIT_WAIT_SECONDS"
      continue
    fi
    ERRORS=$((ERRORS + 1))
    echo ""
    echo "⚠️  O claude terminou com erro ($ERRORS/$MAX_CONSECUTIVE_ERRORS seguidos):"
    echo "   $(echo "$ERR_TEXT" | tr -s '[:space:]' ' ' | cut -c1-300)"
    if [ "$ERRORS" -ge "$MAX_CONSECUTIVE_ERRORS" ]; then
      echo "🛑 Erros demais seguidos. Parando. Veja $ERR_FILE"
      exit 1
    fi
    sleep "$ERROR_WAIT_SECONDS"
    continue
  fi
  ERRORS=0
  OUTPUT="$RESULT_TEXT"

  # ---------- resumo da iteração ----------
  ELAPSED=$(( $(date +%s) - START_TS ))
  DONE_AFTER=$(count_done)
  PASSES=$(story_passes "$STORY_ID")
  [ "$PASSES" = "true" ] && DONE_THIS_RUN=$((DONE_THIS_RUN + 1))
  COMMITS=$(git log --oneline "$START_SHA"..HEAD 2>/dev/null || true)
  DIFFSTAT=$(git diff --shortstat "$START_SHA" HEAD 2>/dev/null || true)
  DIRTY=$(git status --porcelain | wc -l | tr -d ' ')

  echo ""
  echo "──────── Resumo da iteração $i · $STORY_ID ────────"
  if [ "$PASSES" = "true" ]; then
    echo "Status:     ✅ concluída"
  else
    echo "Status:     ❌ não concluída (tentativa $ATTEMPTS/$MAX_ATTEMPTS_PER_STORY)"
  fi
  if [ -n "$RESULT_JSON" ]; then
    echo "Duração:    $(fmt_duration "$ELAPSED") · $(echo "$RESULT_JSON" | jq -r '.num_turns // "?"') turnos · US\$ $(echo "$RESULT_JSON" | jq -r '(.total_cost_usd // 0) * 100 | round / 100') (equivalente em API; no plano Max não é cobrado)"
  else
    echo "Duração:    $(fmt_duration "$ELAPSED")"
  fi
  if [ -n "$COMMITS" ]; then
    echo "Commits:"
    echo "$COMMITS" | sed 's/^/  /'
    echo "Arquivos:  ${DIFFSTAT:- nenhum}"
  else
    echo "Commits:    nenhum"
  fi
  [ "$DIRTY" != "0" ] && echo "Atenção:    $DIRTY arquivo(s) alterado(s) sem commit"
  echo "Progresso:  $DONE_AFTER/$TOTAL stories ($(( DONE_AFTER * 100 / TOTAL ))%)"
  if [ "$DONE_THIS_RUN" -gt 0 ]; then
    RUN_ELAPSED=$(( $(date +%s) - RUN_START ))
    ETA=$(( RUN_ELAPSED / DONE_THIS_RUN * (TOTAL - DONE_AFTER) ))
    echo "Estimativa: ~$(fmt_duration "$ETA") para o restante (média desta execução)"
  fi
  if [ -n "$OUTPUT" ]; then
    echo ""
    echo "Resposta do agente:"
    echo "$OUTPUT" | tail -n 15 | sed 's/^/  /'
  fi
  echo "Log completo: $LOG_DIR/$TAG.*"

  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Progresso: $(count_done)/$TOTAL. Check $PROGRESS_FILE for status."
exit 1
