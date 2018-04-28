//
//  FirstViewController.swift
//  FunctionalTableDataDemo
//
//  Created by Kevin Barnes on 2018-04-20.
//  Copyright © 2018 Shopify. All rights reserved.
//

import UIKit
import FunctionalTableData

class TableExampleController: UITableViewController {

	private let functionalData = FunctionalTableData()
	private var items: [String] = [] {
		didSet {
			render()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		functionalData.tableView = tableView
		tableView.allowsMultipleSelection = false
		title = "Table View"
		navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didSelectAdd))
	}
	
	@objc private func didSelectAdd() {
		items.append(NSDate().description)
	}
	
	private func render() {
		let rows: [CellConfigType] = items.enumerated().map { index, item in
			return LabelCell(
				key: "id-\(index)",
				actions: CellActions(
					canSelectAction: { callback in
						callback(true)
				},
					selectionAction: { (view, selected) -> CellActions.SelectionState in
						print("\(item) is \(selected ? "Selected" : "Deselected")")
						return selected ? .selected : .deselected
				}),
				state: LabelState(text: item),
				cellUpdater: LabelState.updateView)
		}
		
		functionalData.renderAndDiff([
			TableSection(key: "section", rows: rows)
			])
	}

}

