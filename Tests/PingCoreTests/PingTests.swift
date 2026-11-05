import Foundation
import PingCore

var checks = 0
func expectEqual<T: Equatable>(_ actual: T, _ expected: T) { checks += 1; precondition(actual == expected, "Expected \(expected), got \(actual)") }
func expectNil<T>(_ value: T?) { checks += 1; precondition(value == nil) }
func expectSome<T>(_ value: T?) { checks += 1; precondition(value != nil) }
func expectFalse(_ value: Bool) { checks += 1; precondition(!value) }

final class PingTests {
    func testDirections() {
        let expected: [Ping] = [.attack,.help,.defend,.needVision,.enemyVision,.heart,.onMyWay,.danger]
        expectEqual(WheelGeometry.slots, expected)
        for (i, ping) in expected.enumerated() {
            let angle = (Double(i)*45+22.5)*Double.pi/180
            expectEqual(WheelGeometry.selection(dx:sin(angle)*80,dy:cos(angle)*80),ping)
            for offset in [-22.49,22.49] {
                let edge = (Double(i)*45+22.5+offset)*Double.pi/180
                expectEqual(WheelGeometry.selection(dx:sin(edge)*80,dy:cos(edge)*80),ping)
            }
        }

    }
    func testCancelZones() {
        expectNil(WheelGeometry.selection(dx: 0, dy: 0))
        expectNil(WheelGeometry.selection(dx: 34, dy: 0))
        expectNil(WheelGeometry.selection(dx: 88, dy: 0))
        expectNil(WheelGeometry.selection(dx: .nan, dy: 0))
        expectNil(WheelGeometry.selection(dx: .infinity, dy: 0))
    }
    func testRadiusBoundaries() {
        expectEqual(WheelGeometry.selection(dx: 35, dy: 0), .defend)
        expectEqual(WheelGeometry.selection(dx: 87.5, dy: 0), .defend)
    }
    func testSectorSweep() {
        for degree in stride(from: 0, to: 360, by: 1) {
            let angle = (Double(degree)+0.5) * .pi / 180
            expectEqual(WheelGeometry.selection(dx: sin(angle) * 70, dy: cos(angle) * 70), WheelGeometry.slots[Int((Double(degree) + 0.5) / 45) % 8])
        }
    }
    func testMonitorEdgesAndNegativeOrigins() {
        expectEqual(WheelGeometry.panelOrigin(anchor: 5, lower: 0, upper: 1440, size: 360), 0)
        expectEqual(WheelGeometry.panelOrigin(anchor: 1435, lower: 0, upper: 1440, size: 360), 1080)
        expectEqual(WheelGeometry.panelOrigin(anchor: -1910, lower: -1920, upper: 0, size: 360), -1920)
        expectEqual(WheelGeometry.panelOrigin(anchor: 700, lower: 0, upper: 1440, size: 360), 520)
    }
    func testAllSignalsHaveLabels() {
        expectEqual(Ping.allCases.count, 9)
        expectEqual(Ping.allCases.map(\.title), ["DEFAULT PING", "CAUTION", "ON MY WAY", "DEFEND", "ATTACK", "ENEMY WARD", "FRIENDLY WARD", "ASSIST", "HEART"])
        expectFalse(WheelGeometry.slots.contains(.attention))
        for ping in Ping.allCases { expectFalse(ping.title.isEmpty) }
    }
}

