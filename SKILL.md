---
name: session-archiver
description: 智能会话存档工具，自动检测新会话并自动归档上一个会话。支持手动触发："保存会话", "存档", "归档", "archive session", "save conversation"。存档至 ~/Documents/my_ai_archive/conversations/，并维护 MANIFEST.md 索引表。自动生成中文总结标题（简洁 10-30 字）和详细摘要（200+ 字）。通过 session-archiver-state.json 防止重复存档。
---

# 会话存档工具

智能会话存档工具，自动检测新会话创建并归档上一个会话。同时也支持手动触发。

## 需要的外部命令

- `mkdir` - 创建目录
- `echo` - 追加内容到 MANIFEST.md
- `date` - 生成时间戳
- `grep` - 在 MANIFEST.md 中检查重复

## 触发方式

**手动触发：**
- 中文："保存会话", "存档", "归档", "生成会话清单"
- 英文："archive session", "save conversation", "export chat"

**自动触发（基于心跳）：** 每次心跳时，自动检测是否创建了新会话，如果检测到新会话则自动归档上一个会话，无需提示。

## 配置

存档根目录（默认：`~/Documents/my_ai_archive/`）。可通过环境变量覆盖：
```bash
export SESSION_ARCHIVER_ROOT="~/custom/path"
```

## 状态文件

此 skill 在 `~/.openclaw/workspace/session-archiver-state.json` 中维护状态：
```json
{
  "lastTrackedSessionId": "agent:main:xxx",
  "lastCheckTime": 17762442800000
}
```

- 每次心跳时读取此文件以检测新会话
- 每次自动存档操作后更新
- 首次运行时自动创建（如果不存在）

## 工作流程

### 阶段 1：检测新会话（心跳自动触发）

1. 读取状态文件：`~/.openclaw/workspace/session-archiver-state.json`
   - 如果不存在，创建空状态（没有 lastTrackedSessionId）
2. 使用 `sessions_list` 列出最近会话，设置 `activeMinutes=1440`（最近 24 小时）
3. 识别当前运行的会话（列表中的第一个）
4. 与 `lastTrackedSessionId` 比较：
   - **如果不同**：检测到新会话！上一个会话已结束 → 继续存档
   - **如果相同**：没有新会话，不执行任何操作（跳过整个流程）

### 阶段 2：确定目标会话（自动触发）

当检测到新会话时：
1. "上一个会话"是 `lastTrackedSessionId` 中的那个
2. 使用它作为存档目标
3. 如果 `lastTrackedSessionId` 为空/null，跳过（首次运行，暂无内容可存档）

### 阶段 3：检查重复

在存档前，检查 MANIFEST.md 中是否已存在该会话 ID：
```bash
grep -q "| $SESSION_ID |" "$MANIFEST_PATH"
```
如果找到，静默跳过（已在之前的运行中存档）。

### 阶段 4：收集会话数据

1. 获取会话信息：
   - 会话 ID：来自 `lastTrackedSessionId`（上一个会话）
   - 时间戳：使用 `date '+%Y-%m-%d_%H-%M-%S'`
   - 模型：来自会话元数据（如果可用）

2. 使用会话 key 通过 `sessions_history` 获取完整对话
3. 将对话格式化为 markdown：
   - 对于每条消息，使用 `### {role}` 后跟内容
   - 跳过工具调用和结果；仅保留用户/助手的文本
   - 使用 `[...截断]` 标记截断超过 2000 字符的消息

### 阶段 5：生成标题和摘要（自动触发）

自动生成，无需询问用户：
1. **标题**：简洁的中文总结（10-30 字），捕获主要主题
2. **摘要**：详细的中文总结（200+ 字），覆盖对话的关键点

详细逻辑见"自动摘要生成"部分。

### 阶段 6：写入存档文件

1. 确保目录存在：
   ```bash
   mkdir -p "$ARCHIVE_ROOT/conversations"
   ```

