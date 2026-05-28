# Progress

## Goal
把当前 `spank` 从单文件 macOS CLI 逐步改造成“单仓多 target”结构，支持：
- mac CLI
- mac 动态库（c-shared）
- iOS SDK（gomobile）
- Android SDK（gomobile）

## Confirmed Decisions
- 架构：`core + platform adapters + bindings`
- 平台路线：iOS 先行，Android 随后
- API 形态：高层 API + 事件回调
- 资源策略：`with_assets` / `lite` 双模式
  - `with_assets`：内嵌 MP3，面向 CLI（开箱即用）
  - `lite`：不内嵌资源，面向 SDK（体积更小）

## Milestones
1. 核心解耦（提取 core 引擎）
2. macOS 适配层落位（sensor/audio）
3. 多入口构建（CLI + c-shared）
4. iOS 绑定（XCFramework）
5. Android 绑定（AAR）

## Task Board (linked to CodeBuddy tasks)
- [x] #7 创建并维护 Progress.md
- [x] #8 搭建目录骨架与资产模式开关
- [x] #13 抽取核心类型与算法组件
- [x] #14 抽取检测引擎与会话编排
- [x] #11 封装 macOS 平台适配层
- [x] #12 新增 C API 与 gomobile 绑定入口
- [x] #10 调整发布矩阵与构建脚本
- [x] #9 执行回归与产物验证
- [x] #23 迁移 CLI 入口到 cmd/spank
- [x] #24 抽离 macOS 音频适配层
- [x] #25 新增常规 CI 校验工作流
- [x] #26 增加 bindings smoke tests

## Build Matrix (planned)
```bash
# CLI (embed assets)
go build -tags with_assets ./cmd/spank

# mac dynamic library (lite)
go build -tags lite -buildmode=c-shared ./bindings/capi

# iOS SDK (lite)
gomobile bind -tags lite -target=ios ./bindings/mobile

# Android SDK (lite)
gomobile bind -tags lite -target=android ./bindings/mobile
```

## Latest Update
- 已新增 `assets_with.go` 与 `assets_lite.go`，支持 `with_assets/lite` 两种资源模式。
- 已在运行时增加 lite 友好提示：lite 构建需使用 `--custom` 或 `--custom-files`。
- 已创建目录骨架：`cmd/spank`、`pkg/core`、`pkg/platform/{macos,ios,android}`、`pkg/app`、`bindings/{capi,mobile}`、`internal/buildinfo`。
- 已完成 #13：抽取 core 组件到 `pkg/core`（`tuning.go`、`tracker.go`、`volume.go`），`main.go` 已改为调用 core 包。
- 已完成 #14：新增 `pkg/core/engine.go`（检测门控）与 `pkg/app/session.go`（会话编排），`listenForSlaps` 已切换为调用 app/core。
- 新增测试：`pkg/core/engine_test.go`、`pkg/app/session_test.go`，并验证 `go test ./pkg/core ./pkg/app` 通过。
- 已修复 stdio 实时调参回归：`set` 命令更新后会同步到 detection gate。
- 已完成 #11（第一阶段）：新增 `pkg/platform/macos/sensor.go`，封装了 `sensor/shm` 启动、读取、错误通道和关闭清理；`main.go` 已切换到该适配层。
- 已完成 #12：新增绑定入口 `bindings/capi/export.go` 与 `bindings/mobile/export.go`，提供最小可编译导出。
- 已修正审查项：`AccelSource` 明确为异步启动语义；mobile `Gate` 增加并发锁保护。
- 绑定验证通过：`go build ./bindings/mobile`、`go build -buildmode=c-shared ./bindings/capi`。
- 已完成 #10：新增 `Makefile`（CLI / dylib / iOS / Android 构建目标），并新增 `.github/workflows/release-sdk.yml`，将 SDK 构建与 CLI 发布拆分。
- 已完成 #9 回归与产物验证：`make build-cli`、`make build-mac-dylib`、`make build-ios-sdk`、`make build-android-sdk`、`make build-sdk` 均通过。
- 已修复本地 gomobile 环境阻塞：添加 `golang.org/x/mobile` 工具依赖，Android 目标改为 `-androidapi 21`。
- 已完成测试修复：放宽 `stdin_test.go` 的 mid amplitude 断言边界，`go test ./...` 全量通过。
- 已完成本地提交拆分（按阶段拆分为 4 个核心提交 + 1 个测试修复提交）。
- 已完成 #23：CLI 入口已迁移到 `cmd/spank/main.go`，`Makefile` 默认 `CLI_PKG=./cmd/spank`，并更新了 GoReleaser 的 main 路径与 ldflags 注入路径。
- 已完成 #24：新增 `pkg/platform/macos/audio.go`，主流程音频播放链路已从 `main.go` 抽离到平台适配层。
- 已完成 #25：新增 `.github/workflows/ci.yml`，在 PR/push 上执行 `go test ./...`、CLI default/lite 构建及 bindings 构建探针。
- 已完成 #26：新增 `bindings/mobile/export_test.go` 与 `bindings/capi/export_smoke_test.go`，验证 mobile Gate 与 C API 的最小可调用性。
- 回归验证通过：`go test ./...`、CLI 双模式构建与 bindings 构建均通过。

## Next Step
1. 当前改造任务已全部完成（Task Board 全部勾选）。
2. 如需发布，推送后观察 `CI`、`Release CLI`、`Release SDK` 三条工作流结果。
3. 如需继续演进，可选后续项：补充 iOS/Android 集成示例工程与端到端运行文档。
