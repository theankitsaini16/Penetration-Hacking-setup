# Bug Bounty Bootstrap

Portable **installation-only** environment bootstrap for Debian, Ubuntu and Kali Linux. Inventory is based on the connected Notion `Methodology(2.0)` root and the `RECON (1)`, `gf tool extra extension (1)`, `Shodan (1)`, and `Nuclei` pages. **Not every linked subpage was audited**, and not every named item is an executable (some are websites or conceptual techniques).

## Quick start

Download the repository containing `install.sh` and `verify.sh`, review their source, then:

```bash
chmod +x install.sh verify.sh
./install.sh --profile core --yes
source ~/.profile
./verify.sh
```

For wider coverage:

```bash
./install.sh --profile full --yes
```

Re-run failed or outdated packages with `./install.sh --profile full --update --yes`. The script continues after individual installation failures and exits nonzero if any fail; inspect `~/bugbounty-tools/logs/last-failures.txt`.

**Do not run a script downloaded from the internet as root without reviewing it.** Use a normal user with sudo privilege. Some tools need newer Go than your OS repositories provide; see <https://go.dev/doc/install>. Go's `@latest` uses upstream versions, not pinned releases. For reproducible team/VPS images, pin and review revisions before deployment.

## Inventory and origins

| Category | Tools | Install strategy |
| --- | --- | --- |
| Passive/domain | subfinder, assetfinder | Official Go modules |
| DNS | dnsx, shuffledns | ProjectDiscovery Go modules; `massdns` built in full profile |
| HTTP / crawl | httpx, httprobe, katana | Official Go modules |
| URL collection / transforms | gau, waybackurls, anew, gf, qsreplace | Official Go modules |
| Content discovery | ffuf | Official Go module |
| Vulnerability testing | nuclei, sqlmap | Go module / apt |
| Network/OSINT | naabu, asnmap, mapcidr, nmap, masscan, whois, dnsutils | Go / apt |
| Web inspection | whatweb, nikto, dirb | apt |
| Full additional Go tools | notify, uncover, chaos, shosubgo, gobuster, unfurl, hakrawler | Go modules |
| Full additional apt | amass, dirsearch, tcpdump | apt |
| Full JS helpers | LinkFinder, SecretFinder | GitHub clones + isolated Python virtualenvs |
| Full DNS helper | massdns | Official GitHub build |

Useful official references:
- <https://projectdiscovery.io/open-source>
- <https://github.com/projectdiscovery>
- <https://github.com/tomnomnom>
- <https://github.com/ffuf/ffuf>
- <https://github.com/lc/gau>
- <https://github.com/owasp-amass/amass>
- <https://github.com/GerbenJavado/LinkFinder>
- <https://github.com/m4ll0k/SecretFinder>
- <https://github.com/blechschmidt/massdns>

## Additional items referenced in Notion

`rustscan`, `aquatone`, `fff`, `meg`, `wappalyzer`, `findomain`, `crtsh`, `wireshark`, `iperf`, and various GF community pattern packs are referenced but **not all automatically installed**. Their versions, packaging, licensing, or repository maintenance need separate checks before being added. Web resources such as Censys, VirusTotal, Shodan, SecurityTrails, crt.sh, Wayback CDX and Google Dorks are not shell binaries.

## API configuration

API keys are **never required by this installer**, and it stores none. Individual tools require source-specific credentials; use their official documentation to create accounts and configure keys. For example, Subfinder supports source provider configuration (`subfinder -h`), Shodan's CLI uses `shodan init`, and ReconForge can use `SHODAN_API_KEY`. Do not paste tokens into Git, hardcode them in shell history, or publish `.env` files. Use `chmod 600` on local secrets.

## Notes and limitations

- The installer **installs tools only**: it does not run target scans, brute force endpoints, or invoke Nuclei templates.
- `httpx` (ProjectDiscovery) may be named `httpx-toolkit` on some Kali installations. This installer places the Go binary in `~/go/bin/httpx`.
- Go installs may update toolchains automatically and can fail on low-memory VPS machines; check logs.
- Amass is obtained from Debian-family packages, which may be older than upstream. To diagnose strange wrapper behavior use `type -a amass`.
- Python helpers live at `~/bugbounty-tools/LinkFinder` and `.../SecretFinder`, each with its own virtual environment.
- `gf` only receives upstream example patterns if the local names do not already exist. Additional community patterns are not automatically downloaded.
- Default tools are installed for the current OS user. If you use root and a non-root account, their Go binaries/configs differ.
- Work only on explicitly authorized bug bounty scope, respecting rate limits and program rules.
