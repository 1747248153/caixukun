import AppKit

enum PetMode {
    case dance
    case basketball
}

final class PetView: NSView {
    weak var controller: PetController?
    private var mouseDownScreenPoint = NSPoint.zero
    private var windowOriginAtMouseDown = NSPoint.zero
    private var didDrag = false

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        mouseDownScreenPoint = NSEvent.mouseLocation
        windowOriginAtMouseDown = window?.frame.origin ?? .zero
        didDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        let current = NSEvent.mouseLocation
        let dx = current.x - mouseDownScreenPoint.x
        let dy = current.y - mouseDownScreenPoint.y
        if hypot(dx, dy) >= 4 {
            didDrag = true
        }
        controller?.moveWindow(to: NSPoint(
            x: windowOriginAtMouseDown.x + dx,
            y: windowOriginAtMouseDown.y + dy
        ))
    }

    override func mouseUp(with event: NSEvent) {
        if !didDrag {
            controller?.toggleMode()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        controller?.showContextMenu(event: event)
    }
}

final class PetController: NSObject {
    private static let frameCount = 120
    private static let framesPerSecond = 15.0
    private static let windowSize = NSSize(width: 176, height: 230)

    let window: NSWindow
    private let rootView: PetView
    private let imageView = NSImageView()
    private let danceFrames: [NSImage]
    private let basketballFrames: [NSImage]
    private var timer: Timer?
    private var mode: PetMode = .dance
    private var modeStartTime = ProcessInfo.processInfo.systemUptime
    private var displayedFrame = -1

    override init() {
        func loadFrames(prefix: String) -> [NSImage] {
            (0..<Self.frameCount).map { index in
                let name = String(format: "%@_%03d", prefix, index + 1)
                guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
                      let image = NSImage(contentsOf: url) else {
                    fatalError("缺少动作帧：\(name).png")
                }
                return image
            }
        }

        danceFrames = loadFrames(prefix: "dance")
        basketballFrames = loadFrames(prefix: "basketball")

        rootView = PetView(frame: NSRect(origin: .zero, size: Self.windowSize))
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        super.init()

        rootView.controller = self
        rootView.wantsLayer = true
        rootView.layer?.backgroundColor = NSColor.clear.cgColor

        imageView.frame = rootView.bounds
        imageView.autoresizingMask = [.width, .height]
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.wantsLayer = true
        imageView.layer?.magnificationFilter = .linear
        imageView.layer?.minificationFilter = .linear
        rootView.addSubview(imageView)

        window.contentView = rootView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false
        window.isMovableByWindowBackground = false
        window.isReleasedWhenClosed = false

        positionInitially()
        setMode(.dance)
        startTimer()
    }

    deinit {
        timer?.invalidate()
    }

    func show() {
        window.orderFrontRegardless()
    }

    func moveWindow(to origin: NSPoint) {
        window.setFrameOrigin(origin)
    }

    func toggleMode() {
        setMode(mode == .dance ? .basketball : .dance)
    }

    @objc private func chooseDance() {
        setMode(.dance)
    }

    @objc private func chooseBasketball() {
        setMode(.basketball)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    func showContextMenu(event: NSEvent) {
        let menu = NSMenu()

        let danceItem = NSMenuItem(
            title: "只因你太美舞蹈",
            action: #selector(chooseDance),
            keyEquivalent: ""
        )
        danceItem.target = self
        danceItem.state = mode == .dance ? .on : .off
        menu.addItem(danceItem)

        let basketballItem = NSMenuItem(
            title: "篮球运球",
            action: #selector(chooseBasketball),
            keyEquivalent: ""
        )
        basketballItem.target = self
        basketballItem.state = mode == .basketball ? .on : .off
        menu.addItem(basketballItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "退出桌宠", action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)
        NSMenu.popUpContextMenu(menu, with: event, for: rootView)
    }

    private func positionInitially() {
        guard let visible = NSScreen.main?.visibleFrame else { return }
        window.setFrameOrigin(NSPoint(
            x: visible.maxX - Self.windowSize.width - 24,
            y: visible.minY + 18
        ))
    }

    private func setMode(_ newMode: PetMode) {
        mode = newMode
        modeStartTime = ProcessInfo.processInfo.systemUptime
        displayedFrame = -1
        renderCurrentFrame()
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.renderCurrentFrame()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func renderCurrentFrame() {
        let elapsed = ProcessInfo.processInfo.systemUptime - modeStartTime
        let index = Int(elapsed * Self.framesPerSecond) % Self.frameCount
        guard index != displayedFrame else { return }
        displayedFrame = index
        imageView.image = mode == .dance ? danceFrames[index] : basketballFrames[index]
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: PetController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = PetController()
        controller?.show()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

if CommandLine.arguments.contains("--validate-assets") {
    var decoded = 0
    var invalidSize = 0
    for prefix in ["dance", "basketball"] {
        for index in 1...120 {
            let name = String(format: "%@_%03d", prefix, index)
            guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
                  let image = NSImage(contentsOf: url) else {
                fatalError("资源自检失败：\(name).png")
            }
            decoded += 1
            if image.size != NSSize(width: 176, height: 230) {
                invalidSize += 1
            }
        }
    }
    print("资源自检通过：解码 \(decoded) 帧，尺寸异常 \(invalidSize) 帧")
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}
