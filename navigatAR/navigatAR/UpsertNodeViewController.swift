//
//  UpsertNodeViewController.swift
//  navigatAR
//
//  Created by Michael Gira on 2/3/18.
//  Copyright © 2018 MICDS Programming. All rights reserved.
//

import CodableFirebase
import Eureka
import Firebase
import IndoorAtlas

class UpsertNodeViewController: FormViewController {

	@IBAction func unwindToUpsertNodes(unwindSegue: UIStoryboardSegue) {
		let r: CheckRow! = form.rowBy(tag: "location")
		r.value = locationData != nil
		r.reload()
	}
	
	let nodeTypes: [(display: String, value: NodeType)] = [(
		display: "Pathway",
		value: .pathway
	), (
		display: "Bathroom",
		value: .bathroom
	), (
		display: "Printer",
		value: .printer
	), (
		display: "Water Fountain",
		value: .fountain
	), (
		display: "Room",
		value: .room
	), (
		display: "Sports Venue",
		value: .sportsVenue
	)]
	
	let ref = Database.database().reference()
	
	var tagInfos: [TagInfo] = []
	
	var locationData: IALocation?
//	var currentBuilding: Building?

	override func viewDidLoad() {
		super.viewDidLoad()

		form +++ Section("Name")
			<<< TextRow("name") { row in
				row.title = "Name"
				row.placeholder = "Ex. STEM 252"
			}
	
		+++ SelectableSection<ListCheckRow<String>>("Node Type", selectionType: .singleSelection(enableDeselection: true))

			for option in nodeTypes {
				form.last! <<< ListCheckRow<String>(String(describing: option.value)){ listRow in
					listRow.title = option.display
					listRow.selectableValue = String(describing: option.value)
					listRow.value = nil
				}
			}

		form +++ Section("Location")
			<<< CheckRow("location") { row in
				row.title = "Location"
				row.value = locationData != nil
				row.disabled = true
			}
			<<< ButtonRow() { row in
			row.title = locationData == nil ? "Record Location" : "Record Location Again"
			row.onCellSelection(self.recordPosition)
		}

		form +++ ButtonRow() { row in
			row.title = "Create"
//			row.disabled = Condition.function(["... Tags ..."]) { form in
//				return form.validate().count != 0
//			}
			row.onCellSelection(self.createNode)
		}
		
		ref.observeSingleEvent(of: .value, with: { snapshot in
			guard let currentBuilding = Building.current(root: snapshot) else { print("not in a building"); return }
			guard let buildingId = currentBuilding.id else { print("id is nil wtf"); return }
			
			guard let value = snapshot.childSnapshot(forPath: "tags").value else { return }
			
			do {
				self.tagInfos = Array((try FirebaseDecoder().decode([FirebasePushKey: TagInfo].self, from: value)).values).filter({ $0.building == buildingId })
			} catch let err {
				print(err) // handle error properly
				return
			}
			
			
			// TODO: figure out how to insert this in the right place
			if !self.tagInfos.isEmpty {
				self.form +++ Section("Tags")
				
				for tagInfo in self.tagInfos {
					// TODO: Figure out multiple values
					if !tagInfo.multiple {
						switch tagInfo.type {
						case .string:
							self.form.last! <<< TextRow(tagInfo.name) { row in
								row.title = camelToTitle(str: tagInfo.name)
								row.placeholder = "String"
							}
						case .number:
							self.form.last! <<< DecimalRow(tagInfo.name) { row in
								row.title = camelToTitle(str: tagInfo.name)
								row.placeholder = "Number"
							}
						case .boolean:
							self.form.last! <<< SwitchRow(tagInfo.name) { row in
								row.title = camelToTitle(str: tagInfo.name)
							}
						}
					}
				}
			}
		})

	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	func createNode(cell: ButtonCellOf<String>, row: ButtonRow) {
		let formValues = form.values()

		var selectedNodeType: NodeType? = nil
		for nodeType in nodeTypes {
			if formValues[String(describing: nodeType.value)] != nil {
				selectedNodeType = nodeType.value
			}
		}

		// Make sure user selected type
		/** @TODO Actually add form validation and disable button */
		if (formValues["name"] == nil || selectedNodeType == nil || locationData == nil) {
			return
		}
		
		ref.observeSingleEvent(of: .value, with: { snapshot in
			guard let currentBuilding = Building.current(root: snapshot) else {
				print("not in a building")
				return
			}
			
			
			print("Create Node!", selectedNodeType!, self.form.validate(), self.form.values(), self.locationData ?? "No Location", currentBuilding);
			
			guard let buildingId = currentBuilding.id else { print("id is nil wtf"); return }
			
			let data = try! FirebaseEncoder().encode(Node(
				building: buildingId,
				name: formValues["name"] as! String,
				type: selectedNodeType!,
				position: Location(fromIALocation: self.locationData!),
				tags: ["test": Tag.string("TODO: actual values for these")]
			))
			
			self.ref.child("nodes").childByAutoId().setValue(data)

	//		_ = navigationController?.popViewController(animated: true)
			self.performSegue(withIdentifier: "unwindToManageNodesWithUnwindSegue", sender: self)
		})
	}
	
	func recordPosition(cell: ButtonCellOf<String>, row: ButtonRow) {
		performSegue(withIdentifier: "NodePositionSegue", sender: self)
	}

}

//extension UpsertNodeViewController: IALocationManagerDelegate {
//	func indoorLocationManager(_ manager: IALocationManager, didEnter region: IARegion) {
//		try? currentBuilding = Building(fromIARegion: region)
//	}
//}

