# 项目状态

当前版本：`0.1.0`（build `1`）

## 已完成

- [x] XcodeGen 可重生成工程骨架
- [x] SwiftUI + MVVM + Services 目录结构
- [x] ARKit 能力检测与非 LiDAR 降级配置
- [x] 手动距离与长宽高测量流程
- [x] SceneDepth / confidenceMap 点云采样
- [x] 中位数、MAD、IQR 离群值过滤
- [x] Accelerate/simd OBB 计算
- [x] 自动测量稳定器与质量评分模型
- [x] RoomPlan 结果适配器
- [x] Vision 分类与前景实例分割适配器
- [x] JSON 测量历史、单位设置、截图保存服务
- [x] 单元测试与 macOS GitHub Actions 工作流

## 当前环境限制

本次开发运行在 Windows，未安装 Xcode/Swift，无法在本机执行 `xcodebuild`，也没有真实 LiDAR iPhone。因此代码编译、unsigned IPA、CI artifact 和真实测量精度需要在 macOS runner 与 LiDAR 真机上验证。CI 已包含生成工程、测试、iphoneos Release 编译和 unsigned IPA 打包步骤。

## 下一步

1. 在 macOS 运行 `brew install xcodegen` 后执行 `xcodegen generate` 与 `xcodebuild test`。
2. 用 LiDAR iPhone 验证 RoomPlan 类别、深度坐标转换和 OBB 方向。
3. 根据 A4/银行卡等已知尺寸记录校准测试结果；不自动修改比例。
4. 配置 GitHub remote 后推送，检查 Actions 和 release artifact。

