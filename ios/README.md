# iOS 构建说明

iOS 工程已经生成，并配置了相机、局域网访问及本地 HTTP Agent 所需权限。

正式的 `.ipa` 必须在 macOS 上使用 Xcode 构建和签名，Windows 无法完成 Apple 签名流程。

在 Mac 上安装 Flutter、Xcode 和 CocoaPods 后，在项目根目录执行：

```bash
flutter pub get
cd ios
pod install
open Runner.xcworkspace
```

在 Xcode 的 **Signing & Capabilities** 中选择自己的 Apple Developer Team，并确认 Bundle Identifier 唯一，然后连接 iPhone 运行或归档。

当前工程允许访问局域网 HTTP 地址，以便连接同一 Wi-Fi 下的电脑 Agent。若提交 App Store，应根据实际网络方案重新评估 ATS 例外，并优先改用 HTTPS。
