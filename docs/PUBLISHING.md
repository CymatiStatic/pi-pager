# Publishing pi-pager to Package Registries

Step-by-step for releasing a new version across all distribution channels.

## 1. GitHub Release

```powershell
# After merging to main
git tag -a v0.2.0 -m "pi-pager v0.2.0"
git push origin main --tags
gh release create v0.2.0 --generate-notes --title "pi-pager v0.2.0"
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
Install-Module -Name PiPager -Scope CurrentUser
Import-Module PiPager
Send-PiPage -Type done -Message 'Hello'
```

## 3. Scoop

Requires hosting `packaging/scoop/pi-pager.json` at a URL Scoop can reach. Two options:

**Option A — Host in main repo**
```powershell
scoop bucket add pi-pager https://github.com/CymatiStatic/pi-pager
scoop install pi-pager/pi-pager
```
But Scoop by convention expects the bucket repo name to start with `scoop-` or `bucket-`. Cleaner path:

**Option B — Dedicated bucket repo**
```bash
gh repo create CymatiStatic/scoop-pi-pager --public
cd ..
git clone https://github.com/CymatiStatic/scoop-pi-pager.git
cp pi-pager/packaging/scoop/pi-pager.json scoop-pi-pager/
cd scoop-pi-pager
git add . && git commit -m "Initial manifest for v0.2.0" && git push
```

Users:
```powershell
scoop bucket add cymaticstatic https://github.com/CymatiStatic/scoop-pi-pager
scoop install pi-pager
```

**Hash update on release**:
```powershell
$url = "https://github.com/CymatiStatic/pi-pager/archive/refs/tags/v0.2.0.zip"
$hash = (Invoke-WebRequest $url -OutFile tmp.zip; Get-FileHash tmp.zip).Hash
# Paste into packaging/scoop/pi-pager.json -> "hash" field (optional; checkver auto-updates)
```

## 4. Homebrew

Requires hosting `packaging/homebrew/pi-pager.rb` in a tap repo named `homebrew-<something>`.

```bash
gh repo create CymatiStatic/homebrew-pi-pager --public
cd ..
git clone https://github.com/CymatiStatic/homebrew-pi-pager.git
mkdir -p homebrew-pi-pager/Formula
cp pi-pager/packaging/homebrew/pi-pager.rb homebrew-pi-pager/Formula/
cd homebrew-pi-pager

# Update the sha256 in Formula/pi-pager.rb:
curl -sL https://github.com/CymatiStatic/pi-pager/archive/refs/tags/v0.2.0.tar.gz | shasum -a 256
# Paste the hash into the formula's sha256 field, replacing REPLACE_WITH_SHA256...

git add . && git commit -m "pi-pager 0.2.0" && git push
```

Users:
```bash
brew tap CymatiStatic/pi-pager
brew install pi-pager
```

Test the formula locally first:
```bash
brew install --build-from-source ./Formula/pi-pager.rb
brew test pi-pager
brew audit --strict --online pi-pager
```

## 5. Set GitHub Repo Social Preview

```bash
# Upload via web UI (no gh CLI support as of 2026):
# Repo → Settings → General → Social preview → Upload assets/social-1280x640.png
```

Or via API:
```bash
gh api repos/CymatiStatic/pi-pager --method PATCH \
  -f description='Cross-channel alerts for agentic AI workflows' \
  -f homepage='https://github.com/CymatiStatic/pi-pager'
# Social preview image requires web upload
```

## Release Checklist

- [ ] All tests pass (manual smoke test on Windows + Mac if possible)
- [ ] CI green on `main`
- [ ] `CHANGELOG.md` updated with user-facing changes
- [ ] Version bumped in `PiPager.psd1`, `scoop/pi-pager.json`, `homebrew/pi-pager.rb`
- [ ] README install instructions still accurate
- [ ] `git tag -a vX.Y.Z` + `git push --tags`
- [ ] `gh release create vX.Y.Z --generate-notes`
- [ ] Publish to PSGallery
- [ ] Update Scoop bucket
- [ ] Update Homebrew tap (with new sha256)
- [ ] Announce on relevant community channels
