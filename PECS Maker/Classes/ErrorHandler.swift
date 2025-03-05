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
    
    static var shared = ErrorHandler()
    
    @MainActor
    func setLastError(_ error: Error?) {
        //DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        DispatchQueue.main.async {
            self.lastError = error
        }
    }
    
    private init() {
        
    }
}
