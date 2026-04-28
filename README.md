# 🤖 创作猫 Pro v8 - 智能故事创作系统

**版本：** Pro v8  
**完成时间：** 2026-04-11  
**架构：** 5 层架构（config/infra/datalayer/core/service）

---

## 🚀 快速开始

### 方式 1：Cron 定时任务（推荐）
```bash
# 每日 14:00 和 22:00 自动创作
0 14,22 * * * cd /home/administrator/.openclaw/workspace && python3 scripts/auto-create-story-new.py >> logs/create-story.log 2>&1
```

### 方式 2：命令行执行
```bash
cd /home/administrator/.openclaw/workspace
python3 scripts/auto-create-story-new.py
```

### 方式 3：Python 调用
```python
from service.story_service import StoryCreateService

service = StoryCreateService()
results = service.full_create_flow(platform="FANQIE", limit=3)

for story in results:
    print(f"{story['标题']} - {story['字数']}字 - AI:{story['AI 比例']:.1%}")
```

---

## 📁 架构说明

```
openclaw_studio/
├── config/              # 配置中心
│   └── settings.py      # 全局配置
├── core/                # 核心能力层
│   ├── topic_selector.py    # 智能选题
│   ├── mimeng_optimizer.py  # 咪蒙优化
│   ├── router.py            # 智能路由
│   ├── hybrid_engine.py     # 混合引擎（情绪文）
│   └── pro_v4_engine.py     # Pro v4 引擎（爽文）
├── datalayer/           # 数据层
│   ├── material_repo.py     # 素材管理
│   ├── story_repo.py        # 故事管理
│   ├── wiki_client.py       # 知识库客户端
│   └── lark_client.py       # 飞书 API
├── service/             # 业务调度层
│   └── story_service.py     # 全流程服务
├── infra/               # 基础设施层
│   ├── base.py              # 统一基类
│   ├── logger.py            # 日志封装
│   └── exceptions.py        # 异常定义
└── scripts/             # 脚本入口
    └── auto-create-story-new.py  # 新架构入口
```

---

## 🎯 核心功能

### 1. 智能选题
```python
from core.topic_selector import TopicSelector

selector = TopicSelector()
topics = selector.select_topics(platform="FANQIE", limit=3)
```

### 2. 智能路由
```python
from core.router import StoryRouter

router = StoryRouter()
engine_type = router.route({"标题": "重生后我打脸了全家", "标签": ["重生", "逆袭"]})
# 返回："pro_v4"（爽文）
```

### 3. 故事创作
```python
# 情绪文
from core.hybrid_engine import HybridStoryEngine
engine = HybridStoryEngine()
result = engine.create("冰湖离世，今生再无重逢", ["情感", "遗憾"])

# 爽文
from core.pro_v4_engine import ProV4Engine
engine = ProV4Engine()
result = engine.create("重生后我打脸了全家", ["重生", "逆袭"])
```

### 4. 咪蒙优化
```python
from core.mimeng_optimizer import MimengOptimizer

optimizer = MimengOptimizer()
report = optimizer.optimize("标题", "故事内容", ["标签"])
print(report["Overall Rating"])  # S/A/B/C
```

---

## ⚙️ 配置说明

### 环境变量（.env 文件）
```bash
# 飞书配置
FEISHU_APP_TOKEN=JjG8bSk5CamvWYsulXtcGFXanef
FEISHU_WEBHOOK=https://open.feishu.cn/open-apis/bot/v2/hook/xxx
FEISHU_TABLE_ID=xxx

# LLM 配置
QWEN_API_KEY=sk-xxx
```

### 代码配置（config/settings.py）
```python
from config.settings import settings

# 平台配置
settings.platform.DEFAULT_PLATFORM  # "FANQIE"

# 创作配置
settings.creation.HYBRID_WORD_COUNT  # (8000, 10000)
settings.creation.PRO_V4_WORD_COUNT  # (10000, 12000)

# 路径配置
settings.path.STORIES_DIR  # "/home/administrator/.openclaw/workspace/stories"

# 飞书配置
settings.lark.WIKI_SPACE_ID  # "7625657051364003021"
```

