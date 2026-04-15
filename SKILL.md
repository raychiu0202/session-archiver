---
name: session-archiver
description: Archive and save conversation sessions to local markdown files with a manifest index. Triggers on phrases like "保存会话", "存档记录", "生成会话清单", "archive session", or "save conversation". Creates timestamped markdown files under ~/.my_ai_archive/conversations/ and maintains a MANIFEST.md index table.
---

# Session Archiver

Archive the current conversation session to a local markdown file with a manifest index.

## Trigger Phrases

- 保存会话 / 存档记录 / 生成会话清单
- archive session / save conversation / export chat

## Workflow

1. **Ask for title/summary** — Prompt the user: "想给这次会话加个标题或摘要吗？（可以直接说，或回复「跳过」）"
   - Accept their input as the session title/summary.
   - If they skip or say no, use "未命名会话" as default.

2. **Gather session data** — Collect the following:
   - Use `session_status` to get current session info (session ID, model, timestamps).
   - Use `sessions_history` on the current session to retrieve the full conversation content.
   - Generate a timestamp: `date '+%Y-%m-%d_%H-%M-%S'` via `exec`.

3. **Ensure directory structure** — Run:
   ```bash
   mkdir -p ~/.my_ai_archive/conversations
   ```

4. **Generate the archive markdown file** — Build a markdown document with this structure and write it to `~/.my_ai_archive/conversations/YYYY-MM-DD_HH-MM-SS_session.md` using the `write` tool:

   ```markdown
   # {title/summary}

   - **会话 ID**: {session_id}
   - **存档时间**: {timestamp}
   - **模型**: {model}

   ---

   ## 会话内容

   {formatted conversation history}

   ---
   *Archived by session-archiver skill*
   ```

   Format conversation history: for each message, use `### {role}` followed by the content. Skip tool calls/results; keep only user and assistant text. Truncate individual messages longer than 2000 characters with a `[...截断]` marker.

5. **Update MANIFEST.md** — Read `~/.my_ai_archive/MANIFEST.md`. If it exists, append a new row to the table. If not, create it with the header and first row.

   MANIFEST.md format:
   ```markdown
   # 会话存档清单

   | 会话ID | 存档时间 | 标题/摘要 | 文件路径 |
   |--------|----------|-----------|----------|
   | {id} | {timestamp} | {title} | conversations/YYYY-MM-DD_HH-MM-SS_session.md |
   ```

   Append a new table row (do not rewrite the entire file — use `exec` with `echo >> MANIFEST.md` or `edit` to append).

6. **Confirm to user** — Reply with:
   - ✅ 存档完成
   - 📄 文件路径: `{full path}`
   - 📋 清单已更新: `~/.my_ai_archive/MANIFEST.md`

## Error Handling

- If `session_status` or `sessions_history` fails, inform the user and offer to retry.
- If file write fails, check disk space and permissions, then retry.
- If MANIFEST.md is corrupted (missing table header), regenerate the header before appending.
