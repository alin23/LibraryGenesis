//
//  SearchBookViewController.swift
//  LibGen
//
//  Created by Martin Stamenkovski INS on 3/23/20.
//  Copyright © 2020 Stamenkovski. All rights reserved.
//

import UIKit

// MARK: - SearchBookViewController

class SearchBookViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    @IBOutlet var booksGenreSelector: UISegmentedControl!
    var booksGenre = BookGenre.fiction

    lazy var footerView: LoadingFooterView = {
        let footerView = LoadingFooterView(frame: CGRect(origin: .zero, size: CGSize(width: self.tableView.bounds.width, height: 80)))
        return footerView
    }()

    var service: SearchBookService!

    func setupBookGenreSelector() {
        booksGenreSelector.addTarget(self, action: #selector(actionBookGenreSelector(_:)), for: .valueChanged)
    }

    @objc func actionBookGenreSelector(_ sender: UISegmentedControl) {
        booksGenre = BookGenre(rawValue: sender.selectedSegmentIndex)!
        DispatchQueue.main.async {
            self.service.removeAll()
            self.didLoadBooks(self.service)
            self.showLoading {
                self.service.refreshBooks(genre: self.booksGenre)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        searchController.searchBar.becomeFirstResponder()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        service = SearchBookService()
        service.delegate = self

        setupTableView()
        setupSnackbar()

        setupSearchController()
    }

    private var searchController: UISearchController!
    private var loadingViewController: MSLoadingViewController!

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
                self.service.refreshBooks(genre: booksGenre)
            }
        }
    }
}

// MARK: UITableViewDelegate, UITableViewDataSource

extension SearchBookViewController: UITableViewDelegate, UITableViewDataSource {
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
        preview(service.books[indexPath.row])
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == service.lastIndex {
            loadNextPage()
        }
    }
}

// MARK: BookServiceDelegate

extension SearchBookViewController: BookServiceDelegate {
    func didLoadBooks(_ service: BookService) {
        dismissLoading { [weak self] in
            self?.hideSnackbar()
            self?.tableView.reloadData()
            self?.removeLoadingFooter()
        }
    }

    func didFailedLoadBooks(_ service: BookService, with error: LibError) {
        dismissLoading { [weak self] in
            self?.removeLoadingFooter()
            self?.onSearchError(with: error)
        }
    }

    private func removeLoadingFooter() {
        footerView.stopAnimating()
        tableView.tableFooterView = nil
    }

    private func loadNextPage() {
        footerView.startAnimating()
        tableView.tableFooterView = footerView
        service.loadNextPage(genre: booksGenre)
    }

    private func onSearchError(with error: LibError) {
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
            withDuration: 0.7,
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

// MARK: UISearchBarDelegate

extension SearchBookViewController: UISearchBarDelegate {
    private func setupSearchController() {
        guard searchController == nil else { return }
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.sizeToFit()
        searchController.searchBar.placeholder = "Search by title, author..."
        searchController.searchBar.delegate = self
        if #available(iOS 11.0, *) {
            self.navigationItem.hidesSearchBarWhenScrolling = false
            self.navigationItem.searchController = searchController
        } else {
            tableView.tableHeaderView = searchController.searchBar
        }
        definesPresentationContext = true
        searchController.obscuresBackgroundDuringPresentation = false
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text else { return }
        service.removeAll()
        tableView.reloadData()

        showLoading {
            self.service.searchBooks(with: query, genre: self.booksGenre)
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        hideSnackbar()
    }
}

extension SearchBookViewController {
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
