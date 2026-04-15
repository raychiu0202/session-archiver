# OpenClaw 会话存档器

OpenClaw 的智能会话存档工具。自动检测新会话创建（每日凌晨 4 点切分或长时间无操作后）并提示存档上一个会话。同时支持手动触发。

## 功能特性

- **自动检测**：当 OpenClaw 创建新会话时（每日凌晨 4 点或无操作超时）自动提示存档
- **手动触发**：通过自然语言指令随时存档
- **智能去重**：绝不会重复存档同一个会话
- **自动摘要**：如未提供标题，自动从对话内容提取 200 字符摘要
- **Markdown 格式**：整洁易读的存档文件，包含完整对话历史
- **清单索引**：维护 `MANIFEST.md` 表格，记录所有存档会话
- **自定义路径**：通过环境变量自定义存档位置

## 安装

### 方法 1：直接克隆（推荐）

```bash
git clone https://github.com/raychiu0202/openclaw-session-archiver.git ~/.openclaw/skills/session-archiver
```

### 方法 2：通过 ClawHub（发布后）

```bash
clawhub install session-archiver
```

或通过 SkillAtlas（如可用）：

```bash
skill-atlas install session-archiver -y
```

**注意**：安装后需重启 OpenClaw 使 skill 生效。

## 使用方法

### 手动触发

在聊天中输入以下任意指令：

- 中文："保存会话"、"存档"、"归档"、"生成会话清单"
- 英文："archive session"、"save conversation"、"export chat"

skill 会执行以下步骤：
1. 识别上一个会话
2. 询问标题/摘要（可选，回复"跳过"可自动生成）
3. 将对话存档为 markdown 文件
4. 更新清单

### 自动触发（会话切分时）

当 OpenClaw 创建新会话（自动每日 4 点或无操作后）时，skill 会检测到并提示：

> 上一个会话 ([开始时间] 至 [结束时间]) 已结束，需要存档吗？

回复：
- "是" / "yes" → 使用自动摘要存档
- 提供标题 → 使用自定义标题存档
- "不" / "no" → 跳过（v1 版本不会持久记住此选择）

## 配置

### 自定义存档位置

通过环境变量 `SESSION_ARCHIVER_ROOT` 更改存档位置：

```bash
# 在 shell 配置文件中 (~/.zshrc 或 ~/.bashrc)
export SESSION_ARCHIVER_ROOT="~/自定义/存档/路径"
```

默认：`~/Documents/my_ai_archive/`

### 目录结构

```
~/Documents/my_ai_archive/
├── MANIFEST.md                 # 所有会话的索引表格
└── conversations/
    ├── 2026-04-15_15-21-03_session.md
    ├── 2026-04-15_16-00-45_session.md
    └── ...
```

## 存档格式

每个存档文件都是 markdown 文档：

```markdown
# 会话标题

- **会话 ID**: agent:main:abc123
- **存档时间**: 2026-04-15_15-21-03
- **模型**: zai/glm-5

---

## 会话内容

### user
你好，帮我解决...

### assistant
当然可以！这里是...

---
*Archived by session-archiver skill*
```

## 常见问题

### Q: 如何避免重复存档？

A: 存档前，skill 会检查 `MANIFEST.md` 中是否已存在该会话 ID。如果找到，会跳过操作并通知你。

### Q: 可以标记会话为"不存档"吗？

A: v1 版本不支持持久化忽略。被提示时简单回复"不"即可跳过该次。未来版本可能支持持久化忽略列表。

### Q: 手动触发时没有上一个会话怎么办？

A: 你会看到提示："没有可存档的上一个会话。"

### Q: 存档会保留多久？

A: 存档永久保存在本地文件系统中。你可以手动从 `~/Documents/my_ai_archive/` 删除旧文件。

### Q: 可以编辑存档文件吗？

A: 可以！存档文件是纯 markdown。你可以直接编辑，或通过清单定位特定会话。

### Q: 这个工具对所有 OpenClaw 通道都有效吗？

A: 是的，无论通过哪个通道（webchat、Discord、Telegram 等），skill 都会存档对话内容。

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

删除它，skill 在下次存档时会重新生成表头：
```bash
rm ~/Documents/my_ai_archive/MANIFEST.md
```

## 开发

### 文件结构

```
openclaw-session-archiver/
├── SKILL.md              # Skill 核心逻辑（OpenClaw 读取此文件）
├── README.md             # 英文文档
├── README.zh-CN.md       # 中文文档（本文件）
├── LICENSE               # MIT 许可证
├── scripts/
│   └── update_manifest.sh # 辅助脚本，安全更新清单
└── assets/               # 可选截图（用于文档）
```

### 自动检测原理

OpenClaw 每日 4 点或长时间无操作后会自动切分会话。当新会话开始时，本 skill（被触发后）列出最近会话，识别紧邻的上一个会话，然后提示是否存档。

**注意**：v1 版本需要手动触发。真正的会话切分自动提示计划在 v2 版本实现。

## 许可证

MIT License - 详见 [LICENSE](LICENSE)

## 贡献

欢迎提交 issue 和 pull request！这是一个由社区维护的开源项目。

## 致谢

为 [OpenClaw](https://github.com/openclaw/openclaw) 构建 —— 可扩展的 AI 智能体框架。
