import SwiftUI

struct DragMotion {
    var trail: [CGPoint] = []
    var velocity: CGFloat = 0
    var speed: CGFloat = 0

    private let maxTrail = 7

    mutating func sample(_ point: CGPoint) {
        if let last = trail.last {
            let dx = point.x - last.x
            let dy = point.y - last.y
            velocity = velocity * 0.65 + dx * 0.35
            speed = speed * 0.6 + sqrt(dx * dx + dy * dy) * 0.4
        }
        trail.append(point)
        if trail.count > maxTrail { trail.removeFirst(trail.count - maxTrail) }
    }

    mutating func reset() {
        trail.removeAll()
        velocity = 0
        speed = 0
    }

    var tilt: Angle { .degrees(Double(min(20, max(-20, velocity * 1.1)))) }
    var trailStrength: Double { Double(min(1, max(0, (speed - 3) / 17))) }
}

struct BottleTrail: View {
    var points: [CGPoint]
    var width: CGFloat
    var height: CGFloat
    var tilt: Angle
    var strength: Double = 1

    var body: some View {
        Canvas { ctx, _ in
            guard points.count > 1, strength > 0.01 else { return }
            for (i, p) in points.dropLast().enumerated() {
                let f = Double(i + 1) / Double(points.count)
                let alpha = 0.26 * f * f * strength
                guard alpha > 0.012 else { continue }
                let s = 0.78 + 0.22 * CGFloat(f)
                var layer = ctx
                layer.translateBy(x: p.x, y: p.y)
                layer.rotate(by: tilt)
                let rect = CGRect(x: -width * s / 2, y: -height * s / 2,
                                  width: width * s, height: height * s)
                layer.fill(BottleShape().path(in: rect), with: .color(Theme.bottleBlue.opacity(alpha)))
            }
        }
        .allowsHitTesting(false)
    }
}

struct DropImpact: View {
    var trigger: Int
    var color: Color

    @State private var progress: CGFloat = 1
    @State private var live = false

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let p = progress
            let fade = Double(1 - p)

            ZStack {
                Circle()
                    .stroke(color.opacity(fade * 0.85), lineWidth: 1 + 3 * (1 - p))
                    .frame(width: s * (0.22 + p * 0.78), height: s * (0.22 + p * 0.78))

                Ellipse()
                    .stroke(color.opacity(fade * 0.45), lineWidth: 1.5)
                    .frame(width: s * (0.3 + p * 1.15), height: s * (0.3 + p * 1.15) * 0.3)
                    .offset(y: s * 0.18)

                ForEach(0..<8, id: \.self) { i in
                    let a = Double(i) / 8 * 2 * .pi
                    let d = s * 0.48 * p
                    Circle()
                        .fill(color.opacity(fade))
                        .frame(width: 4, height: 4)
                        .offset(x: CGFloat(cos(a)) * d, y: CGFloat(sin(a)) * d * 0.55)
                }
            }
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .opacity(live ? 1 : 0)
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in fire() }
    }

    private func fire() {
        progress = 0
        live = true
        withAnimation(.easeOut(duration: 0.55)) { progress = 1 }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.6))
            live = false
        }
    }
}

struct DragTarget {
    var rect: CGRect
    var color: Color

    init(_ rect: CGRect, _ color: Color) {
        self.rect = rect
        self.color = color
    }
}

struct DraggableBottle: View {
    @Binding var position: CGPoint
    @Binding var dragBase: CGPoint
    @Binding var hasDragged: Bool

    var targets: [DragTarget]
    var containerSize: CGSize
    var width: CGFloat
    var height: CGFloat
    var vibrancy: Double
    var dirt: Double
    var active: Bool
    var onDrop: () -> Void

    @State private var motion = DragMotion()
    @State private var impactToken = 0
    @State private var impactAt = CGPoint(x: 0.5, y: 0.5)
    @State private var impactColor = Color.white

    var body: some View {
        let shown = magnetised(position, into: targets.map(\.rect))

        ZStack {
            BottleTrail(points: motion.trail, width: width, height: height,
                        tilt: motion.tilt, strength: motion.trailStrength)

            BottleView(vibrancy: vibrancy, dirt: dirt, showEyes: false, width: width, height: height)
                .rotationEffect(motion.tilt)
                .position(x: shown.x * containerSize.width, y: shown.y * containerSize.height)

            DropImpact(trigger: impactToken, color: impactColor)
                .frame(width: containerSize.width * 0.30, height: containerSize.width * 0.30)
                .position(x: impactAt.x * containerSize.width, y: impactAt.y * containerSize.height)
        }
        .contentShape(Rectangle())
        .gesture(drag, including: active ? .all : .none)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                hasDragged = true
                let p = CGPoint(
                    x: min(0.95, max(0.05, dragBase.x + value.translation.width / containerSize.width)),
                    y: min(0.95, max(0.05, dragBase.y + value.translation.height / containerSize.height))
                )
                position = p
                motion.sample(CGPoint(x: p.x * containerSize.width, y: p.y * containerSize.height))
            }
            .onEnded { _ in
                if let hit = targets.first(where: { $0.rect.contains(position) }) {
                    impactAt = CGPoint(x: hit.rect.midX, y: hit.rect.midY)
                    impactColor = hit.color
                    impactToken += 1
                }
                withAnimation(.easeOut(duration: 0.25)) { motion.reset() }
                onDrop()
            }
    }
}

func magnetised(_ p: CGPoint, into rects: [CGRect], maxPull: CGFloat = 0.45) -> CGPoint {
    for rect in rects where rect.contains(p) {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let dx = abs(p.x - c.x) / max(rect.width / 2, 0.0001)
        let dy = abs(p.y - c.y) / max(rect.height / 2, 0.0001)
        let depth = 1 - min(1, max(dx, dy))
        let k = min(maxPull, depth * 0.9)
        return CGPoint(x: p.x + (c.x - p.x) * k, y: p.y + (c.y - p.y) * k)
    }
    return p
}
