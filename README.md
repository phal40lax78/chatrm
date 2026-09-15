# chatrm

Find and delete local AI-assistant chat transcripts — Claude Code, GitHub Copilot
Chat, and Codex — from PowerShell.

All three keep every conversation on disk, and none offers a per-chat delete.
`claude project purge` works a whole project at a time; archiving in VS Code only
hides a chat from the list. This deletes one chat, whichever tool wrote it.

One file. No modules, no dependencies, nothing to build.

## Install

```powershell
iex (irm https://raw.githubusercontent.com/phal40lax78/chatrm/main/install.ps1)
```

Then type `chat`. No need to reopen anything — the commands are live in the
shell you just ran that in.

The install builds the search index on the way through, which takes about 30
seconds and is what Tab completion reads. If you ever delete `data/`, run
`chatindex` once to rebuild it — Tab reads that index and never builds it,
because a keypress cannot sit for 30 seconds.

That downloads `chatrm.ps1` to `~/Tools/chatrm`, loads it, and writes the line
into your `$PROFILE`, so every future shell picks it up too. Set
`$env:CHATRM_DIR` first to put it somewhere else.

The file has to reach disk — it is not run from memory. `chatrm.ps1` locates
`data/` and the profile line from its own path, so with no file behind it both
come out empty. `iex` is what makes the one-liner work: it runs in *your* scope,
so the dot-source inside the installer lands the commands in the session you
typed from.

`~/Tools/chatrm` is a suggestion, not a requirement. Nothing reads the script's
own location except `data/`, which sits beside it, so any folder you own works.
Avoid `.claude`, `.codex` and `.vscode` — those belong to the tools named after
them, which rewrite them on update and clear them on reinstall.

If you would rather read before running, the installer is
[install.ps1](install.ps1), and doing it by hand is four lines:

```powershell
$dir = "$HOME\Tools\chatrm"
New-Item $dir -ItemType Directory -Force | Out-Null
Invoke-WebRequest https://raw.githubusercontent.com/phal40lax78/chatrm/main/chatrm.ps1 -OutFile "$dir\chatrm.ps1"
. "$dir\chatrm.ps1"; chatinstall
```

### Already have the file

If `chatrm.ps1` is already on disk — you cloned the repo, or downloaded it by
hand — skip the download and just load it:

```powershell
. "$HOME\Tools\chatrm\chatrm.ps1"
chatinstall
```

To get that line right without typing a path: type a dot and a space, then drag
`chatrm.ps1` out of Explorer onto the window — or shift+right-click it there,
**Copy as path**, and paste. Point it at the `.ps1` itself, never the folder
holding it; a folder gives *"The term '...' is not recognized"*.

The leading dot is not decoration. `. chatrm.ps1` loads the commands into the
shell you are standing in; `& chatrm.ps1`, or double-clicking the file, runs it
and throws every command away as it exits. The script detects that and tells you,
so a shell is never left silently empty.

`chatinstall` writes the line into `$PROFILE` itself — the script knows where it
is, so the path is only ever typed once. Run it again after moving the file and
it repoints the old line instead of leaving a dead one behind.

It only ever runs after a dot-source, so the commands are already loaded in the
shell you called it from. The profile line is for *future* shells; nothing needs
reopening or closing to start using it now.

### Updating

Run the same one-liner again. It overwrites `chatrm.ps1` in place, leaves `data/`
alone, and says which of the two actually happened:

```
updated 1.0.0 -> 1.1.0
version 1.1.0 - unchanged
```

`unchanged` right after a push is usually the CDN, not a failed update —
`raw.githubusercontent.com` serves the previous copy for a few minutes and a
query string will not bust it. Wait, then run it again.

`chat` prints the version it is running, at the bottom. A copy from before
versions existed reports as a plain `version`, with nothing to compare against.

## Uninstall

```powershell
chatuninstall        # drop the line from $PROFILE, keep the folder
chatuninstall -All   # and delete the folder, data/ included
```

It backs the profile up to `$PROFILE.bak` first and leaves every other line in
it alone — an old `deleteLocalChat` line is caught too. Without `-All` it prints
the `Remove-Item` for the folder so you can delete it whenever you like; the
folder holds `data/`, which is the index and the delete tombstones.

The commands stay defined in the shell you run it from. They are already in
memory and nothing can unload them; close the window and they are gone.

