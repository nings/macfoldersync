#!/bin/bash

# FolderSync Pro - Xcode 项目自动设置脚本
#
# 使用方法：
#   chmod +x setup-xcode-project.sh
#   ./setup-xcode-project.sh

set -e  # 遇到错误立即退出

echo "🚀 FolderSync Pro - Xcode 项目设置"
echo "=================================="
echo ""

# 检查 Xcode 是否安装
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ 错误: 未找到 Xcode"
    echo "请先安装 Xcode: https://developer.apple.com/xcode/"
    exit 1
fi

echo "✅ 检测到 Xcode: $(xcodebuild -version | head -n 1)"
echo ""

# 项目信息
PROJECT_NAME="FolderSyncPro"
BUNDLE_ID="com.foldersyncpro.FolderSyncPro"
SOURCE_DIR="$(pwd)/FolderSyncPro/FolderSyncPro"

# 检查源代码是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ 错误: 找不到源代码目录: $SOURCE_DIR"
    exit 1
fi

echo "📁 源代码目录: $SOURCE_DIR"
echo ""

# 提示用户
echo "⚠️  重要提示："
echo "   由于 Xcode 项目文件格式复杂，此脚本将指导您手动创建项目。"
echo ""
echo "请按照以下步骤操作："
echo ""
echo "1️⃣  打开 Xcode"
echo "2️⃣  创建新项目: File → New → Project"
echo "3️⃣  选择: macOS → App"
echo "4️⃣  配置信息:"
echo "     - Product Name: FolderSyncPro"
echo "     - Interface: SwiftUI"
echo "     - Language: Swift"
echo "     - Storage: SwiftData"
echo ""
echo "5️⃣  保存到临时位置（不要保存在当前目录）"
echo ""
echo "6️⃣  删除默认文件:"
echo "     - FolderSyncProApp.swift"
echo "     - ContentView.swift"
echo "     - Item.swift"
echo ""
echo "7️⃣  将以下文件夹拖入 Xcode:"
echo "     - App/"
echo "     - Models/"
echo "     - Services/"
echo "     - Utils/"
echo "     - Views/"
echo ""
echo "     勾选: ✅ Copy items if needed"
echo "     勾选: ✅ Create groups"
echo ""
echo "8️⃣  替换 Entitlements 文件"
echo ""
echo "9️⃣  构建项目: ⌘ + B"
echo "🔟 运行应用: ⌘ + R"
echo ""

# 询问是否打开源代码目录
read -p "📂 是否在 Finder 中打开源代码目录？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$SOURCE_DIR"
    echo "✅ 已打开源代码目录"
fi

echo ""
echo "📖 详细设置指南: XCODE_SETUP_GUIDE.md"
echo ""
echo "✨ 准备就绪！请按照上述步骤在 Xcode 中设置项目。"
