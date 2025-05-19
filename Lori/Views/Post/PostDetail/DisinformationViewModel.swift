import Foundation
import SwiftUI

@MainActor
class DisinformationViewModel: ObservableObject {
    private let disinformationService = DisinformationService()
    
    @Published var isChecking = false
    @Published var checkResult: DisinformationResponse?
    @Published var error: Error?
    
    func checkDisinformation(for post: Post) async {
        isChecking = true
        error = nil
        
        do {
            checkResult = try await disinformationService.checkDisinformation(for: post)
        } catch {
            self.error = error
        }
        
        isChecking = false
    }
} 