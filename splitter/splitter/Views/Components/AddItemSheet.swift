//
//  AddItemSheet.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import SwiftUI
import SwiftData

/// Sheet for adding a new item to a bill
struct AddItemSheet: View {
    let bill: Bill
    @Bindable var viewModel: BillViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var itemName: String = ""
    @State private var amount: String = ""
    @State private var quantity: Int = 1
    @State private var assignToEveryone: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, amount
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Form
            VStack(spacing: 20) {
                // Item name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Item Name")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    TextField("e.g., Chicken Nori Ramen Set", text: $itemName)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .name)
                }
                
                // Amount and quantity row
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Amount (\(bill.currencySymbol))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Text(bill.currencySymbol)
                                .foregroundStyle(.secondary)
                            
                            TextField("0.00", text: $amount)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .amount)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Quantity")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Stepper(value: $quantity, in: 1...99) {
                            Text("\(quantity)")
                                .monospacedDigit()
                        }
                    }
                    .frame(width: 120)
                }
                
                // Quick assign option
                if !bill.people.isEmpty {
                    Toggle(isOn: $assignToEveryone) {
                        HStack {
                            Image(systemName: "person.3")
                            Text("Split equally among everyone")
                        }
                    }
                    .toggleStyle(.checkbox)
                }
                
                Spacer()
                
                // Preview
                if let amountDecimal = Decimal(string: amount), amountDecimal > 0 {
                    previewCard(amount: amountDecimal)
                }
            }
            .padding()
            
            Divider()
            
            // Footer
            footer
        }
        .frame(width: 400, height: 400)
        .onAppear {
            focusedField = .name
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("Add Item")
                .font(.headline)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    // MARK: - Preview Card
    
    private func previewCard(amount: Decimal) -> some View {
        let total = amount * Decimal(quantity)
        
        return VStack(spacing: 8) {
            HStack {
                Text("Total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(bill.formatAmount(total))
                    .font(.headline)
            }
            
            if assignToEveryone && !bill.people.isEmpty {
                let perPerson = total / Decimal(bill.people.count)
                HStack {
                    Text("Per person (\(bill.people.count) people)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(bill.formatAmount(perPerson))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape)
            
            Spacer()
            
            Button("Add Another") {
                addItem()
                clearForm()
            }
            .buttonStyle(.bordered)
            .disabled(!isValid)
            
            Button("Add Item") {
                addItem()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return)
            .disabled(!isValid)
        }
        .padding()
    }
    
    // MARK: - Helpers
    
    private var isValid: Bool {
        !itemName.isEmpty && Decimal(string: amount) != nil && Decimal(string: amount)! > 0
    }
    
    private func addItem() {
        guard let amountDecimal = Decimal(string: amount) else { return }
        
        viewModel.addItem(name: itemName, amount: amountDecimal, quantity: quantity)
        
        // If assign to everyone is checked and there are people
        if assignToEveryone && !bill.people.isEmpty {
            if let lastItem = bill.items.last {
                viewModel.splitItemEqually(lastItem, among: bill.people)
            }
        }
    }
    
    private func clearForm() {
        itemName = ""
        amount = ""
        quantity = 1
        assignToEveryone = false
        focusedField = .name
    }
}

// MARK: - Preview

#Preview {
    AddItemSheet(bill: Bill.mockBill, viewModel: BillViewModel.preview)
        .modelContainer(for: Bill.self, inMemory: true)
}
