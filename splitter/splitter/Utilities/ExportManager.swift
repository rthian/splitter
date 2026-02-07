//
//  ExportManager.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import Foundation
import AppKit

/// Manager for exporting bills to various formats
struct ExportManager {
    
    // MARK: - CSV Export
    
    /// Generate CSV content for a bill
    static func generateCSV(for bill: Bill) -> String {
        var lines: [String] = []
        
        // Header info
        lines.append("IOU Bill Splitter Export")
        lines.append("")
        lines.append("Place:,\(escapeCSV(bill.placeName))")
        lines.append("Date:,\(bill.displayDate)")
        lines.append("Currency:,\(bill.currencyCode)")
        lines.append("")
        
        // Settings
        lines.append("Discount:,\(bill.discountPercentage)%")
        lines.append("Service Charge:,\(bill.serviceChargePercentage)%")
        lines.append("Tax:,\(bill.taxPercentage)%")
        lines.append("")
        
        // Items table header
        var itemHeader = "Item,Amount"
        for person in bill.people {
            itemHeader += ",\(escapeCSV(person.name))"
        }
        lines.append(itemHeader)
        
        // Items rows
        for item in bill.items {
            var row = "\(escapeCSV(item.name)),\(bill.formatAmount(item.totalAmount))"
            
            for person in bill.people {
                if let split = item.splits.first(where: { $0.person?.id == person.id }) {
                    row += ",\(bill.formatAmount(split.amount))"
                } else {
                    row += ","
                }
            }
            lines.append(row)
        }
        
        lines.append("")
        
        // Summary section
        let totals = CalculationEngine.calculateBillTotals(for: bill)
        
        // Subtotals row
        var subtotalRow = "Subtotal,\(bill.formatAmount(totals.subtotal))"
        for person in bill.people {
            let breakdown = CalculationEngine.calculatePersonBreakdown(
                person: person,
                discountPercentage: bill.discountPercentage,
                serviceChargePercentage: bill.serviceChargePercentage,
                taxPercentage: bill.taxPercentage
            )
            subtotalRow += ",\(bill.formatAmount(breakdown.subtotal))"
        }
        lines.append(subtotalRow)
        
        // Discount row (if applicable)
        if totals.discountAmount > 0 {
            var discountRow = "Discount,\(bill.formatAmount(-totals.discountAmount))"
            for person in bill.people {
                let breakdown = CalculationEngine.calculatePersonBreakdown(
                    person: person,
                    discountPercentage: bill.discountPercentage,
                    serviceChargePercentage: bill.serviceChargePercentage,
                    taxPercentage: bill.taxPercentage
                )
                discountRow += ",\(bill.formatAmount(-breakdown.discountAmount))"
            }
            lines.append(discountRow)
        }
        
        // Service charge row (if applicable)
        if totals.serviceCharge > 0 {
            var serviceRow = "Service Charge,\(bill.formatAmount(totals.serviceCharge))"
            for person in bill.people {
                let breakdown = CalculationEngine.calculatePersonBreakdown(
                    person: person,
                    discountPercentage: bill.discountPercentage,
                    serviceChargePercentage: bill.serviceChargePercentage,
                    taxPercentage: bill.taxPercentage
                )
                serviceRow += ",\(bill.formatAmount(breakdown.serviceCharge))"
            }
            lines.append(serviceRow)
        }
        
        // Tax row
        if totals.tax > 0 {
            var taxRow = "Tax,\(bill.formatAmount(totals.tax))"
            for person in bill.people {
                let breakdown = CalculationEngine.calculatePersonBreakdown(
                    person: person,
                    discountPercentage: bill.discountPercentage,
                    serviceChargePercentage: bill.serviceChargePercentage,
                    taxPercentage: bill.taxPercentage
                )
                taxRow += ",\(bill.formatAmount(breakdown.tax))"
            }
            lines.append(taxRow)
        }
        
        // Grand total row
        var totalRow = "TOTAL,\(bill.formatAmount(totals.grandTotal))"
        for person in bill.people {
            let breakdown = CalculationEngine.calculatePersonBreakdown(
                person: person,
                discountPercentage: bill.discountPercentage,
                serviceChargePercentage: bill.serviceChargePercentage,
                taxPercentage: bill.taxPercentage
            )
            totalRow += ",\(bill.formatAmount(breakdown.finalAmount))"
        }
        lines.append(totalRow)
        
        lines.append("")
        
        // Payment status
        var paidRow = "Paid?,,"
        for person in bill.people {
            paidRow += ",\(person.hasPaid ? "YES" : "NO")"
        }
        lines.append(paidRow)
        
        lines.append("")
        
        // Payment info
        lines.append("Pay To:,\(escapeCSV(bill.payToName))")
        lines.append("Method:,\(escapeCSV(bill.payToMethod))")
        lines.append("Details:,\(escapeCSV(bill.payToDetails))")
        
        return lines.joined(separator: "\n")
    }
    
    /// Export bill to CSV file
    static func exportToCSV(bill: Bill) {
        let csvContent = generateCSV(for: bill)
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "\(bill.placeName.isEmpty ? "Bill" : bill.placeName) - \(bill.shortDisplayDate).csv"
        savePanel.title = "Export Bill as CSV"
        
        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                do {
                    try csvContent.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Failed to save CSV: \(error)")
                }
            }
        }
    }
    
    // MARK: - Text Summary
    
    /// Generate a text summary for sharing
    static func generateTextSummary(for bill: Bill) -> String {
        var lines: [String] = []
        
        lines.append("📋 Bill Summary")
        lines.append("━━━━━━━━━━━━━━━━━━━")
        lines.append("📍 \(bill.placeName)")
        lines.append("📅 \(bill.displayDate)")
        lines.append("")
        
        let totals = CalculationEngine.calculateBillTotals(for: bill)
        
        lines.append("💰 Breakdown:")
        for person in bill.people {
            let breakdown = CalculationEngine.calculatePersonBreakdown(
                person: person,
                discountPercentage: bill.discountPercentage,
                serviceChargePercentage: bill.serviceChargePercentage,
                taxPercentage: bill.taxPercentage
            )
            let status = person.hasPaid ? "✅" : "⏳"
            lines.append("  \(status) \(person.name): \(bill.formatAmount(breakdown.finalAmount))")
        }
        
        lines.append("")
        lines.append("━━━━━━━━━━━━━━━━━━━")
        lines.append("Total: \(bill.formatAmount(totals.grandTotal))")
        
        if !bill.payToName.isEmpty {
            lines.append("")
            lines.append("💳 Pay to: \(bill.payToName)")
            if !bill.payToMethod.isEmpty {
                lines.append("   \(bill.payToMethod)")
            }
            if !bill.payToDetails.isEmpty {
                lines.append("   \(bill.payToDetails)")
            }
        }
        
        return lines.joined(separator: "\n")
    }
    
    /// Copy text summary to clipboard
    static func copyToClipboard(bill: Bill) {
        let summary = generateTextSummary(for: bill)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(summary, forType: .string)
    }
    
    // MARK: - Helpers
    
    private static func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }
}
