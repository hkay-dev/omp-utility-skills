#!/bin/sh
set -eu

usage() {
  echo "usage: ensure-checkout.sh [parent-directory]" >&2
  exit 2
}

[ "$#" -le 1 ] || usage
command -v git >/dev/null 2>&1 || { echo "git is required" >&2; exit 1; }

repo=${OMP_DOCS_REPO:-https://github.com/can1357/oh-my-pi.git}
approved_branch=${OMP_DOCS_BRANCH:-main}
git check-ref-format "refs/heads/$approved_branch" >/dev/null 2>&1 || {
  echo "OMP_DOCS_BRANCH must name a valid branch" >&2
  exit 2
}
if [ "$#" -eq 1 ]; then
  parent=$1
elif [ -n "${OMP_DOCS_PARENT:-}" ]; then
  parent=$OMP_DOCS_PARENT
else
  echo "supply parent-directory or OMP_DOCS_PARENT; writable omp config path discovery is not used" >&2
  exit 2
fi

mkdir -p "$parent"
parent=$(cd "$parent" && pwd -P)
checkout=$parent/omp-source

if [ -e "$checkout" ] && [ ! -d "$checkout" ]; then
  echo "checkout path exists and is not a directory: $checkout" >&2
  exit 1
fi

if [ ! -e "$checkout/.git" ]; then
  if [ -d "$checkout" ] && [ -n "$(find "$checkout" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
    echo "refusing to replace non-empty unrelated directory: $checkout" >&2
    exit 1
  fi
  git clone --origin origin --branch "$approved_branch" "$repo" "$checkout" >/dev/null
else
  origin=$(git -C "$checkout" remote get-url origin 2>/dev/null || printf '')
  if [ "$repo" = "https://github.com/can1357/oh-my-pi.git" ]; then
    case "$origin" in
      https://github.com/can1357/oh-my-pi|https://github.com/can1357/oh-my-pi.git|git@github.com:can1357/oh-my-pi.git|ssh://git@github.com/can1357/oh-my-pi.git) ;;
      *) echo "checkout origin is not the expected Oh My Pi repository" >&2; exit 1 ;;
    esac
  elif [ "$origin" != "$repo" ]; then
    echo "checkout origin does not match OMP_DOCS_REPO" >&2
    exit 1
  fi

  branch=$(git -C "$checkout" symbolic-ref --quiet --short HEAD 2>/dev/null || printf '(detached)')
  upstream=$(git -C "$checkout" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || printf '(none)')
  upstream_remote=$(git -C "$checkout" config --get "branch.$branch.remote" || printf '')
  upstream_merge=$(git -C "$checkout" config --get "branch.$branch.merge" || printf '')
  revision=$(git -C "$checkout" rev-parse --short HEAD)
  echo "checkout branch=$branch upstream=$upstream revision=$revision; approved=origin/$approved_branch" >&2

  if [ -n "$(git -C "$checkout" status --porcelain)" ]; then
    echo "checkout has local changes; leaving HEAD unchanged and freshness is uncertain" >&2
  elif [ "$upstream_remote" != origin ] || [ "$upstream_merge" != "refs/heads/$approved_branch" ]; then
    echo "checkout is detached, has no upstream, or tracks an unapproved remote/branch; leaving HEAD unchanged" >&2
  elif ! git -C "$checkout" fetch --prune origin "+refs/heads/$approved_branch:refs/remotes/origin/$approved_branch" >/dev/null; then
    echo "approved upstream fetch failed; preserved checkout is available with uncertain freshness" >&2
  elif git -C "$checkout" merge-base --is-ancestor HEAD "refs/remotes/origin/$approved_branch"; then
    if ! git -C "$checkout" merge --ff-only "refs/remotes/origin/$approved_branch" >/dev/null; then
      echo "approved fast-forward failed; preserved checkout is available with uncertain freshness" >&2
    fi
  elif git -C "$checkout" merge-base --is-ancestor "refs/remotes/origin/$approved_branch" HEAD; then
    echo "checkout has local commits ahead of the approved upstream; leaving HEAD unchanged" >&2
  else
    echo "checkout diverged from the approved upstream; leaving HEAD unchanged and docs are a preserved stale revision" >&2
  fi
fi

[ -d "$checkout/docs" ] || { echo "checkout does not contain the expected docs directory: $checkout/docs" >&2; exit 1; }
printf '%s\n' "$checkout"
