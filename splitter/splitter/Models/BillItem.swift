//
//  BillItem.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import Foundation
import SwiftData

/// Represents an individual menu item on a bill
@Model
final class BillItem {
    var id: UUID
    var name: String
    var amount: Decimal // Base price of the item
    var quantity: Int
    var notes: String
    var createdAt: Date
    var sortOrder: Int
    
    // Relationships
    @Relationship(inverse: \Bill.items)
    var bill: Bill?
    
    @Relationship(deleteRule: .cascade)
    var splits: [ItemSplit]
    
    init(
        id: UUID = UUID(),
        name: String = "",
        amount: Decimal = 0,
        quantity: Int = 1,
        notes: String = "",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.quantity = quantity
        self.notes = notes
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.splits = []
    }
    
    /// Total amount for this item (amount * quantity)
    var totalAmount: Decimal {
        amount * Decimal(quantity)
    }
    
    /// Check if the item is fully assigned (all portions accounted for)
    var isFullyAssigned: Bool {
        let totalAssigned = splits.reduce(Decimal.zero) { $0 + $1.amount }
        return totalAssigned >= totalAmount
    }
    
    /// Get the unassigned amount
    var unassignedAmount: Decimal {
        let totalAssigned = splits.reduce(Decimal.zero) { $0 + $1.amount }
        return max(Decimal.zero, totalAmount - totalAssigned)
    }
    
    /// Get people who are sharing this item
    var sharedBy: [Person] {
        splits.compactMap { $0.person }
    }
    
    /// Split this item equally among the given people
    func splitEqually(among people: [Person]) {
        guard !people.isEmpty else { return }
        
        // Remove existing splits
        splits.removeAll()
        
        // Create new equal splits
        let splitAmount = totalAmount / Decimal(people.count)
        for person in people {
            let split = ItemSplit(amount: splitAmount, percentage: Decimal(100) / Decimal(people.count))
            split.person = person
            split.item = self
            splits.append(split)
            person.itemSplits.append(split)
        }
    }
    
    /// Assign full item to a single person
    func assignTo(person: Person) {
        // Remove existing splits
        splits.removeAll()
        
        // Create new split for full amount
        let split = ItemSplit(amount: totalAmount, percentage: 100)
        split.person = person
        split.item = self
        splits.append(split)
        person.itemSplits.append(split)
    }
}

// MARK: - Mock Data for Previews
extension BillItem {
    static var mockCheeseTeppanyaki: BillItem {
        BillItem(name: "Cheese Teppanyaki Set", amount: Decimal(string: "21.47")!, sortOrder: 0)
    }
    
    static var mockChickenNoriRamen: BillItem {
        BillItem(name: "Chicken Nori Ramen Set", amount: Decimal(string: "38.63")!, sortOrder: 1)
    }
    
    static var mockYakitoriYasaiRamen: BillItem {
        BillItem(name: "Yakitori Yasai Ramen Set", amount: Decimal(string: "35.18")!, sortOrder: 2)
    }
}
