//
//  BillViewModel.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import Foundation
import SwiftUI
import SwiftData

/// ViewModel for managing bill operations and state
@Observable
final class BillViewModel {
    
    // MARK: - Properties
    
    var selectedBill: Bill?
    var searchText: String = ""
    var showArchived: Bool = false
    var filterStatus: FilterStatus = .all
    
    // Sheet states
    var showingAddItem: Bool = false
    var showingAddPerson: Bool = false
    var showingSettings: Bool = false
    var showingContacts: Bool = false
    var showingExport: Bool = false
    
    // Edit states
    var editingItem: BillItem?
    var editingPerson: Person?
    var editingSplit: ItemSplit?
    
    // Alert states
    var showingDeleteConfirmation: Bool = false
    var itemToDelete: BillItem?
    var personToDelete: Person?
    
    // MARK: - Computed Properties
    
    /// Get the calculation breakdown for the selected bill
    var billTotals: BillTotals? {
        guard let bill = selectedBill else { return nil }
        return CalculationEngine.calculateBillTotals(for: bill)
    }
    
    /// Get breakdown for a specific person
    func breakdown(for person: Person) -> PersonBreakdown? {
        guard let bill = selectedBill else { return nil }
        return CalculationEngine.calculatePersonBreakdown(
            person: person,
            discountPercentage: bill.discountPercentage,
            serviceChargePercentage: bill.serviceChargePercentage,
            taxPercentage: bill.taxPercentage
        )
    }
    
    /// Validate assignments for the selected bill
    var assignmentValidation: AssignmentValidation? {
        guard let bill = selectedBill else { return nil }
        return CalculationEngine.validateAssignments(for: bill)
    }
    
    // MARK: - Bill Operations
    
    func createNewBill(context: ModelContext) -> Bill {
        let bill = Bill(placeName: "New Bill", date: Date())
        context.insert(bill)
        selectedBill = bill
        return bill
    }
    
    func duplicateBill(_ bill: Bill, context: ModelContext) {
        let newBill = bill.duplicate()
        context.insert(newBill)
        selectedBill = newBill
    }
    
    func deleteBill(_ bill: Bill, context: ModelContext) {
        if selectedBill?.id == bill.id {
            selectedBill = nil
        }
        context.delete(bill)
    }
    
    func archiveBill(_ bill: Bill) {
        bill.isArchived = true
        bill.markUpdated()
    }
    
    func unarchiveBill(_ bill: Bill) {
        bill.isArchived = false
        bill.markUpdated()
    }
    
    // MARK: - Item Operations
    
    func addItem(name: String, amount: Decimal, quantity: Int = 1) {
        guard let bill = selectedBill else { return }
        _ = bill.addItem(name: name, amount: amount, quantity: quantity)
    }
    
    func deleteItem(_ item: BillItem) {
        guard let bill = selectedBill else { return }
        bill.removeItem(item)
    }
    
    func updateItem(_ item: BillItem, name: String, amount: Decimal, quantity: Int) {
        item.name = name
        item.amount = amount
        item.quantity = quantity
        selectedBill?.markUpdated()
    }
    
    // MARK: - Person Operations
    
    func addPerson(name: String) {
        guard let bill = selectedBill else { return }
        _ = bill.addPerson(name: name)
    }
    
    func addPersonFromContact(_ contact: Person) {
        guard let bill = selectedBill else { return }
        _ = bill.addPersonFromContact(contact)
    }
    
    func deletePerson(_ person: Person) {
        guard let bill = selectedBill else { return }
        bill.removePerson(person)
    }
    
    func updatePerson(_ person: Person, name: String, paymentMethod: String, paymentDetails: String) {
        person.name = name
        person.paymentMethod = paymentMethod
        person.paymentDetails = paymentDetails
        selectedBill?.markUpdated()
    }
    
    func togglePaymentStatus(_ person: Person) {
        person.hasPaid.toggle()
        if person.hasPaid {
            person.paidAt = Date()
        } else {
            person.paidAt = nil
        }
        selectedBill?.markUpdated()
    }
    
    // MARK: - Split Operations
    
    func assignItemToPerson(_ item: BillItem, person: Person) {
        item.assignTo(person: person)
        selectedBill?.markUpdated()
    }
    
    func splitItemEqually(_ item: BillItem, among people: [Person]) {
        item.splitEqually(among: people)
        selectedBill?.markUpdated()
    }
    
    func createCustomSplit(_ item: BillItem, person: Person, amount: Decimal) {
        let percentage = item.totalAmount > 0 ? (amount / item.totalAmount) * 100 : 0
        let split = ItemSplit(amount: amount, percentage: percentage, isManualAmount: true)
        split.item = item
        split.person = person
        item.splits.append(split)
        person.itemSplits.append(split)
        selectedBill?.markUpdated()
    }
    
    func removeSplit(_ split: ItemSplit) {
        split.item?.splits.removeAll { $0.id == split.id }
        split.person?.itemSplits.removeAll { $0.id == split.id }
        selectedBill?.markUpdated()
    }
    
    func clearAllSplits(for item: BillItem) {
        for split in item.splits {
            split.person?.itemSplits.removeAll { $0.id == split.id }
        }
        item.splits.removeAll()
        selectedBill?.markUpdated()
    }
    
    // MARK: - Filtering
    
    func filteredBills(_ bills: [Bill]) -> [Bill] {
        var result = bills
        
        // Filter by archive status
        if !showArchived {
            result = result.filter { !$0.isArchived }
        }
        
        // Filter by payment status
        switch filterStatus {
        case .all:
            break
        case .paid:
            result = result.filter { $0.isFullyPaid }
        case .pending:
            result = result.filter { !$0.isFullyPaid }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { bill in
                bill.placeName.localizedCaseInsensitiveContains(searchText) ||
                bill.people.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Sort by date (newest first)
        result.sort { $0.date > $1.date }
        
        return result
    }
}

// MARK: - Filter Status

enum FilterStatus: String, CaseIterable, Identifiable {
    case all = "All"
    case paid = "Paid"
    case pending = "Pending"
    
    var id: String { rawValue }
}

// MARK: - Preview Helpers

extension BillViewModel {
    static var preview: BillViewModel {
        let viewModel = BillViewModel()
        viewModel.selectedBill = Bill.mockBill
        return viewModel
    }
}
