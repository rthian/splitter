//
//  PersonSummaryCard.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import SwiftUI
import SwiftData

/// Card showing a person's bill breakdown and payment status
struct PersonSummaryCard: View {
    @Bindable var person: Person
    let bill: Bill
    @Bindable var viewModel: BillViewModel
    
    @State private var isExpanded = false
    @State private var showingEditSheet = false
    
    var body: some View {
        let breakdown = CalculationEngine.calculatePersonBreakdown(
            person: person,
            discountPercentage: bill.discountPercentage,
            serviceChargePercentage: bill.serviceChargePercentage,
            taxPercentage: bill.taxPercentage
        )
        
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                PersonAvatar(person: person, size: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if !person.paymentMethod.isEmpty {
                        Text(person.paymentMethod)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Payment status toggle
                Button(action: { viewModel.togglePaymentStatus(person) }) {
                    HStack(spacing: 4) {
                        Image(systemName: person.hasPaid ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(person.hasPaid ? .green : .secondary)
                        
                        Text(person.hasPaid ? "Paid" : "Pending")
                            .font(.caption)
                            .foregroundStyle(person.hasPaid ? .green : .secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(person.hasPaid ? Color.green.opacity(0.1) : Color(nsColor: .quaternarySystemFill))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Amount summary
            VStack(spacing: 6) {
                if breakdown.hasItems {
                    // Subtotal
                    HStack {
                        Text("Items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(bill.formatAmount(breakdown.subtotal))
                            .font(.caption)
                            .monospacedDigit()
                    }
                    
                    // Discount (if applicable)
                    if breakdown.discountAmount > 0 {
                        HStack {
                            Text("Discount")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("-\(bill.formatAmount(breakdown.discountAmount))")
                                .font(.caption)
                                .foregroundStyle(.green)
                                .monospacedDigit()
                        }
                    }
                    
                    // Service charge (if applicable)
                    if breakdown.serviceCharge > 0 {
                        HStack {
                            Text("Service")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(bill.formatAmount(breakdown.serviceCharge))
                                .font(.caption)
                                .monospacedDigit()
                        }
                    }
                    
                    // Tax
                    if breakdown.tax > 0 {
                        HStack {
                            Text("Tax")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(bill.formatAmount(breakdown.tax))
                                .font(.caption)
                                .monospacedDigit()
                        }
                    }
                    
                    Divider()
                }
                
                // Final amount
                HStack {
                    Text("Total")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(bill.formatAmount(breakdown.finalAmount))
                        .font(.title3)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
            }
            
            // Expandable items list
            if !person.itemSplits.isEmpty {
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    HStack {
                        Text("\(person.itemSplits.count) item\(person.itemSplits.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                if isExpanded {
                    VStack(spacing: 4) {
                        ForEach(person.itemSplits) { split in
                            if let item = split.item {
                                HStack {
                                    Text(item.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                    
                                    if split.percentage < 100 {
                                        Text("(\(split.displayString))")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(bill.formatAmount(split.amount))
                                        .font(.caption)
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            } else {
                Text("No items assigned")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        }
        .padding()
        .background(Color(nsColor: .textBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(person.hasPaid ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
        .contextMenu {
            Button("Edit") {
                showingEditSheet = true
            }
            
            Divider()
            
            Button(person.hasPaid ? "Mark as Unpaid" : "Mark as Paid") {
                viewModel.togglePaymentStatus(person)
            }
            
            Divider()
            
            Button("Remove from Bill", role: .destructive) {
                viewModel.deletePerson(person)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditPersonSheet(person: person, bill: bill, viewModel: viewModel)
        }
    }
}

// MARK: - Edit Person Sheet

struct EditPersonSheet: View {
    @Bindable var person: Person
    let bill: Bill
    @Bindable var viewModel: BillViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var paymentMethod: String = ""
    @State private var paymentDetails: String = ""
    
    private let paymentMethods = ["DuitNow", "TNG eWallet", "Bank Transfer", "Cash", "GrabPay", "ShopeePay"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Person")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // Form
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("Enter name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Phone Number")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("e.g., 010-1234567", text: $phoneNumber)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Payment Method")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(paymentMethods, id: \.self) { method in
                                Button(action: { paymentMethod = method }) {
                                    Text(method)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity)
                                        .background(paymentMethod == method ? Color.blue : Color(nsColor: .controlBackgroundColor))
                                        .foregroundStyle(paymentMethod == method ? .white : .primary)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        TextField("Or enter custom method", text: $paymentMethod)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Payment Details")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("e.g., phone number or account", text: $paymentDetails)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Button("Save") {
                    viewModel.updatePerson(person, name: name, paymentMethod: paymentMethod, paymentDetails: paymentDetails)
                    person.phoneNumber = phoneNumber
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 450)
        .onAppear {
            name = person.name
            phoneNumber = person.phoneNumber
            paymentMethod = person.paymentMethod
            paymentDetails = person.paymentDetails
        }
    }
}

// MARK: - Preview

#Preview {
    HStack {
        PersonSummaryCard(person: Person.mockAshley, bill: Bill.mockBill, viewModel: BillViewModel.preview)
        PersonSummaryCard(person: Person.mockZoel, bill: Bill.mockBill, viewModel: BillViewModel.preview)
    }
    .padding()
    .modelContainer(for: Bill.self, inMemory: true)
}
