//
//  ToDoListViewController.swift
//  ToDoApp
//
//  Created by Jeanette on 2/21/25.
//

import UIKit
import CoreData
import FirebaseCore
import FirebaseFirestore

class ToDoListViewController: SwipeTableViewController {
    let db = Firestore.firestore()
    var itemArray: [ItemModel] = []
    var categoryID: String = ""
    let spinner = UIActivityIndicatorView(style: .large)
    
    var selectedCategory: ItemCategories? {
        didSet {
            loadData()
        }
    }
    let dataFilePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent("Items.plist")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        setupSpinner()
    }
    
    func setupSpinner() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        
        //spinner positioning
        let yOffset: CGFloat = view.bounds.height * 0.05
        
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -yOffset)
        ])
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    
    //when cell scrolls into view
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let item = itemArray[indexPath.row]
        cell.textLabel?.text = item.title
        cell.accessoryType = item.done ? .checkmark : .none
        cell.backgroundColor = UIColor(red: 1, green: 0.949, blue: 0.882, alpha: 1) // #fff2e1
        return cell
    }
    
    //cell is tapped
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("[d] selected<##> \(itemArray[indexPath.row])")
        tableView.deselectRow(at: indexPath, animated: true)
        let item = itemArray[indexPath.row]

        if item.done {
            promptChoice(at: indexPath)
        }
        else {
            toggle(cell: tableView.cellForRow(at: indexPath), indexPath: indexPath)
        }
        
    }
    
    //swipe to delete
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "delete") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            
            //delete data
            self.delete(index: indexPath.row)
            
            //delete from table view
            self.tableView.deleteRows(at: [indexPath], with: .fade)
       
            completionHandler(true)
        }
        
        deleteAction.backgroundColor = .red
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    //delete, do nothing, uncheck
    func promptChoice(at indexPath: IndexPath) {
        let alert = UIAlertController(title: "Actions", message: "", preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { alertAction in
            self.delete(index: indexPath.row)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { alertAction in
            alert.dismiss(animated: true)
        }
        let uncheckAction = UIAlertAction(title: "Uncheck", style: .default) { alertAction in
            self.toggle(cell: self.tableView.cellForRow(at: indexPath), indexPath: indexPath)
        }
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        alert.addAction(uncheckAction)
        present(alert, animated: true)
    }
    
    func getDocumentID(item: ItemModel) async -> String {
        guard let itemTitle = item.title else {
            print("[d] no item title for \(item)")
            return ""
        }
        guard let category = selectedCategory else {
            print("[d] no category")
            return ""
        }
        
        do {
            guard let documentID = try await getDocumentIDByTitle(title: itemTitle, selectedCategory: category, categoryID: categoryID) else {
                print("[d] no document id found for<##> \(itemTitle)")
                return ""
            }
            return documentID
        } catch {
            print("[d] Document not found for title: \(itemTitle)")
            return ""
        }
    }
    
    //add item
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Add SubTask", message: "", preferredStyle: .alert)
        var text: String? = ""
        
        let action = UIAlertAction(title: "Add SubTask", style: .default) { alertAction in
            text = alert.textFields?.first?.text
            guard let text, !text.isEmpty else { return }
            
            guard let category = self.selectedCategory else {
                print("[d] no item category")
                return
            }
            guard let categoryName = category.name else {
                print("[d] no item category")
                return
            }
            
            let item = ItemModel(title: text, category: categoryName)
            
            self.addData(item: item)
            
            self.itemArray.append(item)
            
            print("[d] itemarray<##> \(self.itemArray)")
            
            self.tableView.reloadData()
        }
        
        alert.addTextField { $0.placeholder = "Create new subtask" }
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    //MARK: - Data Manipulation Methods
    
    //load firebase data
    func loadData() {
        guard let category = selectedCategory else {
            print("[d] no category selected")
            return
        }
        spinner.startAnimating()
        //set category id here
        Task {
            guard let documentID = try? await getDocumentIDByCategory(selectedCategory: category) else {
                print("[d] Document not found for category: \(category)")
                return
            }
            
            categoryID = documentID
            
            var array: [ItemModel] = []
            let querySnapshot = try await db.collection("category").document(categoryID).collection("contents").getDocuments()

            for document in querySnapshot.documents {
                guard let item = try? document.data(as: ItemModel.self) else {
                    print("[d] Document does not exist or failed to decode")
                    return
                }
                array.append(item)
            }

            //completed items will be moved to the top of the list
            itemArray = array.sorted { $0.done && !$1.done }
            tableView.reloadData()
            
            spinner.stopAnimating()
        }
    }
    
    //adds data to firebase
    func addData(item: ItemModel) {
        guard let itemCategory = item.category else {
            print("[d] no item category name for \(item)")
            return
        }
        
        guard let itemTitle = item.title else {
            print("[d] no item title for \(item)")
            return
        }
        
        Task {
            do {
                let data = [
                    "category": itemCategory,
                    "title": itemTitle,
                    "done": item.done
                ]
                
                //create new document in category -> contents
                let ref = db.collection("category").document(categoryID).collection("contents").document()
                try await ref.setData(data)
          
//              print("[d] Document added with ID: \(ref.documentID)")
            } catch {
              print("[d] Error adding document: \(error)")
            }
        }
     
    }
    
    //deletes firebase data
    override func delete(index: Int) {
        let item = itemArray[index]
        itemArray.remove(at: index)
        
        Task {
            do {
                let documentID = await getDocumentID(item: item)
                try await db.collection("category").document(categoryID).collection("contents")
                    .document(documentID).delete()
                
                tableView.reloadData()
                
//                print("[d] Deleted document: \(documentID)")
            } catch {
                print("[d] Error modifying document: \(error)")
            }
        }
    }
    
    //toggles item completion and updates firebase data
    func toggle(cell: UITableViewCell?, indexPath: IndexPath) {
        guard let cell else { return }
     
        let item = itemArray[indexPath.row]
        cell.accessoryType = !item.done ? .checkmark : .none
        item.done = !item.done
        
        itemArray[indexPath.row] = item
        
        //update done data for item
        Task {
            do {
                let documentID = await getDocumentID(item: item)
                try await db.collection("category").document(categoryID).collection("contents")
                    .document(documentID)
                    .updateData([
                     "done": item.done
                ])
            } catch {
                print("[d] Error updating document: \(error)")
            }
        }
    }
}

//MARK: - Search Bar
extension ToDoListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let text = searchBar.text else {return}
        
        if text.isEmpty || itemArray.isEmpty {
            loadData()
        } else {
            //list items based on the text that's typed in
            var array: [ItemModel] = []
            itemArray.forEach { item in
                if let title = item.title {
                    if(title.starts(with: text)) {
                        array.append(item)
                    }
                }
            }
            itemArray = array.sorted { $0.done && !$1.done }
            tableView.reloadData()
        
            Task {
                self.tableView.reloadData()
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        loadData()
        searchBar.resignFirstResponder()
    }
}
