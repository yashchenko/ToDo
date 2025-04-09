//
//  Utilities.swift
//  ToDo
//
//  Created by Ivan on 08.04.2025.
//

import UIKit

// MARK: - UIColor Extension (for Hex Colors)


extension UIColor {
    // Hex Color Initializer
    
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(a) / 255.0)
    }
    
    // theme colours
    
    static let themePrimary = UIColor(hexString: "#007AFF")
    static let themeBackground = UIColor.systemGroupedBackground
    static let themeSecondaryText = UIColor.secondaryLabel
    static let themeSeparator = UIColor.separator
    static let themeAccentGreen = UIColor(hexString: "#34C759")
    static let themeAccentOrange = UIColor(hexString: "#FF9500")
    static let themeAccentRed = UIColor(hexString: "#FF3B30")
}


// MARK: - Date Extension (for Formatting)

extension Date {
    
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    var isPast: Bool {
        // compare date only, ignore time
        return Calendar.current.compare(self, to: Date(), toGranularity: .day) == .orderedAscending
    }
    
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
}


// MARK: - Network Error Enum

enum FirebaseError: Error, LocalizedError {
    case invalidURL(String)         // Couldn't create a valid URL
    case requestFailed(Error?)      // Network request itself failed (connection, timeout)
    case invalidResponse            // Response wasn't a valid HTTP response
    case badStatusCode(Int)         // Got an HTTP error code (like 404, 500)
    case noData                     // Expected data but received none
    case decodingError(Error)      // Failed to parse the JSON data
    case encodingError(Error)       // Failed to encode data for sending
    case operationFailed(String)    // Generic failure for operations like delete/update
    
    var errorDescription: String? {
        
        switch self {
        case .invalidURL(let url): return "Internal error: Invalid URL constructed (\(url))"
        case .requestFailed(let err): return "Network request failed. Check connection. (\(err?.localizedDescription ?? "Unknown"))"
        case .invalidResponse: return "Received an invalid response from the server."
        case .badStatusCode(let code): return "Server returned an error (Status Code: \(code))."
        case .noData: return "No data received from the server."
        case .decodingError(let err): return "Failed to understand server response. (\(err.localizedDescription))"
        case .encodingError(let err): return "Failed to prepare data to send. (\(err.localizedDescription))"
        case .operationFailed(let msg): return "Operation failed: \(msg)"
        }
        
    }
    
}


//enum FirebaseError: Error, LocalizedError {
//    case invalidURL(String)        // Couldn't create a valid URL
//    case requestFailed(Error?)     // Network request itself failed (connection, timeout)
//    case invalidResponse         // Response wasn't a valid HTTP response
//    case badStatusCode(Int)      // Got an HTTP error code (like 404, 500)
//    case noData                  // Expected data but received none
//    case decodingError(Error)      // Failed to parse the JSON data
//    case encodingError(Error)      // Failed to encode data for sending
//    case operationFailed(String)   // Generic failure for operations like delete/update
//
//    // User-friendly descriptions
//    var errorDescription: String? {
//        switch self {
//        case .invalidURL(let url): return "Internal error: Invalid URL constructed (\(url))."
//        case .requestFailed(let err): return "Network request failed. Check connection. (\(err?.localizedDescription ?? "Unknown"))"
//        case .invalidResponse: return "Received an invalid response from the server."
//        case .badStatusCode(let code): return "Server returned an error (Status Code: \(code))."
//        case .noData: return "No data received from the server."
//        case .decodingError(let err): return "Failed to understand server response. (\(err.localizedDescription))"
//        case .encodingError(let err): return "Failed to prepare data to send. (\(err.localizedDescription))"
//        case .operationFailed(let msg): return "Operation failed: \(msg)"
//        }
//    }
//}
