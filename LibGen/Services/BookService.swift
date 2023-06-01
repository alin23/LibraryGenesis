//
//  LatestService.swift
//  LibGen
//
//  Created by Martin Stamenkovski on 3/23/20.
//  Copyright © 2020 Stamenkovski. All rights reserved.
//

import Foundation
import SwiftSoup

// MARK: - BookGenre

enum BookGenre: Int {
    case fiction = 0
    case nonFiction = 1
}

// MARK: - BookServiceDelegate

protocol BookServiceDelegate: AnyObject {
    func didLoadBooks(_ service: BookService)
    func didFailedLoadBooks(_ service: BookService, with error: LibError)
}

// MARK: - LibError

enum LibError: Error {
    case errorParsingHTML
    case error(Error)
    case noResults

    var localizedDescription: String {
        switch self {
        case .errorParsingHTML:
            return "Failed to load books, try again."
        case .noResults:
            return "No results to show, try more general keyword."
        case let .error(error):
            return error.localizedDescription
        }
    }
}

func fetch<T>(_ url: URL, completion: @escaping ((Result<T, LibError>) -> Void), onData: @escaping (Data) throws -> Void) {
    URLSession.shared.dataTask(with: url) { data, res, error in
        if let error {
            completion(.failure(.error(error)))
            return
        }
        guard let data else { return }
        do {
            try onData(data)
        } catch {
            completion(.failure(.error(error)))
        }
    }.resume()
}

// MARK: - BookService

class BookService {
    weak var delegate: BookServiceDelegate?

    var page = 1
    var books: [Book] = []

    func fetchDetails(book: Book, onSuccess: @escaping (Book) -> Void) {
        guard let link = book.link else {
            return
        }
        let url = URL.search.appending(path: link)

        fetchFictionDetails(url) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(fields):
                    let book = book.with(
                        year: fields["year"],
                        description: fields["description"],
                        coverURL: fields["coverURL"],
                        publisher: fields["publisher"],
                        isbn: fields["isbn"]
                    )
                    self.books = self.books.map { bk in bk.link == link ? book : bk }
                    onSuccess(book)
                    self.delegate?.didLoadBooks(self)
                case let .failure(error):
                    print(error.localizedDescription)
                }
            }
        }
    }

    func loadBooks(from url: URL, completion: @escaping ((Result<[Book], LibError>) -> Void)) {
        fetch(url, completion: completion, onData: { data in
            guard let html = String(data: data, encoding: .utf8) else {
                completion(.failure(.errorParsingHTML))
                return
            }
            let doc: Document = try SwiftSoup.parse(html)

            if url.pathComponents.contains("fiction") {
                try self.parseFiction(doc: doc, completion: completion)
            } else {
                try self.parseNonFiction(doc: doc, completion: completion)
            }

        })
    }

    func parseFiction(doc: Document, completion: @escaping ((Result<[Book], LibError>) -> Void)) throws {
        let trArray = try doc.select("table.catalog tr").array().dropFirst()
        let books = trArray.compactMap { row -> Book? in
            guard let cells = try? row.select("td").array(),
                  let author = try? cells[safe: 0]?.text(),
                  let title = try? cells[safe: 2]?.select("a").text()
            else {
                return nil
            }
            let series = try? cells[1].text()
            let link = try? cells[2].select("a").attr("href")
            let md5 = link?.components(separatedBy: "/").last
            let language = try? cells[3].text()
            let fileTypeAndSize = try? cells[4].text().components(separatedBy: "/")
            let fileType = fileTypeAndSize?.first?.trimmingCharacters(in: .whitespacesAndNewlines)
            let fileSize = fileTypeAndSize?.last?.trimmingCharacters(in: .whitespacesAndNewlines)
            let mirrors = try? row.select("td ul.record_mirrors_compact li a").array().compactMap { try? URL(string: $0.attr("href")) }

            return Book(
                title: title,
                year: nil,
                author: author,
                language: language,
                fileSize: fileSize,
                md5: md5,
                description: nil,
                coverURL: nil,
                publisher: nil,
                pages: nil,
                fileType: fileType,
                series: series,
                link: link,
                mirrors: mirrors,
                isbn: nil
            )
        }

        completion(.success(books))
    }

    func fetchFictionDetails(_ url: URL, completion: @escaping ((Result<[String: String], LibError>) -> Void)) {
        fetch(url, completion: completion, onData: { data in
            guard let html = String(data: data, encoding: .utf8) else {
                completion(.failure(.errorParsingHTML))
                return
            }
            let doc = try SwiftSoup.parse(html)
            let coverURL = try URL.search.appending(path: doc.select("img[alt=cover]").attr("src"))
            let fieldKV: [(String, String)] = try doc.select("tr>td.field").array().compactMap { f in
                let key = try? f
                    .text()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: ":", with: "")
                    .lowercased()
                let value: String?

                if key == "description" {
                    value = try? f.parent()?.nextElementSibling()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    value = try? f.nextElementSibling()?.text().trimmingCharacters(in: .whitespacesAndNewlines)
                }

                guard let key, let value else {
                    return nil
                }
                return (key, value)
            }
            var fields = [String: String](uniqueKeysWithValues: fieldKV)
            fields["coverURL"] = coverURL.absoluteString
            completion(.success(fields))
        })
    }

    func parseNonFiction(doc: Document, completion: @escaping ((Result<[Book], LibError>) -> Void)) throws {
        let trArray = try doc.select("table.c tr").array()
        let ids: [String] = trArray.compactMap { tr in
            guard let id = try? tr.select("td").array().first?.text() else {
                return nil
            }

            return Int(id) == nil ? nil : id
        }

        guard !ids.isEmpty else {
            completion(.failure(.noResults))
            return
        }
        getBooks(with: ids, completion: completion)
    }
}

// MARK: - Get books with given ids.

extension BookService {
    private func getBooks(with ids: [String], completion: @escaping ((Result<[Book], LibError>) -> Void)) {
        var urlComponent = URLComponents(url: .baseURL, resolvingAgainstBaseURL: true)

        urlComponent?.queryItems = [
            URLQueryItem(name: "ids", value: ids.joined(separator: ",")),
            URLQueryItem(name: "fields", value: "*"),
        ]

        guard let url = urlComponent?.url else { return }
        fetch(url, completion: completion, onData: { data in
            self.decodeBooks(from: data, completion)
        })
    }

    private func decodeBooks(from data: Data, _ completion: @escaping ((Result<[Book], LibError>) -> Void)) {
        let jsonDecoder = JSONDecoder()
        do {
            let books = try jsonDecoder.decode([Book].self, from: data)
            completion(.success(books))
        } catch {
            completion(.failure(.error(error)))
        }
    }

    func isEndOfList(with error: LibError) -> Bool {
        switch error {
        case .noResults:
            return page > 1
        default:
            return false
        }
    }
}
