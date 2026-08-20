#!/bin/sh
set -eu

usage() {
  echo "usage: ensure-checkout.sh [parent-directory]" >&2
  exit 2
}

[ "$#" -le 1 ] || usage
command -v git >/dev/null 2>&1 || { echo "git is required" >&2; exit 1; }

repo=${OMP_DOCS_REPO:-https://github.com/can1357/oh-my-pi.git}
if [ "$#" -eq 1 ]; then
  parent=$1
elif [ -n "${OMP_DOCS_PARENT:-}" ]; then
  parent=$OMP_DOCS_PARENT
else
  command -v omp >/dev/null 2>&1 || { echo "omp is required when no parent directory is supplied" >&2; exit 1; }
  agent_dir=$(omp config path)
  [ -n "$agent_dir" ] || { echo "omp config path returned an empty path" >&2; exit 1; }
  parent=$(dirname "$agent_dir")
fi

mkdir -p "$parent"
parent=$(cd "$parent" && pwd -P)
checkout=$parent/omp-source

if [ -e "$checkout" ] && [ ! -d "$checkout" ]; then
  echo "checkout path exists and is not a directory: $checkout" >&2
  exit 1
fi

if [ ! -d "$checkout/.git" ]; then
  if [ -d "$checkout" ] && [ -n "$(find "$checkout" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
    echo "refusing to replace non-empty unrelated directory: $checkout" >&2
    exit 1
  fi
  git clone --origin origin "$repo" "$checkout" >/dev/null
else
  origin=$(git -C "$checkout" remote get-url origin 2>/dev/null || printf '')
  if [ "$repo" = "https://github.com/can1357/oh-my-pi.git" ]; then
    case "$origin" in
      https://github.com/can1357/oh-my-pi|https://github.com/can1357/oh-my-pi.git|git@github.com:can1357/oh-my-pi.git|ssh://git@github.com/can1357/oh-my-pi.git) ;;
      *) echo "checkout origin is not the expected Oh My Pi repository: $origin" >&2; exit 1 ;;
    esac
  elif [ "$origin" != "$repo" ]; then
    echo "checkout origin does not match OMP_DOCS_REPO: $origin" >&2
    exit 1
  fi

  if [ -n "$(git -C "$checkout" status --porcelain)" ]; then
    echo "checkout has local changes; leaving it unchanged and freshness is uncertain" >&2
  else
    git -C "$checkout" fetch --prune origin >/dev/null
    if git -C "$checkout" rev-parse --verify '@{u}' >/dev/null 2>&1; then
      git -C "$checkout" pull --ff-only >/dev/null
    else
      echo "checkout has no upstream branch; fetched origin without changing HEAD" >&2
    fi
  fi
fi

[ -d "$checkout/docs" ] || { echo "checkout does not contain the expected docs directory: $checkout/docs" >&2; exit 1; }
printf '%s\n' "$checkout"
