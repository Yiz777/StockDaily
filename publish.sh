#!/bin/sh
# 兼容入口：实际发布逻辑在 Windows 原生 publish.ps1 中。
# 用法与旧版一致：publish.sh <date> <summary> <sp500> <sp500_chg> <nasdaq> <nasdaq_chg> <vix> <alert>

SCRIPT_DIR=${0%/*}
[ "$SCRIPT_DIR" = "$0" ] && SCRIPT_DIR=.

exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_DIR/publish.ps1" \
  -Date "$1" \
  -Summary "$2" \
  -Sp500Value "$3" \
  -Sp500Change "$4" \
  -NasdaqValue "$5" \
  -NasdaqChange "$6" \
  -VixValue "$7" \
  -Alert "$8"
