//
//  Bill.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import Foundation
import SwiftData

/// Represents a complete bill/dining session
@Model
final class Bill {
    var id: UUID
    var placeName: String
    var date: Date
    var notes: String
    
    // Percentage values (stored as whole numbers, e.g., 6 for 6%)
    var discountPercentage: Decimal
    var serviceChargePercentage: Decimal
    var taxPercentage: Decimal
    
    // Currency
    var currencyCode: String // e.g., "MYR", "SGD", "USD"
    
    // Payment recipient info
    var payToName: String
    var payToMethod: String // e.g., "DuitNow or TNG eWallet"
    var payToDetails: String // e.g., phone number or account
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var items: [BillItem]
    
    @Relationship(deleteRule: .cascade)
    var people: [Person]
    
    init(
        id: UUID = UUID(),
        placeName: String = "",
        date: Date = Date(),
        notes: String = "",
        discountPercentage: Decimal = 0,
        serviceChargePercentage: Decimal = 0,
        taxPercentage: Decimal = 6, // Default 6% SST in Malaysia
        currencyCode: String = "MYR",
        payToName: String = "",
        payToMethod: String = "",
        payToDetails: String = "",
        isArchived: Bool = false
    ) {
        self.id = id
        self.placeName = placeName
        self.date = date
        self.notes = notes
        self.discountPercentage = discountPercentage
        self.serviceChargePercentage = serviceChargePercentage
        self.taxPercentage = taxPercentage
        self.currencyCode = currencyCode
        self.payToName = payToName
        self.payToMethod = payToMethod
        self.payToDetails = payToDetails
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isArchived = isArchived
        self.items = []
        self.people = []
    }
    
    /// Mark the bill as updated
    func markUpdated() {
        updatedAt = Date()
    }
}

// MARK: - Computed Properties
extension Bill {
    /// Total of all items before any adjustments
    var subtotal: Decimal {
        items.reduce(Decimal.zero) { $0 + $1.totalAmount }
    }
    
    /// Discount amount
    var discountAmount: Decimal {
        subtotal * (discountPercentage / 100)
    }
    
    /// Amount after discount
    var afterDiscount: Decimal {
        subtotal - discountAmount
    }
    
    /// Service charge amount
    var serviceChargeAmount: Decimal {
        afterDiscount * (serviceChargePercentage / 100)
    }
    
    /// Tax amount (applied to subtotal after discount + service charge)
    var taxAmount: Decimal {
        (afterDiscount + serviceChargeAmount) * (taxPercentage / 100)
    }
    
    /// Grand total
    var grandTotal: Decimal {
        afterDiscount + serviceChargeAmount + taxAmount
    }
    
    /// Check if all people have paid
    var isFullyPaid: Bool {
        !people.isEmpty && people.allSatisfy { $0.hasPaid }
    }
    
    /// Count of people who have paid
    var paidCount: Int {
        people.filter { $0.hasPaid }.count
    }
    
    /// Currency symbol for display
    var currencySymbol: String {
        switch currencyCode {
        case "MYR": return "RM"
        case "SGD": return "S$"
        case "USD": return "$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "THB": return "฿"
        case "IDR": return "Rp"
        case "PHP": return "₱"
        case "VND": return "₫"
        default: return currencyCode
        }
    }
    
    /// Format a decimal value with the bill's currency
    func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        let formattedNumber = formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "\(amount)"
        return "\(currencySymbol)\(formattedNumber)"
    }
    
    /// Display date string
    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Short display for sidebar
    var shortDisplayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Bill Management
extension Bill {
    /// Add a new item to the bill
    func addItem(name: String, amount: Decimal, quantity: Int = 1) -> BillItem {
        let item = BillItem(
            name: name,
            amount: amount,
            quantity: quantity,
            sortOrder: items.count
        )
        item.bill = self
        items.append(item)
        markUpdated()
        return item
    }
    
    /// Remove an item from the bill
    func removeItem(_ item: BillItem) {
        items.removeAll { $0.id == item.id }
        markUpdated()
    }
    
    /// Add a person to the bill
    func addPerson(name: String) -> Person {
        let person = Person(name: name)
        person.bill = self
        people.append(person)
        markUpdated()
        return person
    }
    
    /// Add a person from contacts
    func addPersonFromContact(_ contact: Person) -> Person {
        let person = contact.copyForBill()
        person.bill = self
        people.append(person)
        markUpdated()
        return person
    }
    
    /// Remove a person from the bill
    func removePerson(_ person: Person) {
        people.removeAll { $0.id == person.id }
        markUpdated()
    }
    
    /// Duplicate this bill (for recurring scenarios)
    func duplicate() -> Bill {
        let newBill = Bill(
            placeName: placeName,
            discountPercentage: discountPercentage,
            serviceChargePercentage: serviceChargePercentage,
            taxPercentage: taxPercentage,
            currencyCode: currencyCode,
            payToName: payToName,
            payToMethod: payToMethod,
            payToDetails: payToDetails
        )
        
        // Copy people (without payment status)
        for person in people {
            let newPerson = person.copyForBill()
            newPerson.bill = newBill
            newBill.people.append(newPerson)
        }
        
        return newBill
    }
}

// MARK: - Mock Data for Previews
extension Bill {
    static var mockBill: Bill {
        let bill = Bill(
            placeName: "Guan's",
            date: Date(),
            discountPercentage: 0,
            serviceChargePercentage: 0,
            taxPercentage: 6,
            payToName: "Tan Chor Koon",
            payToMethod: "DuitNow or TNG eWallet",
            payToDetails: "010-3832929"
        )
        
        // Add mock items
        let item1 = BillItem.mockCheeseTeppanyaki
        item1.bill = bill
        bill.items.append(item1)
        
        let item2 = BillItem.mockChickenNoriRamen
        item2.bill = bill
        bill.items.append(item2)
        
        let item3 = BillItem.mockYakitoriYasaiRamen
        item3.bill = bill
        bill.items.append(item3)
        
        // Add mock people
        let ashley = Person.mockAshley
        ashley.bill = bill
        bill.people.append(ashley)
        
        let eugene = Person.mockEugene
        eugene.bill = bill
        bill.people.append(eugene)
        
        let zoel = Person.mockZoel
        zoel.hasPaid = true
        zoel.bill = bill
        bill.people.append(zoel)
        
        return bill
    }
    
    static var emptyBill: Bill {
        Bill(placeName: "New Bill")
    }
}
