import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SwipeDownImageViewer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDismiss;
  final double minScale;
  final double maxScale;

  const SwipeDownImageViewer({
    super.key,
    required this.child,
    this.onDismiss,
    this.minScale = 1,
    this.maxScale = 4,
  });

  @override
  State<SwipeDownImageViewer> createState() => _SwipeDownImageViewerState();
}

class _SwipeDownImageViewerState extends State<SwipeDownImageViewer> {
  static const _dismissDistance = 120.0;
  static const _dismissVelocity = 900.0;
  static const _dragStartDistance = 8.0;
  static const _baseScaleTolerance = 0.01;

  final _transformationController = TransformationController();
  final _activePointers = <int>{};

  int? _primaryPointer;
  Offset? _pointerOrigin;
  VelocityTracker? _velocityTracker;
  double _dragOffset = 0;
  bool _dragging = false;
  bool _verticalDragLocked = false;

  bool get _isAtBaseScale =>
      _transformationController.value.getMaxScaleOnAxis() <=
      widget.minScale + _baseScaleTolerance;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_handleTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController
      ..removeListener(_handleTransformationChanged)
      ..dispose();
    super.dispose();
  }

  void _handleTransformationChanged() {
    if (!_isAtBaseScale && (_dragging || _dragOffset != 0)) {
      _resetDrag();
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);
    if (_activePointers.length != 1 || !_isAtBaseScale) {
      _resetDrag();
      return;
    }

    _primaryPointer = event.pointer;
    _pointerOrigin = event.position;
    _velocityTracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePointers.length != 1 ||
        event.pointer != _primaryPointer ||
        !_isAtBaseScale ||
        _pointerOrigin == null) {
      return;
    }

    _velocityTracker?.addPosition(event.timeStamp, event.position);
    final distance = event.position - _pointerOrigin!;

    if (!_verticalDragLocked) {
      if (distance.dy <= _dragStartDistance ||
          distance.dy.abs() <= distance.dx.abs()) {
        return;
      }
      _verticalDragLocked = true;
    }

    setState(() {
      _dragging = true;
      _dragOffset = distance.dy.clamp(0, double.infinity);
    });
  }

  void _handlePointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
    if (event.pointer != _primaryPointer) return;

    _velocityTracker?.addPosition(event.timeStamp, event.position);
    final downwardVelocity =
        _velocityTracker?.getVelocity().pixelsPerSecond.dy ?? 0;
    final shouldDismiss =
        _dragOffset >= _dismissDistance ||
        (_dragOffset >= _dragStartDistance &&
            downwardVelocity >= _dismissVelocity);

    if (shouldDismiss) {
      final callback = widget.onDismiss;
      if (callback != null) {
        callback();
      } else {
        Navigator.of(context).maybePop();
      }
      return;
    }

    _resetDrag();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    if (event.pointer == _primaryPointer) _resetDrag();
  }

  void _resetDrag() {
    _primaryPointer = null;
    _pointerOrigin = null;
    _velocityTracker = null;
    _verticalDragLocked = false;
    if (!mounted) return;
    setState(() {
      _dragging = false;
      _dragOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: AnimatedContainer(
        duration: _dragging ? Duration.zero : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _dragOffset, 0),
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: widget.minScale,
          maxScale: widget.maxScale,
          child: widget.child,
        ),
      ),
    );
  }
}
