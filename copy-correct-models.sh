#!/bin/bash

SOURCE_DIR="/Users/Ning/Github/nings/macfoldersync"
TARGET_DIR="/Users/Ning/Github/nings/Xcode/MacOS/FolderSyncPro"

echo "🔧 复制正确的 Model 文件"
echo "========================"
echo ""
echo "源目录: $SOURCE_DIR"
echo "目标目录: $TARGET_DIR"
echo ""

# 检查目录
if [ ! -d "$SOURCE_DIR" ]; then
    echo "❌ 错误: 源目录不存在"
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "❌ 错误: 目标目录不存在"
    exit 1
fi

# 确认操作
echo "⚠️  这将覆盖以下文件:"
echo "   - $TARGET_DIR/FolderSyncPro/Models/SyncConfiguration.swift"
echo "   - $TARGET_DIR/FolderSyncPro/Models/SyncLog.swift"
echo ""
read -p "是否继续？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

echo ""

# 创建备份
echo "📦 创建备份..."
BACKUP_DIR="$TARGET_DIR/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ -f "$TARGET_DIR/FolderSyncPro/Models/SyncConfiguration.swift" ]; then
    cp "$TARGET_DIR/FolderSyncPro/Models/SyncConfiguration.swift" "$BACKUP_DIR/"
    echo "   ✅ 已备份 SyncConfiguration.swift"
fi

if [ -f "$TARGET_DIR/FolderSyncPro/Models/SyncLog.swift" ]; then
    cp "$TARGET_DIR/FolderSyncPro/Models/SyncLog.swift" "$BACKUP_DIR/"
    echo "   ✅ 已备份 SyncLog.swift"
fi

echo ""

# 复制正确的文件
echo "📋 复制正确的文件..."

if [ -f "$SOURCE_DIR/FolderSyncPro/FolderSyncPro/Models/SyncConfiguration.swift" ]; then
    cp "$SOURCE_DIR/FolderSyncPro/FolderSyncPro/Models/SyncConfiguration.swift" \
       "$TARGET_DIR/FolderSyncPro/Models/"
    echo "   ✅ 已复制 SyncConfiguration.swift"
else
    echo "   ❌ 源文件不存在: SyncConfiguration.swift"
fi

if [ -f "$SOURCE_DIR/FolderSyncPro/FolderSyncPro/Models/SyncLog.swift" ]; then
    cp "$SOURCE_DIR/FolderSyncPro/FolderSyncPro/Models/SyncLog.swift" \
       "$TARGET_DIR/FolderSyncPro/Models/"
    echo "   ✅ 已复制 SyncLog.swift"
else
    echo "   ❌ 源文件不存在: SyncLog.swift"
fi

echo ""
echo "✨ 完成！"
echo ""
echo "💾 备份位置: $BACKUP_DIR"
echo ""
echo "🔍 验证文件..."

# 验证文件
ERRORS=0

# 检查 SyncConfiguration.swift
if grep -q "extension SyncConfiguration.*Hashable" "$TARGET_DIR/FolderSyncPro/Models/SyncConfiguration.swift" 2>/dev/null; then
    echo "   ⚠️  SyncConfiguration.swift 仍包含 Hashable 扩展"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✅ SyncConfiguration.swift 正确（无 Hashable 扩展）"
fi

# 检查 SyncLog.swift
if grep -q "extension SyncLog.*Hashable" "$TARGET_DIR/FolderSyncPro/Models/SyncLog.swift" 2>/dev/null; then
    echo "   ⚠️  SyncLog.swift 仍包含 Hashable 扩展"
    ERRORS=$((ERRORS + 1))
else
    echo "   ✅ SyncLog.swift 正确（无 Hashable 扩展）"
fi

# 检查文件结尾
if tail -1 "$TARGET_DIR/FolderSyncPro/Models/SyncConfiguration.swift" | grep -q '^}$'; then
    echo "   ✅ SyncConfiguration.swift 正确结尾"
else
    echo "   ⚠️  SyncConfiguration.swift 结尾异常"
    ERRORS=$((ERRORS + 1))
fi

if tail -1 "$TARGET_DIR/FolderSyncPro/Models/SyncLog.swift" | grep -q '^}$'; then
    echo "   ✅ SyncLog.swift 正确结尾"
else
    echo "   ⚠️  SyncLog.swift 结尾异常"
    ERRORS=$((ERRORS + 1))
fi

echo ""

if [ $ERRORS -eq 0 ]; then
    echo "🎉 所有文件都正确！"
else
    echo "⚠️  发现 $ERRORS 个问题"
fi

echo ""
echo "📋 下一步："
echo "   1. 在 Xcode 中重新加载文件（File → Reload）或重启 Xcode"
echo "   2. Clean Build (⌘ + Shift + K)"
echo "   3. Rebuild (⌘ + B)"
echo ""
