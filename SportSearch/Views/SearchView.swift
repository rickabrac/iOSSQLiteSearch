//
//  SearchView.swift
//  SportSearch
//  Created by Rick Tyler
//
//  SearchView is the root view controller including a search text field, a tableview for displaying
//  results, and a loading view to indicate incremental progress while importing. If there are multiple
//  brands a given title (e.g. Nike vs Underarmor "Golf Shirt"), the brand name (in parentheses) is omitted
//  from the result and a UITableViewCell disclosure indicator is used to indicate multiple matching brands.
//  When the user taps a result row, the DetailView is presented.
//

import UIKit

class SearchView: UIViewController {
	var viewModel: SearchViewModel?
	private var search = UITextField()
	private let tableView = UITableView()
	private let noResults = UILabel(frame: CGRect(x: 0, y:0, width: 200, height: 34))
	private var spinner = UIActivityIndicatorView(style: .medium)
	private var loadingView = UIView()
	private var stateLabel = UILabel()
	private var detailLabel = UILabel()
	private let latencyLabel = UILabel()
	private let resultRowsLabel = UILabel()
	private var progressView = UIProgressView(progressViewStyle: .bar)
	private var progressSpinner = UIActivityIndicatorView(style: .medium)
	private var dispatchQueue: SynchronousDispatchQueue = DispatchQueue.main
	private var presentCatalogUpdatingAlert = false
	private var loadingViewConstraints = [NSLayoutConstraint]()
	private var tableViewConstraints = [NSLayoutConstraint]()
	private var spinnerConstraints = [NSLayoutConstraint]()
	private var backgroundLoadingTableViewConstraints = [NSLayoutConstraint]()
	private var backgroundLoadingAlert: UIAlertController? = nil
	private var helpAlert: UIAlertController? = nil
	
	init(dispatchQueue: SynchronousDispatchQueue) {
		self.dispatchQueue = dispatchQueue
		super.init(nibName: nil, bundle: nil)
		loadViewIfNeeded()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	func configure() {
		if viewModel == nil, unitTestMode() == false {
			viewModel = SearchViewModel(sqliteDBFileName: "catalog.sqlite")
			viewModel?.observer = self
		}
		
		title = "SportSearch"
		
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
		navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15.0)]
		
		view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
		
