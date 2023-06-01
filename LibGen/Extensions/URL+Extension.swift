//
//  URL+Extension.swift
//  LibGen
//
//  Created by Martin Stamenkovski on 3/23/20.
//  Copyright © 2020 Stamenkovski. All rights reserved.
//

import Foundation

extension URL {
    static let baseURL = URL(string: "http://libgen.rs/json.php")!

    static func latestURLHTML(with page: Int) -> URL {
        URL(string: "http://libgen.rs/search.php?mode=last&view=simple&column=def&sort=def&sortmode=ASC&page=\(page)")!
    }

    static func latestFiction(with page: Int) -> URL {
        URL(string: "https://libgen.rs/fiction/recent?page=\(page)")!
    }

    static var search: URL {
        URL(string: "https://libgen.rs")!
    }

    static var searchFiction: URL {
        URL(string: "https://libgen.rs/fiction")!
    }

    static func image(with url: String?) -> URL? {
        guard let url else { return nil }
        return URL(string: "http://libgen.rs/covers/\(url)")
    }
}
