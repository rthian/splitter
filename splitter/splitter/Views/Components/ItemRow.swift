//
//  ItemRow.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import SwiftUI
import SwiftData

/// Row view for displaying and editing a bill item
struct ItemRow: View {
    @Bindable var item: BillItem
    let bill: Bill
    @Bindable var viewModel: BillViewModel
    
    @State private var isExpanded = false
    @State private var isEditing = false
    @State private var editName: String = ""
    @State private var editAmount: String = ""
    @State private var showingSplitEditor = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                // Expand/collapse button
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                }
                .buttonStyle(.plain)
                
                // Item info
                if isEditing {
                    editingView
                } else {
                    displayView
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(nsColor: .textBackgroundColor))
            
            // Expanded content - split details
            if isExpanded {
                expandedContent
            }
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .sheet(isPresented: $showingSplitEditor) {
            ItemSplitEditor(item: item, bill: bill, viewModel: viewModel)
        }
    }
    
    // MARK: - Display View
    
    private var displayView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name.isEmpty ? "Unnamed Item" : item.name)
                    .font(.body)
                    .lineLimit(1)
                
                if item.quantity > 1 {
                    Text("× \(item.quantity)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Split indicators
            if !item.splits.isEmpty {
                splitIndicators
            }
            
            // Amount
            Text(bill.formatAmount(item.totalAmount))
                .font(.body)
                .fontWeight(.medium)
                .monospacedDigit()
            
            // Edit/Delete menu
            Menu {
                Button("Edit") {
                    startEditing()
                }
                
                Button("Split Item") {
                    showingSplitEditor = true
                }
                
                Divider()
                
                Button("Delete", role: .destructive) {
                    viewModel.deleteItem(item)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .menuStyle(.borderlessButton)
            .frame(width: 24)
        }
    }
    
    // MARK: - Split Indicators
    
    private var splitIndicators: some View {
        HStack(spacing: -6) {
            ForEach(item.splits.prefix(3)) { split in
                if let person = split.person {
                    PersonAvatar(person: person, size: 24)
                }
            }
            
            if item.splits.count > 3 {
                ZStack {
                    Circle()
                        .fill(Color(nsColor: .systemGray))
                        .frame(width: 24, height: 24)
                    
                    Text("+\(item.splits.count - 3)")
                        .font(.caption2)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.trailing, 8)
    }
    
    // MARK: - Editing View
    
    private var editingView: some View {
        HStack {
            TextField("Item name", text: $editName)
                .textFieldStyle(.roundedBorder)
            
            TextField("Amount", text: $editAmount)
                .textFieldStyle(.roundedBorder)
                .frame(width: 100)
            
            Button("Save") {
                saveEdit()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Cancel") {
                isEditing = false
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Expanded Content
    
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            
            if item.splits.isEmpty {
                // No splits yet - show quick assign buttons
                HStack {
                    Text("Not assigned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button("Assign") {
                        showingSplitEditor = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    if !bill.people.isEmpty {
                        Button("Split Equally") {
                            viewModel.splitItemEqually(item, among: bill.people)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            } else {
                // Show current splits
                ForEach(item.splits) { split in
                    if let person = split.person {
                        HStack {
                            PersonAvatar(person: person, size: 20)
                            
                            Text(person.name)
                                .font(.caption)
                            
                            Text("(\(split.displayString))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            Text(bill.formatAmount(split.amount))
                                .font(.caption)
                                .monospacedDigit()
                            
                            Button(action: { viewModel.removeSplit(split) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                if item.unassignedAmount > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Text("Unassigned: \(bill.formatAmount(item.unassignedAmount))")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        
                        Spacer()
                        
                        Button("Modify Splits") {
                            showingSplitEditor = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
        .background(Color(nsColor: .textBackgroundColor))
    }
    
    // MARK: - Helpers
    
    private func startEditing() {
        editName = item.name
        editAmount = "\(item.amount)"
        isEditing = true
    }
    
    private func saveEdit() {
        if let amount = Decimal(string: editAmount) {
            viewModel.updateItem(item, name: editName, amount: amount, quantity: item.quantity)
        }
        isEditing = false
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ItemRow(item: BillItem.mockCheeseTeppanyaki, bill: Bill.mockBill, viewModel: BillViewModel.preview)
        ItemRow(item: BillItem.mockChickenNoriRamen, bill: Bill.mockBill, viewModel: BillViewModel.preview)
    }
    .padding()
    .modelContainer(for: Bill.self, inMemory: true)
}
