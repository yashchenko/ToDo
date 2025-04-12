//
//  Task List.swift
//  ToDo
//
//  Created by Ivan on 10.04.2025.
//

import UIKit
// MARK: - TaskList Model

struct TaskList: Codable, Identifiable { // Use struct
    let id: String
    var name: String
    var colorHex: String // Store color as hex string
    var orderIndex: Int  // For sorting lists
    var createdAt: Date
    var updatedAt: Date

    // Simple Initializer
    init(id: String = UUID().uuidString,
         name: String,
         colorHex: String = "#007AFF", // Default Blue
         orderIndex: Int = 0,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Helper to create a dictionary for Firebase updates
     func toDictionaryForUpdate() -> [String: Any] {
         return [
             "id": id,
             "name": name,
             "colorHex": colorHex,
             "orderIndex": orderIndex,
             "createdAt": createdAt.timeIntervalSince1970,
             "updatedAt": Date().timeIntervalSince1970 // Update timestamp
         ]
     }

     // Static helper to create a TaskList from a Firebase Dictionary
     static func fromDictionary(_ dict: [String: Any]) -> TaskList? {
         guard
             let id = dict["id"] as? String,
             let name = dict["name"] as? String,
             let colorHex = dict["colorHex"] as? String,
             let orderIndex = dict["orderIndex"] as? Int,
             let createdAtTimestamp = dict["createdAt"] as? TimeInterval,
             let updatedAtTimestamp = dict["updatedAt"] as? TimeInterval
         else {
             print("⚠️ Failed to parse TaskList dictionary: \(dict)")
             return nil
         }

         return TaskList(
             id: id,
             name: name,
             colorHex: colorHex,
             orderIndex: orderIndex,
             createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
             updatedAt: Date(timeIntervalSince1970: updatedAtTimestamp)
         )
     }
}
