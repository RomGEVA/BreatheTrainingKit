import UIKit
import SwiftUI
import OneSignalFramework

class LoadingSplash: UIViewController {

    // Читаем из UserDefaults напрямую
    private var hasCompletedOnboarding: Bool {
        return UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }

    let loadingLabel = UILabel()
    let loadingImage = UIImageView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupFlow()

    }

    private func setupUI() {
        print("start setupUI")
        view.addSubview(loadingImage)
        loadingImage.image = UIImage(named: "Launch")

        loadingImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingImage.topAnchor.constraint(equalTo: view.topAnchor),
            loadingImage.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingImage.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingImage.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupFlow() {
        CheckURLService.checkURLStatus { is200 in
            DispatchQueue.main.async {
                if is200 {
                    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                        appDelegate.restrictRotation = .all
                    }

                    let link = "https://sportfbf.site/s5PtYzNT?push=\(OneSignal.User.onesignalId ?? "NIHUYA")"
                    let vc = WebviewVC(url: URL(string: link)!)
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true)
                } else {
                    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                        appDelegate.restrictRotation = .portrait
                    }
                        let swiftUIView = StartView()
                        let hostingController = UIHostingController(rootView: swiftUIView)
                        hostingController.modalPresentationStyle = .fullScreen
                        self.present(hostingController, animated: true)
                }
            }
        }
    }
}

// Расширение для удобного доступа к имени уведомления
extension Notification.Name {
    static let didCompleteOnboarding = Notification.Name("didCompleteOnboarding")
}




