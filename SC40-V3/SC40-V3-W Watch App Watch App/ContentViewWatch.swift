//
//  ContentViewWatch.swift
//  SC40-WV1-W Watch App
//
//  Created by David O'Connell on 22/08/2025.
//

import SwiftUI

struct ContentViewWatch: View {
    var body: some View {
        ZStack {
            Canvas { context, size in
                // Simple watch content background
                let contentGradient = Gradient(colors: [
                    Color.black,
                    Color.black.opacity(0.8)
                ])
                context.fill(Path(CGRect(origin: .zero, size: size)),
                           with: .linearGradient(contentGradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))
                
                // Subtle glass effect
                context.addFilter(.blur(radius: 8))
                context.fill(Path(ellipseIn: CGRect(x: size.width * 0.2, y: size.height * 0.3, width: 20, height: 20)),
                           with: .color(Color.blue.opacity(0.15)))
            }
            .ignoresSafeArea()
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
            }
            .padding()
        }
    }
}

#if DEBUG
#Preview("1. Content View Watch") {
    ContentViewWatch()
        .preferredColorScheme(.dark)
}

#Preview("2. Canvas Background Demo") {
    ContentViewWatch()
        .preferredColorScheme(.dark)
}

#Preview("3. Watch Canvas Effects") {
    ZStack {
        Canvas { context, size in
            // Sprint Coach 40 branded background
            let brandGradient = Gradient(colors: [
                Color.brandBackground,
                Color.brandAccent.opacity(0.3),
                Color.black
            ])
            context.fill(Path(CGRect(origin: .zero, size: size)),
                       with: .linearGradient(brandGradient, startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))
            
            // Brand accent effects
            context.addFilter(.blur(radius: 12))
            context.fill(Path(ellipseIn: CGRect(x: size.width * 0.1, y: size.height * 0.2, width: 30, height: 30)),
                       with: .color(Color.brandPrimary.opacity(0.2)))
            context.fill(Path(ellipseIn: CGRect(x: size.width * 0.7, y: size.height * 0.6, width: 25, height: 25)),
                       with: .color(Color.brandSecondary.opacity(0.15)))
        }
        .ignoresSafeArea()
        
        VStack(spacing: WatchAdaptiveSizing.spacing) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.brandPrimary)
            
            Text("Sprint Coach 40")
                .font(.adaptiveTitle)
                .foregroundColor(.brandSecondary)
        }
        .adaptivePadding()
    }
    .preferredColorScheme(.dark)
}

#Preview("4. Watch UI Elements") {
    VStack(spacing: WatchAdaptiveSizing.spacing) {
        Text("Apple Watch UI")
            .font(.adaptiveTitle)
            .foregroundColor(.brandPrimary)
        
        HStack(spacing: WatchAdaptiveSizing.smallPadding) {
            Image(systemName: "applewatch")
                .font(.system(size: WatchAdaptiveSizing.iconSize))
                .foregroundColor(.brandSecondary)
            
            Text("Optimized Interface")
                .font(.adaptiveBody)
                .foregroundColor(.secondary)
        }
        
        Rectangle()
            .fill(Color.brandAccent.opacity(0.3))
            .frame(width: WatchAdaptiveSizing.standardModuleSize.width,
                   height: WatchAdaptiveSizing.standardModuleSize.height)
            .adaptiveCornerRadius()
    }
    .adaptivePadding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("5. Canvas Art Demo") {
    Canvas { context, size in
        // Create Sprint Coach 40 themed canvas art
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        // Background gradient
        let backgroundGradient = Gradient(colors: [Color.brandBackground, Color.black])
        context.fill(Path(CGRect(origin: .zero, size: size)),
                   with: .radialGradient(backgroundGradient, center: CGPoint(x: centerX, y: centerY), startRadius: 0, endRadius: max(size.width, size.height)))
        
        // Sprint track lines
        context.stroke(Path { path in
            path.move(to: CGPoint(x: 0, y: centerY - 20))
            path.addLine(to: CGPoint(x: size.width, y: centerY - 20))
            path.move(to: CGPoint(x: 0, y: centerY + 20))
            path.addLine(to: CGPoint(x: size.width, y: centerY + 20))
        }, with: .color(Color.brandPrimary.opacity(0.3)), lineWidth: 2)
        
        // Lightning bolt effect
        context.fill(Path(ellipseIn: CGRect(x: centerX - 15, y: centerY - 15, width: 30, height: 30)),
                   with: .color(Color.brandPrimary.opacity(0.6)))
    }
    .preferredColorScheme(.dark)
}

#Preview("6. Watch Branding") {
    VStack(spacing: WatchAdaptiveSizing.spacing) {
        Text("SC40")
            .font(.system(size: 32, weight: .black, design: .rounded))
            .foregroundColor(.brandPrimary)
        
        Text("Sprint Coach 40")
            .font(.adaptiveHeadline)
            .foregroundColor(.brandSecondary)
        
        Text("Apple Watch Optimized")
            .font(.adaptiveCaption)
            .foregroundColor(.secondary)
    }
    .adaptivePadding()
    .background(
        LinearGradient(
            colors: [Color.brandBackground, Color.brandAccent.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .adaptiveCornerRadius()
    .preferredColorScheme(.dark)
}
#endif
