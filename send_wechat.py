#!/usr/bin/env python3
"""
send_wechat.py - 通过 Server酱 推送微信通知
用法: python send_wechat.py <date> <summary> <sp500_val> <sp500_chg> <nasdaq_val> <nasdaq_chg> <vix_val> <has_alert>

示例:
python send_wechat.py 2026-07-03 "非农冷风+芯片雪崩" "7,496" "+0.18%" "~25,650" "-1.5%" "18.10" "WDC暴跌约10%"
"""
import sys
import urllib.request
import urllib.parse

SENDKEY = "SCT373627TRedIoaI8bV6GYTNSDeKR4V0v"

def send(date, summary, sp500_val, sp500_chg, nasdaq_val, nasdaq_chg, vix_val, has_alert):
    title = f"Zoe每日果园 {date}"
    desp = f"""今日摘要：{summary}

S&P 500: {sp500_val} ({sp500_chg})
Nasdaq: {nasdaq_val} ({nasdaq_chg})
VIX: {vix_val}

完整日报：https://Yiz777.github.io/StockDaily/{date}.html

持仓提醒：{has_alert}"""

    data = urllib.parse.urlencode({
        'title': title,
        'desp': desp
    }).encode('utf-8')

    req = urllib.request.Request(
        f'https://sctapi.ftqq.com/{SENDKEY}.send',
        data=data
    )
    resp = urllib.request.urlopen(req)
    result = resp.read().decode('utf-8')
    print(f"WeChat push: {result}")
    return result

if __name__ == '__main__':
    if len(sys.argv) < 8:
        print("Usage: python send_wechat.py <date> <summary> <sp500_val> <sp500_chg> <nasdaq_val> <nasdaq_chg> <vix_val> <has_alert>")
        sys.exit(1)
    send(*sys.argv[1:9])
