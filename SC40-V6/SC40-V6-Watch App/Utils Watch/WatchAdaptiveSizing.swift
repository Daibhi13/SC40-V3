import SwiftUI
#if os(watchOS)
import WatchKit
#endif

/// Adaptive sizing system for all Apple Watch sizes
/// Provides consistent scaling across 41mm, 45mm, and Ultra (49mm) watches
struct WatchAdaptiveSizing {
    #if os(watchOS)
    private static let screenSize = WKInterfaceDevice.current().screenBounds.size
    #else
    private static let screenSize = CGSize(width: 368, height: 448) // Default size
    #endif
    
    /// Device categories based on screen width
    static var isUltra: Bool { screenSize.width >= 410 }
    static var isLarge: Bool { screenSize.width >= 368 && screenSize.width < 410 }
    static var isStandard: Bool { screenSize.width < 368 }
    
    /// Adaptive spacing values
    static var spacing: CGFloat {
        if isUltra { return 10 }
        if isLarge { return 8 }
        return 6
    }
    
    /// Adaptive padding values
    static var padding: CGFloat {
        if isUltra { return 12 }
        if isLarge { return 10 }
        return 8
    }
    
    /// Small padding variant
    static var smallPadding: CGFloat {
        if isUltra { return 8 }
        if isLarge { return 6 }
        return 4
    }
    
    /// Adaptive corner radius
    static var cornerRadius: CGFloat {
        if isUltra { return 12 }
        if isLarge { return 10 }
        return 8
    }
    
    /// Font sizes
    static var titleFontSize: CGFloat {
        if isUltra { return 20 }
        if isLarge { return 18 }
        return 16
    }
    
    static var headlineFontSize: CGFloat {
        if isUltra { return 18 }
        if isLarge { return 16 }
        return 15
    }
    
    static var bodyFontSize: CGFloat {
        if isUltra { return 16 }
        if isLarge { return 15 }
        return 14
    }
    
    static var captionFontSize: CGFloat {
        if isUltra { return 13 }
        if isLarge { return 12 }
        return 11
    }
    
    static var largeDisplayFontSize: CGFloat {
        if isUltra { return 52 }
        if isLarge { return 48 }
        return 42
    }
    
    /// Module sizes
    static var standardModuleSize: CGSize {
        if isUltra { return CGSize(width: 102, height: 62) }
        if isLarge { return CGSize(width: 94, height: 57) }
        return CGSize(width: 86, height: 52)
    }
    
    static var smallModuleSize: CGSize {
        if isUltra { return CGSize(width: 70, height: 62) }
        if isLarge { return CGSize(width: 64, height: 57) }
        return CGSize(width: 58, height: 52)
    }
    
    /// Button heights
    static var buttonHeight: CGFloat {
        if isUltra { return 50 }
        if isLarge { return 46 }
        return 42
    }
    
    /// Icon sizes
    static var iconSize: CGFloat {
        if isUltra { return 18 }
        if isLarge { return 16 }
        return 14
    }
    
    static var smallIconSize: CGFloat {
        if isUltra { return 15 }
        if isLarge { return 13 }
        return 11
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// Apply adaptive padding based on watch size
    func adaptivePadding() -> some View {
        self.padding(WatchAdaptiveSizing.padding)
    }
    
    /// Apply adaptive small padding based on watch size
    func adaptiveSmallPadding() -> some View {
        self.padding(WatchAdaptiveSizing.smallPadding)
    }
    
    /// Apply adaptive corner radius based on watch size
    func adaptiveCornerRadius() -> some View {
        self.cornerRadius(WatchAdaptiveSizing.cornerRadius)
    }
}

extension Font {
    /// Adaptive title font
    static var adaptiveTitle: Font {
        .system(size: WatchAdaptiveSizing.titleFontSize, weight: .bold, design: .rounded)
    }
    
    /// Adaptive headline font
    static var adaptiveHeadline: Font {
        .system(size: WatchAdaptiveSizing.headlineFontSize, weight: .semibold, design: .rounded)
    }
    
