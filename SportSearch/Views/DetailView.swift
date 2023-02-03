//
//  DetailView.swift
//  SportSearch
//  Created by Rick Tyler
//
//  The DetailView allows the user to select from multiple brands, prices, and colors if applicable
//  or to simply display a lists of matching items with serial numbers and the available sizes.
//

import UIKit

class DetailView: UIViewController {
	var viewModel: DetailViewModel?
	var spinner: UIActivityIndicatorView = UIActivityIndicatorView()
	var dispatchQueue: SynchronousDispatchQueue = DispatchQueue.main
	@IBOutlet weak var tableView: UITableView!
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15)]
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
		spinner.center = view.center
		spinner.startAnimating()
		view.addSubview(spinner)
		view.bringSubviewToFront(spinner)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if viewModel?.isSearching == false {
			spinner.isHidden = true
		}
	}
	
	func refreshView() {
		spinner.isHidden = false
		if Thread.isMainThread == false {
			fatalError("\(name(self)): refreshView() executed in background thread")
		}
		let title = self.viewModel!.titleText
		self.navigationItem.title = title
		self.tableView.reloadData()
		spinner.isHidden = true
	}
}

// MARK: Observer conformance

extension DetailView: Observer {
	func modelDidUpdate() {
		dispatchQueue.execute {
			self.refreshView()
		}
	}
}

// MARK: UITableViewDataSource conformance

extension DetailView: UITableViewDataSource {
	var numberOfSections: Int {
		return 1
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let numRows = viewModel?.numberOfRows else { return 0 }
		return numRows
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "DetailRow", for: indexPath) as? DetailRow else { return UITableViewCell() }
		cell.leftLabel.font = UIFont.systemFont(ofSize: 14.0)
		cell.leftLabel.text = viewModel?.getLeftText(forRowAt: indexPath)
		cell.centerLabel.font = UIFont.systemFont(ofSize: 14.0)
		cell.centerLabel.text = viewModel?.getCenterText(forRowAt: indexPath)
		cell.rightLabel.font = UIFont.systemFont(ofSize: 14.0)
		cell.rightLabel.text = viewModel?.getRightText(forRowAt: indexPath)
		return cell
	}
}

// MARK: UITableViewDelegate conformance

extension DetailView: UITableViewDelegate {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: false)
		guard let viewModel = viewModel else {
			fatalError("\(name(self)).tableView:didSelectRowAt: failed to unwrap viewModel")
		}
		if !viewModel.shouldSelect(rowAt: indexPath) {
			return
		}
		spinner.isHidden = false
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let vc = storyboard.instantiateViewController(withIdentifier: "DetailView") as! DetailView
		let item = viewModel.result[indexPath.row]
		vc.viewModel = DetailViewModel(db: viewModel.db)
		vc.viewModel?.observer = vc
		self.navigationController?.pushViewController(vc, animated: false)
		vc.viewModel?.loadDetails(Item(serial: item.serial, brand: item.brand, title: item.title, price: item.price, color: item.color))
	}
}
