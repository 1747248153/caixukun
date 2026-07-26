import UIKit

final class PetViewController: UIViewController {
    private enum PetMode {
        case dance
        case basketball

        var title: String {
            switch self {
            case .dance:
                return "只因你太美舞蹈"
            case .basketball:
                return "篮球运球"
            }
        }
    }

    private static let frameCount = 120
    private static let petSize = CGSize(width: 176, height: 230)

    private let gradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let hintLabel = UILabel()
    private let petView = UIView()
    private let imageView = UIImageView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    private var danceFrames: [UIImage] = []
    private var basketballFrames: [UIImage] = []
    private var mode: PetMode = .dance
    private var frameIndex = 0
    private var displayLink: CADisplayLink?
    private var hasPositionedPet = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBackground()
        configureInterface()
        configureGestures()
        loadAnimationFrames()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds

        if !hasPositionedPet {
            hasPositionedPet = true
            petView.center = CGPoint(
                x: view.bounds.midX,
                y: max(view.safeAreaInsets.top + 180, view.bounds.midY)
            )
        } else {
            petView.center = clampedCenter(petView.center)
        }
    }

    deinit {
        displayLink?.invalidate()
    }

    private func configureBackground() {
        view.backgroundColor = UIColor(red: 0.06, green: 0.07, blue: 0.12, alpha: 1)
        gradientLayer.colors = [
            UIColor(red: 0.17, green: 0.12, blue: 0.28, alpha: 1).cgColor,
            UIColor(red: 0.05, green: 0.08, blue: 0.16, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func configureInterface() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "只因你太美桌宠"
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "正在载入 240 帧动作…"
        statusLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        statusLabel.textAlignment = .center
        statusLabel.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        statusLabel.layer.cornerRadius = 16
        statusLabel.layer.masksToBounds = true
        statusLabel.accessibilityLabel = "当前模式"
        view.addSubview(statusLabel)

        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.text = "点击人物切换模式 · 按住拖动人物"
        hintLabel.textColor = UIColor.white.withAlphaComponent(0.66)
        hintLabel.font = .systemFont(ofSize: 13, weight: .medium)
        hintLabel.textAlignment = .center
        hintLabel.numberOfLines = 2
        view.addSubview(hintLabel)

        petView.bounds = CGRect(origin: .zero, size: Self.petSize)
        petView.backgroundColor = .clear
        petView.isAccessibilityElement = true
        petView.accessibilityLabel = "只因你太美桌宠"
        petView.accessibilityHint = "点击切换舞蹈和篮球模式，拖动可移动"
        view.addSubview(petView)

        imageView.frame = petView.bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.isUserInteractionEnabled = false
        petView.addSubview(imageView)

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .white
        loadingIndicator.startAnimating()
        petView.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 32),
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),

            hintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            hintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            hintLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),

            loadingIndicator.centerXAnchor.constraint(equalTo: petView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: petView.centerYAnchor)
        ])
    }

    private func configureGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleMode))
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(movePet(_:)))
        tapGesture.require(toFail: panGesture)
        petView.addGestureRecognizer(tapGesture)
        petView.addGestureRecognizer(panGesture)
    }

    private func loadAnimationFrames() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let dance = self.loadSequence(prefix: "dance")
            let basketball = self.loadSequence(prefix: "basketball")

            DispatchQueue.main.async {
                guard dance.count == Self.frameCount,
                      basketball.count == Self.frameCount else {
                    self.showResourceError()
                    return
                }

                self.danceFrames = dance
                self.basketballFrames = basketball
                self.loadingIndicator.stopAnimating()
                self.statusLabel.text = self.mode.title
                self.frameIndex = 0
                self.imageView.image = dance[0]
                self.startAnimation()
            }
        }
    }

    private func loadSequence(prefix: String) -> [UIImage] {
        var images: [UIImage] = []
        images.reserveCapacity(Self.frameCount)

        for index in 1...Self.frameCount {
            let name = String(format: "%@_%03d", prefix, index)
            guard let url = Bundle.main.url(
                forResource: name,
                withExtension: "png",
                subdirectory: "frames"
            ), let image = UIImage(contentsOfFile: url.path) else {
                return images
            }
            images.append(image)
        }
        return images
    }

    private func startAnimation() {
        displayLink?.invalidate()
        let displayLink = CADisplayLink(target: self, selector: #selector(advanceFrame))
        displayLink.preferredFrameRateRange = CAFrameRateRange(
            minimum: 15,
            maximum: 15,
            preferred: 15
        )
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }

    @objc
    private func advanceFrame() {
        let frames = mode == .dance ? danceFrames : basketballFrames
        guard frames.count == Self.frameCount else { return }
        frameIndex = (frameIndex + 1) % Self.frameCount
        imageView.image = frames[frameIndex]
    }

    @objc
    private func toggleMode() {
        guard danceFrames.count == Self.frameCount,
              basketballFrames.count == Self.frameCount else { return }
        mode = mode == .dance ? .basketball : .dance
        frameIndex = 0
        statusLabel.text = mode.title
        petView.accessibilityValue = mode.title
        imageView.image = (mode == .dance ? danceFrames : basketballFrames)[0]

        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
    }

    @objc
    private func movePet(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let proposedCenter = CGPoint(
            x: petView.center.x + translation.x,
            y: petView.center.y + translation.y
        )
        petView.center = clampedCenter(proposedCenter)
        gesture.setTranslation(.zero, in: view)
    }

    private func clampedCenter(_ proposedCenter: CGPoint) -> CGPoint {
        let safeFrame = view.bounds.inset(by: view.safeAreaInsets)
        let halfWidth = petView.bounds.width / 2
        let halfHeight = petView.bounds.height / 2
        let minimumX = safeFrame.minX + halfWidth
        let maximumX = safeFrame.maxX - halfWidth
        let minimumY = safeFrame.minY + halfHeight
        let maximumY = safeFrame.maxY - halfHeight

        return CGPoint(
            x: min(max(proposedCenter.x, minimumX), max(minimumX, maximumX)),
            y: min(max(proposedCenter.y, minimumY), max(minimumY, maximumY))
        )
    }

    private func showResourceError() {
        loadingIndicator.stopAnimating()
        statusLabel.text = "动作资源载入失败"
        let alert = UIAlertController(
            title: "无法载入桌宠",
            message: "应用包中的 240 帧动作资源不完整，请重新安装。",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}
