#!/bin/sh
# ctf.sh — game controller for the Heartbleed CTF.
# Reads the self-contained level folders under levels/ and grades flags against
# the real secrets in shared/secrets.env (gitignored). POSIX sh, no deps.
set -eu

ROOT=$(cd "$(dirname "$0")" && pwd)
LEVELS_DIR="$ROOT/levels"
SECRETS="$ROOT/shared/secrets.env"

c_reset=''; c_bold=''; c_green=''; c_red=''; c_dim=''
if [ -t 1 ]; then
  c_reset=$(printf '\033[0m'); c_bold=$(printf '\033[1m')
  c_green=$(printf '\033[32m'); c_red=$(printf '\033[31m'); c_dim=$(printf '\033[2m')
fi

die() { printf '%s\n' "$*" >&2; exit 1; }

# Load one level's manifest into LEVEL_* vars. Arg: level id.
load_level() {
  _dir=$(find "$LEVELS_DIR" -mindepth 1 -maxdepth 1 -type d -name "*$1*" 2>/dev/null | head -n1)
  [ -n "${_dir:-}" ] && [ -f "$_dir/level.env" ] || die "Unknown level: $1 (try './ctf.sh levels')"
  LEVEL_DIR=$_dir
  # defaults so a sparse manifest still works
  LEVEL_ID=''; LEVEL_TITLE=''; LEVEL_CATEGORY=''; LEVEL_NUMBER=''
  LEVEL_POINTS=''; LEVEL_TARGET=''; LEVEL_FLAG_VAR=''; LEVEL_STATUS='planned'
  # shellcheck disable=SC1090
  . "$_dir/level.env"
}

# Echo the real flag for the loaded level, or empty if unavailable.
real_flag() {
  [ -n "$LEVEL_FLAG_VAR" ] && [ -f "$SECRETS" ] || return 0
  # pull `VAR=value` from secrets.env without sourcing the whole file
  val=$(grep -E "^[[:space:]]*$LEVEL_FLAG_VAR=" "$SECRETS" 2>/dev/null | tail -n1 | cut -d= -f2-)
  # strip surrounding quotes and trailing whitespace
  val=${val%\"}; val=${val#\"}; val=${val%\'}; val=${val#\'}
  printf '%s' "$val" | sed 's/[[:space:]]*$//'
}

cmd_levels() {
  printf '%s%-11s %-3s %-9s %-7s %s%s\n' "$c_bold" "ID" "#" "CATEGORY" "STATUS" "TITLE" "$c_reset"
  for d in "$LEVELS_DIR"/*/; do
    [ -f "$d/level.env" ] || continue
    case "$d" in */_template/) continue ;; esac
    ( load_level "$(basename "$d")"
      badge=$LEVEL_STATUS
      [ "$LEVEL_STATUS" = ready ] && badge="${c_green}ready${c_reset}" || badge="${c_dim}planned${c_reset}"
      printf '%-11s %-3s %-9s %-16s %s\n' \
        "$LEVEL_ID" "${LEVEL_NUMBER:-?}" "$LEVEL_CATEGORY" "$badge" "$LEVEL_TITLE"
    )
  done
}

cmd_brief()    { load_level "${1:?usage: ctf.sh brief <level-id>}";    cat "$LEVEL_DIR/challenge.md"; }
cmd_solution() { load_level "${1:?usage: ctf.sh solution <level-id>}"; cat "$LEVEL_DIR/solution.md"; }

cmd_submit() {
  load_level "${1:?usage: ctf.sh submit <level-id> <flag>}"
  guess=${2:?usage: ctf.sh submit <level-id> <flag>}
  [ "$LEVEL_STATUS" = ready ] || die "Level $LEVEL_ID is not playable yet (status: $LEVEL_STATUS)."
  want=$(real_flag)
  [ -n "$want" ] || die "No flag configured. Create $SECRETS with $LEVEL_FLAG_VAR set (see shared/secrets.env.example)."
  if [ "$guess" = "$want" ]; then
    printf '%s[+] Correct — %s solved! +%s points%s\n' "$c_green" "$LEVEL_ID" "${LEVEL_POINTS:-0}" "$c_reset"
  else
    printf '%s[-] Wrong flag for %s. Keep leaking.%s\n' "$c_red" "$LEVEL_ID" "$c_reset"; exit 1
  fi
}

level_ids() {
  for d in "$LEVELS_DIR"/*/; do
    [ -f "$d/level.env" ] || continue
    case "$d" in */_template/) continue ;; esac
    basename "$d"
  done | tr '\n' ' '
}

usage() {
  ids=$(level_ids)
  cat <<EOF
${c_bold}Heartbleed CTF${c_reset}
  ./ctf.sh levels               list all levels and their status
  ./ctf.sh brief    <level-id>  show a level's challenge brief
  ./ctf.sh submit   <level-id> <flag>   grade a flag
  ./ctf.sh solution <level-id>  instructor: show the reference solution

Level ids: $ids
EOF
}

case "${1:-}" in
  levels|list) cmd_levels ;;
  brief|show)  shift; cmd_brief "$@" ;;
  submit)      shift; cmd_submit "$@" ;;
  solution)    shift; cmd_solution "$@" ;;
  ''|-h|--help|help) usage ;;
  *) usage; exit 1 ;;
esac
