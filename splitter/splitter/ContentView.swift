//
//  ContentView.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import SwiftUI
import SwiftData

/// Main content view with sidebar navigation
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = BillViewModel()
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel)
        } detail: {
            if let bill = viewModel.selectedBill {
                BillDetailView(bill: bill, viewModel: viewModel)
            } else {
                emptyStateView
            }
        }
        .navigationSplitViewStyle(.balanced)
        // Handle keyboard shortcuts and notifications
        .onReceive(NotificationCenter.default.publisher(for: .createNewBill)) { _ in
            _ = viewModel.createNewBill(context: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: .addItem)) { _ in
            if viewModel.selectedBill != nil {
                viewModel.showingAddItem = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .addPerson)) { _ in
            if viewModel.selectedBill != nil {
                viewModel.showingAddPerson = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showContacts)) { _ in
            viewModel.showingContacts = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSettings)) { _ in
            viewModel.showingSettings = true
        }
        .sheet(isPresented: $viewModel.showingContacts) {
            ContactsView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsView()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.below.ecg")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 8) {
                Text("No Bill Selected")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Select a bill from the sidebar or create a new one")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Button(action: createNewBill) {
                Label("Create New Bill", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            // Keyboard shortcut hint
            Text("Press ⌘N to create a new bill")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private func createNewBill() {
        _ = viewModel.createNewBill(context: modelContext)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Bill.self, inMemory: true)
}
