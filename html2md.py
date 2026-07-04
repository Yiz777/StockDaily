#!/usr/bin/env python3
"""
html2md.py - 把 Zoe 每日果园 HTML 日报转成 Markdown
用法: python html2md.py 2026-07-03.html
输出: 同目录下生成 2026-07-03.md

原理: HTML 结构固定(同一套CSS模板), 用针对性正则提取各板块内容
"""
import sys
import re


def extract_text(html, pattern, group=1, default=''):
    m = re.search(pattern, html, re.DOTALL)
    return m.group(group).strip() if m else default


def strip_tags(text):
    """去除HTML标签, 保留纯文本"""
    text = re.sub(r'<br\s*/?>', '  \n', text)
    text = re.sub(r'</?(strong|b)>', '**', text)
    text = re.sub(r'<[^>]+>', '', text)
    text = re.sub(r'\s+', ' ', text)
    return text.strip()


def convert(html_path):
    with open(html_path, 'r', encoding='utf-8') as f:
        html = f.read()

    lines = []
    BASE = 'C:\\Users\\zhao.zoe\\Desktop\\上海赫贤学校\\0. Newsletter\\'

    # Header
    date_text = extract_text(html, r'<div class="date">(.*?)</div>')
    badges = re.findall(r'<span class="badge"[^>]*>(.*?)</span>', html, re.DOTALL)
    badge_str = ' · '.join(strip_tags(b) for b in badges)
    lines.append(f'# 🍉 Zoe的每日果园')
    lines.append(f'')
    lines.append(f'> {date_text}')
    if badge_str:
        lines.append(f'> {badge_str}')
    lines.append('')

    # 今日一句话
    oneliner = extract_text(html, r'<div class="text">(.*?)</div>')
    if oneliner:
        lines.append('## 🍓 今日一句话')
        lines.append(f'> {strip_tags(oneliner)}')
        lines.append('')

    # 市场温度计 - 解析卡片
    cards = re.findall(
        r'<div class="card"[^>]*>.*?<div class="emoji">(.*?)</div>.*?<div class="name">(.*?)</div>.*?<div class="price">(.*?)</div>.*?<div class="change[^"]*">(.*?)</div>.*?<div class="note">(.*?)</div>',
        html, re.DOTALL
    )
    if cards:
        lines.append('## 🌡️ 市场温度计')
        lines.append('| 指标 | 数值 | 涨跌 | 备注 |')
        lines.append('|---|---|---|---|')
        for emoji, name, price, change, note in cards:
            e = strip_tags(emoji)
            n = strip_tags(name)
            p = strip_tags(price)
            c = strip_tags(change)
            nt = strip_tags(note)
            lines.append(f'| {e} {n} | {p} | {c} | {nt} |')
        lines.append('')

    # 持仓预警
    alert = extract_text(html, r'<div class="alert-box">(.*?)</div>\s*(?:<!--|$|<div class="section)', default='')
    if alert:
        alert_clean = strip_tags(alert)
        lines.append('## ⚠️ 持仓预警')
        lines.append(f'> {alert_clean}')
        lines.append('')

    # 新闻翻译官
    translate_items = re.findall(
        r'<div class="translate-item">(.*?)</div>\s*(?=<div class="translate-item|</div>\s*<!--)',
        html, re.DOTALL
    )
    if translate_items:
        lines.append('## 🔤 新闻翻译官')
        for item in translate_items:
            tag = extract_text(item, r'<span class="tag[^"]*">(.*?)</span>')
            original = extract_text(item, r'<div class="original">(.*?)</div>')
            simple = extract_text(item, r'<div class="simple">(.*?)</div>')
            impact = extract_text(item, r'<div class="impact">(.*?)</div>')
            lines.append(f'### {strip_tags(tag)} {strip_tags(original)}')
            lines.append(f'💬 {strip_tags(simple)}')
            if impact:
                lines.append(f'→ {strip_tags(impact)}')
            lines.append('')

    # 持仓速览
    bag_items = re.findall(
        r'<div class="bag-item"[^>]*>.*?<span class="icon">(.*?)</span>.*?<span class="n">(.*?)</span>.*?<span class="d">(.*?)</span>.*?<div class="v">(.*?)</div>.*?<div class="p[^"]*">(.*?)</div>',
        html, re.DOTALL
    )
    if bag_items:
        title = extract_text(html, r'<div class="title">(.*?)</div>')
        lines.append('## 👜 持仓速览')
        if title:
            lines.append(f'*{strip_tags(title)}*')
        lines.append('')
        lines.append('| 持仓 | 名称 | 今日 | 心情 |')
        lines.append('|---|---|---|---|')
        for icon, code, desc, price, pct in bag_items:
            lines.append(f'| {strip_tags(icon)} {strip_tags(code)} | {strip_tags(desc)} | {strip_tags(price)} {strip_tags(pct)} | |')
        lines.append('')

    # 今日建议
    advice_text = extract_text(html, r'<div class="text">(.*?)</div>\s*<div class="sub">', default='')
    if advice_text:
        advice_full = extract_text(html, r'<div class="advice">(.*?)</div>\s*</div>\s*</div>', default='')
        if not advice_full:
            advice_full = extract_text(html, r'<div class="advice">(.*?)</div>', default='')
        lines.append('## 🧘 今日建议')
        lines.append(f'🧘‍♀️ {strip_tags(advice_text)}')
        # 提取理由
        reasons = re.findall(r'<br>\s*(1️⃣|2️⃣|3️⃣|4️⃣)(.*?)(?:<br>|$)', advice_full, re.DOTALL)
        if reasons:
            lines.append('')
            for num, reason in reasons:
                lines.append(f'{num} {strip_tags(reason)}')
        lines.append('')

    # 机会雷达
    opp_text = extract_text(html, r'<div class="opportunity-box">(.*?)</div>\s*</div>\s*</div>', default='')
    if not opp_text:
        opp_text = extract_text(html, r'<div class="opportunity-box">(.*?)</div>', default='')
    if opp_text:
        lines.append('## 🔭 机会雷达')
        opp_clean = strip_tags(opp_text)
        lines.append(opp_clean)
        lines.append('')

    # 每日一词
    term_text = extract_text(html, r'<div class="term-box">(.*?)</div>\s*</div>\s*</div>', default='')
    if not term_text:
        term_text = extract_text(html, r'<div class="term-box">(.*?)</div>', default='')
    if term_text:
        lines.append('## 📖 每日一词')
        term_clean = strip_tags(term_text)
        lines.append(term_clean)
        lines.append('')

    # 分析师笔记
    kol_items = re.findall(
        r'<div class="kol-item">(.*?)</div>\s*</div>',
        html, re.DOTALL
    )
    if kol_items:
        lines.append('## 🐦 分析师笔记')
        for item in kol_items:
            name = extract_text(item, r'<div class="name">(.*?)</div>')
            handle = extract_text(item, r'<div class="handle">(.*?)</div>')
            take = extract_text(item, r'<div class="take">(.*?)</div>')
            why = extract_text(item, r'<div class="why">(.*?)</div>')
            lines.append(f'**{strip_tags(name)}** {strip_tags(handle)}')
            lines.append(f'{strip_tags(take)}')
            if why:
                lines.append(f'→ {strip_tags(why)}')
            lines.append('')

    # 本周关注 (复用cards结构但不同section)
    week_section = html.split('📅 本周关注')
    if len(week_section) > 1:
        week_cards = re.findall(
            r'<div class="card"[^>]*>(.*?)</div>\s*</div>',
            week_section[1], re.DOTALL
        )
        if week_cards:
            lines.append('## 📅 本周关注')
            lines.append('| 时间 | 事件 | 星级 |')
            lines.append('|---|---|---|')
            for card in week_cards:
                name = extract_text(card, r'<div class="name">(.*?)</div>')
                note = extract_text(card, r'<div class="note">(.*?)</div>')
                lines.append(f'| {strip_tags(name)} | {strip_tags(note)} | |')
            lines.append('')

    # Footer
    footer = extract_text(html, r'<footer>(.*?)</footer>')
    if footer:
        lines.append('---')
        lines.append(strip_tags(footer))

    md_content = '\n'.join(lines)
    md_path = html_path.replace('.html', '.md')
    with open(md_path, 'w', encoding='utf-8') as f:
        f.write(md_content)

    print(f"OK: {html_path} -> {md_path}")
    return md_path


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python html2md.py <file.html>")
        sys.exit(1)
    convert(sys.argv[1])
