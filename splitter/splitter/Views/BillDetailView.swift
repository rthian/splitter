//
//  BillDetailView.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import SwiftUI
import SwiftData

/// Main view for editing a bill's details
struct BillDetailView: View {
    @Bindable var bill: Bill
    @Bindable var viewModel: BillViewModel
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Bill header
                BillHeaderSection(bill: bill)
                
                // Items section
                ItemsSection(bill: bill, viewModel: viewModel)
                
                // People section
                PeopleSection(bill: bill, viewModel: viewModel)
                
                // Bill summary
                BillSummarySection(bill: bill, viewModel: viewModel)
                
                // Payment details
                PaymentDetailsSection(bill: bill, viewModel: viewModel)
            }
            .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle(bill.placeName.isEmpty ? "Untitled Bill" : bill.placeName)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                toolbarButtons
            }
        }
        .sheet(isPresented: $viewModel.showingAddItem) {
            AddItemSheet(bill: bill, viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingAddPerson) {
            AddPersonSheet(bill: bill, viewModel: viewModel)
        }
    }
    
    // MARK: - Toolbar
    
    @ViewBuilder
    private var toolbarButtons: some View {
        Button(action: { viewModel.showingAddPerson = true }) {
            Label("Add Person", systemImage: "person.badge.plus")
        }
        
        Button(action: { viewModel.showingAddItem = true }) {
            Label("Add Item", systemImage: "plus.circle")
        }
        
        Menu {
            Button("Duplicate Bill") {
                viewModel.duplicateBill(bill, context: modelContext)
            }
            
            Divider()
            
            Button("Export as CSV") {
                ExportManager.exportToCSV(bill: bill)
            }
            
            Button("Copy Summary") {
                ExportManager.copyToClipboard(bill: bill)
            }
            
            Divider()
            
            if bill.isArchived {
                Button("Unarchive") {
                    viewModel.unarchiveBill(bill)
                }
            } else {
                Button("Archive") {
                    viewModel.archiveBill(bill)
                }
            }
        } label: {
            Label("More", systemImage: "ellipsis.circle")
        }
    }
}

// MARK: - Bill Header Section

struct BillHeaderSection: View {
    @Bindable var bill: Bill
    @State private var showingCurrencyPicker = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Place name and date row
            HStack(alignment: .top, spacing: 16) {
                // Place name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Restaurant / Place")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextField("Enter place name", text: $bill.placeName)
                        .textFieldStyle(.roundedBorder)
                        .font(.title3)
                }
                
