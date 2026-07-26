# 只因你太美桌宠：macOS、Windows、Android、iPhone

四个平台使用相同的透明全身动作素材：

- 舞蹈模式：120 帧，15 FPS，约 8 秒循环。
- 篮球模式：120 帧，15 FPS，约 8 秒循环。
- 点击人物切换模式，按住人物拖动可移动。
- 不读取指针方向，不追随鼠标，也不会按鼠标方向运球。

## macOS

文件：`只因你太美桌宠-120帧版.app`

- 支持 macOS 13 及以上，兼容 Apple 芯片和 Intel。
- 首次启动若被系统阻止，请在 Finder 中右键应用，选择“打开”。
- 右键人物可直接选择模式或退出。

## Windows

文件：`只因你太美桌宠-Windows.zip`

1. 完整解压 ZIP，不能直接在压缩包预览窗口中运行。
2. 保持 `只因你太美桌宠.exe` 与 `frames` 文件夹在同一目录。
3. 双击 EXE 启动。
4. 右键人物可选择模式或退出。

支持 64 位 Windows 10 和 Windows 11。程序未购买商业代码签名证书；若 SmartScreen 提示，请确认文件来源后选择“更多信息”→“仍要运行”。

## Android

文件：`只因你太美桌宠-Android.apk`

1. 把 APK 发送到 Android 手机并安装；系统可能要求允许该文件管理器“安装未知应用”。
2. 打开应用，点击“启动悬浮桌宠”。
3. 按提示授予“显示在其他应用上层”权限。
4. 点击悬浮人物切换模式，按住拖动可移动。
5. 如需关闭，重新打开应用并点击“关闭悬浮桌宠”。

支持 Android 8.0 及以上。APK 已使用本地发布证书签名。

## iPhone

文件：`只因你太美桌宠-iPhone-Xcode工程.zip`

支持 iOS 15 及以上的 iPhone。由于 iOS 不允许普通应用覆盖在其他应用上方，iPhone 版桌宠运行在自己的 App 界面中，切换到其他 App 后不会继续悬浮显示。

### 使用 Xcode 安装

1. 在 Mac App Store 安装最新版 Xcode。
2. 解压 iPhone 工程并打开 `只因你太美桌宠-iOS.xcodeproj`。
3. 用数据线或无线调试连接 iPhone，并在手机上选择“信任”。
4. 在 Xcode 中选择 `BasketPetIOS` Target，打开 `Signing & Capabilities`。
5. 勾选 `Automatically manage signing`，在 `Team` 中选择自己的 Apple ID 开发团队。
6. 如果 Bundle Identifier 冲突，把 `com.codex.basketpet.ios` 改成自己的唯一标识。
7. 在 Xcode 顶部选择自己的 iPhone，然后点击运行按钮。
8. 若手机提示开发者不受信任，请按系统提示在“设置 → 通用 → VPN 与设备管理”中信任。

当前提供的是完整 Xcode 工程而不是签名 IPA，因为 IPA 必须使用安装者自己的 Apple 开发者身份签名。免费 Apple ID 签名通常需要定期重新安装；长期公开分发需要 Apple Developer Program 和 App Store/TestFlight。

公开影像素材及人物形象的相关权利归原权利人所有，请仅作个人桌面娱乐使用。
