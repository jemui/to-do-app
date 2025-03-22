//
//  Utility.swift
//  ToDoApp
//
//  Created by Jeanette on 2/21/25.
//

import UIKit
import FirebaseCore
import FirebaseFirestore


func getDocumentIDByCategory(selectedCategory: ItemCategories) async throws -> String? {
    let db = Firestore.firestore()
    
    guard let category = selectedCategory.name else {
        print("[d] no item category")
        return ""
    }
//    print("[d] category: \(category)")
//        .document(userId).collection(itemCategory)
    let querySnapshot = try await db.collection("category")
        .whereField("name", isEqualTo: category)
        .getDocuments()
    
    guard let document = querySnapshot.documents.first else {
        print("No document found with title: \(category)")
        return nil
    }
    
    return document.documentID
}

func getDocumentIDByTitle(title: String, selectedCategory: ItemCategories, categoryID: String) async throws -> String? {
    let db = Firestore.firestore()
    
//    print("[d] title:<##> \(title), category: \(category)")
//        .document(userId).collection(itemCategory)
    let querySnapshot = try await db.collection("category").document(categoryID).collection("contents")
        .whereField("title", isEqualTo: title)
        .getDocuments()
    
    guard let document = querySnapshot.documents.first else {
        print("No document found with title: \(title)")
        return nil
    }
    
    return document.documentID
}
