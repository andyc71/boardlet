//
//  ErrorHandler.swift
//  PECS Maker
//
//  Created by Andy on 05/03/2025.
//
import SwiftUI

@MainActor
class ErrorHandler: ObservableObject {
    @Published private(set) var lastError: Error?
    
    static let shared = ErrorHandler()
    
    func setLastError(_ error: Error?) {
        lastError = error
    }
    
    init() {
        
    }
}
