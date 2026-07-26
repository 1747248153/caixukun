# 只因你太美桌宠 iPhone 版

## 功能

- 舞蹈模式 120 帧、篮球模式 120 帧，均以 15 FPS 播放。
- 点击人物切换舞蹈和篮球。
- 按住并拖动人物可在屏幕内移动。
- 支持 iOS 15 及以上的 iPhone。

## iOS 系统限制

iPhone 不允许普通应用像 Windows 或 Android 悬浮窗那样覆盖在其他应用上方。因此，这个版本的桌宠运行在自己的 iPhone App 界面中；切换到其他应用后不会继续显示在屏幕上。

## 安装到自己的 iPhone

1. 在 Mac App Store 安装最新版 Xcode。
2. 使用数据线或无线调试连接 iPhone，并在手机上选择“信任”。
3. 双击打开 `只因你太美桌宠-iOS.xcodeproj`。
4. 在 Xcode 左侧选择工程，再选择 `BasketPetIOS` Target。
5. 打开 `Signing & Capabilities`，勾选 `Automatically manage signing`。
6. 在 `Team` 中选择自己的 Apple ID 开发团队。
7. 如果 Bundle Identifier 冲突，把 `com.codex.basketpet.ios` 改成自己的唯一标识。
8. 在 Xcode 顶部选择自己的 iPhone，点击运行按钮。
9. 若 iPhone 提示开发者不受信任，按系统提示在“设置 → 通用 → VPN 与设备管理”中信任。

免费 Apple ID 签名通常需要定期重新安装；用于长期公开分发则需要 Apple Developer Program 和 App Store/TestFlight 发布。