		// search
		search.delegate = self
		search.layer.cornerRadius = 5.0
		search.autocapitalizationType = .none
		search.font = UIFont.systemFont(ofSize: 14.0)
		search.tintColor = .black
		search.backgroundColor = .systemGray5
		search.clearButtonMode = .always
		let leftView = UIView(frame: CGRect(x: 10, y: 50, width: 7, height: search.frame.size.height))
		leftView.backgroundColor = search.backgroundColor;
		search.leftView = leftView
		search.leftViewMode = .always
		search.isHidden = true
		search.placeholder = " For instructions, tap ?"
		search.autocorrectionType = .no
		view.addSubview(search)
		search.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			search.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 1),
			search.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 18),
			search.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -18),
			search.heightAnchor.constraint(equalToConstant: 34)
		])
		
		// tableView
		tableView.delegate = self
		tableView.dataSource = self
		tableView.register(SearchRow.self as AnyClass, forCellReuseIdentifier: "CatalogTableViewCell")
		tableView.accessibilityIdentifier = "CatalogTableView"
		view.addSubview(tableView)
		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableViewConstraints = [
			tableView.topAnchor.constraint(equalTo: search.bottomAnchor),
			tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
			tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
			tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
		]
		NSLayoutConstraint.activate(tableViewConstraints)
		// loadingView
		loadingView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
		loadingView.layer.borderWidth = 2
		loadingView.layer.cornerRadius = 5
		loadingView.layer.borderColor = UIColor(red:0, green:0, blue:0, alpha: 1).cgColor
		loadingView.isHidden = true
		view.addSubview(loadingView)
		loadingView.translatesAutoresizingMaskIntoConstraints = false
		loadingViewConstraints = [
			loadingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: -85),
			loadingView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 50),
			loadingView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -50),
			loadingView.heightAnchor.constraint(equalToConstant: 100)
		]
		NSLayoutConstraint.activate(loadingViewConstraints)
		
		// stateLabel
		stateLabel.textAlignment = .center
		stateLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13.0, weight: .regular)
		stateLabel.textColor = .black
		loadingView.addSubview(stateLabel)
		stateLabel.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			stateLabel.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor, constant: 15),
			stateLabel.trailingAnchor.constraint(equalTo: loadingView.trailingAnchor, constant: -15),
			stateLabel.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor, constant: -25),
			stateLabel.heightAnchor.constraint(equalToConstant: 15)
		])
		
		// progressView
		progressView.trackTintColor = .lightGray
		progressView.tintColor = .blue
		progressView.center = loadingView.center
		progressView.isHidden = true
		loadingView.addSubview(progressView)
		progressView.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			progressView.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor, constant: 20),
			progressView.trailingAnchor.constraint(equalTo: loadingView.trailingAnchor, constant: -20),
			progressView.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor),
			progressView.heightAnchor.constraint(equalToConstant: 6)
		])
		
		// detailLabel
		detailLabel.isHidden = true
		detailLabel.textAlignment = .center
		detailLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12.0, weight: .regular)
		detailLabel.textColor = .black
		detailLabel.textAlignment = .center // .right
		loadingView.addSubview(detailLabel)
		detailLabel.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			detailLabel.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor), // , constant: -35),
			detailLabel.widthAnchor.constraint(equalToConstant: 300),
			detailLabel.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor, constant: 25),
			detailLabel.heightAnchor.constraint(equalToConstant: 18)
		])

		// progress view activity indicator
		progressSpinner.color = .gray
		progressSpinner.startAnimating()
		loadingView.addSubview(progressSpinner)
		progressSpinner.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			progressSpinner.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
			progressSpinner.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)
		])
		
		// search view activity indicator (spinner)
		spinner.center = view.center
		spinner.startAnimating()
		view.addSubview(spinner)
		view.bringSubviewToFront(spinner)
		spinner.translatesAutoresizingMaskIntoConstraints = false
		spinnerConstraints = [
			spinner.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
			spinner.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
		]
		NSLayoutConstraint.activate(spinnerConstraints)
		
		// configure noResults
		noResults.text = "No results"
		noResults.center = view.center
		noResults.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
		noResults.font = UIFont.boldSystemFont(ofSize: 16.0)
		noResults.center = view.center
		noResults.textAlignment = .center
		noResults.isHidden = true
		view.addSubview(noResults)
		
		// configure help alert
		helpAlert =	UIAlertController(title: "Help", message: "\n\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
		let dismissHelp = UIAlertAction(title: "OK", style: .default) { _ in
			self.search.placeholder = ""
		}
		helpAlert?.addAction(dismissHelp)
		let helpLabel = UILabel()
		helpLabel.numberOfLines = 0
		helpLabel.backgroundColor = .clear
		helpLabel.font = UIFont.systemFont(ofSize: 13.0)
		helpLabel.text =
			"""
			• To search, enter keyword(s)
				
			• To filter by brand, include /<brand>
				
			• To list all brands, enter /
				
			• To filter by serial #, enter #<serial>
				
			• To see the entire catalog, enter *
				
			• To see these instructions, tap ?
				
			"""
		helpLabel.translatesAutoresizingMaskIntoConstraints = false
		helpAlert?.view.addSubview(helpLabel)
		guard let helpAlert = helpAlert else { return }
		NSLayoutConstraint.activate([
			helpLabel.topAnchor.constraint(equalTo: helpAlert.view!.topAnchor, constant: 50),
			helpLabel.leadingAnchor.constraint(equalTo: helpAlert.view!.leadingAnchor, constant: 30),
			helpLabel.trailingAnchor.constraint(equalTo: helpAlert.view!.trailingAnchor, constant: -20),
			helpLabel.bottomAnchor.constraint(equalTo: helpAlert.view!.bottomAnchor, constant: -50),
		])
		
		// configure latencyLabel and resultRowsLabel
		latencyLabel.frame = CGRect(x: 20, y: 0, width: 100, height: 20)
		latencyLabel.font = UIFont.systemFont(ofSize: 8.0)
		latencyLabel.text = ""
		navigationController?.navigationBar.addSubview(latencyLabel)
		resultRowsLabel.frame = CGRect(x: self.view.frame.size.width - 120, y: 0, width: 100, height: 20)
		resultRowsLabel.font = UIFont.systemFont(ofSize: 8.0)
		resultRowsLabel.text = ""
		resultRowsLabel.textAlignment = .right
		navigationController?.navigationBar.addSubview(resultRowsLabel)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		configure()
		if unitTestMode() == false {
			if viewModel?.db != nil {
				modelDidUpdate()
			}
			if let _ = viewModel?.catalog {
				viewModel?.loadCatalog()
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(false)
		search.tintColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
		tableView.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
		self.view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(false)
		if viewModel != nil {
			if presentCatalogUpdatingAlert, backgroundLoadingAlert == nil {
				backgroundLoadingAlert = UIAlertController(title: "Notification", message: "\nThe product catalog is being updated.", preferredStyle: .alert)
				let ok = UIAlertAction(title: "OK", style: .default) { UIAlertAction in
					self.spinner.isHidden = false
				}
				guard let alert = backgroundLoadingAlert else {
					fatalError("\(name(self)).viewDidAppear: failed to unwrap backgroundLoadingAlert")
				}
				alert.addAction(ok)
				self.present(alert, animated: true) {
					self.search.becomeFirstResponder()
				}
				return
			}
		}
		spinner.isHidden = true
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(false)
		UIView.setAnimationsEnabled(false)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(false)
		UIView.setAnimationsEnabled(false)
	}
	
	private func refreshView() {
		guard let viewModel = viewModel else { return }
		if viewModel.sqliteDBFileName != "TestCatalog.sqlite" {
			if viewModel.catalog?.state == .ready {
				// background loading complete so hide loading view
				if loadingView.superview != nil {
					loadingView.removeFromSuperview()
					view.removeConstraints(backgroundLoadingTableViewConstraints)
					tableViewConstraints = [
						tableView.topAnchor.constraint(equalTo: search.bottomAnchor),
						tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
						tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
						tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
					]
					NSLayoutConstraint.activate(tableViewConstraints)
				}
			}
			else if viewModel.catalog?.state == .empty {
				// existing catalog loaded, reposition loading view at bottom of search view
				presentCatalogUpdatingAlert = true
				view.removeConstraints(tableViewConstraints)
				// N.B. reinit search field to work around an apparent bug in layout engine
				// that causes cursor to be vertically offset after changing constraints
				// for background loading view positioned at bottom of search view.
				search.removeFromSuperview()
				search = UITextField()
				search.delegate = self
				search.layer.cornerRadius = 5.0
				search.autocapitalizationType = .none
				search.font = UIFont.systemFont(ofSize: 14.0)
				search.tintColor = .black
				search.backgroundColor = .systemGray5
				search.clearButtonMode = .always
				let leftView = UIView(frame: CGRect(x: 10, y: 50, width: 7, height: search.frame.size.height))
				leftView.backgroundColor = search.backgroundColor;
				search.leftView = leftView
				search.leftViewMode = .always
				search.placeholder = " For instructions, tap ?"
				search.autocorrectionType = .no
				view.addSubview(search)
				search.translatesAutoresizingMaskIntoConstraints = false
				NSLayoutConstraint.activate([
					search.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 1),
					search.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 18),
					search.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -18),
					search.heightAnchor.constraint(equalToConstant: 34)
				])
				backgroundLoadingTableViewConstraints = [
					tableView.topAnchor.constraint(equalTo: self.search.bottomAnchor),
					tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
					tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
					tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100)
				]
				NSLayoutConstraint.activate(backgroundLoadingTableViewConstraints)
				loadingView.layer.borderWidth = 1
				loadingView.layer.borderColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0).cgColor
				loadingView.layer.cornerRadius = 0
				view.removeConstraints(loadingViewConstraints)
				loadingViewConstraints = [
					loadingView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor),
					loadingView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
					loadingView.topAnchor.constraint(equalTo: tableView.bottomAnchor),
					loadingView.heightAnchor.constraint(equalToConstant: 100)
				]
				NSLayoutConstraint.activate(loadingViewConstraints)
				view.removeConstraints(spinnerConstraints)
				NSLayoutConstraint.activate([
					spinner.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
					spinner.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
				])
				tableView.isHidden = false
				view.bringSubviewToFront(spinner)
			} else if viewModel.catalog?.state == .failed {
				var alert: UIAlertController
				var dismiss: UIAlertAction
				if backgroundLoadingAlert?.view.window != nil {
					backgroundLoadingAlert?.dismiss(animated: true)
				}
				if self.viewModel?.db == nil {
					alert = UIAlertController(title: "Fatal Error", message: "\nThe catalog failed to download and there is no local backup. Check your Internet connection and try again.", preferredStyle: .alert)
					dismiss = UIAlertAction(title: "OK", style: .default) { UIAlertAction in
						exit(-1)
					}
				} else {
					alert = UIAlertController(title: "Notification", message: "\nThe catalog cannot be updated due to a cloud failure.", preferredStyle: .alert)
					dismiss = UIAlertAction(title: "OK", style: .default)
				}
				alert.addAction(dismiss)
				self.present(alert, animated: true, completion: nil)
				return
			}
			search.setNeedsLayout()
			search.setNeedsDisplay()
		}
		if view.window != nil, viewModel.updateCatalog() {
			guard let backgroundLoadingAlert = backgroundLoadingAlert else {
				fatalError("\(name(self)).refreshView: failed to unwrap backgroundLoadingAlert")
			}
			if backgroundLoadingAlert.view.window != nil {
				backgroundLoadingAlert.dismiss(animated: true)
			}
			let alert = UIAlertController(title: "Notification", message: "\nThe product catalog has been updated.", preferredStyle: .alert)
			let ok = UIAlertAction(title: "OK", style: .default)
			alert.addAction(ok)
			self.present(alert, animated: true, completion: nil)
		}
		latencyLabel.text = viewModel.latencyText
		resultRowsLabel.text = viewModel.resultRowsText
		stateLabel.text = viewModel.getLoadingState()
		detailLabel.text = viewModel.getLoadingDetail()
		switch viewModel.state {
		case .fetching:
			loadingView.isHidden = false
		case .loading:
			loadingView.isHidden = false
			progressSpinner.isHidden = true
			progressView.isHidden = false
			detailLabel.isHidden = false
			UIView.animate(withDuration: 0.0) {
				self.progressView.setProgress(viewModel.progress, animated: true)
			}
		case .indexing:
			loadingView.isHidden = false
			progressView.isHidden = true
			progressSpinner.isHidden = false
		case .ready:
			loadingView.isHidden = true
			if viewModel.isSearchFieldHidden == false {
				search.isHidden = false
			} else {
				view.removeConstraints(tableViewConstraints)
				tableViewConstraints = [
					tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
					tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
					tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
					tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
				]
				NSLayoutConstraint.activate(tableViewConstraints)
			}
			search.becomeFirstResponder()
		default:
			break
		}
		if viewModel.state != .searching {
			if viewModel.prevSearch == search.text, search.isHidden == false {
				if viewModel.numberOfRows == 0, viewModel.prevSearch != "" {
					noResults.isHidden = false
				} else {
					noResults.isHidden = true
				}
			}
			spinner.isHidden = true
		}
		tableView.reloadData()
	}
}

