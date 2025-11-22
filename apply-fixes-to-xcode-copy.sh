#!/bin/bash

PROJECT_DIR="/Users/Ning/Github/nings/Xcode/MacOS/FolderSyncPro"

echo "🔧 FolderSync Pro - 自动修复脚本"
echo "=================================="
echo "目标路径: $PROJECT_DIR"
echo ""

# 检查目录是否存在
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 错误: 项目目录不存在"
    echo "   请确认路径: $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR" || exit 1

# 备份提醒
echo "⚠️  建议先备份项目！"
read -p "是否继续？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

echo ""
echo "🔧 开始应用修复..."
echo ""

# 1. 修复 SyncLog.swift - 删除手动 Hashable 扩展
echo "1️⃣  检查 SyncLog.swift"
if [ -f "FolderSyncPro/Models/SyncLog.swift" ]; then
    if grep -q "extension SyncLog.*Hashable" FolderSyncPro/Models/SyncLog.swift; then
        # 使用 perl 进行多行删除（更可靠）
        perl -i -pe 'BEGIN{undef $/;} s/\n+\/\/ MARK: - Hashable.*?extension SyncLog.*?\{[^}]*\}//smg' FolderSyncPro/Models/SyncLog.swift
        perl -i -pe 'BEGIN{undef $/;} s/\nextension SyncLog:\s*Hashable.*?\{[^}]*\}//smg' FolderSyncPro/Models/SyncLog.swift
        echo "   ✅ 已删除 Hashable 扩展"
    else
        echo "   ✓ 无需修改（已正确）"
    fi
else
    echo "   ⚠️  文件不存在"
fi

# 2. 修复 SyncConfiguration.swift - 删除手动 Hashable 扩展
echo "2️⃣  检查 SyncConfiguration.swift"
if [ -f "FolderSyncPro/Models/SyncConfiguration.swift" ]; then
    if grep -q "extension SyncConfiguration.*Hashable" FolderSyncPro/Models/SyncConfiguration.swift; then
        perl -i -pe 'BEGIN{undef $/;} s/\n+\/\/ MARK: - Hashable.*?extension SyncConfiguration.*?\{[^}]*\}//smg' FolderSyncPro/Models/SyncConfiguration.swift
        perl -i -pe 'BEGIN{undef $/;} s/\nextension SyncConfiguration:\s*Hashable.*?\{[^}]*\}//smg' FolderSyncPro/Models/SyncConfiguration.swift
        echo "   ✅ 已删除 Hashable 扩展"
    else
        echo "   ✓ 无需修改（已正确）"
    fi
else
    echo "   ⚠️  文件不存在"
fi

# 3. 修复 ConflictResolver.swift
echo "3️⃣  检查 ConflictResolver.swift"
if [ -f "FolderSyncPro/Services/ConflictResolver.swift" ]; then
    # 修复 Combine 导入
    if grep -q "^import Combine$" FolderSyncPro/Services/ConflictResolver.swift; then
        sed -i '' 's/^import Combine$/@preconcurrency import Combine/' FolderSyncPro/Services/ConflictResolver.swift
        echo "   ✅ 已修复 Combine 导入"
    else
        echo "   ✓ Combine 导入已正确"
    fi

    # 修复 LogManager 参数
    if grep -q "logManager: LogManager = \.shared" FolderSyncPro/Services/ConflictResolver.swift; then
        sed -i '' 's/logManager: LogManager = \.shared/logManager: LogManager? = nil/' FolderSyncPro/Services/ConflictResolver.swift
        sed -i '' 's/self\.logManager = logManager$/self.logManager = logManager ?? LogManager.shared/' FolderSyncPro/Services/ConflictResolver.swift
        echo "   ✅ 已修复 LogManager 参数"
    else
        echo "   ✓ LogManager 参数已正确"
    fi
else
    echo "   ⚠️  文件不存在"
fi

# 4. 修复 SyncEngine.swift
echo "4️⃣  检查 SyncEngine.swift"
if [ -f "FolderSyncPro/Services/SyncEngine.swift" ]; then
    # 修复 Combine 导入
    if grep -q "^import Combine$" FolderSyncPro/Services/SyncEngine.swift; then
        sed -i '' 's/^import Combine$/@preconcurrency import Combine/' FolderSyncPro/Services/SyncEngine.swift
        echo "   ✅ 已修复 Combine 导入"
    else
        echo "   ✓ Combine 导入已正确"
    fi

    # 修复 LogManager 参数
    if grep -q "logManager: LogManager = \.shared" FolderSyncPro/Services/SyncEngine.swift; then
        sed -i '' 's/logManager: LogManager = \.shared/logManager: LogManager? = nil/' FolderSyncPro/Services/SyncEngine.swift
        echo "   ✅ 已修复 LogManager 参数"
    else
        echo "   ✓ LogManager 参数已正确"
    fi

    # 修复 logManager.info() 调用
    if grep -q "logManager\.info(" FolderSyncPro/Services/SyncEngine.swift; then
        # 这个需要手动修复，因为参数结构复杂
        echo "   ⚠️  需要手动修复: 将 logManager.info() 改为 logManager.log()"
        echo "      参考 MANUAL_FIX_PATCH.md 第 4 节的修改 3"
    fi
