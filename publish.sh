#!/bin/bash
# publish.sh - 一键发布日报: Git push + 微信推送
# 用法: bash publish.sh <date> <summary> <sp500_val> <sp500_chg> <nasdaq_val> <nasdaq_chg> <vix_val> <has_alert>
#
# 示例:
# bash publish.sh 2026-07-03 "非农冷风+芯片雪崩" "7,496" "+0.18%" "~25,650" "-1.5%" "18.10" "WDC暴跌约10%"

set -e

NEWSLETTER_DIR="C:/Users/zhao.zoe/Desktop/上海赫贤学校/0. Newsletter"
PYTHON="C:/Users/zhao.zoe/.workbuddy/binaries/python/versions/3.13.12/python.exe"

DATE=$1
SUMMARY=$2
SP500_VAL=$3
SP500_CHG=$4
NASDAQ_VAL=$5
NASDAQ_CHG=$6
VIX_VAL=$7
HAS_ALERT=$8

cd "$NEWSLETTER_DIR"

echo "=== Step 1: Git commit + push ==="
git add .
git commit -m "每日更新：$DATE" || echo "Nothing to commit"
# 关键: 用 -c credential.helper= 绕过 Windows GCM 卡死问题
git -c credential.helper= push origin main
echo "Git push done."

echo ""
echo "=== Step 2: WeChat push ==="
"$PYTHON" "$NEWSLETTER_DIR/send_wechat.py" "$DATE" "$SUMMARY" "$SP500_VAL" "$SP500_CHG" "$NASDAQ_VAL" "$NASDAQ_CHG" "$VIX_VAL" "$HAS_ALERT"
echo "WeChat push done."

echo ""
echo "=== All done ==="
echo "日报地址: https://Yiz777.github.io/StockDaily/$DATE.html"