---

## 📊 创作流程

```
1. 智能选题 → 2. 智能路由 → 3. 故事创作 → 4. 质量检测 → 
5. 保存故事 → 6. 知识库同步 → 7. 飞书推送
```

### 详细流程
```
Step 1: 选题
  └─ 读取今日素材
  └─ 筛选高质量（热度>10 万）
  └─ 选择前 3 个

Step 2: 路由
  └─ 分析关键词
  └─ 情绪文 → hybrid 引擎
  └─ 爽文 → pro_v4 引擎

Step 3: 创作
  └─ 生成剧情主线
  └─ LLM 生成故事
  └─ 润色优化

Step 4: 质检
  └─ AI 比例检测（<15%）
  └─ 咪蒙爆文检测
  └─ 合规检测

Step 5: 保存
  └─ 写入 stories/目录
  └─ 生成 Markdown 文件

Step 6: 知识库
  └─ 创建飞书云文档
  └─ 同步到「猫猫故事汇」

Step 7: 推送
  └─ 飞书机器人通知
  └─ 含统计信息 + 知识库链接
```

---

## 🔧 模块使用

### 单独使用选题系统
```python
from core.topic_selector import TopicSelector

selector = TopicSelector()
topics = selector.select_topics(limit=5)

for topic in topics:
    print(topic.get("素材标题"))
```

### 单独使用咪蒙优化
```python
from core.mimeng_optimizer import MimengOptimizer

optimizer = MimengOptimizer()
report = optimizer.optimize(
    title="测试标题",
    content="故事内容...",
    tags=["测试"]
)

print(f"爆款等级：{report['Overall Rating']}")
print(f"综合得分：{report['Overall Score']}")
```

### 单独使用数据层
```python
from datalayer.material_repo import MaterialRepository

repo = MaterialRepository()
materials = repo.get_today_materials()
high_quality = repo.get_high_quality_materials(min_heat=100000, limit=10)
```

---

## ⚠️ 注意事项

### 1. 环境依赖
```bash
pip3 install -r requirements.txt
```

### 2. API Key 配置
```bash
# .env 文件必须存在
cp .env.example .env
# 编辑 .env 填入 API Key
```

### 3. 14:00 创作保障
- ✅ 原有 `auto-create-story-pro-v4.py` 保持不变
- ✅ 新架构 `auto-create-story-new.py` 可选使用
- ✅ 建议先测试再切换 Cron

---

## 📈 性能指标

| 指标 | 标准 | 实际 |
|------|------|------|
| 创作速度 | 20-26 分钟/故事 | ~20 分钟 |
| AI 比例 | <15% | ~5% |
| 爆款率 | S 级>30% | 待统计 |
| 知识库同步 | 100% | 待统计 |

---

## 🐛 故障排查

### 问题 1：LLM 调用失败
```bash
# 检查 API Key
echo $QWEN_API_KEY

# 测试连通性
python3 -c "from openai import OpenAI; print('OK')"
```

### 问题 2：飞书推送失败
```bash
# 检查 Webhook
curl -X POST "https://open.feishu.cn/open-apis/bot/v2/hook/xxx" \
  -H "Content-Type: application/json" \
  -d '{"msg_type":"text","content":{"text":"test"}}'
```

### 问题 3：素材文件不存在
```bash
# 检查采集是否运行
ls /home/administrator/.openclaw/workspace/data/materials/$(date +%Y-%m-%d)/
```

---

## 📚 相关文档

- [架构重构报告](docs/architecture_refactor_report.md)
- [MEMORY.md](MEMORY.md) - 长期记忆
- [USER.md](USER.md) - 用户信息
- [SOUL.md](SOUL.md) - 核心身份

---

**最后更新：** 2026-04-11 12:54  
**维护者：** 创作猫团队
