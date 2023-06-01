//
//  BookTableViewCell.swift
//  LibGen
//
//  Created by Martin Stamenkovski on 3/23/20.
//  Copyright © 2020 Stamenkovski. All rights reserved.
//

import Kingfisher
import UIKit

class BookTableViewCell: UITableViewCell {
    @IBOutlet var imageViewCover: UIImageView!

    @IBOutlet var labelTitle: UILabel!
    @IBOutlet var labelAuthor: UILabel!
    @IBOutlet var labelYear: UILabel!
    @IBOutlet var labelType: UILabel!

    override func prepareForReuse() {
        super.prepareForReuse()
        imageViewCover.image = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setup(with book: Book) {
        labelTitle.text = book.title
        labelAuthor.text = book.author
        labelYear.text = [book.language, book.year]
            .compactMap { $0 }
            .filter(\.isNotEmpty)
            .joined(separator: " | ")
        labelType.text = [book.fileType, book.fileSize]
            .compactMap { $0 }
            .filter(\.isNotEmpty)
            .joined(separator: " / ")

        if let url = book.coverURL {
            imageViewCover.kf.indicatorType = .activity
            if url.contains("/fictioncovers/") {
                imageViewCover.kf.setImage(with: URL(string: url))
            } else {
                imageViewCover.kf.setImage(with: URL.image(with: url))
            }
        }
    }
}
