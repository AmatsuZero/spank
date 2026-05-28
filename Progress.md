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
- 当前基线：`go test ./...` 仍有既有失败（`TestAmplitudeToVolume`）。

## Next Step
按需开始提交拆分（建议按 #8→#13→#14→#11→#12→#10→#9 顺序提交），或继续推进 `cmd/spank` 入口迁移。
