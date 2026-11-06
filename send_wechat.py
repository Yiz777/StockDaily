#!/usr/bin/env python3
"""
send_wechat.py - 通过 Server酱 推送微信通知
用法: python send_wechat.py <date> <summary> <sp500_val> <sp500_chg> <nasdaq_val> <nasdaq_chg> <vix_val> <has_alert>

示例:
python send_wechat.py 2026-07-03 "非农冷风+芯片雪崩" "7,496" "+0.18%" "~25,650" "-1.5%" "18.10" "WDC暴跌约10%"
"""
import sys
import json
import re
from pathlib import Path
from datetime import date as calendar_date
import urllib.request
import urllib.parse

SENDKEY = "SCT373627TRedIoaI8bV6GYTNSDeKR4V0v"

def send(date, summary, sp500_val, sp500_chg, nasdaq_val, nasdaq_chg, vix_val, has_alert, report_url=None):
    report_path = Path(__file__).with_name(f"{date}.md")
    report = report_path.read_text(encoding="utf-8-sig")
    report_date = calendar_date.fromisoformat(date)
    chinese_date = f"{report_date.year}年{report_date.month}月{report_date.day}日"
    if not any(label in report[:500] for label in (date, chinese_date)):
        raise ValueError("日报正文日期与推送日期不一致，停止发送")
    report = re.sub(r"</?small>", "", report)
    reading_url = ("网页入口暂不可用；请在Codex中查看本地当日日报。" if report_url == "inline"
                   else report_url or f"https://github.com/Yiz777/StockDaily/blob/main/{date}.md")
    title = f"Zoe每日果园 {date}"
    desp = f"""今日摘要：{summary}

S&P 500: {sp500_val} ({sp500_chg})
Nasdaq: {nasdaq_val} ({nasdaq_chg})
VIX: {vix_val}

完整日报：{reading_url}

持仓提醒：{has_alert}"""

    data = urllib.parse.urlencode({
        'title': title,
        'desp': desp
    }).encode('utf-8')

    req = urllib.request.Request(
        f'https://sctapi.ftqq.com/{SENDKEY}.send',
        data=data
    )
    resp = urllib.request.urlopen(req, timeout=30)
    result = resp.read().decode('utf-8')
    status = json.loads(result)
    if status.get("code") != 0 or status.get("data", {}).get("errno", 0) != 0:
        raise RuntimeError(f"微信通知未被服务端接受：{status.get('message', 'unknown error')}")
    print("WeChat push: SUCCESS (summary and reading link)")
    return result

if __name__ == '__main__':
    if len(sys.argv) < 9:
        print("Usage: python send_wechat.py <date> <summary> <sp500_val> <sp500_chg> <nasdaq_val> <nasdaq_chg> <vix_val> <has_alert>")
        sys.exit(1)
    send(*sys.argv[1:10])
