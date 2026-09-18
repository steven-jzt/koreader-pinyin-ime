#!/bin/sh
# KOReader 手机式拼音输入法 安装脚本
# 用法: ./install.sh /path/to/koreader
# 例如: ./install.sh /mnt/us/koreader   （Kindle 挂载的 KOReader 目录）

set -e

KOREADER_DIR="${1:-}"

if [ -z "$KOREADER_DIR" ]; then
    echo "用法: $0 /path/to/koreader"
    echo "例如: $0 /mnt/us/koreader"
    exit 1
fi

if [ ! -d "$KOREADER_DIR/frontend" ]; then
    echo "错误: $KOREADER_DIR 不是 KOReader 目录（找不到 frontend/）"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$KOREADER_DIR/.pinyin-ime-backup-$TIMESTAMP"

echo "=== KOReader 手机式拼音输入法 安装 ==="
echo "KOReader 目录: $KOREADER_DIR"
echo "备份目录:     $BACKUP_DIR"
echo

# 1. 备份要覆盖的文件
mkdir -p "$BACKUP_DIR"
for f in \
    "frontend/ui/data/keyboardlayouts/zh_CN_keyboard.lua" \
    "frontend/ui/widget/virtualkeyboard.lua"; do
    if [ -f "$KOREADER_DIR/$f" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$f")"
        cp "$KOREADER_DIR/$f" "$BACKUP_DIR/$f"
        echo "已备份: $f"
    fi
done
echo

# 2. 复制新文件
cp "$SCRIPT_DIR/frontend/ui/data/keyboardlayouts/phone_ime.lua" \
   "$KOREADER_DIR/frontend/ui/data/keyboardlayouts/phone_ime.lua"
cp "$SCRIPT_DIR/frontend/ui/data/keyboardlayouts/zh_CN_keyboard.lua" \
   "$KOREADER_DIR/frontend/ui/data/keyboardlayouts/zh_CN_keyboard.lua"
cp "$SCRIPT_DIR/frontend/ui/widget/virtualkeyboard.lua" \
   "$KOREADER_DIR/frontend/ui/widget/virtualkeyboard.lua"
echo "已安装: phone_ime.lua / zh_CN_keyboard.lua / virtualkeyboard.lua"
echo

echo "=== 安装完成 ==="
echo "重启 KOReader 后，在「设置 → 设备 → 键盘 → 键盘布局」启用中文(zh)，用地球键切换到中文键盘即可。"
echo "如需还原，用备份目录 $BACKUP_DIR 覆盖回原文件即可。"
