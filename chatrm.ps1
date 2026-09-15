<#
chatrm - find and delete local AI-assistant chat transcripts.

Claude Code, Copilot Chat and Codex keep every chat on disk and none offers a
per-chat delete (claude project purge is per-project; archiving only hides).
This deletes one chat, whichever tool wrote it.

INSTALL   two lines, and the path in the first one need not be typed
    . "$HOME\Tools\chatrm\chatrm.ps1"
    chatinstall

  To get that first line right without typing a path at all: type a dot and a
  space, then drag the .ps1 out of Explorer and drop it on the window - or
  shift+right-click it there, "Copy as path", and paste. Enter, then chatinstall.

  Point it at the .ps1 itself, never the folder holding it. A folder gives "The
  term '...' is not recognized", because a folder is not a command - the filename
  is the part that gets left off. Quotes only start to matter once the path has a
  space in it, and "Copy as path" supplies them either way.

  The leading dot matters as much as the path does. `. file.ps1` loads the
  commands into the shell you are standing in; `& file.ps1`, or double-clicking
  the file, runs it and throws every command away again as it exits. It notices
  that itself and prints the line you meant to type, so a shell is never left
  silently empty - though a double-clicked window closes too fast to read it.

  Open a new terminal and type chat.

  chatinstall writes the profile line itself - the script knows where it is, so
  the path is only ever typed once. It calls Unblock-File for you on Windows,
  makes the profile if there is none, and backs it up to $PROFILE.bak first.
  Run it again after moving the file: it replaces the old line instead of leaving
  one that loads nothing and says nothing about it. -Force rewrites regardless.
  If even that first line will not run, the execution policy is Restricted -
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned, once, Windows only.

  One file, no modules, no dependencies. It runs from anywhere - only data/ sits
  beside it - but a folder of its own that no other tool owns is the one to pick,
  hence ~/Tools/chatrm above. Not .claude, .codex or .vscode: those
  belong to the tools named after them, which rewrite them on update and clear
  them on reinstall, and would take the index with them. Not a folder shared with
  other scripts either, where a second data/ would land on top of this one.
  Moving it later is fine - move data/ with it and re-run chatinstall, which
  repoints the profile line rather than leaving a dead one. $PROFILE is per host:
  Documents\WindowsPowerShell for 5.1, Documents\PowerShell for pwsh, and a
  redirected Documents folder moves both - so install once in each shell you use.
  Do not copy data/chat-index.csv - it holds absolute paths from the old machine
  and rebuilds itself on the first search (~30s).

COMMANDS
    chatfind "text" [-Deep] [-All] [-AllProjects] [-Provider codex,copilot]
    chatrm <id|prefix> [...]       unambiguous - deletes outright
    chatrm "<title>" [-Force]      walk the matches, confirm; -Force takes all
    chatclean                      ghost chats (no messages, < 64 KB)
    chatproviders / chatindex      what was found / rebuild the index
    chatinstall / chatuninstall    add to, or drop from, your profile
    chat                           cheat sheet

  chatfind emits objects:  chatfind commit | Select Provider,Title,Id,Age

SCOPE
  Titles match chats belonging to the directory you are standing in - Claude by
  its project slug, Copilot and Codex by the folder name - so a sibling repo
  never answers for this one. Those slugs nest (…-AS-RadarViewer is a prefix of
  …-AS-RadarViewer-Mobile), so the test is exact rather than a prefix, and
  case-insensitive because the drive letter's case varies. Tab is scoped the
  same way, or it would offer chats chatrm then refused to match.
  -AllProjects widens it. Ids skip it - one id is one chat, wherever it lives.
  Standing somewhere that is no project at all narrows nothing.

TAB
    chatrm gitign<Tab>     chatrm 'Gitignore file' (21d) #1/2
    (down)                 chatrm 'Gitignore rules' (5d) #2/2
    chatrm "gitign<Tab>    chatrm 'Gitignore file' (21d) #1/2

  Tab fills in the argument - the whole of it, not the word under the cursor.
  Everything typed after the command is replaced by one quoted title, so
  quoting it yourself changes nothing: a leading " or ' is dropped before
  matching and the title always comes back in single quotes. No quote is left
  to close, and no half-typed word to finish by hand.
  Tab/down next, Shift+Tab/up previous, Enter runs it, Ctrl+Space the full
  list. Prefix match on the whole argument, spaces and all; widens to contains
  when nothing starts with it; hex matches ids. Arrows stay history unless a
  run is live, and editing the line ends the run.
  Opt out: $ChatNoKeyBindings = $true before the dot-source.

  Enter strips "(21d) #1/2" before running - and strips it on any chatrm or
  chatfind line, not only a live run, because it survives an edit. "#1/2" alone
  was a comment and safe to leave; "(21d)" is not, PowerShell would run it.

  The buffer is rewritten because nothing else can be drawn from a key handler:
  PSReadLine's reader already owns the keyboard, so a pane of our own never
  gets a keystroke.

PICKING
  One line everywhere - Tab, one match, several matches all look the same, in
  the same colours (read from PSReadLine, so it follows your theme):
    chatrm 'UI zoom in/out function' (9d) #1/2
    chatrm 'Zoom in/out functions' (3d) #2/2
  Enter deletes what is on screen, at once: no detail dump, no confirmation.
  Esc backs out. Two chats can share a title AND an age - only then does the
  line add the project and size, since nothing else would separate them.
  Enter shows it in full, then:  delete permanently?   Yes   No   (Enter = Yes)
  chatclean uses a checkbox list (space toggle, a all) so ghosts go in one pass.
  Redraws use escape sequences: under VS Code's pseudo-console CursorPosition
  is accepted and ignored. No VT -> numbered list and a typed y/N.

GHOSTS
  A chat still listed in the panel is one the window is tracking, and it
  flushes session state to disk when it reloads or closes. That recreates a
  chat deleted minutes earlier as a stub - ai-title, mode, atis-latch, no
  messages, and a brand new creation time, so it is a fresh write and not a
  failed delete. Archived chats are filtered out of that list, never tracked,
  and stay deleted first time.
  That write happens once. After the reload the window rebuilds its list from
  disk and is no longer holding the session, which is why deleting a second
  time always worked. So it is watched for rather than waited out: a
  FileSystemWatcher on newly created .jsonl files takes the rewrite back the
  moment it lands, with no second command to run. The deletion is written down
  too - data/rewritten.txt - as the backstop for shells that were not open at
  the time, swept by the next chat command.
  Either path only removes a file that is still a stub, so resuming that
  session for real ends it. Tombstones expire after 7 days.
  Deleting can also simply fail - Windows will not remove a file another
  process holds open. That prints LOCKED and is not counted as deleted.

SPEED
  Search and completion run off data/chat-index.csv next to this script; a file
  is re-read only on size/mtime change. ~30s first build, ~1.5s after.
  chatindex -Force rebuilds.

PROVIDERS   one entry each in $script:ChatProviders - Discover/Describe/Extras
    claude   <config>/projects/<slug>/<uuid>.jsonl. Title: custom-title /
             ai-title line, else sidecar custom-title.json, else first prompt.
             Extras: sidecar dir, file-history/<id>, session-env/<id>.
    copilot  <Code user>/workspaceStorage/<hash>/chatSessions/<uuid>.json, where
             <Code user> is %APPDATA%/Code/User on Windows, ~/Library/Application
             Support/Code/User on macOS and ~/.config/Code/User on Linux.
             customTitle, requests[].message.text. Extras: chatEditingSessions/<id>.
    codex    ~/.codex/sessions/YYYY/MM/DD/rollout-<iso>-<uuid>.jsonl. Title:
             thread_name in ~/.codex/session_index.jsonl, which is the name the
             panel lists; else first real prompt, IDE and AGENTS.md preambles
             filtered.
  CLAUDE_CONFIG_DIR and CODEX_HOME are honoured.

NOTES
  Transcripts are opened FileShare.ReadWrite+Delete. Codex holds every rollout
  open for the life of the window, so a plain read throws on all of them and no
  Codex chat is seen at all. Deleting one a live window still holds fails, and
  is reported LOCKED - close the window.
  Permanent, no recycle bin. Age = last real message; Touched = mtime, which is
  what the GUIs show (titles and resumes bump it). Lists are cached until
  Developer: Reload Window. hiddenSessionIds (the archive) is never touched.
  Windows PowerShell 5.1 or pwsh 7; macOS and Linux need pwsh 7. Only Windows
  holds a file against deletion, so LOCKED is a Windows-only guard - elsewhere
  unlinking a transcript a live window still has open simply succeeds, and that
  window goes on writing to a file no longer on disk.
#>

$script:ChatPreview = 3
$script:ChatClaudeHome = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
$script:ChatCodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
# $IsMacOS exists only on pwsh 6+. On 5.1 it is undefined, and under StrictMode
# reading an undefined variable throws outright rather than yielding $false -
# this file is dot-sourced into whatever session the user already has, so it
# cannot assume strict mode is off. Get-Variable answers without touching it.
$script:ChatIsMac = [bool](Get-Variable -Name IsMacOS -ValueOnly -EA SilentlyContinue)

# VS Code's user dir moves per platform: APPDATA on Windows, Application Support
# on macOS, XDG on Linux. Without the middle branch a Mac falls to the Linux path
# and the copilot provider quietly finds nothing at all.
$script:ChatCodeUser =
if ($env:APPDATA) { Join-Path $env:APPDATA 'Code\User' }
elseif ($script:ChatIsMac) { Join-Path $HOME 'Library/Application Support/Code/User' }
else { Join-Path $HOME '.config/Code/User' }
$script:ChatWorkspaceNames = @{}
$script:ChatIndexPath = Join-Path (Join-Path $PSScriptRoot 'data') 'chat-index.csv'
$script:ChatTombPath = Join-Path (Join-Path $PSScriptRoot 'data') 'rewritten.txt'

#region index -----------------------------------------------------------------
# Reading 2000+ transcripts takes ~30s, so nothing does it twice. The index
# holds everything a search needs - title, group, previews, last activity - and
# a file is only re-read when its size or mtime changed. Searches and tab
# completion both run off it.

$script:ChatIndexSep = [char]0x1F   # unit separator: never appears in prompt text

function Get-ChatIndex {
    # CSV, not JSON: ConvertTo-Json on a few thousand rows costs tens of seconds.
    # Kept in memory too, so repeated Tab presses re-parse nothing.
    if (-not (Test-Path -LiteralPath $script:ChatIndexPath)) { return @() }
    $stamp = try {
        $fi = [System.IO.FileInfo]::new($script:ChatIndexPath)
        "$($fi.LastWriteTimeUtc.Ticks):$($fi.Length)"
    }
    catch { $null }
    if ($stamp -and $stamp -eq $script:ChatIndexStamp) { return $script:ChatIndexCache }
    try {
        $rows = @(Import-Csv -LiteralPath $script:ChatIndexPath | ForEach-Object {
                [pscustomobject]@{
                    Provider = $_.Provider
                    Path     = $_.Path
                    Size     = [int64]$_.Size
                    Mtime    = [int64]$_.Mtime
                    Id       = $_.Id
                    Title    = $_.Title
                    Titled   = $_.Titled
                    Group    = $_.Group
                    Hidden   = $_.Hidden -eq 'True'
                    When     = $_.When
                    First    = @($_.First -split $script:ChatIndexSep | Where-Object { $_ })
                    Last     = @($_.Last -split $script:ChatIndexSep | Where-Object { $_ })
                }
            })
        $script:ChatIndexCache = $rows
        $script:ChatIndexStamp = $stamp
        return $rows
    }
    catch { return @() }
}

