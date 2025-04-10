//
//  TaskModel.swift
//  ToDo
//
//  Created by Ivan on 09.04.2025.
//

import UIKit

// MARK: - Task Model

struct Task: Codable, Identifiable {
    
    let id: String               // Unique ID (use let if ID doesn't change)
    var title: String
    var notes: String?
    var dueDate: Date?
    var isCompleted: Bool
    var priority: TaskPriority   // Use the nested enum
    var listId: String           // ID of the parent list
    var createdAt: Date
    var updatedAt: Date
    
    
    // Priority Enum (nested is fine)
    enum TaskPriority: Int, Codable, CaseIterable {
        case none = -1
        case low = 0
        case medium = 1
        case high = 2
        
        var description: String {
            switch self {
            case .none: return "None"
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
    }
    
    // Simple Initializer
    init(id: String = UUID().uuidString, // Auto-generate ID by default
         title: String,
         listId: String,
         notes: String? = nil,
         dueDate: Date? = nil,
         isCompleted: Bool = false,
         priority: TaskPriority = .none,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.title = title
        self.listId = listId
        self.notes = notes
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // Helper to create a dictionary for Firebase (needed for PUT/PATCH)
    // We only include fields that can change, plus identifiers
    func toDictionaryForUpdate() -> [String: Any] {
         var dict: [String: Any] = [
             "id": id, // Include ID for consistency, though it's in the path
             "title": title,
             "isCompleted": isCompleted,
             "priority": priority.rawValue,
             "listId": listId, // Usually needed
             "createdAt": createdAt.timeIntervalSince1970, // Keep original creation
             "updatedAt": Date().timeIntervalSince1970 // Always update 'updatedAt' on change
         ]
         // Add optional fields ONLY if they have a value
         if let notes = notes { dict["notes"] = notes }
         if let dueDate = dueDate { dict["dueDate"] = dueDate.timeIntervalSince1970 }
         return dict
     }

    // Static helper to create a Task from a Firebase Dictionary
    // Firebase often returns data as [String: Any]
     static func fromDictionary(_ dict: [String: Any]) -> Task? {
         guard
             let id = dict["id"] as? String,
             let title = dict["title"] as? String,
             let isCompleted = dict["isCompleted"] as? Bool,
             let priorityRaw = dict["priority"] as? Int,
             let priority = TaskPriority(rawValue: priorityRaw),
             let listId = dict["listId"] as? String,
             let createdAtTimestamp = dict["createdAt"] as? TimeInterval,
             let updatedAtTimestamp = dict["updatedAt"] as? TimeInterval
         else {
             print("⚠️ Failed to parse Task dictionary: \(dict)")
             return nil
         }

         let notes = dict["notes"] as? String
         let dueDate = (dict["dueDate"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }

         return Task(
             id: id,
             title: title,
             listId: listId,
             notes: notes,
             dueDate: dueDate,
             isCompleted: isCompleted,
             priority: priority,
             createdAt: Date(timeIntervalSince1970: createdAtTimestamp),
             updatedAt: Date(timeIntervalSince1970: updatedAtTimestamp)
         )
     }
}