// MARK: Observer conformance

extension SearchView: Observer {
	func modelDidUpdate() {
		if Thread.isMainThread {
			refreshView()
		} else {
			dispatchQueue.execute {
				self.refreshView()
			}
		}
	}
}

// MARK: UITextFieldDelegate conformance

extension SearchView: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		guard let viewModel = viewModel, let text = textField.text else { return false }
		spinner.isHidden = false
		noResults.isHidden = true
		tableView.reloadData()
		viewModel.search(text)
		return false
	}
	
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		guard let viewModel = viewModel else { return false }
		if viewModel.state == .searching {
			return false
		}
		if string == "?", let helpAlert = helpAlert {
			self.present(helpAlert, animated: true)
			return false
		}
		noResults.isHidden = true
		return true
	}
}

// MARK: UITableViewDataSource conformance

extension SearchView: UITableViewDataSource {
	var numberOfSections: Int {
		return 1
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let viewModel = viewModel else { return 0 }
		if viewModel.state == .searching {
			return 0
		}
		return viewModel.numberOfRows
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "CatalogTableViewCell", for: indexPath) as? SearchRow else { return UITableViewCell() }
		cell.titleLabel.text = viewModel?.leftText(forRowAt: indexPath)
		cell.brandLabel.text = viewModel?.centerText(forRowAt: indexPath)
		cell.priceLabel.text = viewModel?.rightText(forRowAt: indexPath)
		guard let show = viewModel?.showDisclosureIndicator(forRowAt: indexPath) else {
			cell.accessoryType = .none
			return cell
		}
		if show {
			cell.accessoryType = .disclosureIndicator
			cell.tintColor = .red
		} else {
			cell.accessoryType = .none
		}
		return cell
	}
}

