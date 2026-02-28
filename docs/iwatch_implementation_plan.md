# iWatch FightPet 实施计划

最后更新：2026-02-25

## 1. 目标

将当前 Swift watchOS 项目与最新设计意图对齐，设计来源包括：

- Figma 截图
- `docs/figma_chat_history.txt` 中的产品对话记录

核心目标：

- 保持代码库稳定且可编译。
- 对齐 41mm 手表界面的布局与交互。
- 完成关键玩法闭环（首页、升级、排行榜/对战、运动、重生/孵化）。

## 2. 当前基线（基于现有代码）

- 项目类型：SwiftUI watchOS App（`FightPet Watch App` target）。
- 现有页面：首页、商店、排行榜、对战、运动、重生。
- 现有系统：宠物属性、升级、对战、健康数据、每日奖励、部分重生逻辑。
- 已知阻塞：若未接入包依赖，Firebase 相关会编译失败（`FirebaseCore`、`FirebaseFirestore`）。

## 3. 范围

本期范围：

- 41mm 界面布局精修。
- 首页信息层级与按钮可点击区域优化。
- 三模块升级系统（`Bed`、`Bowl`、`Toy`）及顺序解锁、二级详情页。
- 排行榜到对战链路稳定化。
- 运动奖励“领取后生效”机制。
- 重生 + 孵化完整流程。

本期不做：

- 新后端服务设计。
- 完整埋点/遥测体系建设。

## 4. 执行阶段

## 阶段 P0 - 编译与运行稳定性

任务：

1. 让项目在本地 Debug（watch target）可编译。
2. 处理 Firebase 接入路径（完整接入或降级保护）。
3. 确保启动不崩溃。

主要文件：

- `FightPet Watch App/FightPetApp.swift`
- `FightPet Watch App/Managers/FirebaseManager.swift`
- `FightPet.xcodeproj/project.pbxproj`

退出标准：

- `xcodebuild` 在 watch target 下 Debug 构建通过。

## 阶段 P1 - 41mm 首页布局对齐

任务：

1. 重排顶部区域，提升信息密度。
2. 保留右上角系统时间安全区。
3. 保证 41mm 下关键按钮可点击。
4. 调整快乐值徽章位置，避免遮挡按钮。

主要文件：

- `FightPet Watch App/Views/MainView.swift`
- `FightPet Watch App/Components/TopBar.swift`
- `FightPet Watch App/Components/PetCard.swift`
- `FightPet Watch App/Utils/LayoutConstants.swift`

退出标准：

- 41mm 下首页无裁切、无爆框。
- 关键操作可稳定点击。

## 阶段 P2 - 升级模块与二级详情页

任务：

1. 固定为 3 个模块（`Bed`、`Bowl`、`Toy`）。
2. 强制顺序解锁（1 -> 2 -> 3，前一项 10 级后解锁下一项）。
3. 修复二级升级详情页数值与展示格式。
4. 避免异常展示（如 NaN）。

主要文件：

- `FightPet Watch App/Models/UpgradeItem.swift`
- `FightPet Watch App/Components/UpgradeOptionsView.swift`
- `FightPet Watch App/Views/BuildingDetailView.swift`
- `FightPet Watch App/ViewModels/GameStateManager.swift`

退出标准：

- 三模块都可打开详情页，并显示正确的当前/下一等级信息。
- 锁定与解锁逻辑可复现且稳定。

## 阶段 P3 - 排行榜与对战流程稳定

任务：

1. 校验排行榜数据与排版。
2. 保持挑战入口与每日次数逻辑稳定。
3. 确保返回路径正确回到首页。

主要文件：

- `FightPet Watch App/Views/RankingView.swift`
- `FightPet Watch App/Views/BattleView.swift`
- `FightPet Watch App/ViewModels/GameStateManager.swift`

退出标准：

- `Rank -> Battle -> Result -> Back` 流程无死路、无异常跳转。

## 阶段 P4 - 运动奖励领取机制

任务：

1. 睡眠与运动奖励采用“领取后生效”。
2. 未领取前仅展示预览，不写入最终数据。
3. 领取后及时刷新页面状态，避免旧状态残留。

主要文件：

- `FightPet Watch App/Views/ActivityView.swift`
- `FightPet Watch App/Managers/HealthManager.swift`
- `FightPet Watch App/ViewModels/GameStateManager.swift`

退出标准：

- 奖励在领取前不生效。
- 领取后首页产出数值即时变化。

## 阶段 P5 - 重生与孵化闭环

任务：

1. 重生按钮常驻显示，但仅 99 级可执行。
2. 增加重生确认到孵化流程的状态转换。
3. 增加孵化计时与可选快速孵化。
4. 孵化完成后生成新宠物，并继承设定比例的核心数值。

主要文件：

- `FightPet Watch App/Views/RebirthView.swift`
- `FightPet Watch App/Models/Pet.swift`
- `FightPet Watch App/Models/Player.swift`
- `FightPet Watch App/ViewModels/GameStateManager.swift`

退出标准：

- `Lv.99` 重生流程可端到端走通。
- 孵化后宠物数据合法且可持久化恢复。

## 阶段 P6 - 文案、格式与收口

任务：

1. 明确各页面中英文策略并统一。
2. 统一数字显示规则（含大数格式）。
3. 清理临时调试信息与冗余逻辑。

主要文件：

- `FightPet Watch App/Views/*.swift`
- `FightPet Watch App/Components/*.swift`

退出标准：

- 关键控件文案不溢出、不遮挡。
- 视觉与文案风格一致。

## 5. 风险与依赖

1. Firebase 依赖若未正确接入，会持续阻塞构建。
2. 41mm 空间极小，点击区与排版可能需要多轮微调。
3. 重生/孵化是状态机逻辑，持久化处理不当会造成恢复异常。

## 6. 验收清单

1. App 可启动并稳定进入首页。
2. 顶部区域不与系统时间冲突。
3. `Bed/Bowl/Toy` 升级流程与二级详情页正确。
4. 排行榜与对战链路可完整往返。
5. 运动奖励仅在“领取”后生效。
6. 重生与孵化流程完整且可恢复。

## 7. 待确认决策

需要产品最终确认：

1. 品质体系最终采用：`C/B/A/S` 还是 `A/S/SS`。
2. 各品质继承比例的最终数值。
3. 文案策略：全英文还是中英混排。
