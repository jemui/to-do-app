//
//  CategoryViewController.swift
//  ToDoApp
//
//  Created by Jeanette on 2/13/25.
//

import UIKit
import CoreData
import FirebaseCore
import FirebaseFirestore

class CategoryViewController: SwipeTableViewController {
    var categoryArray: [ItemCategories] = []
    var selectedIndexPath: IndexPath?
    
    let spinner = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadData()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
  
    func setupSpinner() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    //add new category
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Add New Task Category", message: "", preferredStyle: .alert)
        var text: String? = ""
        
        let action = UIAlertAction(title: "Add Task Category", style: .default) { alertAction in
            text = alert.textFields?.first?.text
            guard let text, !text.isEmpty else { return }
            let category = ItemCategories(name: text, userID: Constants.userId)
            
            self.categoryArray.append(category)
            self.addData(itemCategory: category)
            
            print("[d] create category \(text)")
            
            self.tableView.reloadData()
        }
        
        alert.addTextField { $0.placeholder = "Create new category" }
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    func addData(itemCategory: ItemCategories) {
        let db = Firestore.firestore()
        guard let itemCategory = itemCategory.name else {
            print("[d] no item category name")
            return
        }
        Task {
            do {
                let data = [
                    "name": itemCategory,
                    "userID": Constants.userId,
                ]
                let ref = db.collection("category").document()
                try await ref.setData(data)
              print("Document added with ID: \(ref.documentID)")
            } catch {
              print("Error adding document: \(error)")
            }
        }
    }
    
    
    //MARK: - TableView Datasource methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("[d] category array count<##> \(categoryArray.count)")
        return categoryArray.count
    }
    
   
    
    //MARK: - Data Manipulation Methods
    
    func loadData() {
        let db = Firestore.firestore()
        spinner.startAnimating()
        
        print("[d] loadData<##>")
        Task {
            do {
                var array: [ItemCategories] = []
                let querySnapshot = try await db.collection("category")
                    .whereField("userID", isEqualTo: Constants.userId)
                    .getDocuments()
                
//                print("[d] querySnapshot.documents: \(querySnapshot.documents)")
                
                for document in querySnapshot.documents {
                    guard let itemCategory = try? document.data(as: ItemCategories.self) else {
                        print("Document does not exist or failed to decode")
                        return
                    }
                    
                    array.append(itemCategory)
                }
                
                spinner.stopAnimating()
                categoryArray = array
//                print("[d] loaded categoryArray \(categoryArray)")
                tableView.reloadData()

            } catch {
              print("Error getting documents: \(error)")
            }
        }
    }
    
    override func delete(index: Int) {
        let category = categoryArray[index]
        let db = Firestore.firestore()
        
        print("[d] delete category \(category)")
        categoryArray.remove(at: index)
        
        Task {
            guard let categoryID = try? await getDocumentIDByCategory(selectedCategory: category) else {
                print("[d] Document not found for category: \(category)")
                return
            }

            do {
                try await db.collection("category").document(categoryID).delete()
                tableView.reloadData()
                
                print("[d] Deleted document: \(categoryID)")
            } catch {
                print("[d] Error modifying document: \(error)")
            }
            
        }
        
       
    }
    
    //MARK: - TableView Delegate Methods

    //when cell scrolls into view
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        cell.textLabel?.text = categoryArray[indexPath.row].name
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = UIColor(red: 1, green: 0.949, blue: 0.882, alpha: 1) // #fff2e1
        return cell
    }
    
    //cell is tapped
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        
        performSegue(withIdentifier: "goToItems", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("[d] prepare segue<##>")
        guard let destinationVC = segue.destination as? ToDoListViewController else {
            print("[d] no segue destination<##>")
            return
        }
        
        guard let indexPath = selectedIndexPath else {
            print("[d] no indexPath<##> \(String(describing: selectedIndexPath))")
            return
        }
//        guard let indexPath = tableView.indexPathForSelectedRow else {
//            print("[d] no indexPath<##> \(String(describing: tableView.index))")
//            return
//        }
        destinationVC.selectedCategory = categoryArray[indexPath.row]
        
        print("[d] set selected category<##> \(String(describing: destinationVC.selectedCategory))")
    }
}
