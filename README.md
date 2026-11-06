# Herdr Git History (Windows)

A Git button for the Herdr app's top bar, backed by [rabeeh-ta/herdr-git-graph](https://github.com/rabeeh-ta/herdr-git-graph) v0.3.1. This repository keeps the working Windows setup together: the Git Graph mod, a cloned tab bar and layout, and PowerShell working-directory sync. The upstream Git Graph code is MIT licensed; its copyright and license are retained in `LICENSE`. The tab bar and layout are personal clones of Herdr 0.1.13.

## Install

Requirements: Windows, Herdr app, PowerShell 7, `hc` and `herdr-app` on `PATH`, and Git. Run from this checkout:

```powershell
./install.ps1
```

The installer copies `mod/` to `~/.config/herdr-app/mods/git-graph/`, `tabs-graph/` to `mods/tabs-graph/`, `layouts/main-graph.json` to `layouts/`, and `powershell/herdr-cwd.ps1` to `integration/`. It adds a small loader to the current user's PowerShell profile. Existing Herdr files are backed up under `~/.config/herdr-app/backups/herdr-git-history/<timestamp>/`; a profile changed by the installer gets a `.before-herdr-git-history-<timestamp>` backup beside it. It then runs `herdr-app check` for both mods.

Select the `main-graph` layout if it is not already active:

```powershell
herdr-app do layout.switch --name main-graph
```

Open a **new** PowerShell tab in Herdr so the updated profile loads. Use the normal workflow: press `+`, enter a shell, `cd` to a repository, start Codex if wanted, then click **Git**.

## Why Windows needs directory sync

The Git Graph panel normally reads the focused terminal's directory from Herdr. On the Windows setup this repo was built from, Herdr Core retained the terminal's launch directory (`~`) after PowerShell changed to another folder. Codex knew the correct project directory because the user's PowerShell `codex` function passed `-C (Get-Location).Path`, but that did not update Herdr's directory value. A new `pwd` command launched by the mod would inherit the mod's directory, so it would not reliably read Codex's directory either.

The PowerShell integration runs when the prompt returns after `cd`. When the filesystem path changes, it uses `hc label` to set `workspace.cwd` on that Herdr terminal. Git Graph looks up the focused terminal's label first, then falls back to Herdr's normal directory. It validates the location through Git when loading history. This is local shell and mod work; clicking Git makes no Codex model request.

The profile hook applies to newly opened PowerShell terminals. An existing terminal keeps its PowerShell process when Codex exits and restarts. At that terminal's PowerShell prompt, load the hook once:

```powershell
. $HOME/.config/herdr-app/integration/herdr-cwd.ps1
```

The Git panel can remain open. After `cd` returns to the PowerShell prompt, the hook updates the terminal label and the panel checks for a new location once per second. To update a terminal's label manually instead:

```powershell
hc label <terminal-id> "workspace.cwd=$((Get-Location).ProviderPath)"
```

`hc get <terminal-id> --json` shows the label. `herdr-app status` should show `"errors": []`. Clicking Git should show the branch and commits for the selected repository. The mod check validates loading, but viewing the panel verifies the active terminal and path together.

## Where the button lives

| Part | Installed location |
| --- | --- |
| Git button | `~/.config/herdr-app/mods/tabs-graph/main.js` |
| Panel block | `~/.config/herdr-app/layouts/main-graph.json` |
| Git history and directory choice | `~/.config/herdr-app/mods/git-graph/graph.js` |
| Windows directory reporter | `~/.config/herdr-app/integration/herdr-cwd.ps1`, loaded by PowerShell profile |

The layout's Git panel intentionally has no fixed `props.folder`. A fixed folder makes every tab show one repository. The [upstream top-bar guide](https://github.com/rabeeh-ta/herdr-git-graph/blob/main/docs/top-bar.md) likewise uses a panel without that prop.

## Compatibility and updates

- The packaged tab bar and layout come from Herdr 0.1.13. A later Herdr release may change its shipped layout or tab bar; compare those files before replacing this clone.
- The upstream Git Graph README says Windows is untested. Its single-repository graph works in this setup. Its Manygit folder scan uses Unix `find` and `env`, so that view is not expected to work on Windows.
- Updating `git-graph` directly from upstream overwrites the local `workspace.cwd` change in `graph.js`. Re-run this repository's `install.ps1` afterward to restore the Windows integration. The installer backs up the installed copy first.
- The integration follows PowerShell `cd` before starting Codex. If Codex is explicitly started with `-C` pointing somewhere else, or changes workspace internally while running, the prompt label still reflects the shell's last directory; that case needs a separate update.

This repository contains no Codex transcripts, credentials, personal paths, generated Herdr type files, or runtime state.
