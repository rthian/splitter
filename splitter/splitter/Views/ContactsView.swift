//
//  ContactsView.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import SwiftUI
import SwiftData

/// View for managing saved contacts
struct ContactsView: View {
    @Bindable var viewModel: BillViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Person> { $0.isContact == true }) private var contacts: [Person]
    
    @State private var searchText = ""
    @State private var showingAddContact = false
    @State private var selectedContacts: Set<UUID> = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Search bar
            searchBar
            
            // Content
            if filteredContacts.isEmpty {
                emptyState
            } else {
                contactsList
            }
            
            Divider()
            
            // Footer
            footer
        }
        .frame(width: 500, height: 600)
        .sheet(isPresented: $showingAddContact) {
            AddContactSheet()
        }
    }
    
    // MARK: - Filtered Contacts
    
    private var filteredContacts: [Person] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("Contacts")
                .font(.headline)
            
            Spacer()
            
            Button(action: { showingAddContact = true }) {
                Image(systemName: "plus")
            }
            .buttonStyle(.bordered)
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search contacts...", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
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
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("No contacts saved")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Add contacts to quickly add them to future bills")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            
            Button("Add Contact") {
                showingAddContact = true
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Contacts List
    
    private var contactsList: some View {
        List(selection: $selectedContacts) {
            ForEach(filteredContacts) { contact in
                ContactRow(contact: contact, isSelected: selectedContacts.contains(contact.id)) {
                    toggleSelection(contact)
                }
                .tag(contact.id)
            }
            .onDelete(perform: deleteContacts)
        }
    }
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            if !selectedContacts.isEmpty {
                Text("\(selectedContacts.count) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Cancel") {
                dismiss()
            }
            
            if viewModel.selectedBill != nil {
                Button("Add to Bill") {
                    addSelectedToBill()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedContacts.isEmpty)
            }
        }
        .padding()
    }
    
    // MARK: - Helpers
    
    private func toggleSelection(_ contact: Person) {
        if selectedContacts.contains(contact.id) {
            selectedContacts.remove(contact.id)
        } else {
            selectedContacts.insert(contact.id)
        }
    }
    
    private func addSelectedToBill() {
        for contactId in selectedContacts {
            if let contact = contacts.first(where: { $0.id == contactId }) {
                viewModel.addPersonFromContact(contact)
            }
        }
    }
    
    private func deleteContacts(at offsets: IndexSet) {
        for index in offsets {
            let contact = filteredContacts[index]
            modelContext.delete(contact)
        }
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    let contact: Person
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .blue : .secondary)
            
            PersonAvatar(person: contact, size: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.body)
                
                if !contact.paymentMethod.isEmpty {
                    Text(contact.paymentMethod)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if !contact.phoneNumber.isEmpty {
                Text(contact.phoneNumber)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Add Contact Sheet

struct AddContactSheet: View {
    @Environment(\.modelContext) private var modelContext
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
                Text("Add Contact")
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
                        Text("Preferred Payment Method")
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
                
                Button("Save Contact") {
                    saveContact()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 450)
    }
    
    private func saveContact() {
        let contact = Person(
            name: name.trimmingCharacters(in: .whitespaces),
            phoneNumber: phoneNumber,
            paymentMethod: paymentMethod,
            paymentDetails: paymentDetails,
            isContact: true
        )
        modelContext.insert(contact)
    }
}

// MARK: - Preview

#Preview {
    ContactsView(viewModel: BillViewModel.preview)
        .modelContainer(for: Person.self, inMemory: true)
}