Nothing else is left behind. The tool never writes outside its own folder except
for that one profile line — no registry keys, no AppData, no scheduled tasks.

## Commands

| | |
|---|---|
| `chatfind "text"` | find chats by title or message |
| `chatrm <id>` or `chatrm "title"` | delete a chat, permanently |
| `chatclean` | delete ghost chats left behind by the VS Code list |
| `chatproviders` | which tools were found, and where |
| `chatindex` | rebuild the tab-completion index |
| `chatinstall` | load these in every new shell |
| `chatuninstall [-All]` | undo that; `-All` removes the folder too |
| `chat` | cheat sheet |

Flags: `-Deep` `-All` `-AllProjects` `-Force` `-Provider claude|copilot|codex`

`chatfind` emits objects, so it composes:

```powershell
chatfind commit | Select-Object Provider, Title, Id, Age
```

## Tab

Tab fills in the **whole argument**, not the word under the cursor:

```
chatrm gitign<Tab>     chatrm 'Gitignore file' (21d) #1/2
(down)                 chatrm 'Gitignore rules' (5d) #2/2
```

Quoting it yourself changes nothing — a leading `"` or `'` is dropped before
matching, and the title always comes back single-quoted. Tab/down for next,
Shift+Tab/up for previous, Enter runs it, Ctrl+Space opens the full list.

Opt out with `$ChatNoKeyBindings = $true` before the dot-source.

## Deleting is permanent

Titles match on **substring**, so part of a title is a search rather than a
choice. `chatrm Haiku` matches a chat called *Haiku ChatGPT Opus Astra*, and one
match is not the same as the right match.

So a fragment never deletes on its own:

- **Part of a title** — the match is filled in the way Tab would, and Enter has
  to be pressed again on the full title. Where no key handler can reach — a
  script, `-NoProfile`, no VT — it asks `delete permanently? y / Enter = yes`.
- **A whole title** — deletes, as before. Typing all of it is the decision.
- **An id** — deletes. An id is exact by definition.
- **`-Force`** — skips all of the above.

There is no recycle bin and no undo. `chatrm` removes the transcript and what it
leaves behind: sidecars, `file-history` and `session-env` for Claude,
`chatEditingSessions` for Copilot.

## Scope

Titles match chats belonging to the directory you are standing in — Claude by its
project slug, Copilot and Codex by folder name — so a sibling repo never answers
for this one. `-AllProjects` widens it. Ids skip scoping entirely: one id is one
chat, wherever it lives.

## Where it looks

| | |
|---|---|
| Claude Code | `~/.claude/projects/<slug>/<uuid>.jsonl` |
| Copilot Chat | `<Code user>/workspaceStorage/<hash>/chatSessions/<uuid>.json` |
| Codex | `~/.codex/sessions/YYYY/MM/DD/rollout-<iso>-<uuid>.jsonl` |

`<Code user>` is `%APPDATA%/Code/User` on Windows, `~/Library/Application
Support/Code/User` on macOS, `~/.config/Code/User` on Linux.
`CLAUDE_CONFIG_DIR` and `CODEX_HOME` are honoured.

Codex titles come from `thread_name` in `~/.codex/session_index.jsonl`, which is
the name the panel shows — the first prompt is often nothing like it.

## Notes

Deletion is permanent. No recycle bin.

Transcripts are opened `FileShare.ReadWrite | Delete`. Codex holds every rollout
open for the life of the window, so an ordinary read throws on all of them — get
this wrong and no Codex chat is visible at all.

On Windows, deleting a transcript a live window still holds fails and is reported
`LOCKED`; close the window. On macOS and Linux there is no such protection —
unlinking an open file simply succeeds, and the window goes on writing to a file
that is no longer there.

A chat still listed in the VS Code panel is one the window is tracking, and it
flushes session state to disk when it reloads. That recreates a just-deleted chat
as an empty stub. A `FileSystemWatcher` takes that rewrite back the moment it
lands, and `data/rewritten.txt` records it for shells that were not open at the
time. `chatclean` sweeps the stubs.

`hiddenSessionIds` — the VS Code archive list — is never touched.

`data/` sits next to the script and holds the index; nothing else reads the
script's own location, so it runs from anywhere. Do not copy `data/chat-index.csv`
between machines: it holds absolute paths and rebuilds itself in ~30s.

## Requirements

Windows PowerShell 5.1 or PowerShell 7. macOS and Linux need PowerShell 7.

## Licence

MIT