2. 写入 markdown 文件：`$ARCHIVE_ROOT/conversations/YYYY-MM-DD_HH-MM-SS_session.md`

   格式：
   ```markdown
   # {标题}

   - **会话 ID**: {session_id}
   - **存档时间**: {timestamp}
   - **模型**: {model}

   ---

   ## 摘要

   {summary}

   ---

   ## 会话内容

   {formatted conversation}

   ---
   *由 session-archiver skill 自动存档*
   ```

### 阶段 7：更新 MANIFEST.md

1. 读取现有 MANIFEST.md 检查格式
2. 如果缺失或损坏，重新创建表头：
   ```markdown
   # 会话存档清单

   | 会话ID | 存档时间 | 标题 | 摘要 | 文件路径 |
   |--------|----------|------|------|----------|
   ```

3. 追加新行。使用打包的脚本进行安全追加：
   ```bash
   bash /path/to/scripts/update_manifest.sh "$SESSION_ID" "$TIMESTAMP" "$TITLE" "$SUMMARY" "$REL_PATH"
   ```

### 阶段 8：更新状态并确认

1. 使用当前会话 ID 更新状态文件：
   ```json
   {
     "lastTrackedSessionId": "{current_session_id}",
     "lastCheckTime": {current_timestamp}
   }
   ```

2. 对于自动触发，回复确认信息：
   ```
   ✅ 自动存档完成：上一个会话已存档至 `$ARCHIVE_ROOT/conversations/YYYY-MM-DD_HH-MM-SS_session.md`，清单已更新。
   ```

### 手动触发工作流程（当用户显式触发时）

如果用户明确说"保存会话"或类似内容：

1. 使用相同的阶段 1-4，但以不同方式识别"上一个会话"：
   - 列出最近会话
   - 找到最近的一个不是当前正在运行的会话
2. 询问用户标题和摘要（手动触发时跳过自动生成）
3. 继续执行阶段 6-8

## 错误处理

- **无上一个会话**：不执行任何操作（自动触发时无需报错）
- **重复的会话 ID**：静默跳过（已存档）
- **文件写入失败**：记录错误并通知用户
- **MANIFEST 损坏**：追加前重新生成表头
- **空对话**：仍使用最小内容存档
- **状态文件缺失**：首次运行时自动创建（不是错误）

## 自动摘要生成

自动生成摘要时，阅读完整的对话历史：

### 生成标题
1. 识别主要主题、任务或目的
2. 生成简洁的中文标题（10-30 字符）
3. 重点关注：讨论了什么、构建了什么、解决了什么问题
4. 示例："开发会话存档 Skill"、"优化数据库查询性能"、"设计用户认证流程"

### 生成摘要
1. 阅读完整的对话历史（所有用户和助手消息）
2. 提取关键信息：
   - 用户的目标/请求是什么？
   - 讨论了哪些解决方案/方法？
   - 最终结果或决定是什么？
   - 任何重要的技术细节或决定
3. 以叙述形式撰写详细的中文摘要（200+ 字）
4. 结构：背景需求 → 讨论过程 → 最终结论
5. 如果对话太短（少于 200 字可能），自然包含所有内容

### 示例输出

**标题**："OpenClaw 会话存档 Skill 开发"

**摘要**："用户请求开发一个 OpenClaw Skill，实现会话自动存档功能。讨论了触发方式（自动检测会话切分+手动触发）、存档格式（Markdown）、清单维护（MANIFEST.md 表格）等技术细节。最终实现了包含 SKILL.md、辅助脚本和中英文 README 的完整项目，已发布到 GitHub 并安装到本地环境。测试验证了存档文件生成、清单更新和去重功能均正常工作。后续优化了自动摘要生成逻辑，要求标题为总结性中文标题（10-30 字），摘要为详细中文摘要（200+ 字），并实现了基于心跳的自动检测和存档功能。"
