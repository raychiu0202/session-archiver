# OpenClaw 会话存档工具

OpenClaw 的智能会话存档工具。自动检测新会话创建（通过每日 4am 分割或不活动超时）并提示存档上一个会话。同时也支持手动触发。

## 功能特点

- **自动检测**：当 OpenClaw 创建新会话时提示存档（4am 每日或不活动后）
- **手动触发**：通过自然语言命令按需存档
- **智能去重**：永不重复存档同一会话
- **自动摘要**：如果未提供标题，自动从内容生成 200+ 字摘要
- **Markdown 格式**：整洁、可读的存档文件，包含完整对话历史
- **清单索引**：维护 `MANIFEST.md`，包含所有存档会话的表格
- **自定义路径**：通过环境变量覆盖存档位置

## 安装

### 方法 1：直接克隆（推荐）

```bash
git clone https://github.com/raychiu0202/openclaw-session-archiver.git ~/.openclaw/skills/session-archiver
```

### 方法 2：通过 ClawHub（已发布时）

```bash
clawhub install session-archiver
```

或通过 SkillAtlas（如果可用）：

```bash
skill-atlas install session-archiver -y
```

**注意：**安装后重启 OpenClaw 以使 skill 生效。

## 使用方法

### 手动触发

只需在聊天中说以下任意内容：

- 英文："archive session", "save conversation", "export chat"
- 中文："保存会话", "存档", "归档", "生成会话清单"

该工具将：
1. 识别上一个会话
2. 询问标题/摘要（可选，回复"跳过"自动生成）
3. 将对话存档为 markdown
4. 更新清单

### 自动触发（当会话分割时）

当 OpenClaw 创建新会话时（4am 自动或不活动后），该工具检测到并提示：

> 上一个会话 ([start] 至 [end]) 已结束，需要存档吗？

回复：
- "是" / "yes" → 使用自动摘要存档
- 提供标题 → 使用自定义标题存档
- "不" / "no" → 跳过（v1 中不持久记住）

## 配置

### 自定义存档位置

设置 `SESSION_ARCHIVER_ROOT` 环境变量以更改存档存储位置：

```bash
# 在你的 shell 配置文件中（~/.zshrc 或 ~/.bashrc）
export SESSION_ARCHIVER_ROOT="~/custom/path/to/archives"
```

默认：`~/Documents/my_ai_archive/`

### 目录结构

```
~/Documents/my_ai_archive/
├── MANIFEST.md                 # 所有会话的索引表
└── conversations/
    ├── 2026-04-15_15-21-03_session.md
    ├── 2026-04-15_16-00-45_session.md
    └── ...
```

## 存档格式

每个存档文件是一个 markdown 文档：

```markdown
# 会话标题

- **会话 ID**: agent:main:abc123
- **存档时间**: 2026-04-15_15-21-03
- **模型**: zai/glm-5

---

## 会话内容

### user
你好，能帮我...

### assistant
当然！这里是...

---
*由 session-archiver skill 存档*
```

## 常见问题

### Q: 如何避免重复存档？

A: 存档前，该工具检查 `MANIFEST.md` 中的会话 ID。如果找到，它跳过操作并通知你。

### Q: 我可以标记会话为"不存档"吗？

A: 在 v1 中，这不是持久的。被提示时，只需回复"no"跳过该特定实例。未来版本可能支持持久忽略列表。

### Q: 如果我手动触发但没有上一个会话怎么办？

A: 你会看到："没有可存档的上一个会话。"

### Q: 存档保留多久？

A: 存档无限期存储在本地文件系统上。你可以从 `~/Documents/my_ai_archive/` 手动删除旧文件。

### Q: 我可以编辑存档文件吗？

A: 可以！存档文件是纯 markdown。直接编辑它们或使用清单定位特定会话。

### Q: 这适用于所有 OpenClaw 频道吗？

A: 是的，无论频道（webchat、Discord、Telegram 等），该工具都存档对话内容。

## 故障排除

### 安装后 skill 不触发

重启 OpenClaw：
```bash
openclaw gateway restart
```

### 权限错误

确保存档目录可写：
```bash
mkdir -p ~/Documents/my_ai_archive/conversations
chmod 755 ~/Documents/my_ai_archive
```

### MANIFEST.md 损坏

删除它，skill 将在下次存档时重新生成表头：
```bash
rm ~/Documents/my_ai_archive/MANIFEST.md
```

## 开发

### 文件结构

```
openclaw-session-archiver/
├── SKILL.md              # 核心 skill 逻辑（这是 OpenClaw 读取的内容）
├── README.md             # 本文件
├── README.zh-CN.md       # 中文文档
├── LICENSE               # MIT 许可证
├── scripts/
│   └── update_manifest.sh # 用于安全清单更新的辅助脚本
└── assets/               # 可选截图（用于文档）
```

### 自动检测如何工作

OpenClaw 每日 4am 或长时间不活动后自动分割会话。当新会话开始时，此 skill（被触发时）列出最近会话并识别紧接着的前一个，然后提示存档。

**注意：**在 v1 中，自动检测需要手动触发。真正在会话分割时的自动提示计划在 v2 中实现。

## 许可证

MIT 许可证 - 详见 [LICENSE](LICENSE)。

## 贡献

欢迎提出问题和拉取请求！这是一个由社区维护的开源项目。

## 致谢

为 [OpenClaw](https://github.com/openclaw/openclaw) 构建 - 可扩展的 AI 代理框架。
