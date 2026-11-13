# Brings a restored (already patched) Chromium tree in line with the patches
# in this repository: reverts the patches recorded in the tree, applies the
# current ones, and restores the modification time of every file whose
# content ended up unchanged so that only real changes are recompiled.
param(
  [Parameter(Mandatory)] [string] $Root,
  [Parameter(Mandatory)] [string] $NewPatches
)

$ErrorActionPreference = 'Stop'
$src = Join-Path $Root 'src'
$applied = Join-Path $Root 'applied_patches'

function Get-PatchSignature([string] $dir) {
  (Get-ChildItem (Join-Path $dir '*.patch') | Sort-Object Name | ForEach-Object {
    "$($_.Name):$((Get-FileHash $_.FullName -Algorithm SHA256).Hash)"
  }) -join ';'
}

function Get-PatchedFiles([string] $dir) {
  Get-ChildItem (Join-Path $dir '*.patch') | ForEach-Object {
    Select-String -Path $_.FullName -Pattern '^diff --git a/(\S+) b/(\S+)$' |
      ForEach-Object { $_.Matches[0].Groups[2].Value }
  } | Sort-Object -Unique
}

if (-not (Test-Path $applied)) { throw "no applied_patches directory in the restored tree" }

if ((Get-PatchSignature $applied) -eq (Get-PatchSignature $NewPatches)) {
  Write-Host "Patches unchanged."
  return
}

$files = @(Get-PatchedFiles $applied) + @(Get-PatchedFiles $NewPatches) | Sort-Object -Unique
$before = @{}
foreach ($file in $files) {
  $path = Join-Path $src $file
  if (Test-Path $path) {
    $before[$file] = @{
      Hash = (Get-FileHash $path -Algorithm SHA256).Hash
      Time = (Get-Item $path).LastWriteTimeUtc
    }
  }
}

Push-Location $src
try {
  Get-ChildItem (Join-Path $applied '*.patch') | Sort-Object Name -Descending | ForEach-Object {
    Write-Host "Reverting $($_.Name)"
    git apply -R --whitespace=nowarn $_.FullName
    if ($LASTEXITCODE -ne 0) { throw "failed to revert $($_.Name)" }
  }
  Get-ChildItem (Join-Path $NewPatches '*.patch') | Sort-Object Name | ForEach-Object {
    Write-Host "Applying $($_.Name)"
    git apply --whitespace=nowarn $_.FullName
    if ($LASTEXITCODE -ne 0) { throw "failed to apply $($_.Name)" }
  }
} finally {
  Pop-Location
}

$changed = 0
foreach ($file in $files) {
  $path = Join-Path $src $file
  if ($before.ContainsKey($file) -and (Test-Path $path) -and
      (Get-FileHash $path -Algorithm SHA256).Hash -eq $before[$file].Hash) {
    (Get-Item $path).LastWriteTimeUtc = $before[$file].Time
  } else {
    $changed++
    Write-Host "Changed: $file"
  }
}
Write-Host "$changed of $($files.Count) patched files changed."

Remove-Item -Recurse -Force $applied
New-Item -ItemType Directory -Force $applied | Out-Null
Copy-Item (Join-Path $NewPatches '*.patch') $applied
