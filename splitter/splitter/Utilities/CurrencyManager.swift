//
//  CurrencyManager.swift
//  splitter
//
//  Created by Yew Mun Thian on 05/02/2026.
//

import Foundation
import SwiftUI

/// Manages currency display and formatting
struct CurrencyManager {
    
    // MARK: - Supported Currencies
    
    struct Currency: Identifiable, Hashable {
        let code: String
        let symbol: String
        let name: String
        let flag: String
        
        var id: String { code }
        
        var displayName: String {
            "\(flag) \(code) - \(name)"
        }
        
        var shortDisplay: String {
            "\(flag) \(symbol)"
        }
    }
    
    static let supportedCurrencies: [Currency] = [
        Currency(code: "MYR", symbol: "RM", name: "Malaysian Ringgit", flag: "🇲🇾"),
        Currency(code: "SGD", symbol: "S$", name: "Singapore Dollar", flag: "🇸🇬"),
        Currency(code: "USD", symbol: "$", name: "US Dollar", flag: "🇺🇸"),
        Currency(code: "EUR", symbol: "€", name: "Euro", flag: "🇪🇺"),
        Currency(code: "GBP", symbol: "£", name: "British Pound", flag: "🇬🇧"),
        Currency(code: "JPY", symbol: "¥", name: "Japanese Yen", flag: "🇯🇵"),
        Currency(code: "THB", symbol: "฿", name: "Thai Baht", flag: "🇹🇭"),
        Currency(code: "IDR", symbol: "Rp", name: "Indonesian Rupiah", flag: "🇮🇩"),
        Currency(code: "PHP", symbol: "₱", name: "Philippine Peso", flag: "🇵🇭"),
        Currency(code: "VND", symbol: "₫", name: "Vietnamese Dong", flag: "🇻🇳"),
        Currency(code: "AUD", symbol: "A$", name: "Australian Dollar", flag: "🇦🇺"),
        Currency(code: "HKD", symbol: "HK$", name: "Hong Kong Dollar", flag: "🇭🇰"),
        Currency(code: "TWD", symbol: "NT$", name: "Taiwan Dollar", flag: "🇹🇼"),
        Currency(code: "KRW", symbol: "₩", name: "South Korean Won", flag: "🇰🇷"),
        Currency(code: "CNY", symbol: "¥", name: "Chinese Yuan", flag: "🇨🇳"),
    ]
    
    static let defaultCurrency = supportedCurrencies[0] // MYR
    
    // MARK: - Currency Lookup
    
    static func currency(for code: String) -> Currency {
        supportedCurrencies.first { $0.code == code } ?? defaultCurrency
    }
    
    static func symbol(for code: String) -> String {
        currency(for: code).symbol
    }
    
    // MARK: - Formatting
    
    static func format(_ value: Decimal, currencyCode: String) -> String {
        let currency = self.currency(for: currencyCode)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = currencyCode == "JPY" || currencyCode == "KRW" || currencyCode == "VND" ? 0 : 2
        formatter.minimumFractionDigits = currencyCode == "JPY" || currencyCode == "KRW" || currencyCode == "VND" ? 0 : 2
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
        
        let formattedNumber = formatter.string(from: NSDecimalNumber(decimal: value)) ?? "\(value)"
        return "\(currency.symbol)\(formattedNumber)"
    }
    
    static func formatWithCode(_ value: Decimal, currencyCode: String) -> String {
        let formatted = format(value, currencyCode: currencyCode)
        return "\(formatted) \(currencyCode)"
    }
}

// MARK: - Preview Helpers

extension CurrencyManager {
    static var previewCurrency: Currency {
        defaultCurrency
    }
}
