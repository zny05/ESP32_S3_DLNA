# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

本仓库包含多个相关的ESP32固件项目：
- **`airplay-esp32/`** — ESP32 AirPlay 2接收器固件（主项目）
- **`SoapESP32/`** — 用于DLNA/UPnP媒体服务器发现的Arduino库
- **`components/`** — 共享组件和板级支持文件
- **`docs/`** — 文档和项目规划

airplay-esp32是主要开发目标，SoapESP32作为其DLNA媒体服务器发现功能所依赖的库。

## 多子项目协作开发

### 开发工作流程

当进行影响多个子项目的修改时：
1. **确定影响范围**：识别哪些子项目会受到修改影响
2. **更新依赖关系**：如果接口发生变化，修改 `platformio.ini` 或 CMakeLists.txt
3. **构建策略**：使用目标环境进行测试构建（`esp32s3`、`squeezeamp`等）
4. **跨子项目协调**：由于SoapESP32是airplay-esp32使用的库，因此对SoapESP32 API的修改需要对airplay-esp32进行更新

### 关键子项目依赖关系

- **airplay-esp32** → 使用 **SoapESP32** 库实现DLNA媒体服务器发现
- **components/** → 所有ESP32目标的共享组件
- **PlatformIO环境** 通过通用设置跨越多个子项目

## 构建与烧录命令

### airplay-esp32 (主项目)

**PlatformIO (推荐)：**
```bash
# 为特定环境构建固件
pio run -e esp32s3 -t build

# 构建并通过USB烧录
pio run -e esp32s3 -t upload

# 烧录SPIFFS文件系统（Web UI和数据）
pio run -e esp32s3 -t uploadfs

# 串口监控
pio run -e esp32s3 -t monitor

# 为不同板级构建
pio run -e squeezeamp -t build
pio run -e esparagus-audio-brick -t build
pio run -e esparagus-louder -t build
```

**ESP-IDF (原生)：**
```bash
# 设置目标并构建
idf.py set-target esp32s3
idf.py build

# 构建并烧录
idf.py -p /dev/ttyUSB0 flash

# 串口监控
idf.py -p /dev/ttyUSB0 monitor
```

### SoapESP32 (Arduino库)

**Arduino IDE/PlatformIO库开发：**
```bash
# 如果使用PlatformIO库模式，只需使用当前环境进行编译
pio run -e esp32s3 -t build

# 测试示例
pio run -e esp32s3 -t upload
pio run -e esp32s3 -t monitor
```

## 高层次代码架构

### airplay-esp32架构 (高层)

**主要应用组件：**
- `main/` — 核心应用（WiFi、AirPlay服务、音频管道）
- `components/` — 硬件抽象层和实用工具
- `data/` — Web UI和DSP二进制文件（SPIFFS挂载）

**关键子系统：**
1. **音频管道**：`audio/` → `AudioReceiver` → `decoder` → `AudioBuffer` → `AudioOutput`
2. **网络服务**：RTSP（AirPlay）、mDNS（服务发现）、Web配置
3. **硬件抽象**：DAC驱动器（TAS57xx/TAS58xx）、显示驱动器、按钮处理
4. **协议层**：UPnP/SoapESP32（依赖）、RTSP、家庭Kit（HAP）

### 构建环境策略

**PlatformIO配置管理：**
- 基础配置在 `platformio.ini` 中，包含12+个目标环境
- 通过 `sdkconfig.user.<name>` + `user_platformio.ini` 实现自定义板级配置，无需修改主配置
- Kconfig默认值从左到右覆盖 (`cmake_extra_args`)

**环境类型：**
- **esp32s3** — 默认S3板+PCM5102A DAC
- **squeezeamp** — ESP32+TAS5756 (8MB闪存)
- **esparagus-audio-brick** — ESP32+TAS5825M+以太网
- **esparagus-louder** — TAS5825M+额外增益

## 代码质量与约定

### 格式化与代码检查
```bash
# 为所有C/H文件应用格式化（排除u8g2子模块）
./scripts/format.sh

# 运行clang-tidy检查
./scripts/lint.sh

# 自动修复代码检查问题
./scripts/lint.sh --fix
```

### ESP-IDF要求
- **最低版本**：ESP-IDF >= 5.5
- **板级选择**：通过 `CONFIG_` Kconfig选项
- **DAC自动选择**：`CONFIG_DAC_TAS57XX` 或 `CONFIG_DAC_TAS58XX`

### 组件结构
- 每个 `components/*/CMakeLists.txt` 使用 `idf_component_register()`
- 板级HAL在 `components/boards/*/` 中
- 显示、按钮、蓝牙、以太网均通过Kconfig控制

### 音频管道约定
- **AAC**：使用带深抖动缓冲区的带缓冲流
- **ALAC**：使用低延迟UDP的实时流
- **共存性**：AirPlay和蓝牙在运行时互斥
- **定时**：基于PTP的早/晚帧处理

## 开发与测试

### 测试方法
由于这是没有单元测试框架的嵌入式固件：
- **需要进行手动硬件测试**
- **日志输出** (`CORE_DEBUG_LEVEL`)用于故障排除
- **Wireshark抓包**用于网络协议调试

### 常见开发任务

**添加新板级支持：**
1. 创建 `components/boards/<board_name>/` 目录
2. 添加 `CMakeLists.txt` 板级HAL
3. 创建 `sdkconfig.user.<board>` 进行GPIO引脚分配
4. 扩展 `user_platformio.ini` 进行构建环境配置

**添加音频输出：**
1. 在 `main/audio/` 中创建新的 `audio_output.<type>.c`
2. 实现标准的音频输出接口
3. 添加Kconfig选项进行启用 (`CONFIG_AUDIO_OUTPUT_TYPE`)
4. 更新 `dac.c` 分发层

**协议扩展：**
1. 在 `main/rtsp/rtsp_handlers.c` 中添加新的RTSP处理器
2. 在 `SoapESP32/` 中实现新的UPnP操作
3. 更新 `main/network/mdns_airplay.c` 中的mDNS服务广告

## 工具链设置

### PlatformIO设置
```bash
# 安装PlatformIO CLI
pip install platformio

# 克隆项目（带子模块）
git clone --recursive https://github.com/rbouteiller/airplay-esp32
cd airplay-esp32

# PlatformIO自动管理所有工具链依赖
```

### ESP-IDF设置
```bash
# 安装ESP-IDF v5.x
# 遵循：https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/

# 克隆带子模块的项目（需要u8g2图形库）
git clone --recursive https://github.com/rbouteiller/airplay-esp32
cd airplay-esp32

# 激活环境
source /path/to/esp-idf/export.sh

# 构建工作流程：设置目标 -> 构建 -> 烧录 -> 上传SPIFFS
idf.py set-target esp32s3
idf.py build
idf.py -p /dev/ttyUSB0 flash
```

## 需要记住的重要文件

- **`airplay-esp32/platformio.ini`** — 构建环境和配置
- **`airplay-esp32/sdkconfig.defaults.*`** — 板级Kconfig默认值
- **`SoapESP32/`** — DLNA/UPnP库依赖
- **`components/boards/`** — 每个板级的硬件抽象
- **`data/`** — SPIFFS文件系统内容（Web UI）
