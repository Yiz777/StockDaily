#!/bin/bash
# publish.sh - 一键发布日报: 自我修复 + 同步 + 归档 + Git push + 微信推送
# 用法: bash publish.sh <date> <summary> <sp500_val> <sp500_chg> <nasdaq_val> <nasdaq_chg> <vix_val> <has_alert>
#
# ⚠️⚠️⚠️ 此文件是唯一权威版本，存放在 0. Newsletter/ (Git仓库)。
# ⚠️⚠️⚠️ Claw/publish.sh 是此文件的副本，可能被自动化AI覆盖。
# ⚠️⚠️⚠️ 自动化任务必须用绝对路径调用此文件：bash "C:/Users/zhao.zoe/Desktop/上海赫贤学校/0. Newsletter/publish.sh"
#
# 示例:
# bash publish.sh 2026-07-14 "美伊冲突升级" "7,515" "-0.79%" "25,873" "-1.55%" "16.5" "WDC跌超4%"

# ⚠️ 不使用 set -e — 确保微信推送在任何情况下都能执行

CLAW_DIR="C:/Users/zhao.zoe/Desktop/上海赫贤学校/Claw"
NEWSLETTER_DIR="C:/Users/zhao.zoe/Desktop/上海赫贤学校/0. Newsletter"
PYTHON="C:/Users/zhao.zoe/.workbuddy/binaries/python/versions/3.13.12/python.exe"
MAIN_ARCHIVE="$NEWSLETTER_DIR/归档/投资理财"

DATE=$1
SUMMARY=$2
SP500_VAL=$3
SP500_CHG=$4
NASDAQ_VAL=$5
NASDAQ_CHG=$6
VIX_VAL=$7
HAS_ALERT=$8

echo "=========================================="
echo "  美股日报发布流程 · $DATE"
echo "=========================================="
echo ""

# Step 0: 自我修复 — 从 0. Newsletter 恢复关键文件到 Claw
# 这一步确保即使 AI 覆盖了 Claw 中的文件，下次运行也能恢复
echo "=== Step 0: 自我修复（恢复关键文件）==="
cp "$NEWSLETTER_DIR/daily-reference.md" "$CLAW_DIR/daily-reference.md" 2>/dev/null && echo "  daily-reference.md 已恢复" || true
cp "$NEWSLETTER_DIR/html2md.py" "$CLAW_DIR/html2md.py" 2>/dev/null && echo "  html2md.py 已恢复" || true
cp "$NEWSLETTER_DIR/send_wechat.py" "$CLAW_DIR/send_wechat.py" 2>/dev/null && echo "  send_wechat.py 已恢复" || true
cp "$NEWSLETTER_DIR/prompt-v4.md" "$CLAW_DIR/prompt-v4.md" 2>/dev/null && echo "  prompt-v4.md 已恢复" || true
# template.html 只在 Claw 中存在，复制到 0. Newsletter 备份
cp "$CLAW_DIR/template.html" "$NEWSLETTER_DIR/template.html" 2>/dev/null || true
# template.html 如果 Claw 中不存在，从 0. Newsletter 恢复
cp "$NEWSLETTER_DIR/template.html" "$CLAW_DIR/template.html" 2>/dev/null || true
echo ""

# Step 1: 从 Claw 同步生成的文件到 Git 仓库目录（Obsidian vault）
echo "=== Step 1: 同步文件到发布目录 ==="
HTML_SRC="$CLAW_DIR/0. Newsletter/${DATE}.html"
MD_SRC="$CLAW_DIR/0. Newsletter/${DATE}.md"

if [ ! -f "$HTML_SRC" ]; then
    echo "  ⚠️ HTML文件不存在: $HTML_SRC"
    echo "  尝试从 Claw 根目录查找..."
    HTML_SRC="$CLAW_DIR/${DATE}.html"
    MD_SRC="$CLAW_DIR/${DATE}.md"
fi

