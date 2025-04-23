import Foundation
import FirebaseFirestore

@MainActor
class DisinformationViewModel: ObservableObject {
    @Published var isVerifying = false
    @Published var verificationResult: DisinformationResponse?
    @Published var error: Error?
    
    private let disinformationService = DisinformationService()
    
    func verifyPost(_ post: Post) async {
        isVerifying = true
        error = nil
        
        do {
            verificationResult = try await disinformationService.checkDisinformation(for: post)
        } catch {
            self.error = error
        }
        
        isVerifying = false
    }
    
    func getVerificationStatus(for postId: String) async {
        do {
            verificationResult = try await disinformationService.getDisinformationCheck(for: postId)
        } catch {
            self.error = error
        }
    }
} 