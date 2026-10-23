import SwiftUI

struct SplashView: View {
    let isContentReady: Bool
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var checkProgress: CGFloat = 0
    @State private var logoScale: CGFloat = 0.82
    @State private var glowOpacity: Double = 0
    @State private var logoRevealProgress: Double = 0
    @State private var animationCompleted = false
    @State private var didFinish = false

    var body: some View {
        ZStack {
            Prep4JobTheme.splashGradient
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 230, height: 230)
                        .blur(radius: 30)
                        .opacity(glowOpacity)

                    SplashMark(checkProgress: checkProgress)
                        .frame(width: 230, height: 230)
                        .scaleEffect(logoScale)
                        .opacity(1 - logoRevealProgress)

                    // The catalog icon is revealed at the end as a pixel-perfect brand lockup.
                    Image("Prep4JobLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 230, height: 230)
                        .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
                        .scaleEffect(0.96 + (0.04 * logoRevealProgress))
                        .opacity(logoRevealProgress)
                }

                Text(L10n.Home.appName)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(glowOpacity)

                if animationCompleted && !isContentReady {
                    ProgressView()
                        .tint(.white)
                        .accessibilityLabel(Text(L10n.Common.loading))
                }
            }
            .padding(.horizontal, 24)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(L10n.Home.appName))
        .accessibilityValue(Text(isContentReady ? L10n.Common.ready : L10n.Common.loading))
        .task {
            await playAnimation()
        }
        .onChange(of: isContentReady) { _, ready in
            finishIfPossible(contentReady: ready)
        }
    }

    private func playAnimation() async {
        if reduceMotion {
            checkProgress = 1
            logoScale = 1
            glowOpacity = 1
            logoRevealProgress = 1
            animationCompleted = true
            finishIfPossible(contentReady: isContentReady)
            return
        }

        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
            logoScale = 1
            glowOpacity = 1
        }

        try? await Task.sleep(for: .milliseconds(240))

        withAnimation(.easeOut(duration: 0.8)) {
            checkProgress = 1
        }

        try? await Task.sleep(for: .milliseconds(360))

        withAnimation(.easeInOut(duration: 0.28)) {
            logoRevealProgress = 1
        }

        animationCompleted = true
        finishIfPossible(contentReady: isContentReady)
    }

    private func finishIfPossible(contentReady: Bool) {
        guard animationCompleted, contentReady, !didFinish else { return }
        didFinish = true
        withAnimation(.easeOut(duration: 0.3)) {
            onFinished()
        }
    }
}

private struct SplashMark: View {
    let checkProgress: CGFloat

    var body: some View {
        ZStack {
            SpeechBubbleShape()
                .fill(
                    LinearGradient(
                        colors: [.white, Color(red: 0.82, green: 0.87, blue: 1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 174, height: 148)
                .shadow(color: .black.opacity(0.22), radius: 14, y: 8)
                .offset(x: -18, y: -20)

            SpeechBubbleTailShape()
                .fill(
                    LinearGradient(
                        colors: [.white, Color(red: 0.82, green: 0.87, blue: 1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 38)
                .shadow(color: .black.opacity(0.18), radius: 8, y: 5)
                .offset(x: -70, y: 55)

            CheckmarkShape()
                .trim(from: 0, to: checkProgress)
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 0.12, green: 0.42, blue: 1), Prep4JobTheme.mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 114, height: 88)
                .offset(x: -19, y: -23)

            BriefcaseMark()
                .frame(width: 108, height: 88)
                .offset(x: 44, y: 54)
        }
    }
}

private struct SpeechBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let bubbleRect = rect.insetBy(dx: rect.width * 0.04, dy: rect.height * 0.03)
        return Path(
            roundedRect: bubbleRect,
            cornerSize: CGSize(width: rect.width * 0.28, height: rect.height * 0.28)
        )
    }
}

private struct SpeechBubbleTailShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.08, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.27, y: rect.maxY),
            control: CGPoint(x: rect.maxX * 0.58, y: rect.maxY * 0.70)
        )
        path.closeSubpath()
        return path
    }
}

private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.maxY * 0.78))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.06, y: rect.minY + rect.height * 0.16))
        return path
    }
}

private struct BriefcaseMark: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.53, green: 0.62, blue: 1), Color(red: 0.12, green: 0.17, blue: 0.88)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 96, height: 62)
                .shadow(color: .black.opacity(0.22), radius: 10, y: 6)

            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color(red: 0.74, green: 0.82, blue: 1))
                .frame(width: 96, height: 25)
                .offset(y: -14)

            Capsule()
                .stroke(.white.opacity(0.78), lineWidth: 8)
                .frame(width: 38, height: 22)
                .offset(y: -41)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Prep4JobTheme.mint)
                .frame(width: 22, height: 22)
                .offset(y: 7)
        }
    }
}
