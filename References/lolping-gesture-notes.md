# lolPing gesture comparison for v0.7.1

Inspected upstream commit `c97fe772b98514b83f011ee540601faabd066d23` on 2026-11-04. No upstream code is bundled or executed.

- [geometry.ts](https://github.com/darrenprx/lolPing/blob/c97fe772b98514b83f011ee540601faabd066d23/src/shared/geometry.ts): `pickSlice` rejects the inner dead zone only, then computes the slice using atan2. The outer radius controls artwork, not drag selection.
- [wheel.ts lines 121–131](https://github.com/darrenprx/lolPing/blob/c97fe772b98514b83f011ee540601faabd066d23/src/renderer/overlay/wheel.ts#L121-L131): move and release both recompute selection using cursor offset from the original origin. The placed ping uses the original origin.
- [decision.cpp lines 508–575](https://github.com/darrenprx/lolPing/blob/c97fe772b98514b83f011ee540601faabd066d23/native/hook-helper/src/decision.cpp#L508-L575): right-down cancels Pending or Wheel. It swallows the right-down/up and transitions to SwallowUp for the drag button. A fresh right-down resets stale right-up ownership.
- [helper_tests.cpp lines 197–215](https://github.com/darrenprx/lolPing/blob/c97fe772b98514b83f011ee540601faabd066d23/native/hook-helper/tests/helper_tests.cpp#L197-L215): verifies right cancel, no wheel release after cancellation, and ordinary Option-right-click pass-through outside gestures.

DotaPing applies unbounded angle selection to Option-drag only. Keyboard fallback click hit regions remain bounded. Dota artwork, slot angles and initial target anchoring are unchanged. Cancel-button drags and both release orders are consumed; ordinary right-clicks pass through.

Deliberate remaining difference: current lolPing lets an open wheel survive release of the trigger key (decision.cpp lines 491–492). DotaPing retains its documented Option-release cancellation in this patch. This change addresses outer-boundary selection and right-click cancellation, not every upstream gesture convention.
