//
//  Book.swift
//  LibGen
//
//  Created by Martin Stamenkovski INS on 3/23/20.
//  Copyright © 2020 Stamenkovski. All rights reserved.
//

import Foundation

struct Book: Codable {
    let title: String
    let year: String?
    let author: String
    let language: String?
    let fileSize: String?
    let md5: String?
    let description: String?
    let coverURL: String?
    let publisher: String?
    let pages: String?
    let fileType: String?
    let series: String?
    let link: String?
    let mirrors: [URL]?
    let isbn: String?

    func with(
        title: String? = nil,
        year: String? = nil,
        author: String? = nil,
        language: String? = nil,
        fileSize: String? = nil,
        md5: String? = nil,
        description: String? = nil,
        coverURL: String? = nil,
        publisher: String? = nil,
        pages: String? = nil,
        fileType: String? = nil,
        series: String? = nil,
        link: String? = nil,
        mirrors: [URL]? = nil,
        isbn: String? = nil
    ) -> Book {
        Book(
            title: title ?? self.title,
            year: year ?? self.year,
            author: author ?? self.author,
            language: language ?? self.language,
            fileSize: fileSize ?? self.fileSize,
            md5: md5 ?? self.md5,
            description: description ?? self.description,
            coverURL: coverURL ?? self.coverURL,
            publisher: publisher ?? self.publisher,
            pages: pages ?? self.pages,
            fileType: fileType ?? self.fileType,
            series: series ?? self.series,
            link: link ?? self.link,
            mirrors: mirrors ?? self.mirrors,
            isbn: isbn ?? self.isbn
        )
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case year
        case author
        case language
        case fileSize = "filesize"
        case md5
        case description = "descr"
        case coverURL = "coverurl"
        case publisher
        case pages
        case fileType = "extension"
        case series
        case link
        case mirrors
        case isbn
    }
}