function Save-ChatIndex {
    param([object[]]$Rows)
    try {
        $dir = Split-Path $script:ChatIndexPath -Parent
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $Rows | ForEach-Object {
            [pscustomobject]@{
                Provider = $_.Provider; Path = $_.Path; Size = $_.Size; Mtime = $_.Mtime
                Id = $_.Id; Title = $_.Title; Titled = $_.Titled; Group = $_.Group
                Hidden = $_.Hidden; When = $_.When
                First = (@($_.First) -join $script:ChatIndexSep)
                Last = (@($_.Last) -join $script:ChatIndexSep)
            }
        } | Export-Csv -LiteralPath $script:ChatIndexPath -NoTypeInformation -Encoding UTF8
    }
    catch {}
}

function Sync-ChatIndex {
    # returns the index rows for $Provider, re-reading only what changed
    param([string[]]$Provider, [switch]$Force)
    # before indexing, so a chat the window wrote back never gets indexed
    Clear-ChatTombstones
    $names = if ($Provider) { $Provider } else { @($script:ChatProviders.Keys) }
    $cached = @(Get-ChatIndex)
    $old = @{}
    foreach ($r in $cached) {
        if (-not $r.Path) { continue }
        if ($Force -and $names -contains $r.Provider) { continue }
        $old[$r.Path] = $r
    }

    $rows = [System.Collections.Generic.List[object]]::new()
    $fresh = 0
    $reused = 0
    foreach ($name in $names) {
        $p = $script:ChatProviders[$name]
        if (-not $p) { Write-Warning "unknown provider '$name'"; continue }
        foreach ($file in @(& $p.Discover)) {
            $hit = $old[$file.FullName]
            if ($hit -and $hit.Size -eq $file.Length -and $hit.Mtime -eq $file.LastWriteTimeUtc.Ticks) {
                $rows.Add($hit)     # unchanged since last time
                $reused++
                continue
            }
            $rec = & $p.Describe $file
            if (-not $rec) { continue }
            $fresh++
            $rows.Add([pscustomobject]@{
                    Provider = $name
                    Path     = $file.FullName
                    Size     = $file.Length
                    Mtime    = $file.LastWriteTimeUtc.Ticks
                    Id       = $rec.Id
                    Title    = $rec.Title
                    Titled   = $rec.TitleSource
                    Group    = $rec.Group
                    Hidden   = [bool]$rec.Hidden
                    When     = $rec.When.ToString('o')
                    First    = @($rec.First)
                    Last     = @($rec.Last)
                })
        }
    }
    # only rewrite when something actually moved - the write is the expensive part
    $others = @($cached | Where-Object { $names -notcontains $_.Provider })
    $stale = ($reused + $others.Count) -ne $cached.Count
    if ($fresh -or $stale) {
        # silently: "new or changed" counts any transcript whose mtime moved,
        # which includes every session merely being typed in right now, so the
        # number read as "you made 4 chats" when nobody made any
        Save-ChatIndex @($others + $rows.ToArray())
    }
    return $rows.ToArray()
}

function chatindex {
    <#
    .SYNOPSIS
    Rebuild the chat index that searches and tab completion run off.
    .DESCRIPTION
    Normally unnecessary: every chatfind refreshes the index incrementally,
    re-reading only transcripts whose size or mtime changed. Use -Force to
    discard what is cached and read every transcript again.
    #>
    param([string[]]$Provider, [switch]$Force)
    $rows = Sync-ChatIndex -Provider $Provider -Force:$Force
    $names = if ($Provider) { $Provider } else { @($script:ChatProviders.Keys) }
    Write-Host "indexed $($rows.Count) chats from: $($names -join ', ')"
}

#endregion

#region generic helpers -------------------------------------------------------

function Get-ChatAge {
    param([datetime]$When)
    $s = ([datetime]::Now - $When).TotalSeconds
    if ($s -lt 60) { return 'now' }
    if ($s -lt 3600) { return "$([math]::Floor($s / 60))m" }
    if ($s -lt 86400) { return "$([math]::Floor($s / 3600))h" }
    if ($s -lt 2592000) { return "$([math]::Floor($s / 86400))d" }
    if ($s -lt 31536000) { return "$([math]::Floor($s / 2592000))mo" }
    return "$([math]::Floor($s / 31536000))y"
}

function Format-ChatMessages {
    param([string[]]$Messages, [int]$Width = 100, [string]$Indent = '          ')
    if (-not $Messages) { return '' }
    ($Messages | ForEach-Object {
        $t = $_.Substring(0, [Math]::Min($Width, $_.Length))
        if ($_.Length -gt $Width) { $t += '...' }
        $t
    }) -join "`n$Indent"
}

function Format-ChatTitle {
    param([string]$Text, [int]$Width = 60)
    if (-not $Text) { return '(empty)' }
    $t = ($Text -replace '\s+', ' ').Trim()
    if ($t.Length -gt $Width) { $t = $t.Substring(0, $Width).TrimEnd() + '...' }
    return $t
}

function Test-ChatNoise {
    # prompts that are machinery, not something the user typed
    param([string]$Text)
    $Text.StartsWith('<') -or $Text.StartsWith('Caveat') -or $Text -like '*system-reminder*' -or
    $Text -like '`[Request interrupted*'
}

function Select-ChatDistinctRun {
    # drop consecutive repeats - Codex re-injects the same prompt every turn
    param([string[]]$Texts)
    $out = [System.Collections.Generic.List[string]]::new()
    $prev = $null
    foreach ($t in $Texts) {
        # compare on a normalized prefix: re-injections differ in punctuation
        $key = ($t -replace '[^\w]', '').ToLowerInvariant()
        $key = $key.Substring(0, [Math]::Min(80, $key.Length))
        if ($key -ne $prev) { $out.Add($t) }
        $prev = $key
    }
    # plain array, not comma-wrapped: callers pipe this straight into Select-Object
    return $out.ToArray()
}

