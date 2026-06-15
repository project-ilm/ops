#!/usr/bin/env bash
# recon.sh — quick state-of-the-box for planning. Run: bash recon.sh 2>&1 | tee recon.out
echo "=== 1. work folder contents ==="
find ~/work -maxdepth 3 | head -50
echo "=== 2. hindawi + src + manifest files ==="
ls -la ~/hindawi ~/src 2>/dev/null | head -30
head -5 ~/manifest.hash ~/manifest.uniq 2>/dev/null
echo "=== 3. firefox: snap confinement check (the usual download blocker) ==="
snap list firefox 2>/dev/null
snap connections firefox 2>/dev/null | grep -E "home|removable"
ls -ld ~/Downloads; df -h ~/Downloads | tail -1
journalctl --since "1 hour ago" 2>/dev/null | grep -i -m5 "apparmor.*DENIED.*firefox"
echo "=== 4. toolchain present? ==="
for t in gcc flex make git gh python3 pip3 iconv ots zenodo_get curl jq; do
  printf "%-12s %s\n" "$t" "$(command -v $t || echo MISSING)"
done
python3 -c "import tokenizers" 2>/dev/null && echo "tokenizers: OK" || echo "tokenizers: MISSING"
echo "=== 5. gh auth + git identity ==="
gh auth status 2>&1 | head -3
git config --global user.name; git config --global user.email
echo "=== 6. GPU/CUDA ==="
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv 2>/dev/null || echo "nvidia-smi missing"
echo "=== 7. network reach (for zenodo/github/arxiv) ==="
for u in zenodo.org github.com arxiv.org pypi.org; do
  printf "%-12s HTTP %s\n" "$u" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 https://$u)"
done
