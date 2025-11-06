import SwiftUI
import os.log

// MARK: - Error Boundary Component
// Comprehensive error handling wrapper for critical UI components

struct ErrorBoundary<Content: View>: View {
    let content: Content
    let context: String
    
    @State private var hasError = false
    @State private var errorMessage = ""
    @State private var retryCount = 0
    
    private let logger = Logger(subsystem: "com.accelerate.sc40", category: "ErrorBoundary")
    private let maxRetries = 3
    
    init(context: String = "Unknown", @ViewBuilder content: () -> Content) {
        self.context = context
        self.content = content()
    }
    
    var body: some View {
        if hasError {
            ErrorRecoveryView(
                context: context,
                errorMessage: errorMessage,
                retryCount: retryCount,
                onRetry: {
                    retryOperation()
                },
                onReset: {
                    resetErrorState()
                }
            )
        } else {
            content
                .onAppear {
                    // Reset error state when view appears
                    hasError = false
                    errorMessage = ""
                }
                .onReceive(NotificationCenter.default.publisher(for: .errorBoundaryTriggered)) { notification in
                    if let error = notification.object as? Error,
                       let errorContext = notification.userInfo?["context"] as? String,
                       errorContext == context {
                        handleError(error)
                    }
                }
        }
    }
    
    private func handleError(_ error: Error) {
        logger.error("ErrorBoundary [\(context)]: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            hasError = true
            errorMessage = error.localizedDescription
        }
    }
    
    private func retryOperation() {
        guard retryCount < maxRetries else {
            logger.error("ErrorBoundary [\(context)]: Max retries exceeded")
            return
        }
        
        retryCount += 1
        logger.info("ErrorBoundary [\(context)]: Retry attempt \(retryCount)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            hasError = false
            errorMessage = ""
        }
    }
    
    private func resetErrorState() {
        hasError = false
        errorMessage = ""
        retryCount = 0
        logger.info("ErrorBoundary [\(context)]: State reset")
    }
}

// MARK: - Error Recovery View

struct ErrorRecoveryView: View {
    let context: String
    let errorMessage: String
    let retryCount: Int
    let onRetry: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            // Error Title
            Text("Something went wrong")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            // Error Context
            Text("Error in: \(context)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Error Message
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Action Buttons
            VStack(spacing: 12) {
                if retryCount < 3 {
                    Button(action: onRetry) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                
                Button(action: onReset) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            
            // Retry Count
            if retryCount > 0 {
                Text("Attempt \(retryCount) of 3")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }
}

// MARK: - Error Boundary Extensions

extension Notification.Name {
    static let errorBoundaryTriggered = Notification.Name("errorBoundaryTriggered")
}

extension View {
    func errorBoundary(context: String = "View") -> some View {
        ErrorBoundary(context: context) {
            self
        }
    }
    
    func triggerErrorBoundary(_ error: Error, context: String) {
        NotificationCenter.default.post(
            name: .errorBoundaryTriggered,
            object: error,
            userInfo: ["context": context]
        )
    }
}

// MARK: - Critical View Wrappers

struct CriticalViewWrapper<Content: View>: View {
    let content: Content
    let viewName: String
    
    @State private var isLoading = true
    @State private var loadError: Error?
    
    init(viewName: String, @ViewBuilder content: () -> Content) {
        self.viewName = viewName
        self.content = content()
    }
    
    var body: some View {
        ErrorBoundary(context: viewName) {
            if let error = loadError {
                ErrorRecoveryView(
                    context: viewName,
                    errorMessage: error.localizedDescription,
                    retryCount: 0,
                    onRetry: {
                        loadError = nil
                        isLoading = true
                    },
                    onReset: {
                        loadError = nil
                        isLoading = false
                    }
                )
            } else if isLoading {
                ProgressView("Loading \(viewName)...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        // Simulate loading completion
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isLoading = false
                        }
                    }
            } else {
                content
            }
        }
    }
}

#Preview {
    ErrorBoundary(context: "Preview") {
        VStack {
            Text("This is a test view")
            Button("Trigger Error") {
                let error = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "This is a test error"])
                NotificationCenter.default.post(
                    name: .errorBoundaryTriggered,
                    object: error,
                    userInfo: ["context": "Preview"]
                )
            }
        }
    }
}