else
    echo "   ⚠️  文件不存在"
fi

# 5. 修复 FileMonitor.swift
echo "5️⃣  检查 FileMonitor.swift"
if [ -f "FolderSyncPro/Services/FileMonitor.swift" ]; then
    if grep -q "^import Combine$" FolderSyncPro/Services/FileMonitor.swift; then
        sed -i '' 's/^import Combine$/@preconcurrency import Combine/' FolderSyncPro/Services/FileMonitor.swift
        echo "   ✅ 已修复 Combine 导入"
    else
        echo "   ✓ Combine 导入已正确"
    fi
else
    echo "   ⚠️  文件不存在"
fi

# 6. 修复 LogManager.swift
echo "6️⃣  检查 LogManager.swift"
if [ -f "FolderSyncPro/Services/LogManager.swift" ]; then
    if grep -q "^import Combine$" FolderSyncPro/Services/LogManager.swift; then
        sed -i '' 's/^import Combine$/@preconcurrency import Combine/' FolderSyncPro/Services/LogManager.swift
        echo "   ✅ 已修复 Combine 导入"
    else
        echo "   ✓ Combine 导入已正确"
    fi
else
    echo "   ⚠️  文件不存在"
fi

# 7. 修复 PreferencesView.swift
echo "7️⃣  检查 PreferencesView.swift"
if [ -f "FolderSyncPro/Views/PreferencesView.swift" ]; then
    if ! grep -q "import UniformTypeIdentifiers" FolderSyncPro/Views/PreferencesView.swift; then
        sed -i '' '/^import SwiftUI$/a\
import UniformTypeIdentifiers
' FolderSyncPro/Views/PreferencesView.swift
        echo "   ✅ 已添加 UniformTypeIdentifiers 导入"
    else
        echo "   ✓ UniformTypeIdentifiers 已导入"
    fi
else
    echo "   ⚠️  文件不存在"
fi

# 8. 创建 AccentColor
echo "8️⃣  检查 AccentColor.colorset"
ACCENT_DIR="FolderSyncPro/Resources/Assets.xcassets/AccentColor.colorset"
ACCENT_JSON="$ACCENT_DIR/Contents.json"

if [ ! -f "$ACCENT_JSON" ]; then
    mkdir -p "$ACCENT_DIR"
    cat > "$ACCENT_JSON" <<'EOF'
{
  "colors" : [
    {
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
    echo "   ✅ 已创建 AccentColor.colorset"
else
    echo "   ✓ AccentColor 已存在"
fi

echo ""
echo "✨ 修复完成！"
echo ""

# 验证修复
echo "🔍 验证修复..."
echo ""

ERRORS=0

# 检查 Combine 导入
if grep -l "^import Combine$" FolderSyncPro/Services/*.swift 2>/dev/null | grep -v "^$" > /dev/null; then
    echo "⚠️  警告: 仍有文件使用普通 'import Combine'（应为 '@preconcurrency import Combine'）"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ 所有 Services 文件都正确使用 @preconcurrency import Combine"
fi

# 检查 Hashable 扩展
if grep -l "extension Sync.*Hashable" FolderSyncPro/Models/*.swift 2>/dev/null | grep -v "^$" > /dev/null; then
    echo "⚠️  警告: Models 中仍有手动 Hashable 扩展"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Models 中没有手动 Hashable 扩展"
fi

# 检查 UniformTypeIdentifiers
if grep -q "import UniformTypeIdentifiers" FolderSyncPro/Views/PreferencesView.swift 2>/dev/null; then
    echo "✅ PreferencesView 已导入 UniformTypeIdentifiers"
else
    echo "⚠️  警告: PreferencesView 缺少 UniformTypeIdentifiers 导入"
    ERRORS=$((ERRORS + 1))
fi

# 检查 AccentColor
if [ -f "$ACCENT_JSON" ]; then
    echo "✅ AccentColor.colorset 存在"
else
    echo "⚠️  警告: AccentColor.colorset 缺失"
    ERRORS=$((ERRORS + 1))
fi

echo ""

if [ $ERRORS -eq 0 ]; then
    echo "🎉 所有修复都已正确应用！"
else
    echo "⚠️  发现 $ERRORS 个问题，请查看 MANUAL_FIX_PATCH.md 手动修复"
fi

echo ""
echo "📋 下一步："
echo "   1. 关闭 Xcode (⌘ + Q)"
echo "   2. 清理缓存:"
echo "      rm -rf ~/Library/Developer/Xcode/DerivedData/FolderSyncPro-*"
echo "   3. 重新打开 Xcode:"
echo "      cd $PROJECT_DIR"
echo "      open FolderSyncPro.xcodeproj"
echo "   4. Clean Build (⌘ + Shift + K)"
echo "   5. Rebuild (⌘ + B)"
echo ""
