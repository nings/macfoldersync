#!/bin/bash

PROJECT_DIR="/Users/Ning/Github/nings/Xcode/MacOS/FolderSyncPro"

echo "🔧 修复 Hashable 扩展问题"
echo "=========================="
echo ""

if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 错误: 项目目录不存在: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR" || exit 1

# 修复 SyncConfiguration.swift
echo "1️⃣  修复 SyncConfiguration.swift"

SYNC_CONFIG="FolderSyncPro/Models/SyncConfiguration.swift"

if [ -f "$SYNC_CONFIG" ]; then
    # 显示问题区域
    echo "   问题代码（第 155-158 行）:"
    sed -n '155,158p' "$SYNC_CONFIG" 2>/dev/null || echo "   （无法读取）"
    echo ""

    # 创建备份
    cp "$SYNC_CONFIG" "$SYNC_CONFIG.backup"
    echo "   ✅ 已创建备份: $SYNC_CONFIG.backup"

    # 删除包含 hash(into:) 和多余 } 的行
    # 同时删除整个 extension 块如果存在
    sed -i '' '/extension SyncConfiguration.*Hashable/,/^}$/d' "$SYNC_CONFIG"
    sed -i '' '/^[[:space:]]*func hash(into hasher:/,/^[[:space:]]*}$/d' "$SYNC_CONFIG"
    sed -i '' '/^[[:space:]]*static func ==/,/^[[:space:]]*}$/d' "$SYNC_CONFIG"

    # 删除多余的独立大括号
    sed -i '' '/^}$/d' "$SYNC_CONFIG"

    # 在文件末尾添加一个正确的结束大括号（如果需要）
    if ! tail -1 "$SYNC_CONFIG" | grep -q '^}$'; then
        echo "}" >> "$SYNC_CONFIG"
    fi

    echo "   ✅ 已修复"
else
    echo "   ❌ 文件不存在"
fi

echo ""

# 修复 SyncLog.swift
echo "2️⃣  修复 SyncLog.swift"

SYNC_LOG="FolderSyncPro/Models/SyncLog.swift"

if [ -f "$SYNC_LOG" ]; then
    # 显示问题区域
    echo "   问题代码（第 225 行）:"
    sed -n '225p' "$SYNC_LOG" 2>/dev/null || echo "   （无法读取）"
    echo ""

    # 创建备份
    cp "$SYNC_LOG" "$SYNC_LOG.backup"
    echo "   ✅ 已创建备份: $SYNC_LOG.backup"

    # 删除整个 extension 块
    sed -i '' '/extension SyncLog.*Hashable/,/^}$/d' "$SYNC_LOG"
    sed -i '' '/^[[:space:]]*func hash(into hasher:/,/^[[:space:]]*}$/d' "$SYNC_LOG"
    sed -i '' '/^[[:space:]]*static func ==/,/^[[:space:]]*}$/d' "$SYNC_LOG"

    # 删除多余的独立大括号
    sed -i '' '/^}$/d' "$SYNC_LOG"

    # 在文件末尾添加一个正确的结束大括号
    if ! tail -1 "$SYNC_LOG" | grep -q '^}$'; then
        echo "}" >> "$SYNC_LOG"
    fi

    echo "   ✅ 已修复"
else
    echo "   ❌ 文件不存在"
fi

echo ""
echo "✨ 修复完成！"
echo ""
echo "📋 下一步："
echo "   1. 在 Xcode 中重新加载文件（File → Reload）"
echo "   2. Clean Build (⌘ + Shift + K)"
echo "   3. Rebuild (⌘ + B)"
echo ""
echo "💾 备份文件位置："
echo "   - $SYNC_CONFIG.backup"
echo "   - $SYNC_LOG.backup"
echo ""
