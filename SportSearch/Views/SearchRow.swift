//
//  SearchRow.swift
//  SportSearch
//  Created by Rick Tyler
//

import UIKit

class SearchRow: UITableViewCell {
	let titleLabel = UILabel()
	let priceLabel = UILabel()
	let brandLabel = UILabel()
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String!) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		configure()
	}

	required init?(coder: NSCoder) {
		fatalError("SearchRow.init(coder:) unimplemented")
	}
	
	func configure() {
		titleLabel.numberOfLines = 1
		titleLabel.font = UIFont.systemFont(ofSize: 14.0)
		titleLabel.textColor = .black
		titleLabel.text = "TITLE?"
		titleLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
		addSubview(titleLabel)
		bringSubviewToFront(titleLabel)
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			titleLabel.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.leadingAnchor, constant: 15.0),
			titleLabel.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -60.0),
			titleLabel.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: -9.0),
			titleLabel.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: 9.0),
		])
		
		brandLabel.numberOfLines = 1
		brandLabel.font = UIFont.systemFont(ofSize: 14.0)
		brandLabel.textColor = .black
		brandLabel.text = "BRAND?"
		brandLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
		brandLabel.textAlignment = .center
		addSubview(brandLabel)
		bringSubviewToFront(brandLabel)
		brandLabel.translatesAutoresizingMaskIntoConstraints = false
		NSLayoutConstraint.activate([
			brandLabel.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: -9.0),
			brandLabel.leadingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor, constant: -100.0),
			brandLabel.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.centerXAnchor, constant: 100.0),
			brandLabel.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: 9.0)
		])
		
		priceLabel.numberOfLines = 1
		priceLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14.0, weight: .regular)
		priceLabel.textColor = .black
		priceLabel.text = "PRICE?"
		priceLabel.textAlignment = .right
		addSubview(priceLabel)
		bringSubviewToFront(priceLabel)
		priceLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
		NSLayoutConstraint.activate([
			priceLabel.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor, constant: -9.0),
			priceLabel.trailingAnchor.constraint(equalTo: self.safeAreaLayoutGuide.trailingAnchor, constant: -15.0),
			priceLabel.widthAnchor.constraint(equalToConstant: 55),
			priceLabel.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor, constant: 9.0)
		])
	}

	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
	}
}
