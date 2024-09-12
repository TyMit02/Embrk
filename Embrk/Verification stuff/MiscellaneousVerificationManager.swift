//
//  MiscellaneousVerificationManager.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/9/24.
//


import Foundation

class MiscellaneousVerificationManager: ObservableObject {
    enum VerificationMethod: String, Codable, CaseIterable {
        case photo = "Photo"
        case textInput = "Text Input"
        case checkbox = "Checkbox"
        case numericInput = "Numeric Input"
        case locationCheck = "Location Check"
        case timerBased = "Timer Based"
        case socialMediaPost = "Social Media Post"
        case fileUpload = "File Upload"
    }
    
    // Add other necessary methods and properties here
}
