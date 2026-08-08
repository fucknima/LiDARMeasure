# Third Party Notices

LiDARMeasure 当前没有复制第三方仓库的源代码；核心能力全部来自 Apple SDK（ARKit、RealityKit、RoomPlan、Vision、Accelerate、simd、AVFoundation、Photos）。因此没有需要随本仓库分发的第三方源代码许可证文件。

## Apple — Depth Cloud sample

Source: [Displaying a point cloud using scene depth](https://developer.apple.com/documentation/arkit/displaying-a-point-cloud-using-scene-depth)

License: Apple Sample Code License（仅作为 API/算法参考，未复制其源文件）

Used for: SceneDepth、confidenceMap、深度点云采样思路。

Modified: N/A（本项目独立实现）

## 调研但未复用的 GitHub 项目

以下项目用于比较 API 组织方式和许可证，不复制其源代码：

- [cedanmisquith/SwiftUI-LiDAR](https://github.com/cedanmisquith/SwiftUI-LiDAR) — MIT，偏场景网格扫描与 OBJ 导出。
- [holg/RoomPlanExampleApp](https://github.com/holg/RoomPlanExampleApp) — RoomPlan 示例，使用其 README/目录作为参考，不作为本项目依赖。
- [philipturner/lidar-scanning-app](https://github.com/philipturner/lidar-scanning-app) — MIT，偏网格扫描导出；因其包含外部来源代码说明，本项目没有复制。

本项目最终选择 Apple SDK 的官方实现，以减少旧 API、外部依赖和许可证传播风险。

## Apple — Recognizing Objects in Live Capture

Source: [Recognizing Objects in Live Capture](https://developer.apple.com/documentation/vision/recognizing-objects-in-live-capture)

License: Apple Sample Code License（仅作为 Vision 请求流程参考，未复制其源文件）

Used for: Vision 物体分类与归一化 bounding box 的集成思路。

Modified: N/A（本项目独立实现）
