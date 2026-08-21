#!/bin/bash
# 初始化新的ESP32项目时执行的默认脚本

echo "🔧 初始化ESP32项目默认配置..."

# 检查是否已经存在必要的文件
if [ ! -f "CLAUDE.md" ]; then
    echo "📝 创建CLAUDE.md文件..."
    cat > CLAUDE.md << 'EOF'
# CLAUDE.md

本项目为ESP32固件开发提供指导。

## 常用命令

### 构建和烧录
```bash
# 使用PlatformIO构建和烧录
pio run -e <环境名称> -t upload

# 使用ESP-IDF构建和烧录
idf.py build
idf.py -p /dev/ttyUSB0 flash
```

### 开发工具链
```bash
# 安装PlatformIO
pip install platformio

# 克隆项目（带子模块）
git clone --recursive https://github.com/username/project
```

## 项目结构
- `main/` — 主应用代码
- `components/` — 组件库
- `data/` — Web UI和DSP二进制文件
- `docs/` — 文档

## 开发约定
- 使用PlatformIO进行开发
- 遵循ESP-IDF编码规范
- 进行手动硬件测试
EOF
    echo "✅ CLAUDE.md文件创建完成"
fi

if [ ! -f ".gitignore" ]; then
    echo "📝 创建.gitignore文件..."
    cat > .gitignore << 'EOF'
# 编译文件和构建产物
*.o
*.elf
*.bin
*.map
*.hex
*.gdb
build*
output*

# PlatformIO特定文件
.pio/
.pioenvs/
.piolibdeps/
.piotasks/

# IDE文件
.vscode/
.idea/

# 环境变量文件
.env*
*.key
*.pem
*.crt
EOF
    echo "✅ .gitignore文件创建完成"
fi

echo "🎉 初始化完成！项目已配置好开发环境。"

# 根据项目类型创建特定配置
if [ -f "platformio.ini" ]; then
    echo "📋 检测到PlatformIO项目，应用ESP32特定配置..."
    echo "# ESP32项目特定设置" >> platformio.ini
    echo "# 此文件由初始化脚本自动生成" >> platformio.ini
fi

echo "🚀 项目初始化完成，随时可以开始开发！"