if [ ! -f "$HTML_SRC" ]; then
    echo "  ❌ 找不到今天的 HTML 文件，发布中止"
    exit 1
fi

cp "$HTML_SRC" "$NEWSLETTER_DIR/"
echo "  HTML 已复制: $(basename "$HTML_SRC")"

if [ -f "$MD_SRC" ]; then
    cp "$MD_SRC" "$NEWSLETTER_DIR/"
    echo "  MD 已复制: $(basename "$MD_SRC")"
else
    echo "  MD 不存在，跳过（稍后用 html2md.py 生成）"
fi

# 同步 index.html 和 watchlist.md
for src in "$CLAW_DIR/0. Newsletter/index.html" "$CLAW_DIR/index.html"; do
    [ -f "$src" ] && cp "$src" "$NEWSLETTER_DIR/index.html" 2>/dev/null && echo "  index.html 已同步" && break
done
for src in "$CLAW_DIR/0. Newsletter/watchlist.md" "$CLAW_DIR/watchlist.md"; do
    [ -f "$src" ] && cp "$src" "$NEWSLETTER_DIR/watchlist.md" 2>/dev/null && echo "  watchlist.md 已同步" && break
done

# 同步 Claw 归档目录中的文件
for SRC in "$CLAW_DIR/归档/投资理财" "$CLAW_DIR/0. Newsletter/归档/投资理财"; do
    if [ -d "$SRC" ]; then
        count=0
        for f in "$SRC"/*.md "$SRC"/*.html; do
            if [ -f "$f" ]; then
                cp "$f" "$MAIN_ARCHIVE/" 2>/dev/null && count=$((count + 1))
            fi
        done
        [ $count -gt 0 ] && echo "  归档目录同步了 $count 个文件"
    fi
done
echo ""

# Step 2: 如果 MD 不存在，用 html2md.py 生成
if [ ! -f "$NEWSLETTER_DIR/${DATE}.md" ]; then
    echo "=== Step 2: 生成 MD ==="
    "$PYTHON" "$NEWSLETTER_DIR/html2md.py" "$NEWSLETTER_DIR/${DATE}.html" 2>/dev/null && echo "  MD 已生成" || echo "  ⚠️ MD 生成失败，继续..."
    echo ""
fi

# Step 3: 归档旧日报（主目录中只保留今天的）
echo "=== Step 3: 归档旧日报 ==="
for f in "$NEWSLETTER_DIR"/2026-*.md "$NEWSLETTER_DIR"/2026-*.html; do
    [ -f "$f" ] || continue
    fname=$(basename "$f")
    [ "$fname" = "${DATE}.md" ] && continue
    [ "$fname" = "${DATE}.html" ] && continue
    mv "$f" "$MAIN_ARCHIVE/" 2>/dev/null && echo "  归档: $fname"
done
echo ""

# Step 4: Git commit + push（失败不中断后续步骤）
cd "$NEWSLETTER_DIR"
echo "=== Step 4: Git commit + push ==="
git add .
git commit -m "每日更新：$DATE" 2>/dev/null && echo "  Git commit done" || echo "  Nothing to commit"
git -c credential.helper= push origin main 2>/dev/null && echo "  Git push done ✓" || echo "  ⚠️ Git push failed (可能网络问题)，继续微信推送..."
echo ""

# Step 5: 微信推送（无论如何都执行）
echo "=== Step 5: 微信推送 ==="
"$PYTHON" "$NEWSLETTER_DIR/send_wechat.py" "$DATE" "$SUMMARY" "$SP500_VAL" "$SP500_CHG" "$NASDAQ_VAL" "$NASDAQ_CHG" "$VIX_VAL" "$HAS_ALERT" 2>/dev/null && echo "  微信推送 done ✓" || echo "  ⚠️ 微信推送失败"
echo ""

echo "=========================================="
echo "  发布完成 · $DATE"
echo "  日报地址: https://Yiz777.github.io/StockDaily/$DATE.html"
echo "=========================================="
