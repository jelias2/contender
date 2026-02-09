# Shared setup for query scripts: resolve DB path, require sqlite3 and DB file.
# Source this from query scripts. Use $1 as db path if set, else CONTENDER_DB, else default.

CONTENDER_DB="${1:-${CONTENDER_DB:-}}"
if [[ -z "$CONTENDER_DB" ]]; then
  CONTENDER_DB="${HOME:?}/.contender/contender.db"
fi
export CONTENDER_DB

if ! command -v sqlite3 &>/dev/null; then
  echo "error: sqlite3 not found. Install sqlite3 to run this script." >&2
  exit 1
fi

if [[ ! -f "$CONTENDER_DB" ]]; then
  echo "error: database not found: $CONTENDER_DB" >&2
  echo "Run contender at least once (e.g. contender spam ... erc20) to create the DB." >&2
  exit 1
fi
