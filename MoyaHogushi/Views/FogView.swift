import SwiftUI

/// ゆっくり漂う霧。濃さは呼び出し側で `.opacity` を掛けて調整する。
struct FogView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Blob {
        let x: Double, y: Double, radius: Double
        let vx: Double, vy: Double, alpha: Double
    }

    private let blobs: [Blob] = (0..<14).map { i in
        func unit(_ salt: Double) -> Double {
            let v = sin(Double(i) * 12.9898 + salt * 78.233) * 43758.5453
            return v - v.rounded(.down)
        }
        return Blob(
            x: unit(1), y: unit(2),
            radius: 70 + unit(3) * 130,
            vx: (unit(4) - 0.5) * 0.008,
            vy: (unit(5) - 0.5) * 0.004,
            alpha: 0.35 + unit(6) * 0.4
        )
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let t = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
                for blob in blobs {
                    let cx = wrap(blob.x + blob.vx * t) * size.width
                    let cy = wrap(blob.y + blob.vy * t) * size.height
                    let center = CGPoint(x: cx, y: cy)
                    let rect = CGRect(
                        x: cx - blob.radius, y: cy - blob.radius,
                        width: blob.radius * 2, height: blob.radius * 2
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [Theme.mist.opacity(blob.alpha), Theme.mist.opacity(0)]),
                            center: center,
                            startRadius: 0,
                            endRadius: blob.radius
                        )
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// 0...1 に正規化した位置を、画面外の余白を含む -0.2...1.2 の範囲で循環させる。
    private func wrap(_ value: Double) -> Double {
        var m = value.truncatingRemainder(dividingBy: 1)
        if m < 0 { m += 1 }
        return -0.2 + m * 1.4
    }
}
