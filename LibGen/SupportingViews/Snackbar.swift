//
//  Snackbar.swift
//  LibGen
//
//  Created by Martin Stamenkovski on 3/24/20.
//  Copyright © 2020 Stamenkovski. All rights reserved.
//

import UIKit

class Snackbar: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        if #available(iOS 13.0, *) {
            self.backgroundColor = .secondarySystemBackground
        } else {
            backgroundColor = .lightGray
        }
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.axis = .horizontal
        return stackView
    }()

    var labelMessage: UILabel = {
        let label = UILabel()
        if #available(iOS 13.0, *) {
            label.textColor = .label
        } else {
            label.textColor = .black
        }
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    var buttonAction: UIButton = {
        let button = UIButton()
        button.setTitle("Retry", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.setTitleColor(UIColor.systemBlue.withAlphaComponent(0.5), for: .highlighted)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(onRetryAction(sender:)), for: .touchUpInside)
        return button
    }()

    var onRetry: (() -> Void)?

    var message: String? {
        willSet {
            labelMessage.text = newValue
        }
    }

    private func setupSubviews() {
        addSubview(stackView)
        stackView.addArrangedSubview(labelMessage)
        stackView.addArrangedSubview(buttonAction)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            buttonAction.widthAnchor.constraint(equalToConstant: 60),
        ])

        setupShadow()
    }

    private func setupShadow() {
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = .zero
        layer.shadowRadius = 5
        layer.cornerRadius = 12
    }

    @objc
    private func onRetryAction(sender: UIButton) {
        onRetry?()
    }
}
