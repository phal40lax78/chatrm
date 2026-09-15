# chatrm one-line installer
#
#   iex (irm https://raw.githubusercontent.com/phal40lax78/chatrm/main/install.ps1)
#
# Downloads chatrm.ps1 to a real folder and dot-sources it from there. It has to
# reach disk first: chatrm.ps1 finds data/ and the line it writes into $PROFILE
# from its own file path, and running it out of memory leaves both empty.
#
# Under iex this runs in the caller's scope, which is the point - the dot-source
# at the end then lands the commands in the session you typed from. That also
# means it must not set $ErrorActionPreference or leave variables behind, and it
# cannot wrap itself in & { }, which would dot-source into a scope about to go.
#
# Set CHATRM_DIR beforehand to install somewhere other than ~/Tools/chatrm.

$chatrmUrl = 'https://raw.githubusercontent.com/phal40lax78/chatrm/main/chatrm.ps1'
$chatrmDir = if ($env:CHATRM_DIR) { $env:CHATRM_DIR } else { Join-Path (Join-Path $HOME 'Tools') 'chatrm' }
$chatrmFile = Join-Path $chatrmDir 'chatrm.ps1'

# an untouched 5.1 may still default to TLS 1.0, which raw.githubusercontent
# refuses - add 1.2 rather than replacing whatever is already enabled
if ([Net.ServicePointManager]::SecurityProtocol -notmatch 'Tls12') {
    [Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}

New-Item -ItemType Directory -Path $chatrmDir -Force -ErrorAction Stop | Out-Null
Write-Host "  downloading chatrm.ps1 -> $chatrmFile" -ForegroundColor DarkGray
Invoke-WebRequest $chatrmUrl -OutFile $chatrmFile -UseBasicParsing -ErrorAction Stop

. $chatrmFile
chatinstall

Remove-Variable chatrmUrl, chatrmDir, chatrmFile -ErrorAction SilentlyContinue
