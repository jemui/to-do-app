//
//  ItemModel.swift
//  ToDoApp
//
//  Created by Jeanette on 2/12/25.
//

import Foundation

class ItemModel: Codable {
    var category: String?
    var title: String?
    var done: Bool
    
    init(title: String, category: String) {
        self.title = title
        self.done = false
        self.category = category
    }
}
