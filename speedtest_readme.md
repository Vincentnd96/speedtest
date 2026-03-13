# 🚀 Kernel-Level Network Speed Auditor

A high-precision Bash utility designed to measure true network throughput on Linux systems by querying hardware statistics directly.

## 🛠 Why This Script?

Standard speed test tools often suffer from "CLI Lag" or "Disk Bottlenecks." This script is engineered specifically for **Gigabit (1000 Mbps)** environments using three specialist techniques:

### 1. Kernel-Level Monitoring
Instead of trusting the application layer (curl) to report its own speed, this script queries the Linux kernel's network statistics:
* **Receive:** `/sys/class/net/[intf]/statistics/rx_bytes`
* **Transmit:** `/sys/class/net/[intf]/statistics/tx_bytes`

This captures **every bit** that crosses the wire, including protocol headers and TCP overhead, providing the most accurate representation of line-speed usage.

### 2. Zero Disk I/O Bottlenecks
Traditional scripts write data to the drive, which can throttle results on slower SSDs or HDDs. 
* **Downloads** are piped directly to `/dev/null`.
* **Uploads** are read from `/dev/shm` (Linux RAM-disk), ensuring data is served at the speed of your memory, not your disk.

### 3. Multi-Stream Saturation
A single TCP connection often cannot fill a 1Gbps pipe due to latency and TCP window scaling. This script spawns:
* **10 Parallel Download Streams** via Google's high-capacity mirrors.
* **6 Parallel Upload Streams** via Cloudflare's edge network.

## 📊 The Math

The script calculates speed using nanosecond-precision timing and the absolute delta of bytes transferred:

$$Throughput (Mbps) = \frac{(\Delta Bytes \times 8)}{Duration (seconds) \times 1,000,000}$$

## 🚀 Usage

### Prerequisites
* **Linux OS** (Required for sysfs access)
* **Dependencies:** `curl`, `bc`, `awk`

### Execution
1.  **Grant Permissions:**
    ```bash
    chmod +x speedtest.sh
    ```
2.  **Run the Test:**
    ```bash
    ./speedtest.sh
    ```

## 🔍 Result Interpretation

| Metric | Expectation |
| :--- | :--- |
| **Interface** | Shows the negotiated hardware link (should be 1000 Mbps). |
| **Download** | 800-940 Mbps is optimal for a Gigabit line (allowing for overhead). |
| **Upload** | Varies by ISP (Fiber: ~900 Mbps | Cable: ~35-50 Mbps). |

## 🛡 Safety & Cleanup
* **Cleanup Trap:** Automatically kills all background processes and removes temporary RAM payloads if interrupted (`CTRL+C`).
* **Stealth Mode:** Uses browser-mimicking User-Agents and Referer headers to avoid being blocked by CDN firewalls.

---
*Created by the Network Specialist & Intern Team.*
