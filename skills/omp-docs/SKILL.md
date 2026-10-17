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
omp --version && git --version
```

## Checkout location

Run the packaged `scripts/ensure-checkout.sh` from this skill directory. Resolve the skill directory from the loaded `SKILL.md` path instead of assuming a particular harness installation root.

```sh
<skill-directory>/scripts/ensure-checkout.sh <parent-directory>
```

Select the parent directory with an explicit argument or `OMP_DOCS_PARENT`. There is no writable `omp config path` fallback. Use the target's already-known path or [static path discovery](../omp-config/reference/common-tasks.md#static-path-discovery); if its cwd/profile/environment changes, resolve it again. For example, the usual default-profile parent is `$HOME/.omp`, while a named profile normally uses that profile's config root. An independent agent-directory override is not necessarily the config root.

The checkout always lives in a dedicated `omp-source` child. The helper never turns a non-empty OMP runtime directory into the source repository.

`OMP_DOCS_REPO` may override the upstream URL; the default is `https://github.com/can1357/oh-my-pi.git`. `OMP_DOCS_BRANCH` selects the approved development branch (default `main`). Initial clone selects that branch. Existing checkouts are updated only when their current branch explicitly tracks `origin/<approved-branch>` from the verified remote. Do not embed credentials in repository URLs.

## Required workflow

1. Run the health check and record the installed OMP version. For a strict no-mutation audit, use an existing checkout without running the refresh helper: clone/fetch/fast-forward write checkout files and contact the upstream.
2. For an authorized refresh, pass the resolved parent to `ensure-checkout.sh` and capture its final stdout line as the checkout path. Preserve the target cwd/profile/environment; the helper does not inherit a previous command's `--profile` flag.
3. Read the helper's stderr report of branch, upstream, revision, and approved branch before using refreshed docs. Dirty work, detached HEAD, missing/unapproved upstream, local-ahead/divergent commits, or failed fetch/fast-forward preserve HEAD and still return a valid docs path. Label those answers as a preserved revision with uncertain freshness or local-only changes. Never switch branches, reset, or discard user work to make refresh succeed. Wrong origin and unrelated directories remain hard errors.
4. Record the checkout commit and tag with `git -C <checkout> rev-parse --short HEAD` and `git -C <checkout> describe --tags --always`. Distinguish the installed version, checkout revision, and latest published release. A tag on main does not establish that a release has been published.
5. For installed behavior, read matching release-tag documentation without changing the checkout, using the upstream tag URL or `git show v<installed-version>:docs/<file>`. For recent-development questions, use the approved-branch checkout only if it refreshed successfully; otherwise use its existing docs with the explicit branch/freshness limitation or read upstream docs at a recorded revision. Label changes newer than the installation. State unavailable matching docs and version differences.
6. Search `<checkout>/docs` first for the exact command, setting, or concept, then retry close synonyms. Read enough surrounding context to establish the documented behavior.
7. For release or recent-change questions, also read `packages/coding-agent/CHANGELOG.md` and any affected package changelog. Check upstream published releases before calling an installation outdated; a changelog entry or tag alone is not publication evidence.
8. Inspect narrowly related source when the user requests implementation behavior, docs point there, or docs and the installed CLI disagree. Preserve documented/source disagreements and mark implementation-only conclusions as `[INFERENCE]`.

## Packaged-extension release proof

Keep documentation evidence separate from runtime evidence. Record the installed executable path/version, the authored package owner/revision, and the actual archive's name/version/SHA-256. Read the matching release's CLI, loader, installer, and root-path contracts before choosing a check. Swap the tag for the installed version; for OMP 18.11.3, use the tagged [CLI reference](https://raw.githubusercontent.com/can1357/oh-my-pi/v18.11.3/docs/cli-reference.md), [extension loading](https://raw.githubusercontent.com/can1357/oh-my-pi/v18.11.3/docs/extension-loading.md), [installer plumbing](https://raw.githubusercontent.com/can1357/oh-my-pi/v18.11.3/docs/plugin-manager-installer-plumbing.md), and [environment roots](https://raw.githubusercontent.com/can1357/oh-my-pi/v18.11.3/docs/environment-variables.md), not a newer checkout.

- Source imports, `-e <worktree>`, prepared isolation, and seeded fixture screenshots are not proof that the packaged extension loads in compiled installed OMP.
- Hand off package registration and fresh-root setup to [omp-config's packaged proof recipe](../omp-config/reference/validation.md#packaged-extension-installed-runtime-proof); use [tui-recording](../tui-recording/reference/recipe.md#packaged-omp-consumer-proof) for actual shortcut/TUI/state assertions.
- Report each exercised surface and limit. Registry-linked packaged bytes prove that loader path, not publication, upgrades or unexercised behavior. Record dependency installation separately when the consumer fixture actually performs it.

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
| Releases and recent changes | installed version, release tag, `packages/coding-agent/CHANGELOG.md`, upstream releases |

Use file search and section reads rather than opening unrelated files.

## Safety and source rules

- Treat the checkout as read-only unless the user explicitly asks to modify upstream source.
- Never delete or overwrite an existing unrelated directory.
- Never expose credentials from live OMP configuration while researching docs.
- Prefer documentation that matches the version being discussed over memory; do not apply main-only behavior to an older installation.
- Cite repository-relative documentation paths with the tag or commit when version-sensitive. Link published-release evidence when making release claims.
- If documentation and implementation disagree, state the disagreement, identify the compared revisions, and follow the source requested by the user.
