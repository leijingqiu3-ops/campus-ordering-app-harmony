# 校园食堂 · HarmonyOS 点餐 App

基于 HarmonyOS **ArkTS / ArkUI（Stage 模型）** 的校园点餐应用，内置 **AI 点餐助手**（DeepSeek Chat API）。
课程/实习项目，覆盖从菜品浏览、购物车、下单、取餐到个人中心的完整链路。

## 功能

- **店铺与菜品浏览**：多店铺切换、分类菜单、评分与月销量展示
- **购物车与结算**：加购、数量增减、金额汇总、提交订单
- **订单与取餐**：订单记录、取餐状态
- **个人中心与设置**：账号信息、历史订单
- **登录 / 注册**：本地账号体系，登录态持久化
- **AI 点餐助手**：把当前店铺与菜品数据拼成上下文注入 system prompt，
  支持自然语言推荐、菜单问答、口味偏好询问

## 技术栈

| 层 | 选型 |
|---|---|
| 平台 | HarmonyOS 5.1.1（API 19），Stage 模型 |
| UI | ArkTS + ArkUI 声明式 UI |
| 网络 | `@kit.NetworkKit` 的 `http` 模块 |
| 存储 | `@kit.ArkData` 的 `preferences` |
| 大模型 | DeepSeek `chat/completions`（OpenAI 兼容协议） |

## 目录结构

```
.
├── AppScope/                       # 应用级配置与资源
├── entry/                          # 主模块
│   └── src/main/
│       ├── ets/
│       │   ├── entryability/       # Ability 生命周期
│       │   ├── pages/
│       │   │   ├── Index.ets       # 页面与业务逻辑（首页/菜单/购物车/订单/我的/登录）
│       │   │   └── components/
│       │   │       └── AiChatPage.ets   # AI 点餐助手对话页
│       │   └── services/
│       │       ├── AiService.ets        # DeepSeek 调用与菜单上下文构造
│       │       ├── Secrets.ets.example  # API Key 模板（真实文件不入库）
│       │       └── Types.ets
│       └── resources/              # 图片、颜色、字符串等资源
├── build-profile.json5
└── oh-package.json5
```

## 运行

1. 安装 **DevEco Studio 5.1** 及以上，SDK 选择 **API 19（5.1.1）**。
2. 复制密钥模板并填入自己的 Key：

   ```bash
   cp entry/src/main/ets/services/Secrets.ets.example       entry/src/main/ets/services/Secrets.ets
   ```

   编辑 `Secrets.ets`，把 `YOUR_API_KEY_HERE` 换成你的 DeepSeek API Key。
3. 用 DevEco Studio 打开工程，选择 `entry` 模块，运行到模拟器或真机。

## 安全说明

- `Secrets.ets` 已在 `.gitignore` 中排除，仓库内只保留 `Secrets.ets.example` 占位模板。
- 客户端直连大模型 API 仅用于学习演示：真实产品应改为**服务端代理**，
  由后端持有密钥并做鉴权、限流与用量统计，避免密钥下发到客户端被反编译提取。
- 如密钥曾出现在截图、日志或公开仓库中，请立即在控制台**吊销并轮换**。

## 已知限制

- 数据来自 `SeedRepository` 内置种子数据，未接入真实后端与支付。
- 单文件承载主要页面逻辑（`Index.ets`），后续可按页面拆分组件。
- 未做无障碍与多端适配（当前仅 phone）。

## License

仅用于学习与作品展示。
