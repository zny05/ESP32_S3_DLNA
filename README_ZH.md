# zny05/ESP32_S3_DLNA

[![GitHub stars](https://img.shields.io/github/stars/zy05/ESP32_S3_DLNA?style=flat-square)](https://github.com/zy05/ESP32_S3_DLNA)
[![GitHub forks](https://img.shields.io/github/forks/zy05/ESP32_S3_DLNA?style=flat-square)](https://github.com/zy05/ESP32_S3_DLNA)
[![License](https://img.shields.io/badge/License-Non-Commercial-blue?style=flat-square)](LICENSE)
[![ESP-IDF](https://img.shields.io/badge/ESP-IDF-v5.x-red?style=flat-square)](https://docs.espressif.com/projects/esp-idf/)
[![Platform](https://img.shields.io/badge/platform-ESP32-S3-green?style=flat-square)](https://www.espressif.com/en/products/socs/esp32-s3)
[![Build Status](https://img.shields.io/badge/build-passing-green?style=flat-square)](https://github.com/zy05/ESP32_S3_DLNA/actions)

# 🎛️ ESP32_S3_DLNA: 集成AirPlay & DLNA媒体中心

> **AirPlay 2和DLNA媒体服务器功能在单个ESP32-S3固件项目中的极客融合。**  
> *为什么要局限于只有一种流媒体协议，而不能同时拥有两种？*

---

## 🌐 这是什么？

欢迎来到 **zyn05/ESP32_S3_DLNA** – 一个专门构建的固件项目，它 **在ESP32-S3硬件上将AirPlay 2接收器功能与完整的DLNA媒体服务器发现和文件传输支持集成在一起**。

把它想象成音频流媒体的**瑞士军刀**：
- 🎧 **AirPlay 2** 为苹果设备提供无缝流媒体传输（ALAC/AAC）
- 🌐 **DLNA/UPnP** 用于发现和从网络上的任何媒体服务器流媒体传输
- 📡 **蓝牙A2DP** 用于无线手机流媒体传输
- 🌐 **W5500以太网** 用于有线网络流媒体传输（通过Esparagus Audio Brick）

所有功能集成在一个固件中，**零云依赖** 和 **无需专有应用程序**。只需插入、刷写，即可开始流媒体传输。

---

## 🧩 架构概览

### 🧱 核心组件

```
zyn05/ESP32_S3_DLNA/
├── airplay-esp32/          # 核心AirPlay 2接收器固件（已修改）
├── SoapESP32/              # DLNA/UPnP库（作为依赖集成）
├── components/             # 共享硬件抽象层
├── data/                   # SPIFFS文件系统用于网页UI & DSP配置
└── docs/                 # 电源计划和深度技术文档
```

### 🔗 集成点

1. **AirPlay核心** (`airplay-esp32/main/`)  
   - 核心音频管道，RTSP服务器，HAP（HomeKit），和UI
   - **已修改** 以将SoapESP32作为流媒体源进行集成

2. **SoapESP32** (`SoapESP32/`)  
   - Arduino库用于**网络发现**DLNA媒体服务器  
   - 提供 `seekServer()`, `browseServer()`, 和 `readStart()` APIs  
   - **直接集成** 到airplay-esp32的音频管道中

3. **音频管道**  
   ```
   音频接收器 (RTSP/SoapESP32) → 音频解码器 → 音频缓冲器 → 音频输出
   ```
   - AirPlay流（带缓冲） → 深度抖动缓冲区  
   - SoapESP32流（实时） → 低延迟UDP  
   - 两者在AudioBuffer中汇合以实现统一输出

### 🧩 集成架构

```
+-------------------+       +---------------------+
| airplay-esp32/    |       | SoapESP32/          |
| (主应用)          |       | (DLNA库)            |
|-------------------|       |---------------------|
| audio_receiver.c  |<----->| soapServer_t srv    |
| rtsp_handlers.c   |<----->| seekServer()/seekServer()|
| hap/              |       | browseServer()/readStart()|
+-------------------+       +---------------------+
         |                         |
         v                         v
+-------------------------------------------+
|       音频管道 (audio/)                 |
|  audio_receiver.c → 解码器 → 缓冲器 → 输出|
+-------------------------------------------+
```

### 🧩 关键集成点

- **SoapESP32作为音频源**：AirPlay接收器现在使用SoapESP32的`readStart()`从DLNA服务器拉取音频数据，将其视为流媒体源
- **共享网络栈**：AirPlay和SoapESP32都使用相同的WiFi/Ethernet栈通过`network/`组件
- **统一音频输出**：所有音频流（ALAC, AAC, DLNA）通过相同的`audio_output.c` I2S驱动程序汇合

---

## 🛠️ 构建 & 刷写

### PlatformIO (推荐)

```bash
# 安装PlatformIO CLI
pip install platformio

# 克隆带子模块（对于u8g2 & SoapESP32至关重要）
git clone --recursive https://github.com/zy05/ESP32_S3_DLNA
cd ESP32_S3_DLNA

# 为ESP32-S3 + PCM5102A DAC构建并刷写
pio run -e esp32s3 -t upload

# 对于SqueezeAMP板（TAS5756）
pio run -e squeezeamp-bt -t upload

# 对于Esparagus Audio Brick（TAS5825M + 以太网）
pio run -e esparagus-audio-brick-bt -t upload
```

### ESP-IDF 原生

```bash
# 安装ESP-IDF v5.5+（参见 https://docs.espressif.com/projects/esp-idf/en/latest/get-started/）
source /path/to/esp-idf/export.sh

# 构建并刷写
idf.py set-target esp32s3
idf.py build
idf.py -p /dev/ttyUSB0 flash
```

---

## 🔧 主要特性

| 特性 | 描述 |
|------|------|
| **AirPlay 2** | 原生苹果设备流媒体传输（ALAC/AAC），带深度抖动缓冲 |
| **DLNA/UPnP** | 完整的发现、浏览和从任何DLNA服务器下载文件 |
| **蓝牙A2DP** | 同时支持蓝牙流媒体传输 + AirPlay（互斥） |
| **以太网** | 基于W5500的网络流媒体传输（通过Esparagus Audio Brick） |
| **OTA更新** | 通过 captive portal 进行无线固件更新 |
| **OTA配置** | 通过网页UI进行设备名称、WiFi凭据和音量控制 |
| **OTA固件更新** | 通过网页界面进行无线固件更新 |

---

## ⚙️ 构建环境

| 环境 | 开发板 | DAC | 闪存 | 说明 |
|------|--------|-----|------|------|
| `esp32s3` | ESP32-S3 | PCM5102A | 16MB | 默认配置 |
| `squeezeamp` | ESP32 | TAS5756 | 8MB | 8MB闪存，TAS5756 DAC |
| `esparagus-audio-brick` | ESP32 | TAS5825M | 8MB | W5500以太网 + TAS5825M |
| `esparagus-louder` | ESP32 | TAS5825M | 8MB | 额外增益以获得更大音量 |
| `esparagus-audio-brick-s3` | ESP32-S3 | TAS5825M | 8MB | ESP32-S3 + TAS5825M |

> **注意**：`sdkconfig.defaults.*` 文件提供板级Kconfig默认值。自定义板级配置使用 `sdkconfig.user.<name>` + `user_platformio.ini`。

---

## 🛠️ 开发工作流

### 添加新板级支持

1. 创建 `components/boards/<board_name>/` 目录
2. 添加带板级特定HAL的 `CMakeLists.txt`
3. 创建带GPIO引脚映射的 `sdkconfig.user.<board>`
4. 扩展 `user_platformio.ini` 以进行构建环境配置
5. 测试音频输出和网络功能

### 添加新音频输出

1. 创建带标准接口的 `main/audio/audio_output.<type>.c`
2. 实现 `audio_output_init()`, `audio_output_process()`, `audio_output_deinit()`
3. 添加Kconfig选项：`CONFIG_AUDIO_OUTPUT_<TYPE>`
4. 更新 `dac.c` 以分发到新驱动程序

### 协议扩展

1. **AirPlay**：在 `main/rtsp/rtsp_handlers.c` 中添加RTSP处理器
2. **DLNA**：在 `SoapESP32/` 中实现新的UPnP操作
3. **mDNS**：更新 `main/network/mdns_airplay.c` 以支持新的服务类型

---

## 🛠️ 工具链设置

### PlatformIO (推荐)

```bash
# 安装PlatformIO CLI
pip install platformio

# 带子模块克隆项目（至关重要！）
git clone --recursive https://github.com/zy05/ESP32_S3_DLNA
cd ESP32_S3_DLNA

# PlatformIO自动管理所有工具链依赖
```

### ESP-IDF 设置

```bash
# 安装ESP-IDF v5.5+
# 按照: https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/

# 带子模块克隆（对于u8g2和SoapESP32是必需的）
git clone --recursive https://github.com/zy05/ESP32_S3_DLNA
cd ESP32_S3_DLNA

# 激活环境
source /path/to/esp-idf/export.sh

# 构建工作流程
idf.py set-target esp32s3
idf.py build
idf.py -p /dev/ttyUSB0 flash
```

---

## 🛡️ 代码质量与测试

- **格式化**：LLVM风格，2空格缩进，80字符限制（`.clang-format`）
- **代码检查**：使用`clang-tidy`进行bugprone、性能、可移植性检查
- **提交前钩子**：自动格式化 + clang-tidy（需要`build/compile_commands.json`）
- **CI流水线**：`.github/workflows/ci-release.yml` 运行格式化、代码检查、构建和发布

> **注意**：不存在单元测试 – 需要进行手动硬件测试。

---

## 🛠️ 开发工作流

### 🔄 日常开发周期

```bash
# 1. 构建固件
pio run -e esp32s3 -t build

# 2. 刷写固件
pio run -e esp32s3 -t upload

# 3. 监控日志进行调试
pio run -e esp32s3 -t monitor

# 4. 如果需要，刷写SPIFFS（网页UI + 数据）
pio run -e esp32s3 -t uploadfs
```

### 🛠️ 常见任务

| 任务 | 命令 |
|------|------|
| 格式化代码 | `./scripts/format.sh` |
| 运行代码检查 | `./scripts/lint.sh` |
| 自动修复代码检查问题 | `./scripts/lint.sh --fix` |
| 查看构建日志 | `pio run -e esp32s3 -t monitor` |
| 刷写SPIFFS | `pio run -e esp32s3 -t uploadfs` |

---

## 📂 重要文件

- **`airplay-esp32/platformio.ini`** – 构建环境和配置
- **`airplay-esp32/sdkconfig.defaults.*`** – 板级Kconfig默认值
- **`SoapESP32/library.json`** – 库元数据和依赖关系
- **`components/boards/`** – 板级特定HAL实现
- **`data/`** – SPIFFS内容（网页UI，DSP配置）
- **`scripts/`** – 格式化和代码检查工具

---

## 📡 开始使用（首次启动）

1. 通过USB-C为ESP32供电
2. 连接到 `ESP32-AirPlay-Setup` WiFi网络
3. 在浏览器中打开 captive portal (192.168.4.1)
4. 设置设备名称、WiFi凭据和音量
5. 重启 – 设备连接到家庭WiFi
6. 在AirPlay或DLNA应用中选择设备

> **热插拔**：如果WiFi连接失败超过3次，设备会自动返回设置模式。

---

## 🔄 OTA固件更新

1. 构建新固件（`pio run` 或 `idf.py build`）
2. 通过路由器或 `arp -a` 查找设备IP
3. 打开设备网页界面（例如 `http://192.168.1.100`）
4. 使用固件上传页面刷写新版本

---

## 📚 文档与资源

- **主要文档**：`airplay-esp32/CLAUDE.md`
- **SoapESP32示例**：[github.com/yellobyte/soapESP32/examples](https://github.com/yellobyte/soapESP32/blob/main/examples)
- **硬件组装**：`docs/PCM5102A.png`, `docs/ESP_PCM_front.png`
- **路线图**：`docs/superpowers/plans/2026-05-08-airplay-v1-v2-quality-roadmap.md`

---

## 📜 许可证

本项目采用 **非商业许可证** – 请参阅 `LICENSE` 文件了解详情。

---

*由zny05出于对ESP32社区的热爱而制作。可能含有咖啡、焊锡渣和纯粹工程乐趣的痕迹。*