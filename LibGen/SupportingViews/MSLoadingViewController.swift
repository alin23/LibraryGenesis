//
//  LoadingViewController.swift
//  MSUIKit
//
//  Created by Martin Stamenkovski on 11/30/19.
//  Copyright © 2019 martinstamenkovski. All rights reserved.
//

import UIKit

// MARK: - MSLoadingViewController

public final class MSLoadingViewController: UIViewController {
    public init(width: CGFloat = 150, height: CGFloat = 100) {
        super.init(nibName: nil, bundle: nil)
        self.width = width
        self.height = height
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var hasBlurEffect = false

    public var message = "Please wait..." {
        willSet {
            loadingView.labelDescription.text = newValue
        }
    }

    public var indicatorColor: UIColor! {
        willSet {
            self.loadingView.loadingIndicator.color = newValue
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupSubview()
    }

    private let loadingView: LoadingView = {
        let loadingView = LoadingView()
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        return loadingView
    }()

    private var width: CGFloat!
    private var height: CGFloat!

    private var blurEffectView: UIVisualEffectView!

    private func setupSubview() {
        view.addSubview(loadingView)

        loadingView.layer.cornerRadius = 8

        let constraints = [
            loadingView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loadingView.widthAnchor.constraint(equalToConstant: width),
            loadingView.heightAnchor.constraint(equalToConstant: height),
        ]
        loadingView.labelDescription.text = message
        NSLayoutConstraint.activate(constraints)

        setupLoadingViewColor()
        setupLoadingViewShadow()
    }

    // MARK: - Background color OR blur effect

    private func setupBackground() {
        if hasBlurEffect {
            setupBlurEffectView()
        } else {
            if #available(iOS 13.0, *) {
                self.view.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.5)
            } else {
                view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.4)
            }
        }
    }

    // MARK: - LoadingView Background color

    private func setupLoadingViewColor() {
        if #available(iOS 13.0, *) {
            self.loadingView.backgroundColor = .systemBackground
        } else {
            loadingView.backgroundColor = .white
        }
    }

    // MARK: - LoadingView Shadow color

    private func setupLoadingViewShadow() {
        if #available(iOS 13.0, *) {
            self.loadingView.layer.shadowColor = UIColor.secondaryLabel.cgColor
        } else {
            loadingView.layer.shadowColor = UIColor.lightGray.cgColor
        }
        loadingView.layer.shadowOpacity = 0.5
        loadingView.layer.shadowOffset = .zero
        loadingView.layer.shadowRadius = 1.2
    }
}

// MARK: - BlurEffect setup

extension MSLoadingViewController {
    func setupBlurEffectView() {
        let blurEffect: UIBlurEffect
        let blurAlpha: CGFloat
        if #available(iOS 13.0, *) {
            blurEffect = UIBlurEffect(style: .systemChromeMaterialDark)
            blurAlpha = 0.8
        } else {
            blurEffect = UIBlurEffect(style: .dark)
            blurAlpha = 0.4
        }
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.alpha = blurAlpha
        blurEffectView.frame = view.bounds
        view.insertSubview(blurEffectView, at: 0)
    }
}

// MARK: - LoadingView

// MARK: - LoadingView

private final class LoadingView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSubviews()
    }

    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 15
        return stackView
    }()

    let loadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator: UIActivityIndicatorView!
        if #available(iOS 13.0, *) {
            loadingIndicator = UIActivityIndicatorView(style: .medium)
        } else {
            loadingIndicator = UIActivityIndicatorView(style: .gray)
        }
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        loadingIndicator.color = .systemBlue
        return loadingIndicator
    }()

    let labelDescription: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        if #available(iOS 13.0, *) {
            label.textColor = .label
        } else {
            label.textColor = .black
        }
        return label
    }()

    func setupSubviews() {
        stackView.addArrangedSubview(loadingIndicator)
        stackView.addArrangedSubview(labelDescription)

        addSubview(stackView)

        let constraints = [
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
