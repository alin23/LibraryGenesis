//
//  LoadingFooterView.swift
//  LibGen
//
//  Created by Martin Stamenkovski on 3/23/20.
//  Copyright © 2020 Stamenkovski. All rights reserved.
//

import UIKit

class LoadingFooterView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            indicator.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var indicator: UIActivityIndicatorView = {
        let indicator: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            indicator = UIActivityIndicatorView(style: .medium)
            indicator.color = .systemBlue
        } else {
            indicator = UIActivityIndicatorView(style: .white)
            indicator.color = .blue
        }
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        indicator.hidesWhenStopped = true
        return indicator
    }()

    func stopAnimating() {
        if indicator.isAnimating {
            indicator.stopAnimating()
        }
    }

    func startAnimating() {
        indicator.startAnimating()
    }
}
