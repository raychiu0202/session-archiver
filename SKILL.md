---
name: session-archiver
description: Auto-detect new sessions on heartbeat and automatically archive previous sessions. Also supports manual triggers: "保存会话", "存档", "归档", "archive session", "save conversation". Archives to ~/Documents/my_ai_archive/conversations/ with a MANIFEST.md index table. Auto-generates Chinese summary title (concise 10-30 chars) and detailed summary (200+ words). Prevents duplicates by tracking state in session-archiver-state.json.
---

# Session Archiver

Intelligent session archiving that automatically detects new sessions and archives the previous one. Also supports manual triggers.

## External Commands Required

- `mkdir` - for creating directories
- `echo` - for appending to MANIFEST.md
- `date` - for generating timestamps
- `grep` - for checking duplicates in MANIFEST.md

## Triggers

**Manual triggers:**
- 中文："保存会话", "存档", "归档", "生成会话清单"
- English: "archive session", "save conversation", "export chat"

**Auto-trigger (heartbeat-based):** On every heartbeat, automatically detect if a new session has been created and archive the previous one without prompting.

## Configuration

Archive root directory (default: `~/Documents/my_ai_archive/`). Can override via environment variable:
```bash
export SESSION_ARCHIVER_ROOT="~/custom/path"
```

## State File

The skill maintains state in `~/.openclaw/workspace/session-archiver-state.json`:
```json
{
  "lastTrackedSessionId": "agent:main:xxx",
  "lastCheckTime": 17762442800000
}
```

- Read this file on every heartbeat to detect new sessions
- Update after each auto-archive operation
- Create automatically on first run if missing

## Workflow

### Phase 1: Detect New Session (Auto-Trigger on Heartbeat)

1. Read state file: `~/.openclaw/workspace/session-archiver-state.json`
   - If missing, create with empty state (no lastTrackedSessionId)
2. List recent sessions using `sessions_list` with `activeMinutes=1440` (last 24h)
3. Identify the current running session (first in list)
4. Compare with `lastTrackedSessionId`:
   - **If different**: New session detected! Previous session has ended → proceed to archive
   - **If same**: No new session, do nothing (skip entire workflow)

### Phase 2: Determine Target Session (Auto-Trigger)

When new session detected:
1. The "previous session" is the one in `lastTrackedSessionId`
2. Use this as the target for archiving
3. If `lastTrackedSessionId` is empty/null, skip (first run, nothing to archive yet)

### Phase 3: Check for Duplicates

Before archiving, check if the session ID already exists in MANIFEST.md:
```bash
grep -q "| $SESSION_ID |" "$MANIFEST_PATH"
```
If found, skip silently (already archived in previous run).

### Phase 4: Gather Session Data

1. Get session info:
   - Session ID: from `lastTrackedSessionId` (the previous session)
   - Timestamp: use `date '+%Y-%m-%d_%H-%M-%S'`
   - Model: from session metadata if available

2. Fetch full conversation using `sessions_history` with the session key
3. Format conversation as markdown:
   - For each message, use `### {role}` followed by content
   - Skip tool calls and results; keep only user/assistant text
   - Truncate messages > 2000 chars with `[...截断]` marker

### Phase 5: Generate Title and Summary (Auto-Trigger)

Generate automatically WITHOUT asking user:
1. **标题**: Concise Chinese summary (10-30 chars) that captures main topic
2. **摘要**: Detailed Chinese summary (200+ words) that covers the conversation's key points

See "Auto-Summary Generation" section below for detailed logic.

### Phase 6: Write Archive File

1. Ensure directories exist:
   ```bash
   mkdir -p "$ARCHIVE_ROOT/conversations"
   ```

2. Write markdown file: `$ARCHIVE_ROOT/conversations/YYYY-MM-DD_HH-MM-SS_session.md`

   Format:
   ```markdown
   # {title}

   - **会话 ID**: {session_id}
   - **存档时间**: {timestamp}
   - **模型**: {model}

   ---

   ## 会话内容

   {formatted conversation}

   ---
   *Archived by session-archiver skill (auto-trigger)*
   ```

### Phase 7: Update MANIFEST.md

1. Read existing MANIFEST.md to check format
2. If missing or corrupted, recreate with header:
   ```markdown
   # 会话存档清单

   | 会话ID | 存档时间 | 标题/摘要 | 文件路径 |
   |--------|----------|-----------|----------|
   ```

3. Append new row. Use the bundled script for safe appending:
   ```bash
   bash /path/to/scripts/update_manifest.sh "$SESSION_ID" "$TIMESTAMP" "$TITLE" "$REL_PATH"
   ```

### Phase 8: Update State and Confirm

1. Update state file with current session ID:
   ```json
   {
     "lastTrackedSessionId": "{current_session_id}",
     "lastCheckTime": {current_timestamp}
   }
   ```

2. For auto-trigger, reply with confirmation:
   ```
   ✅ 自动存档完成：上一个会话已存档至 `$ARCHIVE_ROOT/conversations/YYYY-MM-DD_HH-MM-SS_session.md`，清单已更新。
   ```

### Manual Trigger Workflow (When User Explicitly Triggers)

If user explicitly says "保存会话" or similar:

1. Use the same Phase 1-4 but identify "previous session" differently:
   - List recent sessions
   - Find the most recent session that is NOT the current running one
2. Ask user for title/summary (skip auto-generation for manual trigger)
3. Proceed with Phase 6-8 as above

## Error Handling

- **No previous session**: Do nothing (no error needed for auto-trigger)
- **Duplicate session ID**: Skip silently (already archived)
- **File write failure**: Log error and notify user
- **MANIFEST corruption**: Regenerate header before appending
- **Empty conversation**: Still archive with minimal content
- **State file missing**: Create on first run (not an error)

## Auto-Summary Generation

When auto-generating summary, read the full conversation history:

### 生成标题 (Title)
1. Identify the main topic, task, or purpose
2. Generate a concise Chinese title (10-30 characters)
3. Focus on: what was discussed, what was built, what problem was solved
4. Examples: "开发会话存档Skill", "优化数据库查询性能", "设计用户认证流程"

### 生成摘要 (Summary)
1. Read the full conversation history (all user and assistant messages)
2. Extract key information:
   - What was the user's goal/request?
   - What solutions/approaches were discussed?
   - What was the final outcome or decision?
   - Any important technical details or decisions
3. Write a detailed Chinese summary in narrative form (200+ words)
4. Structure: 背景需求 → 讨论过程 → 最终结论
5. If conversation is too short (less than 200 words possible), include all content naturally

### Example Output

**标题**: "OpenClaw 会话存档 Skill 开发"

**摘要**: "用户请求开发一个 OpenClaw Skill，实现会话自动存档功能。讨论了触发方式（自动检测会话切分+手动触发）、存档格式（Markdown）、清单维护（MANIFEST.md 表格）等技术细节。最终实现了包含 SKILL.md、辅助脚本和中英文 README 的完整项目，已发布到 GitHub 并安装到本地环境。测试验证了存档文件生成、清单更新和去重功能均正常工作。后续优化了自动摘要生成逻辑，要求标题为总结性中文标题（10-30 字），摘要为详细中文摘要（200+ 字），并实现了基于心跳的自动检测和存档功能。"
