//
//  SidebarView.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import SwiftUI
import SwiftData

/// Sidebar showing bill history with search and filtering
struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bill.date, order: .reverse) private var bills: [Bill]
    @Bindable var viewModel: BillViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and new bill button
            headerView
            
            Divider()
            
            // Search bar
            searchBar
            
            // Filter pills
            filterPills
            
            Divider()
            
            // Bill list
            billList
            
            Divider()
            
            // Footer with stats
            footerStats
        }
        .frame(minWidth: 250, idealWidth: 280, maxWidth: 320)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("Bills")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(action: createNewBill) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .help("Create new bill")
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search bills...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
            
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(nsColor: .quaternarySystemFill))
        .cornerRadius(8)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Filter Pills
    
    private var filterPills: some View {
        HStack(spacing: 8) {
            ForEach(FilterStatus.allCases) { status in
                FilterPill(
                    title: status.rawValue,
                    isSelected: viewModel.filterStatus == status
                ) {
                    viewModel.filterStatus = status
                }
            }
            
            Spacer()
            
            Toggle(isOn: $viewModel.showArchived) {
                Image(systemName: "archivebox")
                    .foregroundStyle(viewModel.showArchived ? .blue : .secondary)
            }
            .toggleStyle(.button)
            .buttonStyle(.plain)
            .help("Show archived bills")
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Bill List
    
    private var billList: some View {
        let filteredBills = viewModel.filteredBills(bills)
        
        return Group {
            if filteredBills.isEmpty {
                emptyState
            } else {
                List(selection: $viewModel.selectedBill) {
                    ForEach(groupedBills(filteredBills), id: \.key) { month, monthBills in
                        Section(header: Text(month).font(.caption).foregroundStyle(.secondary)) {
                            ForEach(monthBills) { bill in
                                BillRowView(bill: bill, viewModel: viewModel)
                                    .tag(bill)
                                    .contextMenu {
                                        billContextMenu(for: bill)
                                    }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No bills found")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            if !viewModel.searchText.isEmpty {
                Text("Try a different search term")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                Button("Create New Bill") {
                    createNewBill()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Footer Stats
    
    private var footerStats: some View {
        let filteredBills = viewModel.filteredBills(bills)
        let pendingCount = filteredBills.filter { !$0.isFullyPaid }.count
        
        return HStack {
            Label("\(filteredBills.count) bills", systemImage: "doc.text")
            
            Spacer()
            
            if pendingCount > 0 {
                Label("\(pendingCount) pending", systemImage: "clock")
                    .foregroundStyle(.orange)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func billContextMenu(for bill: Bill) -> some View {
        Button("Duplicate") {
            viewModel.duplicateBill(bill, context: modelContext)
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
        
        Divider()
        
        Button("Delete", role: .destructive) {
            viewModel.deleteBill(bill, context: modelContext)
        }
    }
    
    // MARK: - Helpers
    
    private func createNewBill() {
        _ = viewModel.createNewBill(context: modelContext)
    }
    
    private func groupedBills(_ bills: [Bill]) -> [(key: String, value: [Bill])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        let grouped = Dictionary(grouping: bills) { bill in
            formatter.string(from: bill.date)
        }
        
        return grouped.sorted { first, second in
            guard let firstBill = first.value.first,
                  let secondBill = second.value.first else { return false }
            return firstBill.date > secondBill.date
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Color.blue : Color(nsColor: .quaternarySystemFill))
                .foregroundStyle(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bill Row View

struct BillRowView: View {
    let bill: Bill
    @Bindable var viewModel: BillViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(bill.placeName.isEmpty ? "Untitled" : bill.placeName)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                if bill.isFullyPaid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }
            
            HStack {
                Text(bill.shortDisplayDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(bill.formatAmount(bill.grandTotal))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            
            if !bill.people.isEmpty {
                HStack(spacing: -4) {
                    ForEach(bill.people.prefix(4)) { person in
                        PersonAvatar(person: person, size: 20)
                    }
                    
                    if bill.people.count > 4 {
                        Text("+\(bill.people.count - 4)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 8)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Person Avatar

struct PersonAvatar: View {
    let person: Person
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(avatarColor)
            
            Text(person.initials)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(
            Circle()
                .stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 2)
        )
    }
    
    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .teal]
        let hash = person.name.hashValue
        return colors[abs(hash) % colors.count]
    }
}

// MARK: - Preview

#Preview {
    SidebarView(viewModel: BillViewModel.preview)
        .modelContainer(for: Bill.self, inMemory: true)
}
