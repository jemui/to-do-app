//
//  SwipeTableViewController.swift
//  ToDoApp
//
//  Created by Jeanette on 2/21/25.
//

import UIKit

class SwipeTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = Constants.tableRowHeight
        
    }
    
    //when cell scrolls into view
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "delete") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
           
            //delete data
            self.delete(index: indexPath.row)
            
            // Delete the row with animation
            self.tableView.deleteRows(at: [indexPath], with: .fade)
       
            completionHandler(true)
        }
        
        deleteAction.backgroundColor = .red
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    func delete(index: Int) {
        print("[d] attempt to delete cell<##>")
    }
}
