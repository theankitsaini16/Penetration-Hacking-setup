#!/usr/bin/env bash
set -uo pipefail
PROFILE=core; YES=0; UPDATE=0; PREFIX="${HOME}/bugbounty-tools"
usage(){ echo 'Usage: bash install.sh [--profile core|full] [--yes] [--update] [--prefix DIR]'; }
while (($#)); do case "$1" in --profile) PROFILE="${2:?}"; shift 2;; --yes) YES=1; shift;; --update) UPDATE=1; shift;; --prefix) PREFIX="${2:?}"; shift 2;; -h|--help) usage; exit;; *) usage; exit 2;; esac; done
[[ "$PROFILE" == core || "$PROFILE" == full ]] || { usage; exit 2; }
[[ -f /etc/debian_version ]] || { echo 'Only Debian/Ubuntu/Kali supported'; exit 1; }
ROOT_CMD=(); if ((EUID!=0)); then command -v sudo >/dev/null || { echo 'sudo required';exit 1; }; ROOT_CMD=(sudo); fi
mkdir -p "$PREFIX" "$HOME/.local/bin" "$PREFIX/logs"; LOG="$PREFIX/logs/install-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1
failures=(); successes=()
install_apt(){ echo "[APT] $*"; if ! DEBIAN_FRONTEND=noninteractive "${ROOT_CMD[@]}" apt-get install -y "$@"; then failures+=("apt:$*"); fi; }
apt_refresh(){ "${ROOT_CMD[@]}" apt-get update || { echo 'apt update failed'; exit 1; }; }
install_go(){ local bin="$1" module="$2"; if command -v "$bin" >/dev/null 2>&1 && (( ! UPDATE )); then echo "[SKIP] $bin"; return; fi; echo "[GO] $bin <- $module"; if GOBIN="$HOME/go/bin" go install "$module"; then successes+=("$bin"); else failures+=("$bin"); fi; }
clone_repo(){ local name="$1" url="$2"; if [[ -d "$PREFIX/$name/.git" ]]; then if ((UPDATE)); then git -C "$PREFIX/$name" pull --ff-only || failures+=("$name:update"); else echo "[SKIP] $name"; fi; else echo "[GIT] $url"; git clone --depth 1 "$url" "$PREFIX/$name" || failures+=("$name:clone"); fi; }
if (( ! YES )); then echo "Will install $PROFILE bug bounty tooling from apt, Go modules and selected GitHub repositories."; read -r -p 'Continue? [y/N] ' answer; [[ "$answer" =~ ^[Yy]$ ]] || exit 0; fi
apt_refresh
install_apt ca-certificates curl wget git jq unzip zip tar build-essential make gcc pkg-config python3 python3-pip python3-venv pipx golang-go nmap masscan dnsutils whois netcat-openbsd traceroute whatweb nikto dirb sqlmap
if [[ "$PROFILE" == full ]]; then install_apt tcpdump wireshark-common libpcap-dev rustc cargo; fi
if ! command -v go >/dev/null; then echo '[ERROR] Go not available'; exit 1; fi
mkdir -p "$HOME/go/bin"; export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"
# Tested against documented upstream module import paths; latest releases can require newer Go.
GO_TOOLS=(
'subfinder|github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest'
'dnsx|github.com/projectdiscovery/dnsx/cmd/dnsx@latest'
'httpx|github.com/projectdiscovery/httpx/cmd/httpx@latest'
'nuclei|github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest'
'katana|github.com/projectdiscovery/katana/cmd/katana@latest'
'naabu|github.com/projectdiscovery/naabu/v2/cmd/naabu@latest'
'assetfinder|github.com/tomnomnom/assetfinder@latest'
'waybackurls|github.com/tomnomnom/waybackurls@latest'
'anew|github.com/tomnomnom/anew@latest'
'gf|github.com/tomnomnom/gf@latest'
'httprobe|github.com/tomnomnom/httprobe@latest'
'ffuf|github.com/ffuf/ffuf/v2@latest'
'gau|github.com/lc/gau/v2/cmd/gau@latest'
'qsreplace|github.com/tomnomnom/qsreplace@latest'
'asnmap|github.com/projectdiscovery/asnmap/cmd/asnmap@latest'
'mapcidr|github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest'
'shuffledns|github.com/projectdiscovery/shuffledns/cmd/shuffledns@latest'
)
FULL_GO=(
'notify|github.com/projectdiscovery/notify/cmd/notify@latest'
'uncover|github.com/projectdiscovery/uncover/cmd/uncover@latest'
'chaos|github.com/projectdiscovery/chaos-client/cmd/chaos@latest'
'shosubgo|github.com/incogbyte/shosubgo@latest'
'gobuster|github.com/OJ/gobuster/v3@latest'
'unfurl|github.com/tomnomnom/unfurl@latest'
'hakrawler|github.com/hakluke/hakrawler@latest'
)
for item in "${GO_TOOLS[@]}"; do IFS='|' read -r name mod <<< "$item"; install_go "$name" "$mod"; done
if [[ "$PROFILE" == full ]]; then
 for item in "${FULL_GO[@]}"; do IFS='|' read -r name mod <<< "$item"; install_go "$name" "$mod"; done
 clone_repo LinkFinder https://github.com/GerbenJavado/LinkFinder.git
 clone_repo SecretFinder https://github.com/m4ll0k/SecretFinder.git
 clone_repo massdns https://github.com/blechschmidt/massdns.git
 if [[ -f "$PREFIX/massdns/Makefile" ]]; then (cd "$PREFIX/massdns" && make -j2) && cp "$PREFIX/massdns/bin/massdns" "$HOME/.local/bin/massdns" || failures+=(massdns); fi
 for tool in LinkFinder SecretFinder; do if [[ -f "$PREFIX/$tool/requirements.txt" ]]; then python3 -m venv "$PREFIX/$tool/.venv" && "$PREFIX/$tool/.venv/bin/pip" install -r "$PREFIX/$tool/requirements.txt" || failures+=("$tool:dependencies"); fi; done
 # distribution-maintained Amass avoids blindly running unverified scripts
 install_apt amass dirsearch
fi
# GF basic patterns; never overwrite user configurations.
if command -v gf >/dev/null 2>&1; then
 mkdir -p "$HOME/.gf"
 tmp="$(mktemp -d)"
 if git clone --depth 1 https://github.com/tomnomnom/gf.git "$tmp/gf"; then
  for f in "$tmp"/gf/examples/*.json; do [[ -e "$f" ]] && cp -n "$f" "$HOME/.gf/"; done
 else failures+=(gf-patterns); fi
 rm -rf "$tmp"
fi
PROFILE_FILE="$HOME/.profile"
LINE='export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"'
grep -Fqx "$LINE" "$PROFILE_FILE" 2>/dev/null || printf '\n%s\n' "$LINE" >> "$PROFILE_FILE"
echo; echo '===== Installation Summary ====='; echo "Log: $LOG"; echo "Successful Go tools: ${#successes[@]}"; echo "Failures: ${#failures[@]}"; for f in "${failures[@]}"; do echo "  FAILED: $f"; done
printf '%s\n' "${failures[@]}" > "$PREFIX/logs/last-failures.txt"
echo 'Run: source ~/.profile'; echo 'Check: bash verify.sh'; echo 'Configure API keys individually; none are embedded.'
if ((${#failures[@]})); then exit 1; fi
