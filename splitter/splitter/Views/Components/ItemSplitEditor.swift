//
//  ItemSplitEditor.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import SwiftUI
import SwiftData

/// Editor for splitting an item among people
struct ItemSplitEditor: View {
    @Bindable var item: BillItem
    let bill: Bill
    @Bindable var viewModel: BillViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPeople: Set<UUID> = []
    @State private var splitMode: SplitMode = .equal
    @State private var customAmounts: [UUID: String] = [:]
    @State private var customPercentages: [UUID: String] = [:]
    
    enum SplitMode: String, CaseIterable, Identifiable {
        case equal = "Split Equally"
        case custom = "Custom Amounts"
        case percentage = "By Percentage"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Item info
                    itemInfoCard
                    
                    // Split mode picker
                    splitModePicker
                    
                    // People selection
                    peopleSelection
                    
                    // Preview
                    if !selectedPeople.isEmpty {
                        previewSection
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            footer
        }
        .frame(width: 500, height: 600)
        .onAppear {
            loadExistingSplits()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("Split Item")
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
    
    // MARK: - Item Info Card
    
    private var itemInfoCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                if item.quantity > 1 {
                    Text("Quantity: \(item.quantity)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text(bill.formatAmount(item.totalAmount))
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Split Mode Picker
    
    private var splitModePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Split Method")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Picker("", selection: $splitMode) {
                ForEach(SplitMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - People Selection
    
    private var peopleSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select People")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if !bill.people.isEmpty {
                    Button(selectedPeople.count == bill.people.count ? "Deselect All" : "Select All") {
                        if selectedPeople.count == bill.people.count {
                            selectedPeople.removeAll()
                        } else {
                            selectedPeople = Set(bill.people.map { $0.id })
                        }
                    }
                    .font(.caption)
                }
            }
            
            if bill.people.isEmpty {
                VStack(spacing: 8) {
                    Text("No people added yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button("Add Person") {
                        dismiss()
                        viewModel.showingAddPerson = true
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(bill.people) { person in
                        personRow(person)
                    }
                }
            }
        }
    }
    
    private func personRow(_ person: Person) -> some View {
        let isSelected = selectedPeople.contains(person.id)
        
        return HStack {
            // Selection checkbox
            Button(action: { togglePerson(person) }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            
            PersonAvatar(person: person, size: 32)
            
            Text(person.name)
                .font(.body)
            
            Spacer()
            
            // Custom input based on mode
            if isSelected && splitMode != .equal {
                customInputField(for: person)
            } else if isSelected && splitMode == .equal {
                let share = item.totalAmount / Decimal(max(1, selectedPeople.count))
                Text(bill.formatAmount(share))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(isSelected ? Color.blue.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
        .onTapGesture {
            togglePerson(person)
        }
    }
    
    @ViewBuilder
    private func customInputField(for person: Person) -> some View {
        switch splitMode {
        case .equal:
            EmptyView()
        case .custom:
            HStack {
                Text(bill.currencySymbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextField("0.00", text: Binding(
                    get: { customAmounts[person.id] ?? "" },
                    set: { customAmounts[person.id] = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
            }
        case .percentage:
            HStack {
                TextField("0", text: Binding(
                    get: { customPercentages[person.id] ?? "" },
                    set: { customPercentages[person.id] = $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .frame(width: 60)
                
                Text("%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 4) {
                ForEach(bill.people.filter { selectedPeople.contains($0.id) }) { person in
                    HStack {
                        Text(person.name)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text(bill.formatAmount(calculateShare(for: person)))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                
                Divider()
                
                let totalAssigned = bill.people
                    .filter { selectedPeople.contains($0.id) }
                    .reduce(Decimal.zero) { $0 + calculateShare(for: $1) }
                
                HStack {
                    Text("Total")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(bill.formatAmount(totalAssigned))
                        .font(.caption)
                        .fontWeight(.bold)
                }
                
                if abs(totalAssigned - item.totalAmount) > Decimal(string: "0.01")! {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text("Difference: \(bill.formatAmount(item.totalAmount - totalAssigned))")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            Button("Clear All") {
                viewModel.clearAllSplits(for: item)
                selectedPeople.removeAll()
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
            
            Button("Apply Split") {
                applySplit()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedPeople.isEmpty)
        }
        .padding()
    }
    
    // MARK: - Helpers
    
    private func togglePerson(_ person: Person) {
        if selectedPeople.contains(person.id) {
            selectedPeople.remove(person.id)
        } else {
            selectedPeople.insert(person.id)
        }
    }
    
    private func calculateShare(for person: Person) -> Decimal {
        switch splitMode {
        case .equal:
            return item.totalAmount / Decimal(max(1, selectedPeople.count))
        case .custom:
            if let amountStr = customAmounts[person.id], let amount = Decimal(string: amountStr) {
                return amount
            }
            return 0
        case .percentage:
            if let percentStr = customPercentages[person.id], let percent = Decimal(string: percentStr) {
                return item.totalAmount * (percent / 100)
            }
            return 0
        }
    }
    
    private func loadExistingSplits() {
        for split in item.splits {
            if let person = split.person {
                selectedPeople.insert(person.id)
                customAmounts[person.id] = "\(split.amount)"
                customPercentages[person.id] = "\(split.percentage)"
            }
        }
        
        // Determine split mode from existing splits
        if item.splits.count > 1 {
            let firstAmount = item.splits.first?.amount ?? 0
            let allEqual = item.splits.allSatisfy { $0.amount == firstAmount }
            splitMode = allEqual ? .equal : .custom
        }
    }
    
    private func applySplit() {
        // Clear existing splits
        viewModel.clearAllSplits(for: item)
        
        // Get selected people
        let people = bill.people.filter { selectedPeople.contains($0.id) }
        
        switch splitMode {
        case .equal:
            viewModel.splitItemEqually(item, among: people)
        case .custom:
            for person in people {
                if let amountStr = customAmounts[person.id], let amount = Decimal(string: amountStr), amount > 0 {
                    viewModel.createCustomSplit(item, person: person, amount: amount)
                }
            }
        case .percentage:
            for person in people {
                if let percentStr = customPercentages[person.id], let percent = Decimal(string: percentStr), percent > 0 {
                    let amount = item.totalAmount * (percent / 100)
                    viewModel.createCustomSplit(item, person: person, amount: amount)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ItemSplitEditor(item: BillItem.mockCheeseTeppanyaki, bill: Bill.mockBill, viewModel: BillViewModel.preview)
        .modelContainer(for: Bill.self, inMemory: true)
}