let suite = PingTests()
expectEqual(WheelGeometry.scale(screenHeight: 1080), 1)
expectEqual(WheelGeometry.scale(screenHeight: 2160), 2)
expectEqual(WheelGeometry.scale(screenHeight: 900), 5.0/6)
for scale in [0.5, 0.75, 1, 1.5, 2] {
    expectEqual(WheelGeometry.selection(dx: 60*scale, dy: 0, scale: scale), .defend)
    expectNil(WheelGeometry.selection(dx: 34*scale, dy: 0, scale: scale))
    expectNil(WheelGeometry.selection(dx: 88*scale, dy: 0, scale: scale))
}
expectNil(WheelGeometry.selection(dx: 60, dy: 0, scale: 0))
suite.testDirections()
suite.testCancelZones()
suite.testRadiusBoundaries()
suite.testSectorSweep()
suite.testMonitorEdgesAndNegativeOrigins()
suite.testAllSignalsHaveLabels()
var drag = DragGesture()
expectFalse(drag.begin(option: false, otherModifiers: false, paused: false))
expectFalse(drag.begin(option: true, otherModifiers: true, paused: false))
expectFalse(drag.begin(option: true, otherModifiers: false, paused: true))
expectNil(drag.finish(dx: 100, dy: 0, option: true, otherModifiers: false))
for expected in WheelGeometry.slots {
    expectEqual(drag.begin(option: true, otherModifiers: false, paused: false), true)
    let angle = WheelGeometry.angle(for: expected)
    expectEqual(drag.finish(dx: sin(angle) * 70, dy: cos(angle) * 70, option: true, otherModifiers: false), expected)
    expectFalse(drag.ownsMouse)
}
for scenario in 0..<4 {
    expectEqual(drag.begin(option: true, otherModifiers: false, paused: false), true)
    if scenario == 3 { drag.move(dx: 60, dy: 0) }
    if scenario == 0 { drag.cancel(); expectEqual(drag.ownsMouse, true) }
    expectNil(drag.finish(dx: scenario == 3 ? 0 : 100, dy: 0, option: scenario != 1, otherModifiers: scenario == 2))
    expectFalse(drag.ownsMouse)
}
for offset in [0.0, 2, 6] {
    expectEqual(drag.begin(option: true, otherModifiers: false, paused: false), true)
    drag.move(dx: offset, dy: 0)
    expectEqual(drag.finish(dx: offset, dy: 0, option: true, otherModifiers: false), .attention)
}
expectEqual(drag.begin(option: true, otherModifiers: false, paused: false), true)
drag.move(dx: 60, dy: 0); drag.move(dx: 0, dy: 0)
expectNil(drag.finish(dx: 0, dy: 0, option: true, otherModifiers: false))
expectEqual(drag.begin(option: true, otherModifiers: false, paused: false), true)
expectNil(drag.finish(dx: 0, dy: 0, option: false, otherModifiers: false))
expectEqual(drag.begin(option: true, otherModifiers: false, paused: false), true)
drag.cancel(); expectNil(drag.finish(dx: 0, dy: 0, option: true, otherModifiers: false))
for offset in [6.01, 34.99] {
    expectEqual(drag.begin(option: true, otherModifiers: false, paused: false), true)
    drag.move(dx: offset, dy: 0)
    expectEqual(drag.hasDragged, true)
    expectNil(drag.finish(dx: 0, dy: 0, option: true, otherModifiers: false))
}
for invalid in [Double.nan, Double.infinity] {
    expectEqual(drag.begin(option: true, otherModifiers: false, paused: false), true)
    expectNil(drag.finish(dx: invalid, dy: 0, option: true, otherModifiers: false))
    expectFalse(drag.ownsMouse)
}
// The visual rim bounds fallback clicks, not drag directions.
for scale in [0.5, 1.0, 2.0] {
    for radius in [87.5, 88, 300, 3000, 1000000] {
        for degree in 0..<360 {
            let angle = (Double(degree) + 0.5) * .pi / 180
            expectEqual(WheelGeometry.selection(dx: sin(angle) * radius * scale, dy: cos(angle) * radius * scale, scale: scale, bounded: false), WheelGeometry.slots[degree / 45])
        }
    }
    expectNil(WheelGeometry.selection(dx: 34 * scale, dy: 0, scale: scale, bounded: false))
}
expectNil(WheelGeometry.selection(dx: .nan, dy: 0, bounded: false))
expectNil(WheelGeometry.selection(dx: .infinity, dy: 0, bounded: false))
for ping in WheelGeometry.slots {
    expectEqual(drag.begin(option: true, otherModifiers: false, paused: false), true)
    let angle = WheelGeometry.angle(for: ping)
    drag.move(dx: 50, dy: 0)
    expectEqual(drag.finish(dx: sin(angle) * 3000, dy: cos(angle) * 3000, option: true, otherModifiers: false), ping)
}
for dragged in [false, true] {
    for leftFirst in [false, true] {
        var g = DragGesture()
        expectFalse(g.rightDown()); expectFalse(g.rightUp())
        expectEqual(g.begin(option: true, otherModifiers: false, paused: false), true)
        if dragged { g.move(dx: 3000, dy: 0) }
        expectEqual(g.rightDown(), true)
        expectEqual(g.cancelled, true)
        expectEqual(g.ownsMouse, true)
        expectEqual(g.ownsRightMouse, true)
        if leftFirst {
            expectNil(g.finish(dx: 3000, dy: 0, option: true, otherModifiers: false))
            expectEqual(g.ownsRightMouse, true)
            expectEqual(g.rightUp(), true)
        } else {
            expectEqual(g.rightUp(), true)
            expectEqual(g.ownsMouse, true)
            expectNil(g.finish(dx: 3000, dy: 0, option: true, otherModifiers: false))
        }
        expectFalse(g.ownsMouse); expectFalse(g.ownsRightMouse)
        expectFalse(g.rightDown()); expectFalse(g.rightUp())
    }
}
var lostUp = DragGesture()
expectEqual(lostUp.begin(option: true, otherModifiers: false, paused: false), true)
expectEqual(lostUp.rightDown(), true)
expectNil(lostUp.finish(dx: 3000, dy: 0, option: true, otherModifiers: false))
expectFalse(lostUp.rightDown()); expectFalse(lostUp.rightUp())
// Layer timing regressions: rings finish independently; the icon remains fully visible.
for ping in Ping.allCases {
    let timeline = PingAnimation(ping)
    for invalid in [-1.0, Double.nan, Double.infinity, timeline.duration, timeline.duration + 1] {
        let state = timeline.layers(at: invalid)
        expectEqual(state.ring, 0); expectEqual(state.beam, 0); expectEqual(state.icon, 0)
    }
    if timeline.isWard {
        expectEqual(timeline.layers(at: 1.02).ring, 0)
        expectEqual(timeline.layers(at: 1.02).icon, 1)
        expectFalse(timeline.layers(at: 1.25).ring == 0)
        expectEqual(timeline.layers(at: 0.65).beam, 0)
    } else {
        expectFalse(timeline.layers(at: 0.4).ring == 0)
        expectEqual(timeline.layers(at: 1.3).ring, 0)
        expectEqual(timeline.layers(at: 1.3).icon, 1)
        expectFalse(timeline.layers(at: 1.7).hotspot <= 0)
        if ping == .attention { expectEqual(timeline.layers(at: 1.6).hotspot, 1) }
        else { expectEqual(timeline.layers(at: 2.5).hotspot, 0) }
        expectEqual(timeline.layers(at: 1.7).icon, 1)
    }
    for tick in 0...600 {
        let state = timeline.layers(at: Double(tick) / 100)
        for alpha in [state.ring, state.hotspot, state.beam, state.icon] {
            expectFalse(!alpha.isFinite || alpha < 0 || alpha > 1)
        }
    }
}
print("Passed \(checks) core assertions including drag state machine.")
