//
//  Person.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import Foundation
import SwiftData

/// Represents a dining companion who can be assigned items and tracked for payment
@Model
final class Person {
    var id: UUID
    var name: String
    var phoneNumber: String
    var paymentMethod: String // e.g., "DuitNow", "TNG eWallet", "Bank Transfer"
    var paymentDetails: String // e.g., phone number or account number
    var isContact: Bool // If true, this person is saved as a reusable contact
    var createdAt: Date
    
    // Payment status for this bill
    var hasPaid: Bool
    var paidAt: Date?
    var paymentMethodUsed: String?
    
    // Relationships
    @Relationship(inverse: \Bill.people)
    var bill: Bill?
    
    @Relationship(deleteRule: .cascade)
    var itemSplits: [ItemSplit]
    
    init(
        id: UUID = UUID(),
        name: String = "",
        phoneNumber: String = "",
        paymentMethod: String = "",
        paymentDetails: String = "",
        isContact: Bool = false,
        hasPaid: Bool = false,
        paidAt: Date? = nil,
        paymentMethodUsed: String? = nil
    ) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.paymentMethod = paymentMethod
        self.paymentDetails = paymentDetails
        self.isContact = isContact
        self.createdAt = Date()
        self.hasPaid = hasPaid
        self.paidAt = paidAt
        self.paymentMethodUsed = paymentMethodUsed
        self.itemSplits = []
    }
    
    /// Creates a copy of this person for use in a new bill
    func copyForBill() -> Person {
        return Person(
            name: name,
            phoneNumber: phoneNumber,
            paymentMethod: paymentMethod,
            paymentDetails: paymentDetails,
            isContact: false
        )
    }
}

// MARK: - Computed Properties
extension Person {
    /// Calculate the subtotal for this person (sum of all item splits before tax/service)
    var subtotal: Decimal {
        itemSplits.reduce(Decimal.zero) { $0 + $1.amount }
    }
    
    /// Get initials for display in avatars
    var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
}

// MARK: - Mock Data for Previews
extension Person {
    static var mockAshley: Person {
        Person(name: "Ashley", phoneNumber: "010-1234567", paymentMethod: "DuitNow", paymentDetails: "010-1234567")
    }
    
    static var mockEugene: Person {
        Person(name: "Eugene", phoneNumber: "010-2345678", paymentMethod: "TNG eWallet", paymentDetails: "010-2345678")
    }
    
    static var mockZoel: Person {
        Person(name: "Zoel", phoneNumber: "010-3456789", paymentMethod: "Bank Transfer", paymentDetails: "1234567890")
    }
}