    /// Adaptive body font
    static var adaptiveBody: Font {
        .system(size: WatchAdaptiveSizing.bodyFontSize, weight: .regular, design: .default)
    }
    
    /// Adaptive caption font
    static var adaptiveCaption: Font {
        .system(size: WatchAdaptiveSizing.captionFontSize, weight: .regular, design: .default)
    }
    
    /// Adaptive large display font
    static var adaptiveLargeDisplay: Font {
        .system(size: WatchAdaptiveSizing.largeDisplayFontSize, weight: .black, design: .monospaced)
    }
}

// MARK: - Canvas Previews

#if DEBUG
import SwiftUI

#Preview("1. Adaptive Sizing Overview") {
    VStack(spacing: WatchAdaptiveSizing.spacing) {
        Text("Watch Adaptive Sizing")
            .font(Font.adaptiveTitle)
            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
        
        VStack(alignment: .leading, spacing: 4) {
            Text("Device: \(WatchAdaptiveSizing.isUltra ? "Ultra" : WatchAdaptiveSizing.isLarge ? "Large" : "Standard")")
                .font(Font.adaptiveHeadline)
            Text("Spacing: \(Int(WatchAdaptiveSizing.spacing))px")
                .font(Font.adaptiveBody)
            Text("Padding: \(Int(WatchAdaptiveSizing.padding))px")
                .font(Font.adaptiveCaption)
        }
        
        Rectangle()
            .fill(Color(red: 1.0, green: 0.8, blue: 0.0).opacity(0.3))
            .frame(width: WatchAdaptiveSizing.smallModuleSize.width, 
                   height: WatchAdaptiveSizing.smallModuleSize.height)
            .adaptiveCornerRadius()
    }
    .adaptivePadding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("2. Font Scaling Demo") {
    VStack(spacing: WatchAdaptiveSizing.smallPadding) {
        Text("Title Font")
            .font(Font.adaptiveTitle)
        Text("Headline Font")
            .font(Font.adaptiveHeadline)
        Text("Body Font")
            .font(Font.adaptiveBody)
        Text("Caption Font")
            .font(Font.adaptiveCaption)
        Text("42.85")
            .font(Font.adaptiveLargeDisplay)
            .foregroundColor(Color(red: 1.0, green: 0.8, blue: 0.0))
    }
    .adaptivePadding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("3. Module Sizing Demo") {
    VStack(spacing: WatchAdaptiveSizing.spacing) {
        Text("Module Sizes")
            .font(Font.adaptiveTitle)
        
        HStack(spacing: WatchAdaptiveSizing.spacing) {
            Rectangle()
                .fill(Color.green.opacity(0.3))
                .frame(width: WatchAdaptiveSizing.smallModuleSize.width,
                       height: WatchAdaptiveSizing.smallModuleSize.height)
                .adaptiveCornerRadius()
                .overlay(
                    Text("Small")
                        .font(Font.adaptiveCaption)
                        .foregroundColor(.white)
                )
            
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: WatchAdaptiveSizing.standardModuleSize.width,
                       height: WatchAdaptiveSizing.standardModuleSize.height)
                .adaptiveCornerRadius()
                .overlay(
                    Text("Standard")
                        .font(Font.adaptiveCaption)
                        .foregroundColor(.white)
                )
        }
    }
    .adaptivePadding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}

#Preview("4. Button Heights Demo") {
    VStack(spacing: WatchAdaptiveSizing.spacing) {
        Text("Button Heights")
            .font(Font.adaptiveTitle)
        
        Button("Adaptive Button") {
            // Action
        }
        .frame(maxWidth: .infinity)
        .frame(height: WatchAdaptiveSizing.buttonHeight)
        .background(Color(red: 1.0, green: 0.8, blue: 0.0))
        .foregroundColor(.white)
        .adaptiveCornerRadius()
        
        Text("Height: \(Int(WatchAdaptiveSizing.buttonHeight))px")
            .font(Font.adaptiveCaption)
            .foregroundColor(.secondary)
    }
    .adaptivePadding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
#endif
