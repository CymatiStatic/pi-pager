# Publishing pi-notify to Package Registries

Step-by-step for releasing a new version across all distribution channels.

## 1. GitHub Release

```powershell
# After merging to main
git tag -a v0.2.0 -m "pi-notify v0.2.0"
git push origin main --tags
gh release create v0.2.0 --generate-notes --title "pi-notify v0.2.0"
```

## 2. PowerShell Gallery

Requires a free account at [powershellgallery.com](https://www.powershellgallery.com).

```powershell
# One-time: get API key from https://www.powershellgallery.com/account/apikeys
$apiKey = Read-Host -AsSecureString "PSGallery API Key"
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)
)

# Copy scripts next to the module (so relative path works after install)
Copy-Item -Recurse -Force scripts module\scripts

# Publish
Publish-Module -Path .\module -NuGetApiKey $plain -Repository PSGallery -Verbose
```

Users install via:
```powershell
Install-Module -Name PiNotify -Scope CurrentUser
Import-Module PiNotify
Send-PiNotify -Type done -Message 'Hello'
```

## 3. Scoop

Requires hosting `packaging/scoop/pi-notify.json` at a URL Scoop can reach. Two options:

**Option A — Host in main repo**
```powershell
scoop bucket add pi-notify https://github.com/CymatiStatic/pi-notify
scoop install pi-notify/pi-notify
```
But Scoop by convention expects the bucket repo name to start with `scoop-` or `bucket-`. Cleaner path:

**Option B — Dedicated bucket repo**
```bash
gh repo create CymatiStatic/scoop-pi-notify --public
cd ..
git clone https://github.com/CymatiStatic/scoop-pi-notify.git
cp pi-notify/packaging/scoop/pi-notify.json scoop-pi-notify/
cd scoop-pi-notify
git add . && git commit -m "Initial manifest for v0.2.0" && git push
```

Users:
```powershell
scoop bucket add cymaticstatic https://github.com/CymatiStatic/scoop-pi-notify
scoop install pi-notify
```

**Hash update on release**:
```powershell
$url = "https://github.com/CymatiStatic/pi-notify/archive/refs/tags/v0.2.0.zip"
$hash = (Invoke-WebRequest $url -OutFile tmp.zip; Get-FileHash tmp.zip).Hash
# Paste into packaging/scoop/pi-notify.json -> "hash" field (optional; checkver auto-updates)
```

## 4. Homebrew

Requires hosting `packaging/homebrew/pi-notify.rb` in a tap repo named `homebrew-<something>`.

```bash
gh repo create CymatiStatic/homebrew-pi-notify --public
cd ..
git clone https://github.com/CymatiStatic/homebrew-pi-notify.git
mkdir -p homebrew-pi-notify/Formula
cp pi-notify/packaging/homebrew/pi-notify.rb homebrew-pi-notify/Formula/
cd homebrew-pi-notify

# Update the sha256 in Formula/pi-notify.rb:
curl -sL https://github.com/CymatiStatic/pi-notify/archive/refs/tags/v0.2.0.tar.gz | shasum -a 256
# Paste the hash into the formula's sha256 field, replacing REPLACE_WITH_SHA256...

git add . && git commit -m "pi-notify 0.2.0" && git push
```

Users:
```bash
brew tap CymatiStatic/pi-notify
brew install pi-notify
```

Test the formula locally first:
```bash
brew install --build-from-source ./Formula/pi-notify.rb
brew test pi-notify
brew audit --strict --online pi-notify
```

## 5. Set GitHub Repo Social Preview

```bash
# Upload via web UI (no gh CLI support as of 2026):
# Repo → Settings → General → Social preview → Upload assets/social-1280x640.png
```

Or via API:
```bash
gh api repos/CymatiStatic/pi-notify --method PATCH \
  -f description='Cross-channel alerts for agentic AI workflows' \
  -f homepage='https://github.com/CymatiStatic/pi-notify'
# Social preview image requires web upload
```

## Release Checklist

- [ ] All tests pass (manual smoke test on Windows + Mac if possible)
- [ ] CI green on `main`
- [ ] `CHANGELOG.md` updated with user-facing changes
- [ ] Version bumped in `PiNotify.psd1`, `scoop/pi-notify.json`, `homebrew/pi-notify.rb`
- [ ] README install instructions still accurate
- [ ] `git tag -a vX.Y.Z` + `git push --tags`
- [ ] `gh release create vX.Y.Z --generate-notes`
- [ ] Publish to PSGallery
- [ ] Update Scoop bucket
- [ ] Update Homebrew tap (with new sha256)
- [ ] Announce on relevant community channels
