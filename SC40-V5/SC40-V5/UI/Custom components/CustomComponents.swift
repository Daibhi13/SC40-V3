//
//  CustomComponents.swift
//  SC40-V5
//
//  Created by David O'Connell on 14/10/2025.
//

import SwiftUI

// MARK: - Reusable UI Components

/// Custom gradient button with animation
struct GradientButton: View {
    let title: String
    let gradient: LinearGradient
    let action: () -> Void
    let isDisabled: Bool

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(gradient)
                .cornerRadius(12)
                .shadow(radius: 4)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
        .scaleEffect(isDisabled ? 0.95 : 1.0)
    }
}

/// Custom card view with shadow and styling
struct CustomCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack {
            content
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
}

/// Animated circular progress indicator
struct AnimatedProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let color: Color

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = newProgress
            }
        }
    }
}

/// Custom text field with icon and styling
struct CustomTextField: View {
    let placeholder: String
    let iconName: String
    @Binding var text: String
    let isSecure: Bool

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.gray)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Custom slider with gradient track
struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let gradient: LinearGradient

    var body: some View {
        VStack {
            Slider(value: $value, in: range, step: step) { _ in
                // Slider editing changed
            }
            .accentColor(.clear)
            .background(gradient.mask(
                Rectangle()
                    .frame(height: 4)
            ))
            .overlay(
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(gradient)
                            .frame(width: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width, height: 4)
                            .cornerRadius(2)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .shadow(radius: 2)
                            .offset(x: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width - 10)
                    }
                }
            )
            .cornerRadius(2)

            // Value labels
            HStack {
                Text("\(Int(range.lowerBound))")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text("\(Int(value))")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(range.upperBound))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

/// Loading spinner with custom styling
struct LoadingSpinner: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                .frame(width: 40, height: 40)

            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(Color.blue, lineWidth: 4)
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

/// Custom toggle switch
struct CustomToggle: View {
    @Binding var isOn: Bool
    let onColor: Color
    let offColor: Color

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(isOn ? onColor : offColor)
                .frame(width: 50, height: 30)
                .animation(.easeInOut(duration: 0.2), value: isOn)

            Circle()
                .fill(Color.white)
                .frame(width: 26, height: 26)
                .shadow(radius: 1)
                .padding(2)
                .animation(.easeInOut(duration: 0.2), value: isOn)
        }
        .frame(width: 50, height: 30)
        .onTapGesture {
            isOn.toggle()
        }
    }
}

/// Custom segmented control
struct CustomSegmentedControl: View {
    @Binding var selection: Int
    let options: [String]

    var body: some View {
        HStack {
            ForEach(options.indices, id: \.self) { index in
                Button(action: {
                    selection = index
                }) {
                    Text(options[index])
                        .font(.subheadline)
                        .fontWeight(selection == index ? .semibold : .regular)
                        .foregroundColor(selection == index ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selection == index ? Color.blue : Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

/// Custom alert view
struct CustomAlert: View {
    let title: String
    let message: String
    let primaryButtonText: String
    let secondaryButtonText: String?
    let primaryAction: () -> Void
    let secondaryAction: (() -> Void)?

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 15) {
                if let secondaryText = secondaryButtonText {
                    Button(action: {
                        secondaryAction?()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(secondaryText)
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                    }
                }

                Button(action: {
                    primaryAction()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(primaryButtonText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(.horizontal, 40)
    }
}

// MARK: - Preview

struct CustomComponents_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            GradientButton(title: "Test Button", gradient: LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing), action: {}, isDisabled: false)

            CustomCard {
                Text("Card Content")
                    .font(.headline)
            }

            AnimatedProgressView(progress: 0.7, lineWidth: 8, color: .blue)

            CustomTextField(placeholder: "Email", iconName: "envelope", text: .constant(""), isSecure: false)

            LoadingSpinner()

            CustomToggle(isOn: .constant(true), onColor: .green, offColor: .gray)

            CustomSegmentedControl(selection: .constant(1), options: ["Option 1", "Option 2", "Option 3"])
        }
        .padding()
    }
}
