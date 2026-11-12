# Skills — Claude Code Skill Collection

This folder contains **Claude Code skills** — reusable, versioned procedural memories that define how to run specific engineering workflows autonomously. Each skill is a self-contained `SKILL.md` with frontmatter, detailed instructions, and optional supporting scripts/templates.

> **Not Hermes skills.** These are native Claude Code skills (loaded via `.claude/skills/` or `~/.claude/skills/`), designed for autonomous coding agents running in Claude Code CLI.

---

## 📦 Skills Index

| Skill | Category | Description |
| :--- | :--- | :--- |
| [`autopilot/`](autopilot/) | Orchestration | Zero-confirmation batch execution: decomposes → routes via `claude-foreman` → workers execute → verifies → watchdog recovery → batch checkpoint menu |
| [`night/`](night/) | Orchestration | Overnight autonomous loop: clarify once → build backlog → execute → verify → discover → triage → persist → repeat until legitimate stop condition |
| [`improve-system/`](improve-system/) | Meta | Analyzes conversation history → extracts recurring corrections/directives → proposes CLAUDE.md/skills/hooks/permissions upgrades → applies only after validation |
| [`claude-foreman/`](claude-foreman/) | Orchestration | Team-lead orchestrator: lead (Opus) plans/routes → workers (Haiku + free seats) implement/check/fix → blind verifier → integrates |
| [`unlazy/`](unlazy/) | Completion | Completion discipline: gates + evidence + blind verifier pass before marking `DONE`; stop hook prevents silent exits |
| [`reprise/`](reprise/) | Recovery | Auto-resume interrupted work: state reconciliation (git status + ledger) → watchdog relaunch → continue from last safe checkpoint |
| [`claim-check/`](claim-check/) | Verification | Final truth pass: verifies every claim against cited evidence before submission; catches hallucinations, stale assumptions |
| [`system-one/`](system-one/) | Reasoning | System 1/2 integration: fast intuition (pattern match) + slow verification (explicit gates) loops |
| [`playwright-cli/`](playwright-cli/) | Verification | Headed browser automation for real runtime verification (not screenshots); dev launcher + Playwright CLI |
| [`reverse-engineer-anything/`](reverse-engineer-anything/) | Analysis | Binary/static analysis: native, managed, Electron, WASM, smart contracts; symbol recovery, control flow, decompilation |
| [`paseo-poste/`](paseo-poste/) | Control | Command post MCP: agents, terminals, tasks, bots, services, groups, inbox via `post_*` tools |

### Career Skills
| Skill | Purpose |
| :--- | :--- |
| [`resume-auditor/`](resume-auditor/) | Honest, critical feedback on résumés |
| [`resume-builder/`](resume-builder/) | Create/update source résumé (JSON → LaTeX/PDF/HTML) |
| [`resume-tailor/`](resume-tailor/) | Tailor résumé to a specific job posting |
| [`cover-letter/`](cover-letter/) | Write targeted cover letters |
| [`claim-check/`](claim-check/) | (Also listed above) Final truth verification |

### Creative / Research / Productivity Skills
`design-md`, `architecture-diagram`, `baoyu-infographic`, `popular-web-designs`, `ascii-video`, `manim-video`, `p5js`, `songwriting-and-ai-music`, `humanizer`, `arxiv`, `competitor-news-monitor`, `grounded-citations`, `llm-wiki`, `document-to-action-items`, `meeting-action-items`, `weekly-review-planning`, `notion`, `airtable`, `google-workspace`, `pdf`, `docx`, `xlsx`, `powerpoint`, `obsidian`, `himalaya`, `email-inbox-triage`, `product-price-monitor`, `maps`, `teams-meeting-pipeline`, `perso`, `poste`

---

## 🚀 Usage

### In a project (recommended)
```bash
# Clone this repo or copy specific skill folders into your project
cp -r Skills/autopilot .claude/skills/
cp -r Skills/night .claude/skills/
# etc.

# Then in Claude Code:
> /skill autopilot
```

### Global (user-level)
```bash
cp -r Skills/* ~/.claude/skills/
```

### Skill structure
```
skill-name/
├── SKILL.md          # Main skill definition (YAML frontmatter + markdown body)
├── scripts/          # Optional executable scripts (referenced in SKILL.md)
├── templates/        # Optional templates
├── references/       # Optional reference docs
└── assets/           # Optional static assets
```

---

## 📝 Skill Authoring Conventions

- **Frontmatter**: `name`, `description` (rich triggers: "Use when X. Does Y.")
- **Body**: Imperative rules, not logs. One rule per lesson. Reference by topic.
- **Scripts**: Shebang + executable. Document inputs/outputs in SKILL.md.
- **No secrets**: Never embed API keys, paths, or credentials.
- **Portable**: Use relative paths, environment variables, or CLI args.

---

## 🔗 Related

- [Claude Code Skills Documentation](https://github.com/anthropics/claude-code/tree/main/docs/skills)
- [Skills.sh Community Catalog](https://skills.sh)
- This collection lives at: `github.com/Philippeh5/Philippeh5/Skills`

---

*Maintained as part of the [Quantitative Engineer & Web3 Systems Builder](https://github.com/Philippeh5) portfolio.*