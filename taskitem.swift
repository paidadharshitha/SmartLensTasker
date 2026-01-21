//
//  taskitem.swift
//  SmartLensTasker
//
//  Created by DHARSHITHA PAIDA on 20/01/26.
//

import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var priority: Priority
    var category: Category
    var createdAt: Date
    var dueDate: Date // Reminder/Deadline kosam idhi kothaga add chesam

    init(
        title: String,
        priority: Priority = .medium,
        category: Category = .personal,
        dueDate: Date = Date().addingTimeInterval(3600) // Default ga 1 hour tharvatha set avthundi
    ) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.priority = priority
        self.category = category
        self.createdAt = Date()
        self.dueDate = dueDate
    }
}

// Enums (Ivi ikkade unchandi)
enum Priority: String, Codable, CaseIterable {
    case low = "Low 🟢"
    case medium = "Medium 🟡"
    case high = "High 🔴"
}

enum Category: String, Codable, CaseIterable {
    case work = "Work 💼"
    case personal = "Personal 🏠"
    case shopping = "Shopping 🛒"
    case health = "Health 🏥"
}
