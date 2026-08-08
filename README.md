# LiDARMeasure

LiDARMeasure 是一个使用 SwiftUI、ARKit、RealityKit、RoomPlan、Vision、Accelerate 和 simd 的 iOS 现实物体尺寸测量 App。它把 RoomPlan 的系统识别结果与通用 SceneDepth 点云测量结合起来，并始终保留手动测量作为可靠的 fallback。

## 功能

- 自动模式：Vision 分类/前景分割（可用时）+ SceneDepth + 点云 + 重力对齐的二维 PCA OBB。
- 框选模式：在 AR 画面拖动矩形，使用 ROI 深度点云计算物体尺寸。
- 手动长度：点击点 A、点 B，使用世界坐标距离计算长度。
- 手动长宽高：依次点击左下、右下、左上和后角，绘制四点测量结果。
- RoomPlan：在支持的 LiDAR 设备上直接读取系统识别的物体类别、`dimensions` 和 `transform`。
- 测量稳定器：保留最近 15 帧，用中位数平滑，变化小于 2% 且持续若干帧后显示“测量稳定”。
- 质量评分：结合 Tracking、深度置信度、有效点数量、距离和帧间稳定度显示“优秀 / 良好 / 较差”。
- 历史记录：Codable JSON 保存日期、模式、尺寸、单位、质量和截图路径。
- 截图：写入 Documents 并请求 Photos add-only 权限保存到照片图库。
- 设置：mm、cm、m、inch 单位切换；设备能力与版本信息。
- 调试覆盖层：Tracking、Depth、点数、质量和尺寸信息。

## 支持设备

- 最低部署目标：iOS 17。
- LiDAR 设备：启用 `sceneDepth`、`smoothedSceneDepth`；如果支持则启用 mesh reconstruction 和 RoomPlan。
- 非 LiDAR 设备：通过 `ARWorldTrackingConfiguration` 能力 API 自动降级到平面检测、raycast 和手动测量，不通过型号判断，也不会因为缺少深度而崩溃。

## 测量流程

```text
Camera / ARKit
  ├─ RoomPlan 已识别 → 使用 CapturedRoom.Object.dimensions / transform
  └─ 否则 → Vision 分类/前景 mask → ROI + SceneDepth → 点云过滤 → OBB
```

深度点会依次经过 invalid 检查、confidence 检查、中心深度带宽筛选、MAD/IQR 离群值过滤，并通过相机内参和相机 transform 转换为世界坐标。OBB 的高度轴使用 AR 重力方向，水平轴进行稳定的二维 PCA；矩阵和向量操作使用 `simd`/`Accelerate`，没有自定义通用 eigen solver。

## 在 macOS 上编译

当前仓库包含 `project.yml`，使用 XcodeGen 生成 `LiDARMeasure.xcodeproj`：

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project LiDARMeasure.xcodeproj \
  -scheme LiDARMeasure \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

打开真机测试前，在 Xcode 中选择 Apple Developer Team 并配置签名。应用只需要 `NSCameraUsageDescription` 和 `NSPhotoLibraryAddUsageDescription` 两项权限；未配置签名时仍可编译 unsigned Release。

## unsigned IPA

```bash
xcodebuild \
  -project LiDARMeasure.xcodeproj \
  -scheme LiDARMeasure \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

./Scripts/package_unsigned_ipa.sh build 0.1.0
```

输出文件为 `artifacts/LiDARMeasure-v0.1.0-unsigned.ipa`。unsigned IPA 不能直接安装到未授权的真机；需要签名、开发者模式和 provisioning profile 才能安装。

## GitHub Actions

`.github/workflows/build.yml` 在 `push`、`pull_request` 和手动触发时运行：检查 Xcode 版本、安装 XcodeGen、生成工程、运行单元测试、执行 iphoneos Release 编译、打包并上传带版本号的 unsigned IPA artifact。

推送 `v0.1.0` 等 tag 会触发 `.github/workflows/release.yml`，执行相同的编译/打包流程并将 IPA 附加到 GitHub Release。runner 以 `macos-15` 为首选，并在日志中记录实际 `xcodebuild -version`；不假设固定 Xcode 小版本。

## 开源依赖与许可证

本项目没有复制第三方仓库源代码，核心能力使用 Apple SDK。API 参考和许可证说明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。没有引入 GPL/AGPL 代码，也没有额外 Swift Package 依赖。

## 测量限制

ARKit / LiDAR 是辅助测量工具，不是工业计量设备。距离、材质、光照、视角、反光、透明物体、黑色物体、运动和遮挡都会影响结果。建议在约 0.3–3 m 范围内保持手机稳定；过近、过远或 Tracking 受限时应切换手动模式或重新框选。

## 已知问题

- Windows 环境没有 Xcode/Swift，无法本地执行 `xcodebuild`；macOS CI 与真实 LiDAR iPhone 是最终编译/精度验证环境。
- Vision 的系统分类不是专用目标检测模型，未知物体会落入框选 + 深度聚类 fallback。
- RoomPlan 的类别名称使用系统枚举的字符串表示，后续可补充本地化映射。
- 自动模式的 OBB 仍需用 A4、银行卡、纸箱等已知尺寸在真机上记录误差；应用不会偷偷修改比例。

## Roadmap

1. macOS CI 首次运行并修复真实 Xcode API/availability 差异。
2. LiDAR 真机验证屏幕—深度—世界坐标方向、RoomPlan 分类和 OBB 方向。
3. 加入可选的成熟 Core ML 检测模型（单独核对模型体积、许可证和性能）。
4. 增加校准测试报告与更细粒度的截图标注导出。

## 项目状态

详细阶段记录见 [PROJECT_STATUS.md](PROJECT_STATUS.md)。

