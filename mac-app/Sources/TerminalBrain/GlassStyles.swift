import SwiftUI

extension View {
    @ViewBuilder
    func terminalBackgroundExtension() -> some View {
        if #available(macOS 26.0, *) {
            self.backgroundExtensionEffect()
        } else {
            self
        }
    }

    @ViewBuilder
    func floatingGlassSidebar(reduceGlass: Bool = false) -> some View {
        if #available(macOS 26.0, *), !reduceGlass {
            self
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
    }

    @ViewBuilder
    func liquidPanel(cornerRadius: CGFloat = 18, tint: Color = .white, reduceGlass: Bool = false) -> some View {
        if #available(macOS 26.0, *), !reduceGlass {
            self
                .background(tint.opacity(0.84), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.white.opacity(0.62), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.09), radius: 18, x: 0, y: 12)
        } else {
            self
                .background(tint.opacity(0.72), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 8)
        }
    }

    @ViewBuilder
    func liquidCapsule(selected: Bool, accent: Color, reduceGlass: Bool = false) -> some View {
        if #available(macOS 26.0, *), !reduceGlass {
            self
                .background(selected ? accent.opacity(0.86) : .white.opacity(0.34), in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(selected ? 0.26 : 0.42), lineWidth: 1))
        } else {
            self
                .background(selected ? accent : Color.white.opacity(0.20), in: Capsule())
        }
    }

    @ViewBuilder
    func terminalButtonStyle(prominent: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            if prominent {
                self.buttonStyle(GlassProminentButtonStyle())
            } else {
                self.buttonStyle(GlassButtonStyle())
            }
        } else {
            if prominent {
                self.buttonStyle(.borderedProminent)
            } else {
                self.buttonStyle(.bordered)
            }
        }
    }
}
