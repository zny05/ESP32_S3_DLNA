# zny05/ESP32_S3_DLNA

[![GitHub stars](https://img.shields.io/github/stars/zy05/ESP32_S3_DLNA?style=flat-square)](https://github.com/zy05/ESP32_S3_DLNA)
[![GitHub forks](https://img.shields.io/github/forks/zy05/ESP32_S3_DLNA?style=flat-square)](https://github.com/zy05/ESP32_S3_DLNA)
[![License](https://img.shields.io/badge/License-Non-Commercial-blue?style=flat-square)](LICENSE)
[![ESP-IDF](https://img.shields.io/badge/ESP-IDF-v5.x-red?style=flat-square)](https://docs.espressif.com/projects/esp-idf/)
[![Platform](https://img.shields.io/badge/platform-ESP32-S3-green?style=flat-square)](https://www.espressif.com/en/products/socs/esp32-s3)
[![Build Status](https://img.shields.io/badge/build-passing-green?style=flat-square)](https://github.com/zy05/ESP32_S3_DLNA/actions)

# 🎛️ ESP32_S3_DLNA: Integrated AirPlay & DLNA Media Hub

> **A geeky fusion of AirPlay 2 and DLNA media server capabilities in a single ESP32-S3 firmware project.**  
> *Because why limit yourself to just one streaming protocol when you can have both?*

---

## 🌐 What is this?

Welcome to **zyn05/ESP32_S3_DLNA** – a purpose-built firmware project that **integrates AirPlay 2 receiver capabilities with full DLNA media server discovery and file transfer support** on ESP32-S3 hardware. 

Think of it as the **Swiss Army knife of audio streaming**:  
- 🎧 **AirPlay 2** for seamless Apple device streaming (ALAC/AAC)  
- 🌐 **DLNA/UPnP** for discovering and streaming from any media server on your network  
- 📡 **Bluetooth A2DP** for wireless phone streaming  
- 🌐 **W5500 Ethernet** for wired network streaming (via Esparagus Audio Brick)  

All in one firmware, with **zero cloud dependency** and **no proprietary app required**. Just plug in, flash, and start streaming.

---

## 🧩 Architecture Overview

### 🧱 Core Components

```
zyn05/ESP32_S3_DLNA/
├── airplay-esp32/          # Core AirPlay 2 receiver firmware (modified)
├── SoapESP32/              # DLNA/UPnP library (integrated as dependency)
├── components/             # Shared hardware abstraction layer
├── data/                   # SPIFFS filesystem for web UI & DSP configs
└── docs/                 # Power plans and deep technical docs
```

### 🔗 Integration Points

1. **AirPlay Core** (`airplay-esp32/main/`)  
   - Core audio pipeline, RTSP server, HAP (HomeKit), and UI
   - **Modified** to integrate SoapESP32 as a streaming source

2. **SoapESP32** (`SoapESP32/`)  
   - Arduino library for **network discovery** of DLNA media servers  
   - Provides `seekServer()`, `browseServer()`, and `readStart()` APIs  
   - **Integrated directly** into airplay-esp32's audio pipeline

3. **Audio Pipeline**  
   ```
   AudioReceiver (RTSP/SoapESP32) → Audio Decoder → AudioBuffer → AudioOutput
   ```
   - AirPlay streams (buffered) → deep jitter buffer  
   - SoapESP32 streams (real-time) → low-latency UDP  
   - Both converge at AudioBuffer for unified output

### 🧩 Integration Architecture

```
+-------------------+       +---------------------+
| airplay-esp32/    |       | SoapESP32/          |
| (main app)        |       | (DLNA library)      |
|-------------------|       |---------------------|
| audio_receiver.c  |<----->| soapServer_t srv    |
| rtsp_handlers.c   |<----->| seekServer()/seekServer()|
| hap/              |       | browseServer()/readStart()|
+-------------------+       +---------------------+
         |                         |
         v                         v
+-------------------------------------------+
|       Audio Pipeline (audio/)           |
|  audio_receiver.c → decoder → buffer → output|
+-------------------------------------------+
```

### 🧩 Key Integration Points

- **SoapESP32 as Audio Source**: The AirPlay receiver now uses SoapESP32's `readStart()` to pull audio data from DLNA servers, treating it as a stream source
- **Shared Network Stack**: Both AirPlay and SoapESP32 use the same WiFi/Ethernet stack via `network/` components
- **Unified Audio Output**: All audio streams (ALAC, AAC, DLNA) funnel through the same `audio_output.c` I2S driver

---

## 🛠️ Build & Flash

### PlatformIO (Recommended)

```bash
# Install PlatformIO CLI
pip install platformio

# Clone with submodules (critical for u8g2 & SoapESP32)
git clone --recursive https://github.com/zy05/ESP32_S3_DLNA
cd ESP32_S3_DLNA

# Build and flash for ESP32-S3 + PCM5102A DAC
pio run -e esp32s3 -t upload

# For SqueezeAMP boards (TAS5756)
pio run -e squeezeamp-bt -t upload

# For Esparagus Audio Brick (TAS5825M + Ethernet)
pio run -e esparagus-audio-brick-bt -t upload
```

### ESP-IDF Native

```bash
# Install ESP-IDF v5.5+ (see https://docs.espressif.com/projects/esp-idf/en/latest/get-started/)
source /path/to/esp-idf/export.sh

# Build and flash
idf.py set-target esp32s3
idf.py build
idf.py -p /dev/ttyUSB0 flash
```

---

## 🔧 Key Features

| Feature | Description |
|---------|-------------|
| **AirPlay 2** | Native Apple device streaming (ALAC/AAC) with deep jitter buffering |
| **DLNA/UPnP** | Full discovery, browsing, and file download from any DLNA server |
| **Bluetooth A2DP** | Simultaneous BT streaming + AirPlay (mutually exclusive) |
| **Ethernet** | W5500-based network streaming (Esparagus Audio Brick) |
| **OTA Updates** | Wireless firmware updates via captive portal |
| **OTA Config** | Web UI for device name, WiFi credentials, volume control |
| **OTA Firmware Updates** | OTA firmware updates via web interface |

---

## ⚙️ Build Environments

| Environment | Board | DAC | Flash | Notes |
|-------------|-------|-----|-------|-------|
| `esp32s3` | ESP32-S3 | PCM5102A | 16MB | Default configuration |
| `squeezeamp` | ESP32 | TAS5756 | 8MB | 8MB flash, TAS5756 DAC |
| `esparagus-audio-brick` | ESP32 | TAS5825M | 8MB | W5500 Ethernet + TAS5825M |
| `esparagus-louder` | ESP32 | TAS5825M | 8MB | Extra gain for louder output |
| `esparagus-audio-brick-s3` | ESP32-S3 | TAS5825M | 8MB | ESP32-S3 + TAS5825M |

> **Note**: `sdkconfig.defaults.*` files provide board-specific Kconfig defaults. Custom board configs use `sdkconfig.user.<name>` + `user_platformio.ini`.

---

## 🛠️ Development Workflow

### Adding New Board Support

1. Create `components/boards/<board_name>/` directory
2. Add `CMakeLists.txt` with board-specific HAL
3. Create `sdkconfig.user.<board>` with GPIO pin mappings
4. Extend `user_platformio.ini` for build environment
5. Test audio output and network functionality

### Adding New Audio Output

1. Create `main/audio/audio_output.<type>.c` with standard interface
2. Implement `audio_output_init()`, `audio_output_process()`, `audio_output_deinit()`
3. Add Kconfig option: `CONFIG_AUDIO_OUTPUT_<TYPE>`
4. Update `dac.c` to dispatch to new driver

### Protocol Extensions

1. **AirPlay**: Add RTSP handlers in `main/rtsp/rtsp_handlers.c`
2. **DLNA**: Implement new UPnP actions in `SoapESP32/`  
3. **mDNS**: Update `main/network/mdns_airplay.c` for new service types

## 🛠️ Toolchain Setup

### PlatformIO (Recommended)

```bash
# Install PlatformIO CLI
pip install platformio

# Clone project with submodules (critical!)
git clone --recursive https://github.com/zy05/ESP32_S3_DLNA
cd ESP32_S3_DLNA

# PlatformIO auto-manages all toolchain dependencies
```

### ESP-IDF Setup

```bash
# Install ESP-IDF v5.5+
# Follow: https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/

# Clone with submodules (required for u8g2 and SoapESP32)
git clone --recursive https://github.com/zy05/ESP32_S3_DLNA
cd ESP32_S3_DLNA

# Activate environment
source /path/to/esp-idf/export.sh

# Build workflow
idf.py set-target esp32s3
idf.py build
idf.py -p /dev/ttyUSB0 flash
```

## 🛡️ Code Quality & Testing

- **Formatting**: LLVM-style, 2-space indent, 80-char limit (`.clang-format`)
- **Linting**: `clang-tidy` with bugprone, performance, portability checks
- **Pre-commit hook**: auto-format + clang-tidy (requires `build/compile_commands.json`)
- **CI Pipeline**: `.github/workflows/ci-release.yml` runs format, lint, build, and release

> **Note**: No unit tests exist – manual hardware testing required.

---

## 🛠️ Development Workflow

### 🔄 Daily Development Cycle

```bash
# 1. Build firmware
pio run -e esp32s3 -t build

# 2. Flash firmware
pio run -e esp32s3 -t upload

# 3. Monitor logs for debugging
pio run -e esp32s3 -t monitor

# 4. If needed, flash SPIFFS (web UI + data)
pio run -e esp32s3 -t uploadfs
```

### 🛠️ Common Tasks

| Task | Command |
|------|---------|
| Format code | `./scripts/format.sh` |
| Run linting | `./scripts/lint.sh` |
| Auto-fix lint issues | `./scripts/lint.sh --fix` |
| View build logs | `pio run -e esp32s3 -t monitor` |
| Flash SPIFFS | `pio run -e esp32s3 -t uploadfs` |

---

## 📂 Important Files

- **`airplay-esp32/platformio.ini`** – Build environments and config
- **`airplay-esp32/sdkconfig.defaults.*`** – Board Kconfig defaults
- **`SoapESP32/library.json`** – Library metadata and dependencies
- **`components/boards/`** – Board-specific HAL implementations
- **`data/`** – SPIFFS contents (web UI, DSP configs)
- **`scripts/`** – Formatting and linting tools

---

## 📡 Getting Started (First Boot)

1. Power ESP32 via USB-C  
2. Connect to `ESP32-AirPlay-Setup` WiFi network  
3. Open captive portal (192.168.4.1) in browser  
4. Set device name, WiFi credentials, and volume  
5. Reboot – device connects to home WiFi  
6. Select device in AirPlay or DLNA app  

> **Hot-swap**: If WiFi fails after 3 attempts, device auto-returns to setup mode.

---

## 🔄 OTA Firmware Updates

1. Build new firmware (`pio run` or `idf.py build`)  
2. Find device IP via router or `arp -a`  
3. Open device web interface (e.g., `http://192.168.1.100`)  
4. Use firmware upload page to flash new version  

---

## 📚 Documentation & Resources

- **Main Docs**: `airplay-esp32/CLAUDE.md`  
- **SoapESP32 Examples**: [github.com/yellobyte/soapESP32/examples](https://github.com/yellobyte/soapESP32/blob/main/examples)  
- **Hardware Assembly**: `docs/PCM5102A.png`, `docs/ESP_PCM_front.png`  
- **Roadmap**: `docs/superpowers/plans/2026-05-08-airplay-v1-v2-quality-roadmap.md`

---

## 📜 License

This project is licensed under the **Non-Commercial License** – see `LICENSE` file for details.

---

*Made with ❤️ by zny05 for the ESP32 community. May contain traces of coffee, solder flux, and pure engineering joy.*