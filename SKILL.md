---
name: session-archiver
description: Auto-detect when OpenClaw creates a new session (via auto-split at 4am or after inactivity) and prompt to archive the previous session. Also supports manual triggers: "保存会话", "存档", "归档", "archive session", "save conversation". Archives to ~/Documents/my_ai_archive/conversations/ with a MANIFEST.md index table. Auto-generates Chinese summary title (concise) and detailed summary (200+ words) from content if not provided. Prevents duplicates by checking MANIFEST.md for existing session IDs.
---

# Session Archiver

Intelligent session archiving that detects auto session splits (4am daily or inactivity timeout) and prompts to archive the previous session. Also supports manual triggers.

## External Commands Required

- `mkdir` - for creating directories
- `echo` - for appending to MANIFEST.md
- `date` - for generating timestamps
- `grep` - for checking duplicates in MANIFEST.md

## Triggers

**Manual triggers:**
- 中文："保存会话", "存档", "归档", "生成会话清单"
- English: "archive session", "save conversation", "export chat"

**Auto-trigger (not implemented in this version):** Detects new session creation after 4am split or inactivity timeout, then prompts: "上一个会话 ([start] 至 [end]) 已结束，需要存档吗？"

## Configuration

Archive root directory (default: `~/Documents/my_ai_archive/`). Can override via environment variable:
```bash
export SESSION_ARCHIVER_ROOT="~/custom/path"
```

## Workflow

### Phase 1: Determine Target Session

**Manual trigger:**
1. List recent sessions using `sessions_list` with `activeMinutes=1440` (last 24h).
2. Identify the most recent session that is NOT the current session.
3. If no previous session found, reply: "没有可存档的上一个会话。"

**Auto-trigger (future):**
1. Detect current session is newly created (timestamp < threshold).
2. Identify the immediately preceding session via `sessions_list`.

### Phase 2: Check for Duplicates

Before archiving, check if the session ID already exists in MANIFEST.md:
```bash
grep -q "| $SESSION_ID |" "$MANIFEST_PATH"
```
If found, reply: "该会话已存档，跳过。"

### Phase 3: Ask for Title/Summary (If Not Already Provided)

Reply: "想给这次会话加个标题或摘要吗？（可以直接说，或回复「跳过」来自动生成标题和摘要）"

Wait for user input:
- If they provide a title → use it (user-provided title)
- If they skip/reply "跳过" → automatically generate:
  1. **标题**: Concise Chinese summary (10-30 chars) that captures the main topic
  2. **摘要**: Detailed Chinese summary (200+ words) that covers the conversation's key points
- If they reply "不存档" or similar → mark as ignored (no need to implement persistent ignore state in v1)

### Phase 4: Gather Session Data

1. Get session info:
   - Session ID: from `sessions_list` response
   - Timestamp: use `date '+%Y-%m-%d_%H-%M-%S'`
   - Model: from session metadata if available

2. Fetch full conversation:
   ```bash
   sessions_history --sessionKey "$SESSION_KEY" --limit 1000
   ```

3. Format conversation as markdown:
   - For each message, use `### {role}` followed by content
   - Skip tool calls and results; keep only user/assistant text
   - Truncate messages > 2000 chars with `[...截断]` marker

### Phase 5: Write Archive File

1. Ensure directories exist:
   ```bash
   mkdir -p "$ARCHIVE_ROOT/conversations"
   ```

2. Write markdown file: `$ARCHIVE_ROOT/conversations/YYYY-MM-DD_HH-MM-SS_session.md`

   Format:
   ```markdown
   # {title/summary}

   - **会话 ID**: {session_id}
   - **存档时间**: {timestamp}
   - **模型**: {model}

   ---

   ## 会话内容

   {formatted conversation}

   ---
   *Archived by session-archiver skill*
   ```

### Phase 6: Update MANIFEST.md

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
   The script handles:
   - Creating directory if needed
   - Checking/creating table header
   - Escaping special characters (pipes, newlines)
   - Safe append operation

### Phase 7: Confirm to User

Reply in Chinese:
```
✅ 会话已存档至 `$ARCHIVE_ROOT/conversations/YYYY-MM-DD_HH-MM-SS_session.md`，清单已更新。
```

Or in English (auto-detect user language):
```
✅ Session archived to `$ARCHIVE_ROOT/conversations/YYYY-MM-DD_HH-MM-SS_session.md`, manifest updated.
```

## Error Handling

- **No previous session**: Inform user there's nothing to archive
- **Duplicate session ID**: Skip and notify user
- **File write failure**: Check disk space and permissions, retry
- **MANIFEST corruption**: Regenerate header before appending
- **Empty conversation**: Still archive with minimal content

## Auto-Summary Generation

When user skips, generate BOTH title and summary from conversation content:

### 生成标题 (Title)
1. Read the full conversation history
2. Identify the main topic, task, or purpose
3. Generate a concise Chinese title (10-30 characters)
4. Focus on: what was discussed, what was built, what problem was solved
5. Examples: "开发会话存档Skill", "优化数据库查询性能", "设计用户认证流程"

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

**摘要**: "用户请求开发一个 OpenClaw Skill，实现会话自动存档功能。讨论了触发方式（自动检测会话切分+手动触发）、存档格式（Markdown）、清单维护（MANIFEST.md 表格）等技术细节。最终实现了包含 SKILL.md、辅助脚本和中英文 README 的完整项目，已发布到 GitHub 并安装到本地环境。测试验证了存档文件生成、清单更新和去重功能均正常工作。"
