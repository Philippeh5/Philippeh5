<div align="center">

# Quantitative Engineer & Web3 Systems Builder

*Algorithmic Trading • Crypto Payment Infrastructure • Autonomous AI Orchestration*

[![Stack](https://img.shields.io/badge/Stack-Python%20%7C%20TypeScript%20%7C%20Rust%20%7C%20Go-003366?style=for-the-badge&logo=github)](https://github.com/Philippeh5)
[![Focus](https://img.shields.io/badge/Focus-Quant%20%26%20Web3%20%26%20AI-0052FF?style=for-the-badge&logo=ethereum)](https://github.com/Philippeh5)
[![Status](https://img.shields.io/badge/Status-Building%20in%20Public-brightgreen?style=for-the-badge)](https://github.com/Philippeh5)

<p align="center">
  <a href="#-featured-projects">Featured Projects</a> •
  <a href="#-technical-stack">Technical Stack</a> •
  <a href="#-skills--tooling">Skills & Tooling</a> •
  <a href="#-contact">Contact</a>
</p>

---

</div>

## 📌 About

Building production-grade systems at the intersection of **quantitative finance**, **crypto infrastructure**, and **autonomous agent orchestration**.

- 📈 **Quantitative Trading**: ML-augmented algorithmic strategies (Freqtrade, FreqAI, LightGBM) on high-frequency and multi-timeframe crypto markets. Walk-forward backtesting, regime detection, risk-bounded position sizing.
- 💳 **Web3 & Payment Infrastructure**: Non-custodial settlement engines, BIP-44 HD wallet derivation, chain listeners with reorg protection, automated hot-wallet withdrawal pipelines on EVM (Base, Ethereum).
- 🤖 **AI & Agent Orchestration**: Multi-agent autonomous coordination loops, quota-aware provider failover, DAG-based task decomposition, persistent context handoffs, self-healing error recovery.
- 📊 **Corporate Finance Automation**: IFRS ↔ German GAAP (HGB §275) conversion pipelines, lease accounting restatements (IFRS 16), audit-ready reconciliation reports.

---

## 🚀 Featured Projects

<table width="100%">
<tr>
<td width="50%" valign="top">

### 📈 [freqtrade-lightgbm-strategy](https://github.com/Philippeh5/freqtrade-lightgbm-strategy)
**Algorithmic Trading Bot & ML Prediction Engine**
* Automated strategy using **Freqtrade**, **FreqAI**, and **LightGBM** regressor for multi-timeframe price forecasting
* Custom feature engineering (OHLCV, order flow, volatility bands)
* Dynamic position sizing, trailing stops, walk-forward backtesting
* **Backtest (3M)**: Win Rate **62.4%** • Sharpe **2.14** • Profit Factor **1.83** • Max DD **7.8%**
* **Stack**: `Python 3.11`, `Freqtrade`, `LightGBM`, `Scikit-learn`, `Pandas`, `NumPy`

</td>
<td width="50%" valign="top">

### 💳 [crypto-payment-gateway](https://github.com/Philippeh5/crypto-payment-gateway)
**Production-Ready EVM & Base USDC Payment & Settlement Infrastructure**
* High-throughput chain-watcher tracking on-chain deposits via WebSocket/RPC
* Deterministic BIP-44 HD wallet address derivation per user
* Deep reorg protection, multi-confirmation crediting, automated withdrawals
* **Stack**: `TypeScript`, `Node.js`, `Viem/Ethers.js`, `PostgreSQL/Supabase`, `Docker`

</td>
</tr>
<tr>
<td width="50%" valign="top">

### 📊 [automated-ifrs-hgb-converter](https://github.com/Philippeh5/automated-ifrs-hgb-converter)
**Corporate Finance Automation: IFRS → German GAAP (HGB §275)**
* Automated financial reporting pipeline converting P&L & Balance Sheet
* Rules engine: IFRS 16 lease capitalization vs HGB off-balance, revenue recognition, pension provisions
* Audit-ready reconciliation reports with Excel/Markdown output
* **Stack**: `Python`, `Pandas`, `OpenPyXL`, `Pydantic`

</td>
<td width="50%" valign="top">

### 🤖 [ai-agent-workflows](https://github.com/Philippeh5/ai-agent-workflows)
**Autonomous Multi-Agent Orchestration & Quota-Aware Routing**
* Scalable multi-agent system: code gen, market analysis, review workflows
* Dynamic fallback router across LLM providers (rate-limits, quota depletion)
* Persistent state management, event-driven execution, checkpoint recovery
* **Stack**: `Python/TypeScript`, `FastAPI`, `Pydantic V2`, `SQLite/PostgreSQL`

</td>
</tr>
<tr>
<td width="50%" valign="top">

### 💳 [crypto-payment-starter-kit](https://github.com/Philippeh5/crypto-payment-starter-kit)
**Educational Starter Kit: Non-Custodial Crypto Payment Foundation**
* Simplified reference implementation: address derivation, deposit watching, settlement
* Clean architecture: watcher → validator → creditor → withdrawal queue
* No production secrets, no casino logic, fully documented for learning
* **Stack**: `TypeScript`, `Node.js`, `Viem`, `PostgreSQL`, `Docker`

</td>
<td width="50%" valign="top">

### 📈 [freqtrade-test-strategie-copie](https://github.com/Philippeh5/freqtrade-test-strategie-copie)
**Freqtrade Strategy: Multi-Indicator Confluence (1m Futures)**
* 10 long / 9 short entry conditions + 10 exit conditions (RSI, MACD, EMA, Bollinger, Ichimoku, Stochastic, Heikin Ashi, Supertrend, Fractals)
* Hyperopt-ready parameters, custom stake sizing (20% capital/trade), 10x leverage futures
* **Backtest**: ~14% return on 1m BTC/ETH futures (walk-forward, dry-run)
* **Stack**: `Python`, `Freqtrade`, `TA-Lib`, `pandas-ta`, `FreqAI-compatible`

</td>
</tr>
</table>

---

## 🛠️ Technical Stack

| Domain | Technologies & Tools |
| :--- | :--- |
| **Languages** | Python, TypeScript, JavaScript, SQL, Rust, Go, HTML5/CSS3 |
| **Quant & Data Science** | Freqtrade, FreqAI, LightGBM, Pandas, NumPy, Scikit-learn, TA-Lib, pandas-ta |
| **Web3 & Blockchain** | EVM (Base, Ethereum), Viem, Ethers.js, WebSockets, RPC, HD Wallets (BIP-32/44) |
| **Backend & Databases** | Node.js, FastAPI, PostgreSQL, Supabase, Redis, SQLite |
| **Cloud & DevOps** | Docker, Docker Compose, Linux, Git, GitHub Actions, Tailscale |
| **Finance & Accounting** | IFRS Standards, German GAAP (HGB), Financial Modeling, Valuation |

---

## 🧰 Skills & Tooling

**Claude Code Skills** (in [`/Skills`](https://github.com/Philippeh5/Philippeh5/tree/main/Skills) folder):
| Skill | Purpose |
| :--- | :--- |
| `autopilot` | Zero-confirmation batch execution with foreman delegation & watchdog recovery |
| `night` | Overnight autonomous engineering loop: backlog → execute → verify → discover → repeat |
| `improve-system` | Analyzes conversation history → proposes CLAUDE.md/skills/hooks/permissions upgrades |
| `claude-foreman` | Team-lead orchestrator: decomposes → routes to workers (Haiku + free seats) → verifies |
| `unlazy` | Completion discipline: gates + evidence + blind verifier before marking done |
| `reprise` | Auto-resume interrupted work: state reconciliation + watchdog relaunch |
| `claim-check` | Final truth pass: verifies claims against evidence before submission |
| `system-one` | System 1/2 thinking integration: fast intuition + slow verification loops |
| `playwright-cli` | Headed browser automation for real verification (not screenshots) |
| `reverse-engineer-anything` | Binary/static analysis: native, managed, Electron, WASM, smart contracts |
| `paseo-poste` | Command post control: agents, terminals, tasks, bots, services via MCP |

*Plus career skills (resume-auditor, resume-builder, resume-tailor, cover-letter, claim-check) and creative/research/productivity skills.*

---

## 📫 Contact

<div align="center">

[![GitHub](https://img.shields.io/badge/GitHub-Philippeh5-181717?style=for-the-badge&logo=github)](https://github.com/Philippeh5)
[![Email](https://img.shields.io/badge/Email-Contact-D14836?style=for-the-badge&logo=protonmail)](mailto:quant.web3.builder@proton.me)

</div>