# OpenClaw Session Archiver

Intelligent session archiving for OpenClaw. Automatically detects when a new session is created (via daily 4am split or inactivity timeout) and prompts to archive the previous session. Also supports manual triggers.

## Features

- **Auto-detection**: Prompts to archive when OpenClaw creates a new session (4am daily or after inactivity)
- **Manual triggers**: Archive on demand with natural language commands
- **Smart deduplication**: Never archives the same session twice
- **Auto-summary**: Generates 200-char summary from content if no title provided
- **Markdown format**: Clean, readable archive files with full conversation history
- **Manifest index**: Maintains `MANIFEST.md` with table of all archived sessions
- **Customizable path**: Override archive location via environment variable

## Installation

### Method 1: Clone directly (recommended)

```bash
git clone https://github.com/raychiu0202/openclaw-session-archiver.git ~/.openclaw/skills/session-archiver
```

### Method 2: Via ClawHub (when published)

```bash
clawhub install session-archiver
```

Or via SkillAtlas (if available):

```bash
skill-atlas install session-archiver -y
```

**Note:** Restart OpenClaw after installation for the skill to take effect.

## Usage

### Manual Triggers

Simply say any of the following in your chat:

- English: "archive session", "save conversation", "export chat"
- Chinese: "保存会话", "存档", "归档", "生成会话清单"

The skill will:
1. Identify the previous session
2. Ask for a title/summary (optional, reply "跳过" to auto-generate)
3. Archive the conversation to markdown
4. Update the manifest

### Auto-Trigger (when session splits)

When OpenClaw creates a new session (automatically at 4am or after inactivity), the skill detects this and prompts:

> 上一个会话 ([start] 至 [end]) 已结束，需要存档吗？

Reply with:
- "是" / "yes" → archive with auto-summary
- Provide a title → archive with custom title
- "不" / "no" → skip (not persistently remembered in v1)

## Configuration

### Custom Archive Location

Set the `SESSION_ARCHIVER_ROOT` environment variable to change where archives are stored:

```bash
# In your shell profile (~/.zshrc or ~/.bashrc)
export SESSION_ARCHIVER_ROOT="~/custom/path/to/archives"
```

Default: `~/Documents/my_ai_archive/`

### Directory Structure

```
~/Documents/my_ai_archive/
├── MANIFEST.md                 # Index table of all sessions
└── conversations/
    ├── 2026-04-15_15-21-03_session.md
    ├── 2026-04-15_16-00-45_session.md
    └── ...
```

## Archive Format

Each archive file is a markdown document:

```markdown
# Session Title

- **会话 ID**: agent:main:abc123
- **存档时间**: 2026-04-15_15-21-03
- **模型**: zai/glm-5

---

## 会话内容

### user
Hello, can you help me with...

### assistant
Of course! Here's how...

---
*Archived by session-archiver skill*
```

## FAQ

### Q: How does it avoid duplicate archives?

A: Before archiving, the skill checks `MANIFEST.md` for the session ID. If found, it skips the operation and notifies you.

### Q: Can I mark a session as "don't archive"?

A: In v1, this is not persistent. When prompted, simply reply "no" to skip that specific instance. Future versions may support persistent ignore lists.

### Q: What if I manually trigger but there's no previous session?

A: You'll see: "没有可存档的上一个会话。" (No previous session to archive.)

### Q: How long are archives kept?

A: Archives are stored indefinitely on your local filesystem. You can manually delete old files from `~/Documents/my_ai_archive/`.

### Q: Can I edit archive files?

A: Yes! Archive files are plain markdown. Edit them directly or use the manifest to locate specific sessions.

### Q: Does this work with all OpenClaw channels?

A: Yes, the skill archives the conversation content regardless of channel (webchat, Discord, Telegram, etc.).

## Troubleshooting

### Skill not triggering after installation

Restart OpenClaw:
```bash
openclaw gateway restart
```

### Permission errors

Ensure the archive directory is writable:
```bash
mkdir -p ~/Documents/my_ai_archive/conversations
chmod 755 ~/Documents/my_ai_archive
```

### MANIFEST.md corrupted

Delete it and the skill will regenerate the header on next archive:
```bash
rm ~/Documents/my_ai_archive/MANIFEST.md
```

## Development

### File Structure

```
openclaw-session-archiver/
├── SKILL.md              # Core skill logic (this is what OpenClaw reads)
├── README.md             # This file
├── README.zh-CN.md       # Chinese documentation
├── LICENSE               # MIT License
├── scripts/
│   └── update_manifest.sh # Helper script for safe manifest updates
└── assets/               # Optional screenshots (for docs)
```

### How the auto-detection works

OpenClaw automatically splits sessions daily at 4am or after long inactivity. When a new session starts, this skill (when triggered) lists recent sessions and identifies the immediately preceding one, then prompts for archiving.

**Note:** In v1, auto-detection requires manual triggering. True automatic prompting on session split is planned for v2.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Issues and pull requests welcome! This is an open-source project maintained by the community.

## Credits

Built for [OpenClaw](https://github.com/openclaw/openclaw) - the extensible AI agent framework.
