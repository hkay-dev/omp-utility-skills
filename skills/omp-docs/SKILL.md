---
name: omp-docs
description: Use to initialize or refresh a local Oh My Pi source checkout and answer OMP questions from the current upstream documentation.
---

# Oh My Pi Docs

## Purpose

Keep a safe local checkout of the Oh My Pi source, then answer OMP questions from its `docs/` directory instead of memory.

## When to use

Use this skill for questions about Oh My Pi commands, configuration, providers, models, tools, skills, plugins, MCP, releases, troubleshooting, or implementation behavior.

Use `omp-config` alongside this skill when the task changes live OMP configuration.

## Prerequisites

`omp` and `git` must be available.

Health check:

```sh
omp --version >/dev/null && git --version >/dev/null
```

## Checkout location

Run the packaged `scripts/ensure-checkout.sh` from this skill directory. Resolve the skill directory from the loaded `SKILL.md` path instead of assuming a particular harness installation root.

```sh
<skill-directory>/scripts/ensure-checkout.sh [parent-directory]
```

The parent directory is selected in this order:

1. Explicit command argument
2. `OMP_DOCS_PARENT`
3. The parent of the active OMP agent directory returned by `omp config path`

The checkout always lives in a dedicated `omp-source` child. For example, a parent of `~/.omp` produces `~/.omp/omp-source`. The helper never turns a non-empty OMP runtime directory into the source repository.

`OMP_DOCS_REPO` may override the upstream URL. The default is `https://github.com/can1357/oh-my-pi.git`.

## Required workflow

1. Run the health check.
2. Run `ensure-checkout.sh` and capture the checkout path printed on its final line.
3. If the helper reports local changes, do not overwrite them. Read the docs if possible and state that freshness is uncertain.
4. Search `<checkout>/docs` first for the exact command, setting, or concept.
5. Retry with close synonyms before concluding that the docs are silent.
6. Read the matching section with enough surrounding context to establish the documented behavior.
7. Inspect source outside `docs/` only when the user asks for implementation truth or the docs explicitly point there. Mark implementation-only conclusions as `[INFERENCE]`.

## Search guidance

| Topic | Start with |
| --- | --- |
| Configuration and settings | `config`, the setting key, `settings` |
| Skills and plugins | `skills`, `plugin`, `manifest`, `extension` |
| Models and providers | provider name, model name, `models.yml` |
| Authentication | provider name, `auth`, `credential`, `OAuth` |
| Tools | tool name under `docs/tools/` |
| MCP | `mcp`, transport name, server name |
| Hooks and commands | command name, `hook`, `slash` |

Use file search and section reads rather than opening unrelated files.

## Safety and source rules

- Treat the checkout as read-only unless the user explicitly asks to modify upstream source.
- Never delete or overwrite an existing unrelated directory.
- Never expose credentials from live OMP configuration while researching docs.
- Prefer current checked-out docs over memory.
- Cite repository-relative documentation paths such as `docs/config-usage.md`.
- If documentation and implementation disagree, state the disagreement and follow the source requested by the user.
