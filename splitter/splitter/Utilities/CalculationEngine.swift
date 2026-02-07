//
//  CalculationEngine.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import Foundation

/// Calculation engine that replicates the spreadsheet formula logic
/// Formula per person:
/// 1. Subtotal = Sum of items assigned to person
/// 2. After Discount = Subtotal × (1 - discount%)
/// 3. Service Charge = After Discount × service%
/// 4. Tax = (After Discount + Service) × tax%
/// 5. Final Amount = After Discount + Service + Tax
struct CalculationEngine {
    
    // MARK: - Per-Person Calculations
    
    /// Calculate the breakdown for a single person
    static func calculatePersonBreakdown(
        person: Person,
        discountPercentage: Decimal,
        serviceChargePercentage: Decimal,
        taxPercentage: Decimal
    ) -> PersonBreakdown {
        // Step 1: Calculate subtotal from all item splits
        let subtotal = person.subtotal
        
        // Step 2: Apply discount
        let discountAmount = subtotal * (discountPercentage / 100)
        let afterDiscount = subtotal - discountAmount
        
        // Step 3: Calculate service charge on discounted amount
        let serviceCharge = afterDiscount * (serviceChargePercentage / 100)
        
        // Step 4: Calculate tax on (afterDiscount + serviceCharge)
        let taxableAmount = afterDiscount + serviceCharge
        let tax = taxableAmount * (taxPercentage / 100)
        
        // Step 5: Calculate final amount
        let finalAmount = afterDiscount + serviceCharge + tax
        
        return PersonBreakdown(
            person: person,
            subtotal: subtotal,
            discountAmount: discountAmount,
            afterDiscount: afterDiscount,
            serviceCharge: serviceCharge,
            tax: tax,
            finalAmount: finalAmount
        )
    }
    
    /// Calculate breakdowns for all people in a bill
    static func calculateAllBreakdowns(for bill: Bill) -> [PersonBreakdown] {
        bill.people.map { person in
            calculatePersonBreakdown(
                person: person,
                discountPercentage: bill.discountPercentage,
                serviceChargePercentage: bill.serviceChargePercentage,
                taxPercentage: bill.taxPercentage
            )
        }
    }
    
    // MARK: - Bill Totals
    
    /// Calculate the total breakdown for the entire bill
    static func calculateBillTotals(for bill: Bill) -> BillTotals {
        let subtotal = bill.subtotal
        let discountAmount = subtotal * (bill.discountPercentage / 100)
        let afterDiscount = subtotal - discountAmount
        let serviceCharge = afterDiscount * (bill.serviceChargePercentage / 100)
        let taxableAmount = afterDiscount + serviceCharge
        let tax = taxableAmount * (bill.taxPercentage / 100)
        let grandTotal = afterDiscount + serviceCharge + tax
        
        // Calculate per-person breakdowns
        let personBreakdowns = calculateAllBreakdowns(for: bill)
        let totalFromPeople = personBreakdowns.reduce(Decimal.zero) { $0 + $1.finalAmount }
        
        // Calculate unassigned amount (items not yet assigned to anyone)
        let assignedSubtotal = bill.people.reduce(Decimal.zero) { $0 + $1.subtotal }
        let unassignedSubtotal = subtotal - assignedSubtotal
        
        return BillTotals(
            subtotal: subtotal,
            discountAmount: discountAmount,
            afterDiscount: afterDiscount,
            serviceCharge: serviceCharge,
            tax: tax,
            grandTotal: grandTotal,
            totalFromPeople: totalFromPeople,
            unassignedAmount: unassignedSubtotal,
            personBreakdowns: personBreakdowns
        )
    }
    
    // MARK: - Splitting Helpers
    
    /// Split an amount equally among N people
    static func splitEqually(amount: Decimal, among count: Int) -> Decimal {
        guard count > 0 else { return amount }
        return amount / Decimal(count)
    }
    
    /// Calculate the share based on percentage
    static func calculateShare(of amount: Decimal, percentage: Decimal) -> Decimal {
        amount * (percentage / 100)
    }
    
    /// Round to 2 decimal places for currency
    static func roundToCurrency(_ value: Decimal) -> Decimal {
        var result = value
        var rounded = Decimal()
        NSDecimalRound(&rounded, &result, 2, .bankers)
        return rounded
    }
    
    // MARK: - Validation
    
    /// Check if all items are fully assigned
    static func validateAssignments(for bill: Bill) -> AssignmentValidation {
        var unassignedItems: [BillItem] = []
        var partiallyAssignedItems: [BillItem] = []
        
        for item in bill.items {
            let totalAssigned = item.splits.reduce(Decimal.zero) { $0 + $1.amount }
            
            if totalAssigned == 0 {
                unassignedItems.append(item)
            } else if totalAssigned < item.totalAmount {
                partiallyAssignedItems.append(item)
            }
        }
        
        return AssignmentValidation(
            isComplete: unassignedItems.isEmpty && partiallyAssignedItems.isEmpty,
            unassignedItems: unassignedItems,
            partiallyAssignedItems: partiallyAssignedItems
        )
    }
}

// MARK: - Supporting Types

/// Breakdown of amounts for a single person
struct PersonBreakdown: Identifiable {
    let person: Person
    let subtotal: Decimal
    let discountAmount: Decimal
    let afterDiscount: Decimal
    let serviceCharge: Decimal
    let tax: Decimal
    let finalAmount: Decimal
    
    var id: UUID { person.id }
    
    /// Items this person is paying for
    var items: [(item: BillItem, split: ItemSplit)] {
        person.itemSplits.compactMap { split in
            guard let item = split.item else { return nil }
            return (item, split)
        }
    }
    
    /// Check if this person has any items assigned
    var hasItems: Bool {
        !person.itemSplits.isEmpty
    }
}

/// Total calculations for the entire bill
struct BillTotals {
    let subtotal: Decimal
    let discountAmount: Decimal
    let afterDiscount: Decimal
    let serviceCharge: Decimal
    let tax: Decimal
    let grandTotal: Decimal
    let totalFromPeople: Decimal
    let unassignedAmount: Decimal
    let personBreakdowns: [PersonBreakdown]
    
    /// Check if there's any difference between grand total and sum of person totals
    var hasDifference: Bool {
        abs(grandTotal - totalFromPeople) > Decimal(string: "0.01")!
    }
    
    /// The difference amount (positive means unassigned, negative means over-assigned)
    var difference: Decimal {
        grandTotal - totalFromPeople
    }
}

/// Validation result for item assignments
struct AssignmentValidation {
    let isComplete: Bool
    let unassignedItems: [BillItem]
    let partiallyAssignedItems: [BillItem]
    
    var hasIssues: Bool {
        !isComplete
    }
    
    var issueCount: Int {
        unassignedItems.count + partiallyAssignedItems.count
    }
}

// MARK: - Formatting Helpers

extension CalculationEngine {
    /// Format a decimal as currency string with symbol
    static func formatCurrency(_ value: Decimal, symbol: String = "RM") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        let formattedNumber = formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
        return "\(symbol)\(formattedNumber)"
    }
    
    /// Format a percentage for display
    static func formatPercentage(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        let formattedNumber = formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
        return "\(formattedNumber)%"
    }
}