// MARK: UITableViewDelegate conformance

extension SearchView: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		spinner.isHidden = false
		view.setNeedsDisplay()
		dispatchQueue.execute {
			tableView.deselectRow(at: indexPath, animated: false)
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			let vc = storyboard.instantiateViewController(withIdentifier: "DetailView") as! DetailView
			vc.viewModel = self.viewModel?.getItemViewModel(forRowAt: indexPath)
			vc.viewModel?.observer = vc
			let item = self.viewModel?.getItem(forRowAt: indexPath)
			guard let item = item else {
				fatalError("\(name(self)): tableView:didSelectRow: failed to unwrap item)")
			}
//			print("SELECT [\(item.brand)] title=[\(item.title)] price=[\(item.price)] color=[\(item.color)]")
			if item.title == "" {
				let vc = storyboard.instantiateViewController(withIdentifier: "SearchView") as! SearchView
				let vm = SearchViewModel()
				vm.catalog = nil
				vm.observer = vc
				vm.db = self.viewModel?.db
				vc.viewModel = vm
				vm.isSearchFieldHidden = true
				vc.presentCatalogUpdatingAlert = false
				vm.state = .ready
				let brandSearch = "/\(item.brand.replacingOccurrences(of: " ", with: "\\").lowercased()) "
				vm.search(brandSearch)
				usleep(250000)
				self.navigationController?.pushViewController(vc, animated: false)
				return
			}
			self.navigationController?.pushViewController(vc, animated: false)
			vc.viewModel?.loadDetails(Item(serial: item.serial, brand: item.brand, title: item.title, price: item.price, color: item.color))
		}
	}
}
