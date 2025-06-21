import SwiftUI

struct QuietHoursView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isEnabled = false
    @State private var startTime = Date()
    @State private var endTime = Date()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Quiet Hours Toggle
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Quiet Hours")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        Toggle("Enable Quiet Hours", isOn: $isEnabled)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(15)
                            .padding(.horizontal)
                    }
                    
                    if isEnabled {
                        // Start Time
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Start Time")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(15)
                                .padding(.horizontal)
                        }
                        
                        // End Time
                        VStack(alignment: .leading, spacing: 15) {
                            Text("End Time")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(WheelDatePickerStyle())
                                .labelsHidden()
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(15)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Quiet Hours")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    // Save quiet hours
                    dismiss()
                }
                .foregroundColor(.white)
            }
        }
    }
} 