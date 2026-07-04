# 日报外部参考文件

> AI 生成日报时读取此文件获取 KOL 轮换池、学习路径、读者信息等固定参考数据。
> 此文件不每次写入 prompt，减少 token 消耗。

---

## 读者信息（仅 AI 内部使用，不出现在公开日报里）

| 项目 | 内容 |
|---|---|
| 姓名 | YI ZHAO (Zoe) |
| 持仓 | VOO / SCHD / QQQ / WDC / MCD / ECHO / LAC |
| 风险偏好 | 稳健，ETF 定投为主 |
| 文件保存路径 | `0. Newsletter\[YYYY-MM-DD].html` + `.md`（纯英文文件名） |
| 归档路径 | `0. Newsletter\归档\投资理财\` |
| 首页文件 | `0. Newsletter\index.html` |
| GitHub 仓库 | `https://github.com/Yiz777/StockDaily.git` |
| GitHub Pages | `https://Yiz777.github.io/StockDaily/` |
| 发布脚本 | `bash publish.sh <参数>` (Git+微信一键推送) |
| MD转换脚本 | `python html2md.py <file.html>` (HTML自动转MD) |

---

## KOL 轮换池

| KOL | 身份 | 适合 |
|---|---|---|
| 🎯 @EricBalchunas | Bloomberg ETF 首席 | **常驻**（每天必出） |
| 📖 @BrianFeroldi | 小白科普 | 波动安抚 |
| 🧠 @MorganHousel | 《金钱心理学》 | 心态 |
| 📊 @awealthofcs (Ben Carlson) | 机构资管总监 | 数据/历史 |
| 🔢 @10kdiver | 投资数学 | 估值/复利 |
| 📈 @LizAnnSonders | Schwab 首席策略 | 市场结构/技术分析 |
| 💰 @DividendGrowth | 分红投资 | SCHD 相关 |

**规则**：3 条 KOL = 1 常驻(EricBalchunas) + 2 轮换。搜不到当天内容标"近期观点"，不编造。

---

## 每日一词学习路径（不循环，不重复）

```
入门：ETF / 定投(DCA) / 市盈率(P/E) / 股息(Dividend) / 恐慌指数(VIX) / 牛市熊市 / 回调(Correction) / 毛利率(Gross Margin)
↓
进阶：鹰派鸽派 / 再平衡(Rebalance) / 收益率曲线 / 流动性(Liquidity) / 市值(Market Cap) / 去风险(De-risking)
↓
中高：资本支出(CapEx) / 市销率(P/S) / 自由现金流(FCF) / 护城河 / Beta / Alpha / 安全边际
↓
高级：期货贴水(Contango/Backwardation) / QE / QT / 期限溢价 / 杠杆周期
```

**选词规则**：优先从当天新闻里出现的专业术语中选词。如果没有合适的，从学习路径选一个没讲过的。

---

## 美股休市日历（2026 年）

| 日期 | 节日 | 类型 |
|---|---|---|
| 1月1日 | 元旦 | 全天休市 |
| 1月19日 | 马丁·路德·金日 | 全天休市 |
| 2月16日 | 总统日 | 全天休市 |
| 4月3日 | 耶稣受难日 | 全天休市 |
| 5月25日 | 阵亡将士纪念日 | 全天休市 |
| 6月19日 | 六月节 | 全天休市 |
| 7月3日 | 独立日（观察到） | 全天休市（7月4日是周六） |
| 9月7日 | 劳动节 | 全天休市 |
| 11月26日 | 感恩节 | 全天休市 |
| 11月27日 | 感恩节次日 | 提前收盘（美东13:00） |
| 12月24日 | 圣诞夜 | 提前收盘（美东13:00） |
| 12月25日 | 圣诞节 | 全天休市 |

**休市日处理规则**：
1. 识别当天是否为休市日（查上表或搜索 "US stock market holiday today"）
2. 休市日：跳过所有实时价格搜索，复用上一交易日收盘数据
3. 只搜索当天新闻（如有重大宏观事件）
4. 日报标题标注"美股休市"
5. 今日建议固定写"今天休市，什么都不用做"
6. 持仓速览标注"数据截至X月X日收盘"

---

## 12 个固定板块（按顺序）

```
①  🍉 Header            — 标题 + 日期 + badge标签
②  🍓 今日一句话          — 红色左边框，不超过30字
③  🌡️ 市场温度计          — 8个卡片，每行4个
④  ⚠️ 持仓预警（可选）     — 红色alert框，仅持仓有事件时出现
⑤  🔤 新闻翻译官          — 2-3条新闻，专业→大白话
⑥  👜 我的持仓            — 持仓列表 + 当日涨跌 + 心情emoji
⑦  🧘 今日建议            — 黄色框，操作建议 + 编号理由
⑧  🔭 机会雷达            — 前瞻性机会，1-2个方向
⑨  📖 每日一词            — 结合当日市场的金融术语
⑩  🐦 分析师笔记           — 3位KOL（1常驻+2轮换）
⑪  📅 本周关注            — 即将发生的事件卡片
⑫  🔗 快速入口            — Yahoo Finance/CNBC/华尔街见闻等链接
```

---

## 心情 emoji 对照表

| 当日涨跌 | emoji |
|---|---|
| 涨 > 2% | 🚀 |
| 涨 0-2% | 🙂 |
| 跌 0-2% | 🤧 |
| 跌 2-5% | 😅 |
| 跌 > 5% | 💔 |

单日跌幅 > 5% 的持仓，该行加红色边框高亮。

---

## VIX 判断规则

| VIX 区间 | 状态 |
|---|---|
| < 15 | 乐观 |
| 15-20 | 正常 |
| 20-30 | 紧张 |
| > 30 | 恐慌（通常是底部） |

---

## CSS 模板说明

CSS 完全复用上一期 HTML 的 `<style>` 块。AI 只需填充内容，不改动 style 块。

关键 class 名：

| class | 用途 |
|---|---|
| `.header` | 顶部黄色区 |
| `.badge` | 汇率/金价/事件标签 |
| `.one-liner` | 今日一句话（红左边框） |
| `.cards` + `grid-template-columns: repeat(4, 1fr)` | 温度计8卡片每行4个（手机端每行2个） |
| `.card .emoji` | 卡片emoji独占一行 |
| `.card .name` | 卡片名称独占一行 |
| `.alert-box` | 持仓预警红框 |
| `.translate-box` / `.translate-item` | 新闻翻译 |
| `.portfolio` / `.bag-item` | 持仓列表 |
| `.advice` | 今日建议黄框 |
| `.opportunity-box` | 机会雷达 |
| `.term-box` | 每日一词 |
| `.kol-item` | 分析师笔记 |
| `.links-grid` / `.link-card` | 快速入口 |
