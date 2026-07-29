# Link Windows OpenSSH client config to dotfiles-managed unified ssh/config
$ErrorActionPreference = 'Stop'
$dst = "$env:USERPROFILE\.ssh\config"
$src = "$env:USERPROFILE\dotfiles\ssh\config"
New-Item -ItemType Directory -Force "$env:USERPROFILE\.ssh" | Out-Null
if (Test-Path $dst -and -not (Get-Item $dst).LinkType) {
  Copy-Item $dst "$dst.bak.$(Get-Date -Format yyyyMMddHHmmss)"
}
New-Item -ItemType SymbolicLink -Path $dst -Target $src -Force | Out-Null
Write-Host "Linked $dst -> $src"
