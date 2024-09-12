//
//  ProView.swift
//  Embrk
//
//  Created by Ty Mitchell on 9/7/24.
//


import SwiftUI

struct ProView: View {
    @StateObject private var proManager = ProManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Upgrade to Pro")
                    .font(AppFonts.largeTitle)
                    .foregroundColor(AppColors.primary)
                
                Image(systemName: "star.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(AppColors.primary)
                
                Text("Unlock the full potential of Challenger!")
                    .font(AppFonts.title3)
                    .multilineTextAlignment(.center)
                
                VStack(alignment: .leading, spacing: 10) {
                    FeatureRow(text: "Join unlimited challenges")
                    FeatureRow(text: "Exclusive pro-only challenges")
                    FeatureRow(text: "Advanced progress tracking")
                    FeatureRow(text: "Priority customer support")
                }
                .padding()
                .background(colorScheme == .dark ? Color(hex: "1C1C1E") : Color.white)
                .cornerRadius(15)
                
                if let product = proManager.products.first {
                    Button(action: {
                        Task {
                            do {
                                try await proManager.purchase()
                                alertMessage = "Thank you for upgrading to Pro!"
                            } catch {
                                alertMessage = "Purchase failed: \(error.localizedDescription)"
                            }
                            showingAlert = true
                        }
                    }) {
                        Text("Upgrade Now - \(product.displayPrice)")
                            .font(AppFonts.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primary)
                            .cornerRadius(10)
                    }
                }
                
                Button("Restore Purchases") {
                    Task {
                        do {
                            try await proManager.restorePurchases()
                            if proManager.isPro {
                                alertMessage = "Pro features restored successfully!"
                            } else {
                                alertMessage = "No previous Pro purchase found."
                            }
                        } catch {
                            alertMessage = "Restore failed: \(error.localizedDescription)"
                        }
                        showingAlert = true
                    }
                }
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.primary)
            }
            .padding()
        }
        .background(colorScheme == .dark ? Color.black : AppColors.background)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Pro Mode"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

struct FeatureRow: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppColors.secondary)
            Text(text)
                .font(AppFonts.body)
        }
    }
}
