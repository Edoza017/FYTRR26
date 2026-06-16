import SwiftUI
import AuthenticationServices

struct AuthView: View {
    private enum AuthMode: String, CaseIterable, Identifiable {
        case signIn = "Sign In"
        case create = "Create"

        var id: String { rawValue }

        var actionTitle: String {
            switch self {
            case .signIn: return "Sign In"
            case .create: return "Create Account"
            }
        }

        var helperText: String {
            switch self {
            case .signIn: return "Welcome back. Pick up your fuel plan where you left off."
            case .create: return "Create your account and build a meal plan around your goals."
            }
        }
    }

    @StateObject private var vm = AuthViewModel()
    @State private var mode: AuthMode = .signIn
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        ZStack {
            BrandBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    heroSection
                    authPanel
                }
                .padding(.horizontal, 22)
                .padding(.top, 32)
                .padding(.bottom, 28)
            }
        }
        .environment(\.colorScheme, .dark)
    }

    private var heroSection: some View {
        VStack(spacing: 14) {
            BrandNeonLogo(size: 190)
                .shadow(color: BrandPalette.accent.opacity(0.35), radius: 22, x: 0, y: 8)

            VStack(spacing: 6) {
                Text("Fuel that fits.")
                    .font(.custom("AvenirNext-Heavy", size: 32))
                    .foregroundStyle(BrandPalette.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Find nearby meals that match your calories, budget, and training goals.")
                    .font(.custom("AvenirNext-Medium", size: 15))
                    .foregroundStyle(BrandPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                compactPill("Targeted")
                compactPill("Nearby")
                compactPill("Fast")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var authPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Mode", selection: $mode) {
                ForEach(AuthMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .tint(BrandPalette.accent)
            .disabled(vm.isLoading)
            .accessibilityIdentifier("auth_mode_picker")

            Text(mode.helperText)
                .font(.custom("AvenirNext-Regular", size: 13))
                .foregroundStyle(BrandPalette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            SignInWithAppleButton(.continue, onRequest: { request in
                vm.configureAppleSignInRequest(request)
            }, onCompletion: { result in
                vm.handleAppleSignInCompletion(result)
            })
            .signInWithAppleButtonStyle(.white)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityIdentifier("auth_apple_signin_button")
            .disabled(vm.isLoading)

            HStack(spacing: 10) {
                Rectangle()
                    .fill(BrandPalette.stroke)
                    .frame(height: 1)
                Text("EMAIL")
                    .font(.custom("AvenirNext-DemiBold", size: 11))
                    .foregroundStyle(BrandPalette.textTertiary)
                Rectangle()
                    .fill(BrandPalette.stroke)
                    .frame(height: 1)
            }
            .padding(.vertical, 2)

            VStack(spacing: 10) {
                TextField(
                    "",
                    text: $vm.email,
                    prompt: Text("Email")
                        .foregroundStyle(BrandPalette.textSecondary.opacity(0.85))
                )
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($focusedField, equals: .email)
                .onSubmit { focusedField = .password }
                .brandFieldStyle()
                .accessibilityIdentifier("auth_email_field")

                SecureField(
                    "",
                    text: $vm.password,
                    prompt: Text("Password")
                        .foregroundStyle(BrandPalette.textSecondary.opacity(0.85))
                )
                .textContentType(mode == .create ? .newPassword : .password)
                .submitLabel(.go)
                .focused($focusedField, equals: .password)
                .onSubmit { submitEmailAuth() }
                .brandFieldStyle()
                .accessibilityIdentifier("auth_password_field")
            }

            if let message = vm.errorMessage {
                Text(message)
                    .font(.custom("AvenirNext-Regular", size: 13))
                    .foregroundStyle(message.lowercased().contains("sent") ? BrandPalette.accent : BrandPalette.warning)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("auth_status_message")
            }

            Button {
                submitEmailAuth()
            } label: {
                if vm.isLoading {
                    ProgressView()
                        .tint(.black)
                        .frame(maxWidth: .infinity)
                } else {
                    Text(mode.actionTitle)
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle())
            .disabled(vm.isLoading || !vm.canSubmitEmailAuth)
            .opacity(vm.canSubmitEmailAuth || vm.isLoading ? 1.0 : 0.55)
            .accessibilityIdentifier(mode == .create ? "auth_create_account_button" : "auth_login_button")

            HStack {
                Button(mode == .signIn ? "Need an account? Create one" : "Already have an account? Sign in") {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        mode = mode == .signIn ? .create : .signIn
                        vm.errorMessage = nil
                    }
                }
                .font(.custom("AvenirNext-DemiBold", size: 13))
                .foregroundStyle(BrandPalette.textPrimary)
                .disabled(vm.isLoading)

                Spacer()

                Button("Forgot Password") {
                    vm.resetPassword { _ in }
                }
                .font(.custom("AvenirNext-DemiBold", size: 13))
                .foregroundStyle(BrandPalette.accent)
                .disabled(vm.isLoading)
                .accessibilityIdentifier("auth_forgot_password_button")
            }
        }
        .brandCard()
    }

    private func compactPill(_ title: String) -> some View {
        Text(title)
            .font(.custom("AvenirNext-DemiBold", size: 12))
            .foregroundStyle(BrandPalette.accent)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(BrandPalette.accent.opacity(0.11))
            .overlay(Capsule().stroke(BrandPalette.accent.opacity(0.35), lineWidth: 1))
            .clipShape(Capsule())
    }

    private func submitEmailAuth() {
        focusedField = nil
        switch mode {
        case .signIn:
            vm.login { _ in }
        case .create:
            vm.signUp { _ in }
        }
    }
}

#Preview {
    AuthView()
}
