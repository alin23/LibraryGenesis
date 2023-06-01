//
//  LatestViewController.swift
//  LibGen
//
//  Created by Martin Stamenkovski on 3/23/20.
//  Copyright © 2020 Stamenkovski. All rights reserved.
//

import UIKit

// MARK: - LatestViewController

class LatestViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var booksGenreSelector: UISegmentedControl!
    var booksGenre = BookGenre.fiction

    var loadingViewController: MSLoadingViewController!

    lazy var footerView: LoadingFooterView = {
        let footerView = LoadingFooterView(frame: CGRect(origin: .zero, size: CGSize(width: self.tableView.bounds.width, height: 80)))
        return footerView
    }()

    var service: LatestBookService!

    func setupBookGenreSelector() {
        booksGenreSelector.addTarget(self, action: #selector(actionBookGenreSelector(_:)), for: .valueChanged)
    }

    @objc func actionBookGenreSelector(_ sender: UISegmentedControl) {
        booksGenre = BookGenre(rawValue: sender.selectedSegmentIndex)!
        DispatchQueue.main.async {
            self.service.books = []
            self.didLoadBooks(self.service)
            self.showLoading {
                self.service.fetchLatestBooks(genre: self.booksGenre)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        service = LatestBookService()
        service.delegate = self
        setupSnackbar()
        setupBookGenreSelector()
        setupTableView()

        DispatchQueue.main.async {
            self.showLoading {
                self.service.fetchLatestBooks(genre: self.booksGenre)
            }
        }
    }

    private var snackBar: Snackbar = {
        let snackBar = Snackbar()
        snackBar.translatesAutoresizingMaskIntoConstraints = false
        return snackBar
    }()

    private var bottomAnchorSnackbar: NSLayoutConstraint!

    private func setupTableView() {
        tableView.register(UINib(nibName: "BookTableViewCell", bundle: nil), forCellReuseIdentifier: .bookTableViewCell)
        tableView.delegate = self
        tableView.dataSource = self
    }

    private func setupSnackbar() {
        view.addSubview(snackBar)
        if #available(iOS 11.0, *) {
            self.bottomAnchorSnackbar = self.snackBar.bottomAnchor.constraint(
                equalTo: self.view.safeAreaLayoutGuide.bottomAnchor,
                constant: 500
            )
        } else {
            bottomAnchorSnackbar = snackBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 500)
        }
        bottomAnchorSnackbar.isActive = true

        NSLayoutConstraint.activate([
            snackBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            snackBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            snackBar.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
        ])

        snackBar.onRetry = { [unowned self] in
            showLoading {
                self.service.refreshBooks()
            }
        }
    }
}

// MARK: UITableViewDelegate, UITableViewDataSource

extension LatestViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        service.books.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: .bookTableViewCell, for: indexPath) as! BookTableViewCell
        cell.setup(with: service.books[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let book = service.books[indexPath.row]
        preview(book)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == service.lastIndex {
            footerView.startAnimating()
            self.tableView.tableFooterView = footerView
            service.loadNextPage()
        }
    }
}

// MARK: BookServiceDelegate

extension LatestViewController: BookServiceDelegate {
    func didLoadBooks(_ service: BookService) {
        dismissLoading { [weak self] in
            self?.removeLoadingFooter()
            self?.tableView.reloadData()
            self?.hideSnackbar()
        }
    }

    func didFailedLoadBooks(_ service: BookService, with error: LibError) {
        dismissLoading { [weak self] in
            self?.removeLoadingFooter()
            self?.onFailedLatestBooks(with: error)
        }
    }

    private func removeLoadingFooter() {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.allowUserInteraction, .curveLinear], animations: {
            self.footerView.stopAnimating()
            self.tableView.tableFooterView = nil
        }, completion: nil)
    }

    private func onFailedLatestBooks(with error: LibError) {
        guard !service.isEndOfList(with: error) else { return }

        snackBar.message = error.localizedDescription
        bottomAnchorSnackbar.constant = -20
        UIView.animate(
            withDuration: 0.7,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 7,
            options: [.curveEaseInOut],
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }

    private func hideSnackbar() {
        guard bottomAnchorSnackbar.constant == -20 else { return }
        bottomAnchorSnackbar.constant = 500
        UIView.animate(
            withDuration: 0.5,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 7,
            options: [.curveEaseIn],
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: nil
        )
    }
}

extension LatestViewController {
    private func preview(_ book: Book) {
        let detailStoryboard = UIStoryboard(name: "Detail", bundle: nil)
        let detailsViewController = detailStoryboard
            .instantiateViewController(withIdentifier: "detailsViewController") as! DetailsViewController
        detailsViewController.book = book
        detailsViewController.parentView = self
        navigationController?.pushViewController(detailsViewController, animated: true)
    }

    private func showLoading(_ completion: @escaping (() -> Void)) {
        loadingViewController = MSLoadingViewController()
        loadingViewController.message = "Fetching books..."
        present(loadingViewController, animated: true, completion: completion)
    }

    private func dismissLoading(_ completion: @escaping (() -> Void)) {
        guard let loadingViewController else {
            completion()
            return
        }
        loadingViewController.dismiss(animated: true, completion: completion)
        self.loadingViewController = nil
    }
}
