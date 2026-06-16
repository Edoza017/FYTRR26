import Foundation
import FirebaseAuth
import FirebaseCore
import AuthenticationServices
import CryptoKit

final class AuthViewModel: NSObject, ObservableObject {

    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?
    @Published var isLoading = false
    private var currentNonce: String?

    var canSubmitEmailAuth: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).contains("@") && password.count >= 6 && !isLoading
    }

    func signUp(completion: @escaping (Bool) -> Void) {

        guard validateEmailPassword() else {
            completion(false)
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in

            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                completion(false)
                return
            }

            DispatchQueue.main.async {
                self.errorMessage = nil
                self.isLoading = false
            }

            completion(true)
        }
    }

    func login(completion: @escaping (Bool) -> Void) {

        guard validateEmailPassword() else {
            completion(false)
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        Auth.auth().signIn(withEmail: email, password: password) { result, error in

            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                completion(false)
                return
            }

            DispatchQueue.main.async {
                self.errorMessage = nil
                self.isLoading = false
            }

            completion(true)
        }
    }


    func resetPassword(completion: @escaping (Bool) -> Void) {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@") else {
            errorMessage = "Enter your email first, then tap Forgot Password."
            completion(false)
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        Auth.auth().sendPasswordReset(withEmail: trimmedEmail) { error in
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = error?.localizedDescription ?? "Password reset email sent."
            }
            completion(error == nil)
        }
    }

    private func validateEmailPassword() -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@") else {
            errorMessage = "Enter a valid email address."
            return false
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return false
        }
        email = trimmedEmail
        return true
    }

    func configureAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard FirebaseApp.app() != nil else {
                errorMessage = "Firebase is not configured. Check GoogleService-Info.plist target membership."
                isLoading = false
                return
            }

            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Unable to read Apple ID credentials."
                return
            }

            guard let nonce = currentNonce else {
                errorMessage = "Apple sign-in security state missing."
                return
            }
            currentNonce = nil

            guard let appleIDToken = appleIDCredential.identityToken else {
                errorMessage = "Unable to fetch Apple identity token."
                return
            }

            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                errorMessage = "Unable to decode Apple identity token."
                return
            }

            DispatchQueue.main.async {
                self.isLoading = true
                self.errorMessage = nil
            }

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )

            Auth.auth().signIn(with: credential) { _, error in
                DispatchQueue.main.async {
                    self.isLoading = false

                    if let nsError = error as NSError? {
                        if let code = AuthErrorCode(rawValue: nsError.code), code == .operationNotAllowed {
                            self.errorMessage = "Apple Sign In is not enabled in Firebase Auth. Enable provider: apple.com."
                            return
                        }
                    }

                    self.errorMessage = error?.localizedDescription
                }
            }

        case .failure(let error):
            DispatchQueue.main.async {
                self.isLoading = false

                if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                    self.errorMessage = "Apple sign-in was canceled."
                    return
                }

                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
