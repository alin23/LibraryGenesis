//
//  LatestBookService.swift
//  LibGen
//
//  Created by Martin Stamenkovski on 3/23/20.
//  Copyright © 2020 Stamenkovski. All rights reserved.
//

import Foundation

class LatestBookService: BookService {
    var lastIndex: Int {
        books.count - 1
    }

    func fetchLatestBooks(with page: Int = 1, genre: BookGenre = .fiction) {
        let url: URL = genre == .fiction ? .latestFiction(with: page) : .latestURLHTML(with: page)
        loadBooks(from: url) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(books):
                    self.books.append(contentsOf: books)
                    self.page += 1
                    self.delegate?.didLoadBooks(self)
                case let .failure(error):
                    self.delegate?.didFailedLoadBooks(self, with: error)
                }
                self.isLoading = false
            }
        }
    }

    func loadNextPage() {
        guard !isLoading else { return }
        isLoading = true
        fetchLatestBooks(with: page)
    }

    func refreshBooks() {
        fetchLatestBooks(with: page)
    }

    private var isLoading = false
}
