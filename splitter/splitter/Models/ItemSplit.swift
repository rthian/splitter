//
//  ItemSplit.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import Foundation
import SwiftData

/// Represents how an item is split between people
/// Links a Person to a BillItem with the amount they owe for that item
@Model
final class ItemSplit {
    var id: UUID
    var amount: Decimal // The actual amount this person pays for this item
    var percentage: Decimal // What percentage of the item this represents (for display)
    var isManualAmount: Bool // True if user entered a specific amount instead of percentage
    var createdAt: Date
    
    // Relationships
    @Relationship(inverse: \BillItem.splits)
    var item: BillItem?
    
    @Relationship(inverse: \Person.itemSplits)
    var person: Person?
    
    init(
        id: UUID = UUID(),
        amount: Decimal = 0,
        percentage: Decimal = 100,
        isManualAmount: Bool = false
    ) {
        self.id = id
        self.amount = amount
        self.percentage = percentage
        self.isManualAmount = isManualAmount
        self.createdAt = Date()
    }
    
    /// Display string for the split (e.g., "1/2", "100%", or "$10.50")
    var displayString: String {
        if isManualAmount {
            return formatCurrency(amount)
        }
        
        // Try to show as fraction for common splits
        switch percentage {
        case 100:
            return "Full"
        case 50:
            return "1/2"
        case Decimal(string: "33.33")!, Decimal(string: "33.34")!:
            return "1/3"
        case 25:
            return "1/4"
        case 20:
            return "1/5"
        default:
            let formatter = NumberFormatter()
            formatter.numberStyle = .percent
            formatter.maximumFractionDigits = 1
            return formatter.string(from: NSDecimalNumber(decimal: percentage / 100)) ?? "\(percentage)%"
        }
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = ""
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
    }
}

// MARK: - Mock Data for Previews
extension ItemSplit {
    static var mockHalfSplit: ItemSplit {
        ItemSplit(amount: Decimal(string: "10.74")!, percentage: 50)
    }
    
    static var mockFullSplit: ItemSplit {
        ItemSplit(amount: Decimal(string: "21.47")!, percentage: 100)
    }
}
