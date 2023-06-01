//
//  SearchBookService.swift
//  LibGen
//
//  Created by Martin Stamenkovski on 3/23/20.
//  Copyright © 2020 Stamenkovski. All rights reserved.
//

import Foundation

class SearchBookService: BookService {
    var lastIndex: Int {
        books.count - 1
    }

    var isEmptySearch: Bool {
        page == 1 && books.isEmpty
    }

    func searchBooks(with query: String, and page: Int = 1, genre: BookGenre = .fiction) {
        self.query = query
        guard let url = buildURLComponents(genre: genre) else { return }
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

    func loadNextPage(genre: BookGenre = .fiction) {
        guard !isLoading else { return }
        isLoading = true
        searchBooks(with: query, and: page, genre: genre)
    }

    func refreshBooks(genre: BookGenre = .fiction) {
        searchBooks(with: query, genre: genre)
    }

    func removeAll() {
        page = 1
        books.removeAll()
    }

    private var isLoading = false

    private var query: String!

    private func buildURLComponents(genre: BookGenre = .fiction) -> URL? {
        var urlComponents = URLComponents(url: genre == .fiction ? .searchFiction : .search, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = genre == .fiction
            ? [
                URLQueryItem(name: "q", value: query),
            ]
            : [
                URLQueryItem(name: "req", value: query),
                URLQueryItem(name: "phrase", value: "0"),
                URLQueryItem(name: "view", value: "simple"),
                URLQueryItem(name: "column", value: "def"),
                URLQueryItem(name: "sort", value: "def"),
                URLQueryItem(name: "sortmode", value: "ASC"),
                URLQueryItem(name: "page", value: String(page)),
            ]
        return urlComponents?.url
    }
}
