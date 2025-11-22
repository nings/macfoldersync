#!/bin/bash

echo "🔧 FolderSync Pro - Xcode 缓存清理"
echo "=================================="
echo ""

# 1. 关闭 Xcode
echo "1️⃣  关闭 Xcode..."
killall Xcode 2>/dev/null || true
sleep 2

# 2. 拉取最新代码
echo "2️⃣  拉取最新代码..."
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

git pull origin claude/implement-project-modules-012sRvPv9iPjabTbBa1qLYRB

# 3. 删除缓存
echo "3️⃣  删除 Derived Data 缓存..."
rm -rf ~/Library/Developer/Xcode/DerivedData/FolderSyncPro-*

echo "4️⃣  删除 Swift 缓存..."
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/org.swift.swiftpm

# 4. 清理项目文件
echo "5️⃣  清理项目临时文件..."
find . -name ".DS_Store" -delete 2>/dev/null || true
find . -name "*.xcuserstate" -delete 2>/dev/null || true
find . -type d -name "xcuserdata" -exec rm -rf {} + 2>/dev/null || true

echo ""
echo "✅ 清理完成！"
echo ""
echo "🔍 验证关键修复..."
echo ""

# 验证修复
echo "检查 1: SyncConfiguration.swift (不应该有手动 Hashable 扩展)"
if grep -q "extension SyncConfiguration.*Hashable" FolderSyncPro/FolderSyncPro/Models/SyncConfiguration.swift 2>/dev/null; then
    echo "   ⚠️  警告: 仍然包含手动 Hashable 扩展"
else
    echo "   ✅ 正确: 已移除手动 Hashable 扩展"
fi

echo ""
echo "检查 2: SyncEngine.swift (应该使用可选参数)"
if grep -q "logManager: LogManager?" FolderSyncPro/FolderSyncPro/Services/SyncEngine.swift 2>/dev/null; then
    echo "   ✅ 正确: 使用可选参数"
else
    echo "   ⚠️  警告: 未找到可选参数"
fi

echo ""
echo "检查 3: AccentColor.colorset"
if [ -f "FolderSyncPro/FolderSyncPro/Resources/Assets.xcassets/AccentColor.colorset/Contents.json" ]; then
    echo "   ✅ 正确: AccentColor 存在"
else
    echo "   ⚠️  警告: AccentColor 缺失"
fi

echo ""
echo "检查 4: Combine 导入"
if grep -q "import Combine" FolderSyncPro/FolderSyncPro/Services/ConflictResolver.swift 2>/dev/null; then
    echo "   ✅ 正确: ConflictResolver 包含 Combine 导入"
else
    echo "   ⚠️  警告: ConflictResolver 缺少 Combine 导入"
fi

echo ""
echo "📋 Git 状态："
echo "   当前分支: $(git branch --show-current)"
echo "   最新提交: $(git log -1 --oneline)"
echo ""

echo "📋 下一步："
echo "   1. Xcode 将会自动打开"
echo "   2. 在 Xcode 中按 ⌘ + Shift + K 清理构建"
echo "   3. 按 ⌘ + B 重新构建"
echo "   4. 检查是否还有错误"
echo ""

# 询问是否打开 Xcode
read -p "🚀 是否现在打开 Xcode？(y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "正在打开 Xcode..."
    open FolderSyncPro/FolderSyncPro.xcodeproj
    echo ""
    echo "⏳ 等待 Xcode 打开后："
    echo "   1. 按 ⌘ + Shift + K (Clean Build Folder)"
    echo "   2. 按 ⌘ + B (Build)"
else
    echo ""
    echo "稍后手动打开 Xcode："
    echo "   open FolderSyncPro/FolderSyncPro.xcodeproj"
fi

echo ""
echo "✨ 完成！"
