//
//  DetailsViewController.swift
//  LibGen
//
//  Created by Martin Stamenkovski INS on 3/23/20.
//  Copyright © 2020 Stamenkovski. All rights reserved.
//

import UIKit

// MARK: - DetailsViewController

class DetailsViewController: UIViewController {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageViewHeader: UIImageView!

    @IBOutlet var buttonExpandDescription: UIButton!
    @IBOutlet var buttonDownload: UIButton!

    @IBOutlet var labelTitle: UILabel!
    @IBOutlet var labelAuthor: UILabel!
    @IBOutlet var labelYear: UILabel!
    @IBOutlet var labelLanguage: UILabel!
    @IBOutlet var labelPublisher: UILabel!
    @IBOutlet var labelPages: UILabel!
    @IBOutlet var labelFileType: UILabel!

    @IBOutlet var labelDescription: UILabel!

    @IBOutlet var imageViewHeaderHeight: NSLayoutConstraint!

    var book: Book!
    weak var parentView: UIViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBookData()
        setupStretchyHeader()
        if let view = parentView as? LatestViewController, book.coverURL == nil {
            view.service.fetchDetails(book: book) { book in
                self.book = book
                self.setupBookData()
                self.setupStretchyHeader()
            }
        } else if let view = parentView as? SearchBookViewController, book.coverURL == nil {
            view.service.fetchDetails(book: book) { book in
                self.book = book
                self.setupBookData()
                self.setupStretchyHeader()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.transparent()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.removeTransparency()
    }

    @IBAction
    func actionExpandDescription(_ sender: UIButton) {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .curveLinear], animations: {
            if self.labelDescription.numberOfLines == 3 {
                self.labelDescription.numberOfLines = 0
                self.buttonExpandDescription.transform = CGAffineTransform(rotationAngle: .pi)
            } else {
                self.labelDescription.numberOfLines = 3
                self.buttonExpandDescription.transform = .identity
            }
            self.view.layoutIfNeeded()
        }, completion: nil)
    }

    @IBAction
    func actionDownload(_ sender: UIButton) {
        if let mirrors = book.mirrors, mirrors.isNotEmpty {
            Alert.showMirrors(on: self, sourceView: buttonDownload, with: mirrors) { url in
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                } else {
                    Alert.urlError(on: self)
                }
            }
            return
        }

        guard let md5 = book.md5 else { return }
        Alert.showMirrors(on: self, sourceView: buttonDownload, for: md5) { url in
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                Alert.urlError(on: self)
            }
        }
    }

    private var imageViewHeaderOriginalHeight: CGFloat!

    private func setupStretchyHeader() {
        imageViewHeaderOriginalHeight = imageViewHeaderHeight.constant
        scrollView.delegate = self
        scrollView.contentInset = .init(top: imageViewHeaderOriginalHeight, left: 0, bottom: 0, right: 0)
    }

    private func setupBookData() {
        if let url = book.coverURL {
            imageViewHeader.kf.indicatorType = .activity
            if url.contains("/fictioncovers/") {
                imageViewHeader.kf.setImage(with: URL(string: url))
            } else {
                imageViewHeader.kf.setImage(with: URL.image(with: url))
            }
        }
        labelTitle.text = book.title
        labelYear.text = book.year
        labelAuthor.text = book.author
        labelLanguage.text = book.language
        labelPublisher.text = book.publisher ?! "N/A"
        labelPages.text = book.pages ?! "N/A"
        if let type = book.fileType, let size = book.fileSize {
            labelFileType.text = "\(type) / \(size)"
        } else {
            labelFileType.text = book.fileType ?! book.fileSize ?! "N/A"
        }
        labelDescription.text = (book.description ?! "N/A").html
    }
}

// MARK: UIScrollViewDelegate

extension DetailsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let y = imageViewHeaderOriginalHeight - (scrollView.contentOffset.y + imageViewHeaderOriginalHeight)
        let height = min(max(y, 100), UIScreen.main.bounds.height)
        imageViewHeaderHeight.constant = height
    }
}
