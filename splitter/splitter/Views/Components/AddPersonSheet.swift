//
//  AddPersonSheet.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import SwiftUI
import SwiftData

/// Sheet for adding a new person to a bill
struct AddPersonSheet: View {
    let bill: Bill
    @Bindable var viewModel: BillViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var paymentMethod: String = ""
    @State private var paymentDetails: String = ""
    @State private var saveAsContact: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, phone, paymentMethod, paymentDetails
    }
    
    // Common payment methods for quick selection
    private let paymentMethods = ["DuitNow", "TNG eWallet", "Bank Transfer", "Cash", "GrabPay", "ShopeePay"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Form
            ScrollView {
                VStack(spacing: 20) {
                    // Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("Enter name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .name)
                    }
                    
                    // Phone number
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Phone Number (optional)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("e.g., 010-1234567", text: $phoneNumber)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .phone)
                    }
                    
                    // Payment method
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Preferred Payment Method")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        // Quick select buttons
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
                            .focused($focusedField, equals: .paymentMethod)
                    }
                    
                    // Payment details
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Payment Details (optional)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("e.g., phone number or account", text: $paymentDetails)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .paymentDetails)
                    }
                    
                    // Save as contact toggle
                    Toggle(isOn: $saveAsContact) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Save as contact for future bills")
                        }
                    }
                    .toggleStyle(.checkbox)
                }
                .padding()
            }
            
            Divider()
            
            // Footer
            footer
        }
        .frame(width: 400, height: 500)
        .onAppear {
            focusedField = .name
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        HStack {
            Text("Add Person")
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
    
    // MARK: - Footer
    
    private var footer: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape)
            
            Spacer()
            
            Button("Add Another") {
                addPerson()
                clearForm()
            }
            .buttonStyle(.bordered)
            .disabled(!isValid)
            
            Button("Add Person") {
                addPerson()
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
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func addPerson() {
        let person = bill.addPerson(name: name.trimmingCharacters(in: .whitespaces))
        person.phoneNumber = phoneNumber
        person.paymentMethod = paymentMethod
        person.paymentDetails = paymentDetails
        person.isContact = saveAsContact
    }
    
    private func clearForm() {
        name = ""
        phoneNumber = ""
        paymentMethod = ""
        paymentDetails = ""
        saveAsContact = false
        focusedField = .name
    }
}

// MARK: - Preview

#Preview {
    AddPersonSheet(bill: Bill.mockBill, viewModel: BillViewModel.preview)
        .modelContainer(for: Bill.self, inMemory: true)
}
