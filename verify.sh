#!/usr/bin/env bash
set -uo pipefail
export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"
for x in subfinder assetfinder amass shosubgo dnsx httpx nuclei katana naabu shuffledns gau waybackurls anew gf ffuf asnmap mapcidr masscan nmap dirsearch sqlmap whatweb nikto dirb httprobe qsreplace notify uncover chaos gobuster massdns; do
 if command -v "$x" >/dev/null 2>&1; then printf '[OK] %-15s %s\n' "$x" "$(command -v "$x")"; else printf '[--] %s\n' "$x"; fi
done