                // Date picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    DatePicker("", selection: $bill.date, displayedComponents: .date)
                        .datePickerStyle(.field)
                        .labelsHidden()
                }
                .frame(width: 150)
                
                // Currency picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Currency")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Picker("", selection: $bill.currencyCode) {
                        ForEach(CurrencyManager.supportedCurrencies) { currency in
                            Text(currency.shortDisplay)
                                .tag(currency.code)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
            }
            
            Divider()
            
            // Discount, service charge, tax row
            HStack(spacing: 24) {
                PercentageField(
                    title: "Discount",
                    value: $bill.discountPercentage,
                    icon: "tag",
                    color: .green
                )
                
                PercentageField(
                    title: "Service Charge",
                    value: $bill.serviceChargePercentage,
                    icon: "person.2",
                    color: .blue
                )
                
                PercentageField(
                    title: "Tax (SST/GST)",
                    value: $bill.taxPercentage,
                    icon: "building.columns",
                    color: .orange
                )
                
                Spacer()
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Percentage Field

struct PercentageField: View {
    let title: String
    @Binding var value: Decimal
    let icon: String
    let color: Color
    
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 4) {
                TextField("0", text: $textValue)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .focused($isFocused)
                    .onAppear {
                        textValue = value == 0 ? "" : "\(value)"
                    }
                    .onChange(of: isFocused) { _, focused in
                        if !focused {
                            if let newValue = Decimal(string: textValue) {
                                value = max(0, min(100, newValue))
                            } else {
                                value = 0
                            }
                            textValue = value == 0 ? "" : "\(value)"
                        }
                    }
                
                Text("%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Items Section

struct ItemsSection: View {
    @Bindable var bill: Bill
    @Bindable var viewModel: BillViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Items", systemImage: "list.bullet")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { viewModel.showingAddItem = true }) {
                    Label("Add Item", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            
            if bill.items.isEmpty {
                emptyItemsView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(bill.items.sorted(by: { $0.sortOrder < $1.sortOrder })) { item in
                        ItemRow(item: item, bill: bill, viewModel: viewModel)
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var emptyItemsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            
            Text("No items added")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button("Add First Item") {
                viewModel.showingAddItem = true
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - People Section

struct PeopleSection: View {
    @Bindable var bill: Bill
    @Bindable var viewModel: BillViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("People", systemImage: "person.3")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { viewModel.showingContacts = true }) {
                    Label("From Contacts", systemImage: "person.crop.circle.badge.plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                
                Button(action: { viewModel.showingAddPerson = true }) {
                    Label("Add Person", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            
            if bill.people.isEmpty {
                emptyPeopleView
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(bill.people) { person in
                        PersonSummaryCard(person: person, bill: bill, viewModel: viewModel)
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var emptyPeopleView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            
            Text("No people added")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Button("Add First Person") {
                viewModel.showingAddPerson = true
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

// MARK: - Bill Summary Section

struct BillSummarySection: View {
    let bill: Bill
    @Bindable var viewModel: BillViewModel
    
    var body: some View {
        let totals = CalculationEngine.calculateBillTotals(for: bill)
        
        VStack(alignment: .leading, spacing: 12) {
            Label("Bill Summary", systemImage: "chart.bar")
                .font(.headline)
            
            Divider()
            
            VStack(spacing: 8) {
                SummaryRow(title: "Subtotal", amount: totals.subtotal, bill: bill)
                
                if totals.discountAmount > 0 {
                    SummaryRow(
                        title: "Discount (\(CalculationEngine.formatPercentage(bill.discountPercentage)))",
                        amount: -totals.discountAmount,
                        bill: bill,
                        color: .green
                    )
                }
                
                if totals.serviceCharge > 0 {
                    SummaryRow(
                        title: "Service Charge (\(CalculationEngine.formatPercentage(bill.serviceChargePercentage)))",
                        amount: totals.serviceCharge,
                        bill: bill
                    )
                }
                
                if totals.tax > 0 {
                    SummaryRow(
                        title: "Tax (\(CalculationEngine.formatPercentage(bill.taxPercentage)))",
                        amount: totals.tax,
                        bill: bill
                    )
                }
                
                Divider()
                
                SummaryRow(
                    title: "Grand Total",
                    amount: totals.grandTotal,
                    bill: bill,
                    isTotal: true
                )
                
                if totals.unassignedAmount > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text("Unassigned: \(bill.formatAmount(totals.unassignedAmount))")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Summary Row

struct SummaryRow: View {
    let title: String
    let amount: Decimal
    let bill: Bill
    var color: Color = .primary
    var isTotal: Bool = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(isTotal ? .headline : .body)
                .foregroundStyle(color)
            
            Spacer()
            
            Text(bill.formatAmount(amount))
                .font(isTotal ? .headline : .body)
                .fontWeight(isTotal ? .bold : .regular)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Payment Details Section

struct PaymentDetailsSection: View {
    @Bindable var bill: Bill
    @Bindable var viewModel: BillViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Payment Details", systemImage: "creditcard")
                .font(.headline)
            
            Divider()
            
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pay To")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("Name", text: $bill.payToName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Payment Method")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("e.g., DuitNow, TNG", text: $bill.payToMethod)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account/Phone")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("e.g., 010-1234567", text: $bill.payToDetails)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // Payment status summary
                if !bill.people.isEmpty {
                    Divider()
                    
                    HStack {
                        let paidCount = bill.paidCount
                        let totalCount = bill.people.count
                        
                        Circle()
                            .fill(bill.isFullyPaid ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)
                        
                        Text("\(paidCount)/\(totalCount) paid")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        if !bill.isFullyPaid {
                            Button("Mark All Paid") {
                                for person in bill.people {
                                    if !person.hasPaid {
                                        viewModel.togglePaymentStatus(person)
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    BillDetailView(bill: Bill.mockBill, viewModel: BillViewModel.preview)
        .modelContainer(for: Bill.self, inMemory: true)
}
