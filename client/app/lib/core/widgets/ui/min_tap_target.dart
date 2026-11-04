import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Grows the touch area of a small control to [minSize] (44×44 by default,
/// ACCESSIBILITY_STRATEGY.md) without changing how it looks: the control
/// stays centered and taps on the margin are forwarded to it, like Material
/// does for its own chips and checkboxes.
class MinTapTarget extends SingleChildRenderObjectWidget {
  final Size minSize;

  const MinTapTarget({super.key, this.minSize = const Size.square(44), required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMinTapTarget(minSize);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderMinTapTarget).minSize = minSize;
  }
}

class _RenderMinTapTarget extends RenderShiftedBox {
  _RenderMinTapTarget(this._minSize) : super(null);

  Size _minSize;

  set minSize(Size value) {
    if (_minSize == value) return;
    _minSize = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(super.computeMinIntrinsicWidth(height), _minSize.width);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(super.computeMaxIntrinsicWidth(height), _minSize.width);

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(super.computeMinIntrinsicHeight(width), _minSize.height);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(super.computeMaxIntrinsicHeight(width), _minSize.height);

  Size _sizeFor(BoxConstraints constraints, Size childSize) => constraints.constrain(
        Size(math.max(childSize.width, _minSize.width), math.max(childSize.height, _minSize.height)),
      );

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _sizeFor(constraints, child?.getDryLayout(constraints) ?? Size.zero);

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = _sizeFor(constraints, Size.zero);
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = _sizeFor(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(size - child.size as Offset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    final child = this.child;
    if (child == null || !size.contains(position)) return false;
    final center = child.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, position) => child.hitTest(result, position: center),
    );
  }
}