function Open-ChatRead {
    # Codex holds every rollout open for the life of the window. OpenRead asks
    # for FileShare.Read, which collides with that writer and throws, so no
    # Codex chat ever reached the index - discovery found the files and Describe
    # then returned null on all of them. Share what the writer holds.
    param([string]$Path)
    [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read,
        ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
}

function Read-ChatAllText {
    # File::ReadAllText shares no better than OpenRead does
    param([string]$Path)
    $fs = Open-ChatRead $Path
    try {
        $sr = [System.IO.StreamReader]::new($fs, [System.Text.Encoding]::UTF8)
        try { return $sr.ReadToEnd() } finally { $sr.Dispose() }
    }
    finally { $fs.Dispose() }
}

function Read-ChatChunk {
    # head+tail only - transcripts run to megabytes and there are thousands
    param([string]$Path, [int]$Size = 524288)
    $fi = [System.IO.FileInfo]::new($Path)
    try { $fs = Open-ChatRead $Path } catch { return $null }  # can vanish mid-scan
    try {
        if ($fi.Length -le 2 * $Size) {
            $buf = [byte[]]::new($fi.Length)
            $fs.Read($buf, 0, $buf.Length) | Out-Null
            return [pscustomobject]@{ Head = [System.Text.Encoding]::UTF8.GetString($buf); Tail = ''; Split = $false }
        }
        $hb = [byte[]]::new($Size)
        $fs.Read($hb, 0, $Size) | Out-Null
        $tb = [byte[]]::new($Size)
        $fs.Seek(-$Size, [System.IO.SeekOrigin]::End) | Out-Null
        $fs.Read($tb, 0, $Size) | Out-Null
        return [pscustomobject]@{
            Head  = [System.Text.Encoding]::UTF8.GetString($hb)
            Tail  = [System.Text.Encoding]::UTF8.GetString($tb)
            Split = $true
        }
    }
    finally { $fs.Dispose() }
}

function Get-ChatJsonLines {
    # index scan for a marker, not a line split + pipeline - that was 10x slower.
    # several markers may be given: the first one present in the text wins, which
    # covers writers that emit compact JSON and ones that pad after the colon
    param([string]$Text, [string[]]$Marker, [int]$Count, [switch]$FromEnd,
        [string[]]$Skip = @('"tool_result"', '"isMeta":true', 'system-reminder'))
    $out = [System.Collections.Generic.List[string]]::new()
    if (-not $Text) { return , @() }
    $needle = $Marker | Where-Object { $Text.IndexOf($_, [StringComparison]::Ordinal) -ge 0 } | Select-Object -First 1
    if (-not $needle) { return , @() }
    $Marker = $needle
    $pos = if ($FromEnd) { $Text.Length - 1 } else { 0 }
    while ($out.Count -lt $Count) {
        $j = if ($FromEnd) { $Text.LastIndexOf($Marker, [Math]::Min($pos, $Text.Length - 1), [StringComparison]::Ordinal) }
        else { $Text.IndexOf($Marker, $pos, [StringComparison]::Ordinal) }
        if ($j -lt 0) { break }
        $s = $Text.LastIndexOf("`n", $j) + 1
        $e = $Text.IndexOf("`n", $j)
        if ($e -lt 0) { $e = $Text.Length }
        $line = $Text.Substring($s, $e - $s)
        # skip before counting, not after parsing: a chat can have hundreds of
        # tool-result lines carrying the same marker, which would fill the quota
        $keep = $line.Length -lt 200000
        if ($keep) { foreach ($s2 in $Skip) { if ($line -like "*$s2*") { $keep = $false; break } } }
        if ($keep) {
            if ($FromEnd) { $out.Insert(0, $line) } else { $out.Add($line) }
        }
        $pos = if ($FromEnd) { $s - 1 } else { $e + 1 }
        if ($FromEnd -and $pos -lt 0) { break }
        if (-not $FromEnd -and $pos -ge $Text.Length) { break }
    }
    return , $out.ToArray()
}

function Get-ChatTimestampFromText {
    # the head/tail chunks are already in hand - no second read of the file
    param($Prompts, [System.IO.FileInfo]$File)
    foreach ($t in @($Prompts.Tail, $Prompts.Head)) {
        if (-not $t) { continue }
        $m = [regex]::Matches($t, '"timestamp":\s*"([^"]+)"')
        if ($m.Count) {
            try {
                return [datetime]::Parse($m[$m.Count - 1].Groups[1].Value,
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::RoundtripKind).ToLocalTime()
            }
            catch {}
        }
    }
    return $File.LastWriteTime
}

function Get-ChatLastTimestamp {
    # the last timestamp sits in the final few KB; ISO-8601, culture-invariant
    param([string]$Path)
    $fi = [System.IO.FileInfo]::new($Path)
    $tailLen = [Math]::Min(65536, $fi.Length)
    $buf = [byte[]]::new($tailLen)
    try { $fs = Open-ChatRead $Path } catch { return $fi.LastWriteTime }
    try {
        $fs.Seek(-$tailLen, [System.IO.SeekOrigin]::End) | Out-Null
        $fs.Read($buf, 0, $tailLen) | Out-Null
    }
    finally { $fs.Dispose() }
    $m = [regex]::Matches([System.Text.Encoding]::UTF8.GetString($buf), '"timestamp":\s*"([^"]+)"')
    if ($m.Count) {
        return [datetime]::Parse($m[$m.Count - 1].Groups[1].Value,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::RoundtripKind).ToLocalTime()
    }
    return $fi.LastWriteTime
}

function Get-ChatHeadTailPrompts {
    # walk head and tail for prompt lines, parse only those, and fall back to the
    # whole file when one turn is bigger than the chunk and hides every prompt
    param([string]$Path, [string[]]$Marker, [scriptblock]$Parse, [int]$Count = $script:ChatPreview)
    $chunk = Read-ChatChunk $Path
    if (-not $chunk) { return $null }
    $scan = $Count * 4   # over-fetch: some candidates parse out as noise
    $head = $chunk.Head
    $tail = if ($chunk.Split) { $chunk.Tail } else { $chunk.Head }
    $first = @(); $last = @()
    foreach ($pass in 1, 2) {
        # assign before piping - these return comma-wrapped arrays
        $headLines = Get-ChatJsonLines $head $Marker $scan
        $tailLines = Get-ChatJsonLines $tail $Marker $scan -FromEnd
        $headTexts = Select-ChatDistinctRun @($headLines | ForEach-Object { & $Parse $_ } | Where-Object { $_ })
        $tailTexts = Select-ChatDistinctRun @($tailLines | ForEach-Object { & $Parse $_ } | Where-Object { $_ })
        $first = @($headTexts | Select-Object -First $Count)
        $last = @($tailTexts | Select-Object -Last $Count)
        if (-not $chunk.Split -or ($first.Count -gt 0 -and $last.Count -gt 0)) { break }
        if ($pass -eq 1) {
            $head = Read-ChatAllText $Path
            $tail = $head
            $chunk = [pscustomobject]@{ Head = $head; Tail = ''; Split = $false }
        }
    }
    return [pscustomobject]@{ First = $first; Last = $last; Head = $chunk.Head; Tail = $chunk.Tail }
}

function Convert-ChatJsonEscaped {
    # \n, \" and friends, without parsing the document they came from
    param([string]$Text)
    if ($Text -notlike '*\*') { return $Text }
    try { return ('"' + $Text + '"') | ConvertFrom-Json } catch { return $Text }
}

function Get-ChatJsonString {
    # index lookup rather than regex: this runs over megabyte-sized text.
    # both spacings are tried, since writers differ on the space after the colon
    param([string]$Text, [string]$Key)
    if (-not $Text) { return $null }
    $best = -1
    $len = 0
    foreach ($anchor in @("`"$Key`":`"", "`"$Key`": `"")) {
        $i = $Text.LastIndexOf($anchor, [StringComparison]::Ordinal)
        if ($i -gt $best) { $best = $i; $len = $anchor.Length }
    }
    if ($best -lt 0) { return $null }
    $rest = $Text.Substring($best + $len)
    if ($rest -match '^((?:[^"\\]|\\.)*)"') { return $Matches[1] }
    return $null
}

#endregion

#region provider: claude ------------------------------------------------------

function Read-ClaudePrompt {
    param([string]$Line)
    if ($Line -like '*"tool_result"*' -or $Line -like '*"isMeta":true*' -or $Line -like '*system-reminder*') { return $null }
    try { $o = $Line | ConvertFrom-Json } catch { return $null }
    if ($o.type -ne 'user') { return $null }
    $c = $o.message.content
    if ($c -isnot [string]) { $c = ($c | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join ' ' }
    if (-not $c) { return $null }
    $c = $c.Trim()
    if (Test-ChatNoise $c) { return $null }
    return ($c -replace '\s+', ' ')
}

#endregion

#region provider: copilot -----------------------------------------------------

function Get-CopilotWorkspaceName {
    # workspaceStorage/<hash>/workspace.json points at the folder the chats belong to
    param([string]$StorageDir)
    if ($script:ChatWorkspaceNames.ContainsKey($StorageDir)) { return $script:ChatWorkspaceNames[$StorageDir] }
    $name = Split-Path $StorageDir -Leaf
    $meta = Join-Path $StorageDir 'workspace.json'
    if (Test-Path -LiteralPath $meta) {
        try {
            $uri = (Get-Content -LiteralPath $meta -Raw | ConvertFrom-Json).folder
            if ($uri) { $name = Split-Path ([Uri]::UnescapeDataString($uri)) -Leaf }
        }
        catch {}
    }
    $script:ChatWorkspaceNames[$StorageDir] = $name
    return $name
}

#endregion

#region provider: codex -------------------------------------------------------

function Get-CodexThreadNames {
    # Codex names a thread itself and keeps that name in session_index.jsonl,
    # never in the rollout. The panel lists the name, so the title has to come
    # from here - the first prompt was 'test' where the panel said 'Test task'.
    # Cached against the index mtime: a chat named after dot-source still lands.
    $path = Join-Path $script:ChatCodexHome 'session_index.jsonl'
    $f = Get-Item -LiteralPath $path -EA SilentlyContinue
    $stamp = if ($f) { $f.LastWriteTimeUtc.Ticks } else { 0 }
    if ($script:ChatCodexNames -and $script:ChatCodexNamesAt -eq $stamp) { return $script:ChatCodexNames }
    $map = @{}
    if ($f) {
        foreach ($line in (Get-Content -LiteralPath $path -EA SilentlyContinue)) {
            $o = try { $line | ConvertFrom-Json } catch { $null }
            if ($o.id -and $o.thread_name) { $map[[string]$o.id] = [string]$o.thread_name }
        }
    }
    $script:ChatCodexNames = $map
    $script:ChatCodexNamesAt = $stamp
    return $map
}

function Read-CodexPrompt {
    param([string]$Line)
    try { $o = $Line | ConvertFrom-Json } catch { return $null }
    if ($o.payload.role -ne 'user') { return $null }
    $t = ($o.payload.content | Where-Object { $_.type -eq 'input_text' } | ForEach-Object { $_.text }) -join ' '
    if (-not $t) { return $null }
    $t = $t.Trim()
    # the IDE wraps the real prompt in a context block
    $i = $t.IndexOf('## My request for Codex:')
    if ($i -ge 0) { $t = $t.Substring($i + 24).Trim() }
    # AGENTS.md preambles and environment blocks are not prompts
    if ($t.StartsWith('# AGENTS.md') -or $t.StartsWith('<') -or $t.StartsWith('# Context from my IDE')) { return $null }
    if (Test-ChatNoise $t) { return $null }
    return ($t -replace '\s+', ' ')
}

#endregion

#region provider registry -----------------------------------------------------

$script:ChatProviders = [ordered]@{

    claude  = [pscustomobject]@{
        Root     = (Join-Path $script:ChatClaudeHome 'projects')
        Discover = {
            # only projects/<slug>/<uuid>.jsonl - a recursive sweep also drags in
            # workflow journals and agent transcripts, which are not chats
            $root = Join-Path $script:ChatClaudeHome 'projects'
            if (Test-Path -LiteralPath $root) {
                Get-ChildItem -Path $root -Directory | ForEach-Object {
                    Get-ChildItem -Path $_.FullName -Filter *.jsonl -File |
                        Where-Object { $_.BaseName -match '^[0-9a-fA-F-]{36}$' }
                }
            }
        }
        Describe = {
            param($File)
            $p = Get-ChatHeadTailPrompts $File.FullName '"type":"user"' ${function:Read-ClaudePrompt}
            if (-not $p) { return $null }
            # subagent transcripts are flagged on line 1; the GUI hides them too
            $nl = $p.Head.IndexOf("`n")
            $firstLine = if ($nl -ge 0) { $p.Head.Substring(0, $nl) } else { $p.Head }
            $hidden = $firstLine -like '*"isSidechain":true*'
            $title = $null; $source = 'first message'
            foreach ($t in @($p.Tail, $p.Head)) {
                if (-not $title) { $title = Get-ChatJsonString $t 'customTitle'; if ($title) { $source = 'renamed' } }
            }
            if (-not $title) {
                foreach ($t in @($p.Tail, $p.Head)) {
                    if (-not $title) { $title = Get-ChatJsonString $t 'aiTitle'; if ($title) { $source = 'auto' } }
                }
            }
            if (-not $title) {
                $sidecar = Join-Path (Join-Path $File.DirectoryName $File.BaseName) 'custom-title.json'
                if (Test-Path -LiteralPath $sidecar) {
                    try { $title = (Get-Content -LiteralPath $sidecar -Raw | ConvertFrom-Json).customTitle; if ($title) { $source = 'renamed' } } catch {}
                }
            }
            if (-not $title) { $title = @($p.First)[0] }
            [pscustomobject]@{
                Id          = $File.BaseName
                Title       = Format-ChatTitle $title
                TitleSource = $source
                Group       = $File.Directory.Name
                Hidden      = $hidden
                When        = Get-ChatTimestampFromText $p $File
                First       = $p.First
                Last        = $p.Last
            }
        }
        IsEmpty  = {
            # a ghost holds only state lines - ai-title / mode / atis-latch - and
            # is written when the GUI opens a chat whose transcript is gone
            param($File)
            if ($File.Length -gt 65536) { return $false }
            $t = Read-ChatAllText $File.FullName
            (-not ($t -like '*"type":"user"*')) -and (-not ($t -like '*"type":"assistant"*'))
        }
        Extras   = {
            param($File, $Record)
            @(
                (Join-Path $File.DirectoryName $File.BaseName)
                (Join-Path (Join-Path $script:ChatClaudeHome 'file-history') $File.BaseName)
                (Join-Path (Join-Path $script:ChatClaudeHome 'session-env') $File.BaseName)
            )
        }
    }

    copilot = [pscustomobject]@{
        Root     = (Join-Path $script:ChatCodeUser 'workspaceStorage')
        Discover = {
            $root = Join-Path $script:ChatCodeUser 'workspaceStorage'
            if (Test-Path -LiteralPath $root) {
                Get-ChildItem -Path $root -Directory | ForEach-Object {
                    $dir = Join-Path $_.FullName 'chatSessions'
                    if (Test-Path -LiteralPath $dir) { Get-ChildItem -Path $dir -Filter *.json -File }
                }
            }
        }
        Describe = {
            param($File)
            # regex over head+tail, not ConvertFrom-Json: these files reach 700 KB
            # each and the metadata sits after requests[], so the tail carries it
            $chunk = Read-ChatChunk $File.FullName
            if (-not $chunk) { return $null }
            $meta = if ($chunk.Split) { $chunk.Tail } else { $chunk.Head }
            $rx = [regex]'"message":\s*\{\s*"text":\s*"((?:[^"\\]|\\.)*)"'
            $grab = {
                param($text)
                Select-ChatDistinctRun @($rx.Matches($text) | ForEach-Object {
                        $t = (Convert-ChatJsonEscaped $_.Groups[1].Value) -replace '\s+', ' '
                        $t = $t.Trim()
                        if ($t -and -not (Test-ChatNoise $t)) { $t }
                    })
            }
            $first = @(& $grab $chunk.Head | Select-Object -First $script:ChatPreview)
            $last = @(& $grab $meta | Select-Object -Last $script:ChatPreview)
            if (-not $first -and $chunk.Split) {
                $whole = Read-ChatAllText $File.FullName
                $first = @(& $grab $whole | Select-Object -First $script:ChatPreview)
                $last = @(& $grab $whole | Select-Object -Last $script:ChatPreview)
            }
            $texts = $first
            $title = Get-ChatJsonString $meta 'customTitle'
            if ($title) { $title = Convert-ChatJsonEscaped $title }
            $source = if ($title) { 'renamed' } else { 'first message' }
            if (-not $title) { $title = @($texts)[0] }
            $ms = if ($meta -match '"lastMessageDate":\s*(\d+)') { $Matches[1] }
            elseif ($meta -match '"creationDate":\s*(\d+)') { $Matches[1] }
            $when = if ($ms) { [System.DateTimeOffset]::FromUnixTimeMilliseconds([int64]$ms).LocalDateTime } else { $File.LastWriteTime }
            [pscustomobject]@{
                Id          = $File.BaseName
                Title       = Format-ChatTitle $title
                TitleSource = $source
                Group       = Get-CopilotWorkspaceName (Split-Path $File.DirectoryName -Parent)
                Hidden      = $false
                When        = $when
                First       = $first
                Last        = $last
            }
        }
        IsEmpty  = {
            param($File)
            if ($File.Length -gt 65536) { return $false }
            $t = Read-ChatAllText $File.FullName
            [bool]($t -match '"requests":\s*\[\s*\]')   # panel opened, never used
        }
        Extras   = {
            param($File, $Record)
            @(Join-Path (Join-Path (Split-Path $File.DirectoryName -Parent) 'chatEditingSessions') $File.BaseName)
        }
    }

    codex   = [pscustomobject]@{
        Root     = (Join-Path $script:ChatCodexHome 'sessions')
        Discover = {
            $root = Join-Path $script:ChatCodexHome 'sessions'
            if (Test-Path -LiteralPath $root) { Get-ChildItem -Path $root -Filter *.jsonl -Recurse -File }
        }
        Describe = {
            param($File)
            $p = Get-ChatHeadTailPrompts $File.FullName @('"role":"user"', '"role": "user"') ${function:Read-CodexPrompt}
            if (-not $p) { return $null }
            # rollout-<iso>-<uuid>.jsonl - the id is everything after the timestamp
            $id = if ($File.BaseName -match '([0-9a-fA-F-]{36})$') { $Matches[1] } else { $File.BaseName }
            $cwd = Get-ChatJsonString $p.Head 'cwd'
            $group = if ($cwd) { Split-Path ($cwd -replace '\\\\', '\') -Leaf } else { 'codex' }
            $named = (Get-CodexThreadNames)[$id]
            $title = if ($named) { $named } else { @($p.First)[0] }
            [pscustomobject]@{
                Id          = $id
                Title       = Format-ChatTitle $title
                TitleSource = if ($named) { 'thread name' } else { 'first message' }
                Group       = $group
                Hidden      = $false
                When        = Get-ChatTimestampFromText $p $File
                First       = $p.First
                Last        = $p.Last
            }
        }
        IsEmpty  = {
            param($File)
            if ($File.Length -gt 65536) { return $false }
            $t = Read-ChatAllText $File.FullName
            -not ($t -match '"role":\s*"user"')
        }
        Extras   = { param($File, $Record) @() }
    }
}

function chatclean {
    <#
    .SYNOPSIS
    Delete ghost chats - transcripts that hold no messages at all.
    .DESCRIPTION
    Clicking a chat in the VS Code list after its transcript was deleted makes
    the extension write the session back as a stub: a title line, a mode line,
    nothing else. Those stubs then show up as ghost rows, and clicking them
    again makes more. This finds and removes them.

    A file counts as empty only if it is under 64 KB AND contains no user or
    assistant message at all, so a real chat can never match.
    .PARAMETER Force
    Delete every ghost found without asking.
    .EXAMPLE
    chatclean
    #>
    param([string[]]$Provider, [switch]$Force)

    $candidates = @(Sync-ChatIndex -Provider $Provider | Where-Object { -not $_.First })
    $ghosts = foreach ($row in $candidates) {
        $p = $script:ChatProviders[$row.Provider]
        if (-not $p.IsEmpty) { continue }
        $file = try { Get-Item -LiteralPath $row.Path -EA Stop } catch { continue }
        if (-not (& $p.IsEmpty $file)) { continue }
        [pscustomobject]@{
            Provider = $row.Provider
            File     = $file
            Record   = [pscustomobject]@{
                Id = $row.Id; Title = $row.Title; TitleSource = $row.Titled
                Group = $row.Group; Hidden = $row.Hidden
                When = [datetime]::Parse($row.When, [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::RoundtripKind)
                First = @(); Last = @()
            }
        }
    }
    $ghosts = @($ghosts)
    if (-not $ghosts) { Write-Host 'no ghost chats found'; return }

    $chosen = if ($Force) { $ghosts } else { Select-ChatItems $ghosts "$($ghosts.Count) ghost chats (no messages at all)" }
    if (-not $chosen) { Write-Host 'nothing deleted'; return }
    foreach ($g in $chosen) { $null = Remove-ChatSession $g }
    Write-Host ''
    Write-ChatGhostAdvice
}

function chatproviders {
    <#
    .SYNOPSIS
    Show which chat tools were found on this machine, and where they store chats.
    #>
    $script:ChatProviders.GetEnumerator() | ForEach-Object {
        $files = @(& $_.Value.Discover)
        [pscustomobject]@{
            Provider = $_.Key
            Present  = Test-Path -LiteralPath $_.Value.Root
            Chats    = $files.Count
            MB       = [math]::Round((($files | Measure-Object Length -Sum).Sum) / 1MB, 1)
            Root     = $_.Value.Root
        }
    }
}

#endregion

#region search and delete -----------------------------------------------------

function Get-ChatProjectScope {
    # What "this project" means to each tool. Claude names its project folder
    # after the whole path with every non-alphanumeric turned into a dash;
    # Copilot and Codex only ever record the leaf folder name.
    param([string]$Path = $PWD.Path)
    $full = $Path.TrimEnd('\', '/')
    [pscustomobject]@{
        Slug = ($full -replace '[^A-Za-z0-9]', '-')
        Leaf = Split-Path $full -Leaf
    }
}

function Test-ChatInProject {
    # Exact, never a prefix. Sibling repos nest - the slug for AS-RadarViewer
    # is a prefix of the one for AS-RadarViewer-Mobile - so -like or StartsWith
    # would quietly drag the neighbour in, which is the bug this exists to fix.
    param($Row, $Scope)
    if (-not $Row.Group) { return $false }
    if ($Row.Provider -eq 'claude') { return $Row.Group -eq $Scope.Slug }
    return $Row.Group -eq $Scope.Leaf
}

function Select-ChatInProject {
    # Narrow rows to the project being stood in. Returns them untouched when
    # this directory is not a project any tool knows - otherwise running from
    # anywhere else would match nothing at all.
    param([object[]]$Rows, [switch]$AllProjects)
    if ($AllProjects -or -not $Rows) { return $Rows }
    $scope = Get-ChatProjectScope
    $mine = @($Rows | Where-Object { Test-ChatInProject $_ $scope })
    if ($mine) { return $mine }
    return $Rows
}

function Find-ChatSessions {
    param(
        [string]$Needle,
        [string[]]$Provider,
        [switch]$Deep,
        [switch]$All,
        [switch]$AllProjects,
        [switch]$TitleOnly
    )
    # match against the index; only matches are turned back into file objects
    $rows = Select-ChatInProject @(Sync-ChatIndex -Provider $Provider) -AllProjects:$AllProjects
    foreach ($row in $rows) {
        if ($row.Hidden -and -not $All) { continue }
        $hit = if ($Deep) {
            Select-String -Path $row.Path -SimpleMatch -Pattern $Needle -Quiet -EA SilentlyContinue
        }
        elseif ($TitleOnly) {
            # literal, not -like: a completed title may contain [ ] ? or *
            $row.Title.IndexOf($Needle, [StringComparison]::OrdinalIgnoreCase) -ge 0
        }
        else {
            ($row.Title -like "*$Needle*") -or
            [bool](@($row.First) + @($row.Last) | Where-Object { $_ -like "*$Needle*" })
        }
        if (-not $hit) { continue }
        $file = try { Get-Item -LiteralPath $row.Path -EA Stop } catch { continue }
        [pscustomobject]@{
            Provider = $row.Provider
            File     = $file
            Record   = [pscustomobject]@{
                Id          = $row.Id
                Title       = $row.Title
                TitleSource = $row.Titled
                Group       = $row.Group
                Hidden      = $row.Hidden
                When        = [datetime]::Parse($row.When, [System.Globalization.CultureInfo]::InvariantCulture,
                    [System.Globalization.DateTimeStyles]::RoundtripKind)
                First       = @($row.First)
                Last        = @($row.Last)
            }
        }
    }
}

function chatfind {
    <#
    .SYNOPSIS
    Find local AI chat transcripts by title or message text.
    .DESCRIPTION
    Searches Claude Code, Copilot Chat and Codex transcripts on this machine and
    returns one object per match, so results can be piped. Also refreshes the
    index that makes chatrm's tab completion instant.
    .PARAMETER Text
    Text to look for in the chat title and the first/last user messages.
    .PARAMETER Provider
    Limit the search: claude, copilot, codex. Defaults to all of them.
    .PARAMETER Deep
    Match anywhere in the transcript rather than title and previews. Slower.
    .PARAMETER All
    Include subagent / workflow transcripts, which are hidden by default.
    .PARAMETER AllProjects
    Search every project rather than the one this directory belongs to.
    .EXAMPLE
    chatfind "brownout"
    .EXAMPLE
    chatfind gitignore -Provider copilot | Select-Object Title, Id, Age
    .LINK
    chatrm
    #>
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)][string[]]$Text,
        [string[]]$Provider,
        [switch]$Deep,
        [switch]$All,
        [switch]$AllProjects
    )

    $needle = $Text -join ' '
    if (-not $needle) { Write-Error 'usage: chatfind "text" [-Provider claude,copilot,codex] [-Deep] [-All] [-AllProjects]'; return }
    # emits objects, not formatted text, so results stay pipeable
    Find-ChatSessions -Needle $needle -Provider $Provider -Deep:$Deep -All:$All -AllProjects:$AllProjects | ForEach-Object {
        $r = $_.Record
        [pscustomobject]@{
            Title    = $r.Title
            Titled   = $r.TitleSource
            Provider = $_.Provider
            Id       = $r.Id
            Group    = $r.Group
            Age      = Get-ChatAge $r.When
            LastAt   = $r.When.ToString('yyyy-MM-dd HH:mm')
            Touched  = Get-ChatAge $_.File.LastWriteTime   # mtime, as the GUIs show it
            MB       = [math]::Round($_.File.Length / 1MB, 2)
            First    = Format-ChatMessages $r.First
            Recent   = if (($r.First -join "`n") -eq ($r.Last -join "`n")) { '(same)' } else { Format-ChatMessages $r.Last }
        }
    }
}

function Get-ChatProviderForPath {
    param([string]$Path)
    foreach ($e in $script:ChatProviders.GetEnumerator()) {
        if ($e.Value.Root -and $Path.StartsWith($e.Value.Root, [StringComparison]::OrdinalIgnoreCase)) {
            return $e.Key
        }
    }
    return $null
}

function Add-ChatTombstone {
    # Remember what was deleted, because the window will write some of it back
    param([string]$Path)
    $dir = Split-Path $script:ChatTombPath -Parent
    if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
    Add-Content -LiteralPath $script:ChatTombPath -Value ("{0}`t{1}" -f (Get-Date).ToString('o'), $Path)
    Start-ChatGhostWatch
}

function Test-ChatGhostWatch {
    # Asking Get-EventSubscriber for a name that is not registered raises an
    # error - and -ErrorAction SilentlyContinue hides it but still files it in
    # $Error. Listing and filtering asks the same question quietly.
    [bool]@(Get-EventSubscriber -EA SilentlyContinue |
        Where-Object { $_.SourceIdentifier -eq 'ChatGhostWatch' })
}

function Start-ChatGhostWatch {
    # Why running it a second time works: the window flushes a tracked session
    # to disk once, when it reloads. After that reload it rebuilds its list
    # from disk and is no longer holding that session, so the next delete
    # sticks. The write is a single event, not a state to out-wait - so watch
    # for it instead of polling, and take the file back the moment it lands.
    #
    # Created only, and FileName only: transcripts are appended to constantly,
    # and a rewritten ghost always arrives as a brand new file. That keeps this
    # silent until the one event that matters.
    if (Test-ChatGhostWatch) { return }
    $root = Join-Path $script:ChatClaudeHome 'projects'
    if (-not (Test-Path -LiteralPath $root)) { return }

    $fsw = New-Object System.IO.FileSystemWatcher $root, '*.jsonl'
    $fsw.IncludeSubdirectories = $true
    $fsw.NotifyFilter = [System.IO.NotifyFilters]::FileName
    $fsw.EnableRaisingEvents = $true
    $script:ChatGhostWatcher = $fsw          # a reference, or it is collected

    # self-contained: this runs in its own runspace, with none of these
    # functions loaded, and must stay silent so it cannot garble the prompt
    $null = Register-ObjectEvent -InputObject $fsw -EventName Created `
        -SourceIdentifier 'ChatGhostWatch' -MessageData $script:ChatTombPath -Action {
        $tomb = $Event.MessageData
        $path = $Event.SourceEventArgs.FullPath
        if (-not (Test-Path -LiteralPath $tomb)) { return }
        # the same seven days the sweep honours, or an entry the sweep would
        # have dropped would still be acted on here
        $cutoff = (Get-Date).AddDays(-7)
        $wanted = @(Get-Content -LiteralPath $tomb -EA SilentlyContinue | ForEach-Object {
                $parts = $_ -split "`t", 2
                if ($parts.Count -eq 2) {
                    $when = try {
                        [datetime]::Parse($parts[0], [System.Globalization.CultureInfo]::InvariantCulture,
                            [System.Globalization.DateTimeStyles]::RoundtripKind)
                    }
                    catch { $null }
                    if ($when -and $when -ge $cutoff) { $parts[1] }
                }
            })
        if ($wanted -notcontains $path) { return }
        Start-Sleep -Milliseconds 200        # let the writer finish the file
        $f = Get-Item -LiteralPath $path -EA SilentlyContinue
        if (-not $f -or $f.Length -gt 65536) { return }
        # runs in the watcher's own runspace, where the shared-read helpers are
        # not defined - open the handle inline, sharing what a writer may hold
        $t = try {
            $fh = [System.IO.FileStream]::new($f.FullName, [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Read,
                ([System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete))
            try { [System.IO.StreamReader]::new($fh).ReadToEnd() } finally { $fh.Dispose() }
        }
        catch { return }
        if ($t -like '*"type":"user"*' -or $t -like '*"type":"assistant"*') { return }
        Remove-Item -LiteralPath $path -Force -EA SilentlyContinue
    }
}

function Stop-ChatGhostWatch {
    if (Test-ChatGhostWatch) { Unregister-Event -SourceIdentifier 'ChatGhostWatch' -EA SilentlyContinue }
    if ($script:ChatGhostWatcher) {
        $script:ChatGhostWatcher.EnableRaisingEvents = $false
        $script:ChatGhostWatcher.Dispose()
        $script:ChatGhostWatcher = $null
    }
}

function Clear-ChatTombstones {
    # The window does not write a deleted session back straight away - it
    # flushes session state when it reloads or closes, minutes later, and the
    # file reappears with a brand new creation time.
    #
    # Start-ChatGhostWatch catches that write as it happens, but only while a
    # shell that loaded this file is open. This is the backstop for the rest:
    # the deletion is remembered, and taken again the next time any of these
    # commands runs, in whatever shell.
    #
    # Only ever removes a file that is still a stub, so resuming one of these
    # sessions for real makes it stop being a tombstone's business.
    if (-not (Test-Path -LiteralPath $script:ChatTombPath)) { return }
    $keep = [System.Collections.Generic.List[string]]::new()
    $took = 0
    $cutoff = (Get-Date).AddDays(-7)
    foreach ($line in @(Get-Content -LiteralPath $script:ChatTombPath -EA SilentlyContinue)) {
        $parts = $line -split "`t", 2
        if ($parts.Count -ne 2) { continue }
        $when = try {
            [datetime]::Parse($parts[0], [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::RoundtripKind)
        }
        catch { continue }
        if ($when -lt $cutoff) { continue }        # long gone, stop watching it
        $path = $parts[1]
        if (Test-Path -LiteralPath $path) {
            $file = Get-Item -LiteralPath $path -EA SilentlyContinue
            $name = Get-ChatProviderForPath $path
            $prov = if ($name) { $script:ChatProviders[$name] } else { $null }
            if ($file -and $prov -and $prov.IsEmpty -and (& $prov.IsEmpty $file)) {
                Remove-Item -LiteralPath $path -Force -EA SilentlyContinue
                if (-not (Test-Path -LiteralPath $path)) { $took++ }
            }
            elseif ($file) { continue }            # it has real content now - leave it, drop it
        }
        $keep.Add($line)
    }
    if ($keep.Count) {
        Set-Content -LiteralPath $script:ChatTombPath -Value $keep.ToArray()
        Start-ChatGhostWatch          # a new shell picks the watch back up
    }
    else {
        Remove-Item -LiteralPath $script:ChatTombPath -Force -EA SilentlyContinue
        Stop-ChatGhostWatch           # nothing left to watch for
    }
    if ($took) {
        Write-Host "  took back $took chat$(if ($took -ne 1) { 's' }) the window had rewritten" -ForegroundColor DarkGray
    }
}

function Remove-ChatSession {
    # Returns $true only if the transcript is actually gone. Windows refuses to
    # delete a file another process holds open, and Remove-Item reports that as
    # a non-terminating error - so without the check afterwards this printed
    # "deleted" for a chat that was still sitting there.
    param($Hit)
    $path = $Hit.File.FullName
    Remove-Item -LiteralPath $path -Force -EA SilentlyContinue
    foreach ($p in @(& $script:ChatProviders[$Hit.Provider].Extras $Hit.File $Hit.Record)) {
        if ($p -and (Test-Path -LiteralPath $p)) { Remove-Item -LiteralPath $p -Recurse -Force -EA SilentlyContinue }
    }
    if (Test-Path -LiteralPath $path) {
        Write-Host "  LOCKED   $($Hit.Record.Title)" -ForegroundColor Yellow
        Write-Host '           still on disk - another process has it open' -ForegroundColor DarkGray
        return $false
    }
    Add-ChatTombstone $path
    # the title, not the full row: the row is wider than a narrow panel and wraps
    Write-Host "  deleted  $($Hit.Record.Title)" -ForegroundColor DarkGray
    return $true
}

function Write-ChatGhostAdvice {
    # Said once, after a delete, and only while a window is up to do it. macOS
    # runs VS Code as Electron and 'Code Helper (...)', never a bare Code, so the
    # name has to differ per platform or the advice never prints there at all.
    $procs = if ($script:ChatIsMac) { @('Electron', 'Code Helper*') } else { @('Code') }
    if (-not @(Get-Process -Name $procs -EA SilentlyContinue).Count) { return }
    Write-Host 'the session list is cached - reload to see it go:'
    Write-Host '  Ctrl+Shift+P > Developer: Reload Window'
    if (Test-ChatGhostWatch) {
        Write-Host '  the window rewrites it as it reloads; that is watched for and taken back' -ForegroundColor DarkGray
    }
    else {
        Write-Host '  then run any chat command - the window rewrites it as it reloads' -ForegroundColor DarkGray
    }
}
function Format-ChatRow {
    param($Hit)
    $r = $Hit.Record
    '{0,-52} {1,-8} {2,-28} {3,4} {4,6} MB' -f
    $r.Title.Substring(0, [Math]::Min(52, $r.Title.Length)),
    $Hit.Provider,
    $r.Group.Substring(0, [Math]::Min(28, $r.Group.Length)),
    (Get-ChatAge $r.When),
    [math]::Round($Hit.File.Length / 1MB, 2)
}

function Test-ChatVT {
    # can the cursor be moved with escape sequences? Absolute CursorPosition is
    # not usable here: under the pseudo-console VS Code runs, setting it is
    # accepted and does nothing, so a redrawing list paints a fresh copy of
    # itself below the last one on every keypress. Relative moves work.
    if ([Console]::IsInputRedirected) { return $false }
    try { return [bool]$Host.UI.SupportsVirtualTerminal } catch { return $false }
}

function Invoke-ChatKeyLoop {
    # Every picker below is this loop: back up over what was drawn last time,
    # draw again, read one key. $Paint draws and returns how many lines it
    # wrote; $OnKey returns nothing to keep going, or @{ Value = ... } to stop
    # and hand that back. Shared state goes in a hashtable both blocks close
    # over - a plain variable assigned inside a scriptblock would only ever
    # change that block's own copy.
    param([scriptblock]$Paint, [scriptblock]$OnKey)
    $esc = [char]27
    $painted = 0
    while ($true) {
        if ($painted) { Write-Host "$esc[${painted}A" -NoNewline }
        $painted = [int](& $Paint)
        $stop = & $OnKey ([Console]::ReadKey($true))
        if ($stop) { return $stop.Value }
    }
}

# What Format-ChatPickTail writes, anchored, so Enter can take it back off.
# It has to come off: "#1/3" alone was a comment and harmless to leave, but
# "(5d)" in front of it is not - PowerShell would run it as an expression.
$script:ChatTailPattern = '\s*(\([^)]*\))?\s*#\d+/\d+\s*$'

function Format-ChatPickTail {
    # The decoration every path shares: the age, then where you are in the run.
    # Tab puts this straight into the command line, so Enter strips it again
    # before running - see the Enter handler.
    param([string]$Age, [int]$Index, [int]$Count)
    $t = ''
    if ($Age) { $t = " ($Age)" }
    return "$t #$Index/$Count"
}

function Format-ChatWalkRow {
    # The line Tab leaves on the command line, rebuilt: the command, the full
    # title, the tail. Walking matches after Enter should look exactly like
    # walking them before it. Trimmed rather than padded so the tail stays
    # beside the title, and its width is held back before clipping so a long
    # title can never push it off the end.
    param($Hit, [int]$Index, [int]$Count, [int]$Width, [switch]$Ambiguous)
    $c = Get-ChatSyntaxColor
    $tail = Format-ChatPickTail (Get-ChatAge $Hit.Record.When) $Index $Count
    $segments = @(
        @{ Text = '  chatrm '; Color = $c.Command }
        @{ Text = "'" + $Hit.Record.Title.Replace("'", "''") + "'"; Color = $c.String }
    )
    # Only when title and age are both the same, which the line alone cannot
    # separate - and Enter deletes on the spot, so they have to be separable.
    # Project and size together, because two chats in one project can share a
    # title and an age as well.
    if ($Ambiguous) {
        $segments += @{
            Text  = "  $($Hit.Record.Group) $([math]::Round($Hit.File.Length / 1MB, 2))MB"
            Color = $c.Param
        }
    }
    # clip across the segments, measuring the text and never the escapes
    $budget = $Width - (Get-ChatCells $tail)
    $line = ''
    $used = 0
    foreach ($seg in $segments) {
        if ($used -ge $budget) { break }
        $piece = Format-ChatCell $seg.Text ($budget - $used) -NoPad
        $line += $seg.Color + $piece
        $used += Get-ChatCells $piece
    }
    return $line + $c.Comment + $tail + $c.Reset
}

function Select-ChatOne {
    # The same one-line walk Tab does, over the chats a title matched. Enter
    # takes the one on screen and deletes it, with nothing in between.
    param([object[]]$Items)
    $width = [Math]::Max(20, $Host.UI.RawUI.WindowSize.Width - 1)
    # one match still shows the line, so all three paths look alike - there is
    # simply nothing to walk
    if ($Items.Count -eq 1) {
        Write-Host (Format-ChatWalkRow $Items[0] 1 1 $width)
        return $Items[0]
    }
    if (-not (Test-ChatVT)) { return Select-ChatNumbered $Items -One }

    # no header, no key hints: the counter says there is more than one, and the
    # keys are the ones Tab already walks with
    $esc = [char]27
    # keyed on title AND age, because that pair is all the line shows - only a
    # pair the counter cannot separate earns the project name
    $seen = @{}
    foreach ($it in $Items) {
        $k = "$($it.Record.Title)|$(Get-ChatAge $it.Record.When)"
        $seen[$k] = 1 + $(if ($seen.ContainsKey($k)) { $seen[$k] } else { 0 })
    }
    $s = @{ I = 0 }
    return Invoke-ChatKeyLoop -Paint {
        # no highlight - it is the only line on screen, so nothing needs
        # marking, and an inverse bar the width of the terminal reads far
        # heavier than the plain line Tab leaves behind
        $it = $Items[$s.I]
        $key = "$($it.Record.Title)|$(Get-ChatAge $it.Record.When)"
        $row = Format-ChatWalkRow $it ($s.I + 1) $Items.Count $width -Ambiguous:($seen[$key] -gt 1)
        Write-Host ($row + "$esc[K")
        1
    } -OnKey {
        param($key)
        $last = $Items.Count - 1
        switch ($key.Key) {
            'UpArrow' { $s.I = [Math]::Max(0, $s.I - 1); return }
            'DownArrow' { $s.I = [Math]::Min($last, $s.I + 1); return }
            'Enter' { return @{ Value = $Items[$s.I] } }
            'Escape' { return @{ Value = $null } }
        }
        switch ($key.KeyChar) {
            'k' { $s.I = [Math]::Max(0, $s.I - 1); return }
            'j' { $s.I = [Math]::Min($last, $s.I + 1); return }
            'q' { return @{ Value = $null } }
        }
    }
}

function Select-ChatItems {
    # the same walk, but every chat can be ticked: clearing ghosts is a job you
    # want to finish in one pass
    param([object[]]$Items, [string]$Title = 'Select chats to delete')
    if (-not (Test-ChatVT) -or $Host.Name -notlike '*ConsoleHost*') {
        return Select-ChatNumbered $Items $Title
    }

    $width = [Math]::Max(20, $Host.UI.RawUI.WindowSize.Width - 1)
    $window = [Math]::Min(15, $Items.Count)
    $s = @{ I = 0; Top = 0; Picked = New-Object bool[] $Items.Count }

    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host '  up/down move   space toggle   a all   enter delete   esc cancel' -ForegroundColor DarkGray
    return Invoke-ChatKeyLoop -Paint {
        if ($s.I -lt $s.Top) { $s.Top = $s.I }
        if ($s.I -ge $s.Top + $window) { $s.Top = $s.I - $window + 1 }
        for ($n = $s.Top; $n -lt $s.Top + $window; $n++) {
            $mark = if ($s.Picked[$n]) { '[x]' } else { '[ ]' }
            $line = Format-ChatCell "  $mark $(Format-ChatRow $Items[$n])" $width
            if ($n -eq $s.I) { Write-Host $line -ForegroundColor Black -BackgroundColor Cyan }
            else { Write-Host $line }
        }
        $count = @($s.Picked | Where-Object { $_ }).Count
        Write-Host (Format-ChatCell "  $count of $($Items.Count) selected" $width) -ForegroundColor DarkGray
        $window + 1
    } -OnKey {
        param($key)
        $last = $Items.Count - 1
        switch ($key.Key) {
            'UpArrow' { $s.I = [Math]::Max(0, $s.I - 1); return }
            'DownArrow' { $s.I = [Math]::Min($last, $s.I + 1); return }
            'Spacebar' { $s.Picked[$s.I] = -not $s.Picked[$s.I]; return }
            'Enter' { return @{ Value = @(0..$last | Where-Object { $s.Picked[$_] } | ForEach-Object { $Items[$_] }) } }
            'Escape' { return @{ Value = @() } }
        }
        switch ($key.KeyChar) {
            'k' { $s.I = [Math]::Max(0, $s.I - 1); return }
            'j' { $s.I = [Math]::Min($last, $s.I + 1); return }
            'a' {
                $all = @($s.Picked | Where-Object { $_ }).Count -lt $Items.Count
                for ($n = 0; $n -le $last; $n++) { $s.Picked[$n] = $all }
                return
            }
            'q' { return @{ Value = @() } }
        }
    }
}

function Select-ChatNumbered {
    # what both of them fall back to where there is no raw keyboard
    param([object[]]$Items, [string]$Title, [switch]$One)
    Write-Host ''
    if ($Title) { Write-Host "  $Title" -ForegroundColor Cyan }
    $width = [Math]::Max(20, $Host.UI.RawUI.WindowSize.Width - 1)
    for ($i = 0; $i -lt $Items.Count; $i++) {
        Write-Host (Format-ChatCell ('  {0,2}. {1}' -f ($i + 1), (Format-ChatRow $Items[$i])) $width)
    }
    if ($One) {
        $answer = (Read-Host '  which one? (empty=cancel)').Trim()
        if ($answer -match '^\d+$' -and [int]$answer -ge 1 -and [int]$answer -le $Items.Count) {
            return $Items[[int]$answer - 1]
        }
        return $null
    }
    $answer = Read-Host '  delete which? (1,3-5 / a=all / empty=cancel)'
    if (-not $answer) { return @() }
    if ($answer.Trim() -eq 'a') { return $Items }
    $idx = [System.Collections.Generic.List[int]]::new()
    foreach ($part in ($answer -split '[,\s]+' | Where-Object { $_ })) {
        if ($part -match '^(\d+)-(\d+)$') { [int]$Matches[1]..[int]$Matches[2] | ForEach-Object { $idx.Add($_ - 1) } }
        elseif ($part -match '^\d+$') { $idx.Add([int]$part - 1) }
    }
    return @($idx | Sort-Object -Unique | Where-Object { $_ -ge 0 -and $_ -lt $Items.Count } | ForEach-Object { $Items[$_] })
}
function chatrm {
    <#
    .SYNOPSIS
    Delete a local AI chat transcript, permanently.
    .DESCRIPTION
    An id is unambiguous, so it deletes outright. A title can match several
    chats, so those are listed and confirmed one by one. Tab fills in the whole
    argument - title or id, quoted or not - from the index that chatfind keeps
    warm; run chatindex to rebuild it.
    Also removes what the transcript leaves behind - sidecars, file-history and
    session-env for Claude, chatEditingSessions for Copilot.
    .PARAMETER Target
    One or more ids (prefixes are fine), or a chat title.
    .PARAMETER Provider
    Limit to claude, copilot or codex. Defaults to all of them.
    .PARAMETER Force
    Skip the confirmation prompts in title mode.
    .PARAMETER AllProjects
    Match titles from every project rather than the one this directory belongs
    to. Ids are unambiguous and always reach any project.
    .EXAMPLE
    chatrm 44e899d3
    .EXAMPLE
    chatrm "Review uncommitted changes"
    .LINK
    chatfind
    #>
    param(
        [Parameter(Position = 0, ValueFromRemainingArguments)][string[]]$Target,
        [string[]]$Provider,
        [switch]$Force,
        [switch]$AllProjects
    )

    if (-not $Target) { Write-Error 'usage: chatrm <id>... | "<title>" [-Force] [-AllProjects]'; return }
    $names = if ($Provider) { $Provider } else { @($script:ChatProviders.Keys) }
    $deleted = 0
    $byId = -not ($Target | Where-Object { $_ -notmatch '^[0-9a-fA-F]{6,}(-[0-9a-fA-F-]*)?$' })

    # ids are not scoped to the project: an id names exactly one chat, so there
    # is nothing for the current directory to disambiguate
    if ($byId) {
        foreach ($id in $Target) {
            $found = $false
            foreach ($name in $names) {
                $p = $script:ChatProviders[$name]
                if (-not $p) { continue }
                foreach ($file in @(& $p.Discover)) {
                    # substring, not prefix: Codex buries the uuid after a timestamp
                    if ($file.BaseName -notlike "*$id*") { continue }
                    $rec = & $p.Describe $file
                    if (-not $rec) { continue }
                    $hit = [pscustomobject]@{ Provider = $name; File = $file; Record = $rec }
                    if (Remove-ChatSession $hit) { $deleted++ }
                    $found = $true
                }
            }
            if (-not $found) { Write-Warning "no transcript for $id - already deleted, or wrong id" }
        }
    }
    else {
        $needle = $Target -join ' '
        $matched = @(Find-ChatSessions -Needle $needle -Provider $Provider -TitleOnly -AllProjects:$AllProjects)
        if (-not $matched) {
            $where = if ($AllProjects) { '' } else { ' here - add -AllProjects to look wider' }
            Write-Warning "no chat titled like '$needle'$where"
            return
        }

        # one chat or several, the path is the same: the line, then Enter.
        # Several only adds the walking. Enter deletes on the spot - no detail
        # dump, no confirmation.
        $chosen = if ($Force) { $matched }
        else {
            $one = Select-ChatOne $matched
            if ($one) { @($one) } else { @() }
        }

        if (-not $chosen) { Write-Host 'nothing deleted'; return }
        foreach ($m in $chosen) {
            # already shown once - by the confirm above, or by the picker list
            if (Remove-ChatSession $m) { $deleted++ }
        }
    }

    if ($deleted) { Write-ChatGhostAdvice }
}

#endregion

#region discoverability -------------------------------------------------------

function chatinstall {
    <#
    .SYNOPSIS
    Add this script to your PowerShell profile, so the chat commands are there in
    every new shell. Dot-source the file once, then run chatinstall.
    .DESCRIPTION
    Writes the dot-source line into $PROFILE, creating the profile if there is
    none, and backing it up to $PROFILE.bak first. The script knows where it is,
    so no path has to be typed twice. A line left behind by an older copy is
    replaced rather than left to load nothing - run this again after moving the
    file.
    .PARAMETER Force
    Rewrite the line even when it is already there.
    .EXAMPLE
    . C:\tools\chatrm\chatrm.ps1
    chatinstall
    #>
    [CmdletBinding()]
    param([switch]$Force)

    $me = $PSCommandPath
    if (-not $me) {
        Write-Host '  cannot tell where this file is' -ForegroundColor Yellow
        Write-Host '  dot-source it by path first:  . C:\path\to\chatrm.ps1' -ForegroundColor DarkGray
        return
    }
    # only Windows marks downloads; elsewhere the cmdlet does not exist at all
    if (Get-Command Unblock-File -EA SilentlyContinue) { Unblock-File -LiteralPath $me -EA SilentlyContinue }

    $dir = Split-Path $PROFILE -Parent
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $lines = if (Test-Path -LiteralPath $PROFILE) { @(Get-Content -LiteralPath $PROFILE) } else { @() }

    # both names: the file was deleteLocalChat.ps1 before it was chatrm.ps1, and
    # a profile still holding that older line has to be repaired, not added to
    $mine = @($lines | Where-Object { $_ -match '(chatrm|deleteLocalChat)\.ps1' })
    # IndexOf, not -like: a path is not a wildcard pattern, and one containing
    # [ or ] would never match itself - appending a second line every run
    $here = @($mine | Where-Object { $_.IndexOf($me, [StringComparison]::OrdinalIgnoreCase) -ge 0 })
    if ($here -and -not $Force) {
        Write-Host '  already installed' -ForegroundColor DarkGray
        Write-Host "    $PROFILE" -ForegroundColor DarkGray
        return
    }

    # the whole file is rewritten to drop a stale line, so keep a copy: this is
    # the user's profile and may hold plenty that has nothing to do with us
    if (Test-Path -LiteralPath $PROFILE) { Copy-Item -LiteralPath $PROFILE -Destination "$PROFILE.bak" -Force }
    $kept = @($lines | Where-Object { $_ -notmatch '(chatrm|deleteLocalChat)\.ps1' })
    $kept += ". `"$me`""
    Set-Content -LiteralPath $PROFILE -Value $kept -Encoding UTF8

    Write-Host '  installed' -ForegroundColor Green
    Write-Host "    $PROFILE"
    # only the lines that pointed somewhere else were really replaced - counting
    # the current one too claimed "from an older location" on a plain -Force rerun
    $stale = $mine.Count - $here.Count
    if ($stale -gt 0) {
        Write-Host "    replaced $stale line$(if ($stale -ne 1) { 's' }) from an older location" -ForegroundColor DarkGray
    }
    Write-Host '    open a new terminal, then type chat' -ForegroundColor DarkGray
}

function chatuninstall {
    <#
    .SYNOPSIS
    Take the chat commands back out of your PowerShell profile.
    .DESCRIPTION
    Drops the dot-source line from $PROFILE, backing it up to $PROFILE.bak first,
    and leaves everything else in that file alone. Matches the old filename too,
    so a profile still carrying a deleteLocalChat line is cleaned as well.

    The commands stay defined in the shell you run this from - they are already
    in memory, and nothing can unload them. Close it and they are gone.

    The folder is left on disk by default, data/ and all, since it holds the
    index and the tombstones. -All deletes it too.
    .PARAMETER All
    Also delete the script's own folder, including data/.
    .EXAMPLE
    chatuninstall
    .EXAMPLE
    chatuninstall -All
    #>
    [CmdletBinding()]
    param([switch]$All)

    # a live watcher outlasts the file it was started for, so stop it first
    Stop-ChatGhostWatch

    $lines = if (Test-Path -LiteralPath $PROFILE) { @(Get-Content -LiteralPath $PROFILE) } else { @() }
    $mine = @($lines | Where-Object { $_ -match '(chatrm|deleteLocalChat)\.ps1' })
    if ($mine.Count) {
        Copy-Item -LiteralPath $PROFILE -Destination "$PROFILE.bak" -Force
        Set-Content -LiteralPath $PROFILE -Encoding UTF8 -Value `
        @($lines | Where-Object { $_ -notmatch '(chatrm|deleteLocalChat)\.ps1' })
        Write-Host "  removed $($mine.Count) line$(if ($mine.Count -ne 1) { 's' }) from the profile" -ForegroundColor Green
        Write-Host "    $PROFILE" -ForegroundColor DarkGray
        Write-Host "    backup: $PROFILE.bak" -ForegroundColor DarkGray
    }
    else {
        Write-Host '  nothing in the profile to remove' -ForegroundColor DarkGray
    }

    $here = if ($PSCommandPath) { Split-Path $PSCommandPath -Parent } else { $null }
    if ($All) {
        if (-not $here) {
            Write-Host '  cannot tell where this file is - delete the folder by hand' -ForegroundColor Yellow
        }
        else {
            # the .ps1 is not held open once dot-sourced, so it can delete itself
            Remove-Item -LiteralPath $here -Recurse -Force -EA SilentlyContinue
            $gone = -not (Test-Path -LiteralPath $here)
            Write-Host "  $(if ($gone) { 'deleted' } else { 'COULD NOT DELETE' })  $here" -ForegroundColor $(if ($gone) { 'Green' } else { 'Yellow' })
            if (-not $gone) { Write-Host '    something in it is open elsewhere' -ForegroundColor DarkGray }
        }
    }
    elseif ($here) {
        Write-Host "  the folder is still there - delete it when you want to:" -ForegroundColor DarkGray
        Write-Host "      Remove-Item -LiteralPath `"$here`" -Recurse -Force" -ForegroundColor Cyan
    }

    Write-Host '  these commands stay in this shell until you close it' -ForegroundColor DarkGray
}

function chat {
    <#
    .SYNOPSIS
    Cheat sheet for the chat commands. Type chat<Tab> to cycle through them.
    #>
    Write-Host ''
    Write-Host '  chatfind "text"        find chats by title or message' -ForegroundColor Cyan
    Write-Host '  chatrm <id> | "title"  delete a chat, permanently' -ForegroundColor Cyan
    Write-Host '  chatclean              delete ghost chats left by the VS Code list' -ForegroundColor Cyan
    Write-Host '  chatproviders          which tools were found, and where' -ForegroundColor Cyan
    Write-Host '  chatindex              rebuild the tab-completion index' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  chatinstall            load these in every new shell (once)' -ForegroundColor DarkGray
    Write-Host '  chatuninstall [-All]   undo that; -All removes the folder too' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '  Tab fills in the argument: type any part of a title, no quotes needed'
    Write-Host '  -Provider claude|copilot|codex   -Deep   -All   -AllProjects   -Force'
    Write-Host '  Get-Help chatfind -Full           full help, examples and notes'
    Write-Host "  $PSCommandPath"
    Write-Host ''
}

# verb-noun aliases so Get-Command *-Chat* and Find-<Tab> surface these too
Set-Alias -Name Find-Chat -Value chatfind -Scope Global -Force
Set-Alias -Name Remove-Chat -Value chatrm -Scope Global -Force
Set-Alias -Name Get-ChatProvider -Value chatproviders -Scope Global -Force
Set-Alias -Name Update-ChatIndex -Value chatindex -Scope Global -Force

Register-ArgumentCompleter -CommandName chatfind, chatrm, chatindex -ParameterName Provider -ScriptBlock {
    param($cmd, $param, $word)
    @('claude', 'copilot', 'codex') | Where-Object { $_ -like "$word*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

function Get-ChatCells {
    # width in console cells, not characters: Hangul and CJK draw two cells
    # each, so String.Length leaves a column of Korean titles ragged
    param([string]$Text)
    $n = 0
    foreach ($c in $Text.ToCharArray()) {
        $u = [int]$c
        if (($u -ge 0x1100 -and $u -le 0x115F) -or ($u -ge 0x2E80 -and $u -le 0x303E) -or
            ($u -ge 0x3041 -and $u -le 0x33FF) -or ($u -ge 0x3400 -and $u -le 0x4DBF) -or
            ($u -ge 0x4E00 -and $u -le 0x9FFF) -or ($u -ge 0xA000 -and $u -le 0xA4CF) -or
            ($u -ge 0xAC00 -and $u -le 0xD7A3) -or ($u -ge 0xF900 -and $u -le 0xFAFF) -or
            ($u -ge 0xFE30 -and $u -le 0xFE6F) -or ($u -ge 0xFF00 -and $u -le 0xFF60) -or
            ($u -ge 0xFFE0 -and $u -le 0xFFE6)) { $n += 2 } else { $n++ }
    }
    return $n
}

function Format-ChatCell {
    # clip to exactly $Cells console cells, padding short text out to the same
    # unless -NoPad, which callers use when they are joining pieces themselves
    param([string]$Text, [int]$Cells, [switch]$NoPad)
    $w = Get-ChatCells $Text
    if ($w -le $Cells) {
        if ($NoPad) { return $Text }
        return $Text + (' ' * ($Cells - $w))
    }
    $len = 0
    while ($len -lt $Text.Length -and (Get-ChatCells $Text.Substring(0, $len + 1)) -le ($Cells - 3)) { $len++ }
    $out = $Text.Substring(0, $len) + '...'
    if ($NoPad) { return $out }
    return $out + (' ' * [Math]::Max(0, $Cells - (Get-ChatCells $out)))
}

function Get-ChatSyntaxColor {
    # PSReadLine's own colours, read from the live options rather than guessed,
    # so the walked line is painted exactly like the line Tab writes into the
    # buffer - and follows the user's theme if they changed it
    if ($script:ChatColors) { return $script:ChatColors }
    $esc = [char]27
    $c = @{
        Command = "$esc[93m"; String = "$esc[36m"
        Param   = "$esc[90m"; Comment = "$esc[32m"; Reset = "$esc[0m"
    }
    $o = try { Get-PSReadLineOption -EA Stop } catch { $null }
    if ($o) {
        if ($o.CommandColor) { $c.Command = $o.CommandColor }
        if ($o.StringColor) { $c.String = $o.StringColor }
        if ($o.ParameterColor) { $c.Param = $o.ParameterColor }
        if ($o.CommentColor) { $c.Comment = $o.CommentColor }
    }
    $script:ChatColors = $c
    return $c
}

function Format-ChatMenuRow {
    # One menu row: title, owner, age, opening prompt. PSReadLine 2.0 draws no
    # tooltip, so this line is the whole preview. Fixed columns rather than
    # free text - run together, the rows read as one paragraph.
    param($Row, [int]$Extra = 0)
    $when = try {
        Get-ChatAge ([datetime]::Parse($Row.When, [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::RoundtripKind))
    }
    catch { '?' }
    $tag = if ($Extra) { "[$Extra chats $when]" } else { "[$($Row.Provider) $when]" }

    $total = [Math]::Max(24, $Host.UI.RawUI.WindowSize.Width - 4)
    $tagCells = 15
    $titleCells = [Math]::Max(12, [Math]::Min(44, [int]($total * 0.42)))
    $rest = $total - $titleCells - $tagCells - 2
    if ($rest -lt 12) {
        # too narrow for an excerpt - give the space back to the title
        $titleCells = [Math]::Max(8, $total - $tagCells - 1)
        $rest = 0
    }

    $text = (Format-ChatCell $Row.Title $titleCells) + ' ' + (Format-ChatCell $tag $tagCells)
    $first = @($Row.First)[0]
    if ($rest -and $first) {
        $text += ' ' + (Format-ChatCell ('> ' + ($first -replace '\s+', ' ')) $rest)
    }
    return $text
}

function Get-ChatCompletionPreview {
    # the multi-line tooltip - shown by Ctrl+Space and PSReadLine 2.2+
    param($Row, [int]$Extra = 0)
    $when = try {
        Get-ChatAge ([datetime]::Parse($Row.When, [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::RoundtripKind))
    }
    catch { '?' }
    $lines = @("$($Row.Title)", "$($Row.Provider) / $($Row.Group) / $when")
    if ($Extra) { $lines += "$Extra chats share this title - you pick from a list" }
    $clip = { param($t) if ($t.Length -gt 76) { $t.Substring(0, 76) + '...' } else { $t } }
    foreach ($m in @($Row.First) | Select-Object -First 2) { $lines += '  > ' + (& $clip $m) }
    $tail = @($Row.Last)
    if ($tail -and (@($Row.First) -join "`n") -ne ($tail -join "`n")) {
        $lines += '  ...'
        $lines += '  > ' + (& $clip $tail[-1])
    }
    return ($lines -join "`n")
}

$script:ChatTitleCompleter = {
    param($cmd, $param, $word)
    $w = $word.Trim('"', "'")
    $rows = @(Get-ChatIndex | Where-Object { $_.Title -ne '(empty)' })   # abandoned sessions
    if (-not $rows) {
        return [System.Management.Automation.CompletionResult]::new(
            "''", 'run chatindex first', 'ParameterValue', 'No index yet - run chatindex or any chatfind')
    }

    # hex looks like an id, anything else looks like a title
    if ($w -match '^[0-9a-fA-F]{2,}$') {
        return $rows | Where-Object { $_.Id -like "$w*" } |
            Sort-Object When -Descending | Select-Object -First 25 | ForEach-Object {
                [System.Management.Automation.CompletionResult]::new(
                    $_.Id, (Format-ChatMenuRow $_), 'ParameterValue',
                    (Get-ChatCompletionPreview $_))
            }
    }

    $starts = @($rows | Where-Object { -not $w -or $_.Title.StartsWith($w, [StringComparison]::OrdinalIgnoreCase) })
    if (-not $starts -and $w) {
        $starts = @($rows | Where-Object { $_.Title.IndexOf($w, [StringComparison]::OrdinalIgnoreCase) -ge 0 })
    }
    $starts |
        Group-Object Title | ForEach-Object {
            $newest = ($_.Group | Sort-Object When -Descending)[0]
            $extra = if ($_.Count -gt 1) { $_.Count } else { 0 }
            [pscustomobject]@{
                Title = $_.Name; When = $newest.When
                Label = Format-ChatMenuRow $newest $extra
                Tip   = Get-ChatCompletionPreview $newest $extra
            }
        } |
        Sort-Object When -Descending | Select-Object -First 25 | ForEach-Object {
            # single quotes: titles carry apostrophes, $ and braces that would
            # otherwise be interpreted when the line is run
            $quoted = "'" + $_.Title.Replace("'", "''") + "'"
            [System.Management.Automation.CompletionResult]::new($quoted, $_.Label, 'ParameterValue', $_.Tip)
        }
}

# chatfind takes the same titles, under a different parameter name
Register-ArgumentCompleter -CommandName chatrm -ParameterName Target -ScriptBlock $script:ChatTitleCompleter
Register-ArgumentCompleter -CommandName chatfind -ParameterName Text -ScriptBlock $script:ChatTitleCompleter

# ---------------------------- the one-line cycler ----------------------------
# Tab does not open a list, and does not complete the word under the cursor. It
# replaces the whole argument with one chat and describes it on the same line,
# in a trailing comment PowerShell ignores; arrows walk to the next one.
# It has to work this way: a preview pane of our own would have to read the
# arrow keys itself, and inside a key handler PSReadLine's key reader is
# already blocked on the console waiting for them - the two race and the pane
# never gets a keystroke. Rewriting the buffer needs no keyboard at all.

$script:ChatCycle = $null

function Get-ChatCycleRows {
    # candidates for the cycler: ids if it looks like one, else titles,
    # prefix first and only then widening to a contains-match
    param([string]$Filter, [ref]$ById)
    # scoped like the search is: offering a chat from another project that
    # chatrm would then refuse to match is worse than offering nothing
    $all = @(Select-ChatInProject @(Get-ChatIndex | Where-Object { $_.Title -ne '(empty)' }))
    if ($Filter -match '^[0-9a-fA-F]{2,}$') {
        $hit = @($all | Where-Object { $_.Id -like "$Filter*" })
        if ($hit) {
            $ById.Value = $true
            return @($hit | Sort-Object When -Descending | Select-Object -First 40)
        }
    }
    $ById.Value = $false
    $rows = @($all | Where-Object { -not $Filter -or $_.Title.StartsWith($Filter, [StringComparison]::OrdinalIgnoreCase) })
    if (-not $rows -and $Filter) {
        $rows = @($all | Where-Object { $_.Title.IndexOf($Filter, [StringComparison]::OrdinalIgnoreCase) -ge 0 })
    }
    # one entry per title - chatrm sorts out duplicates itself, with its own list
    $uniq = $rows | Group-Object Title | ForEach-Object { ($_.Group | Sort-Object When -Descending)[0] }
    return @($uniq | Sort-Object When -Descending | Select-Object -First 40)
}

function Get-ChatRowAge {
    # The cycler runs off the cached index, which is only as fresh as the last
    # chatfind or chatrm - it read 2h for a chat the panel called 32m, because
    # the chat had grown 1.1 MB since the index was written. Only one row is
    # ever on screen, so re-read that one when its file has moved. The walk
    # after Enter needs none of this: Find-ChatSessions syncs first.
    param($Row)
    $when = try {
        [datetime]::Parse($Row.When, [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::RoundtripKind)
    }
    catch { $null }
    $f = Get-Item -LiteralPath $Row.Path -EA SilentlyContinue
    if ($f -and ($f.Length -ne $Row.Size -or $f.LastWriteTimeUtc.Ticks -ne $Row.Mtime)) {
        $name = Get-ChatProviderForPath $Row.Path
        $rec = if ($name) { & $script:ChatProviders[$name].Describe $f } else { $null }
        if ($rec) { $when = $rec.When }
    }
    if ($when) { return Get-ChatAge $when }
    return ''
}

function Set-ChatCycleLine {
    # move by $Step through the run and rewrite the whole buffer
    param([int]$Step)
    $c = $script:ChatCycle
    $c.Index = ($c.Index + $Step) % $c.Items.Count
    if ($c.Index -lt 0) { $c.Index += $c.Items.Count }
    $row = $c.Items[$c.Index]

    $pick = if ($c.ById) { $row.Id } else { "'" + $row.Title.Replace("'", "''") + "'" }
    $head = $c.Head + $pick
    # once per chat per run: re-reading a growing transcript costs ~300ms, and
    # arrowing back and forth would pay it again every time
    if (-not $c.Ages.ContainsKey($row.Path)) { $c.Ages[$row.Path] = Get-ChatRowAge $row }
    # the same tail the walk shows, so both look like one another
    $line = $head + (Format-ChatPickTail $c.Ages[$row.Path] ($c.Index + 1) $c.Items.Count)

    $cur = $null; $pos = 0
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$cur, [ref]$pos)
    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $cur.Length, $line)
    # leave the cursor on the chat, not out in the comment
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($head.Length)
    $c.Line = $line
}

function Test-ChatCycling {
    # still on the line we wrote last time?
    param([string]$Line)
    $script:ChatCycle -and $script:ChatCycle.Line -eq $Line
}

function Start-ChatCycle {
    # begin a run from whatever has been typed after the command
    param([string]$Line)
    $m = [regex]::Match($Line, '^\s*chat(rm|find)\s+')
    if (-not $m.Success) { return $false }
    $arg = $Line.Substring($m.Length)
    # everything after the command is the filter, spaces and quotes included - a
    # quote the user opened is dropped here and Set-ChatCycleLine puts single
    # ones back, so typing one neither helps the match nor breaks it
    $arg = ($arg -replace $script:ChatTailPattern, '').Trim().Trim("'", '"').Trim()
    if ($arg.StartsWith('-')) { return $false }        # a parameter, not a title
    $byId = $false
    $rows = @(Get-ChatCycleRows $arg ([ref]$byId))
    if (-not $rows) { return $false }
    $script:ChatCycle = @{
        Head  = $Line.Substring(0, $m.Length)
        Items = $rows
        Index = -1
        ById  = $byId
        Line  = ''
        Ages  = @{}
    }
    Set-ChatCycleLine 1
    return $true
}

# Tab starts or advances the run, Shift+Tab steps back, and the arrows do the
# same but only while a run is live - otherwise they stay history navigation.
# Opt out with $ChatNoKeyBindings = $true before the dot-source line.
if (-not $ChatNoKeyBindings -and (Get-Module PSReadLine -ListAvailable -EA SilentlyContinue)) {
    try {
        Import-Module PSReadLine -EA Stop

        # remember what the arrows did before we took them over
        $script:ChatArrowWas = @{}
        foreach ($k in 'UpArrow', 'DownArrow') {
            $bound = Get-PSReadLineKeyHandler -Bound | Where-Object { $_.Key -eq $k }
            $script:ChatArrowWas[$k] = if ($bound) { $bound.Function } else { $null }
        }

        function Invoke-ChatPSReadLine {
            # call a PSReadLine action by name, so the arrows keep doing
            # whatever they were bound to before this file was loaded
            param([string]$Name, [string]$Fallback)
            if (-not $Name) { $Name = $Fallback }
            $mi = [Microsoft.PowerShell.PSConsoleReadLine].GetMethod(
                $Name, [type[]]@([System.Nullable[System.ConsoleKeyInfo]], [object]))
            if (-not $mi) {
                $mi = [Microsoft.PowerShell.PSConsoleReadLine].GetMethod(
                    $Fallback, [type[]]@([System.Nullable[System.ConsoleKeyInfo]], [object]))
            }
            if ($mi) { [void]$mi.Invoke($null, @($null, $null)) }
        }

        Set-PSReadLineKeyHandler -Key Tab -BriefDescription 'ChatCycleNext' `
            -Description 'Fill in the next matching chat, described in a trailing comment' -ScriptBlock {
            $line = $null; $pos = 0
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$pos)
            if (Test-ChatCycling $line) { Set-ChatCycleLine 1; return }
            $script:ChatCycle = $null
            if (-not (Start-ChatCycle $line)) {
                [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()
            }
        }

        Set-PSReadLineKeyHandler -Key Shift+Tab -BriefDescription 'ChatCyclePrev' `
            -Description 'Step back through the matching chats' -ScriptBlock {
            $line = $null; $pos = 0
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$pos)
            if (Test-ChatCycling $line) { Set-ChatCycleLine -1; return }
            [Microsoft.PowerShell.PSConsoleReadLine]::TabCompletePrevious()
        }

        Set-PSReadLineKeyHandler -Key DownArrow -BriefDescription 'ChatCycleOrHistory' `
            -Description 'Next matching chat while cycling, history otherwise' -ScriptBlock {
            $line = $null; $pos = 0
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$pos)
            if (Test-ChatCycling $line) { Set-ChatCycleLine 1; return }
            Invoke-ChatPSReadLine $script:ChatArrowWas['DownArrow'] 'NextHistory'
        }

        Set-PSReadLineKeyHandler -Key UpArrow -BriefDescription 'ChatCycleOrHistory' `
            -Description 'Previous matching chat while cycling, history otherwise' -ScriptBlock {
            $line = $null; $pos = 0
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$pos)
            if (Test-ChatCycling $line) { Set-ChatCycleLine -1; return }
            Invoke-ChatPSReadLine $script:ChatArrowWas['UpArrow'] 'PreviousHistory'
        }

        Set-PSReadLineKeyHandler -Key Enter -BriefDescription 'ChatAcceptLine' `
            -Description 'Drop the age and counter, then run the line' -ScriptBlock {
            $line = $null; $pos = 0
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$pos)
            # not only while cycling: the tail survives an edit, and left on the
            # line "(5d)" would be run as an expression rather than ignored
            if ($line -match '^\s*chat(rm|find)\s') {
                $clean = $line -replace $script:ChatTailPattern, ''
                if ($clean -ne $line) {
                    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, $clean)
                }
                $script:ChatCycle = $null
            }
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
        }
    }
    catch {}
}

# a shell opened after the delete picks the watch back up
if (Test-Path -LiteralPath $script:ChatTombPath) { Start-ChatGhostWatch }

# Run instead of dot-sourced - & file.ps1, powershell -File, a double-click.
# Everything above was defined in a scope about to be thrown away, leaving a
# shell with no chat command and nothing said about why. InvocationName is '.'
# for a real dot-source, at the prompt and from inside a profile alike, and the
# path or '&' otherwise, so this cannot fire on a legitimate load.
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host ''
    Write-Host '  nothing was loaded - this file has to be dot-sourced' -ForegroundColor Yellow
    Write-Host '  a dot and a space in front of the path is the whole difference:' -ForegroundColor DarkGray
    # iex has no file behind it, so PSCommandPath is empty there - printing
    # . "" would be advice nobody can follow, and is how an empty dot-source
    # line ends up pasted into a profile in the first place
    $shown = if ($PSCommandPath) { $PSCommandPath } else { 'C:\path\to\chatrm.ps1' }
    Write-Host "      . `"$shown`"" -ForegroundColor Cyan
    Write-Host '  then chatinstall, to have every new shell do it for you' -ForegroundColor DarkGray
    Write-Host ''
}

#endregion
