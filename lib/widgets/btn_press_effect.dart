import 'package:flutter/material.dart';

class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BoxDecoration? decoration;
  final double pressedScale;
  final Color? pressedColor;
  final Duration duration;
  final Color hoverColor;
  final Duration hoverDuration;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.decoration,
    this.pressedScale = 0.95,
    this.pressedColor,
    this.duration = const Duration(milliseconds: 100),
    this.hoverColor = const Color(0xFF6C3BFF),
    this.hoverDuration = const Duration(milliseconds: 200),
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  late AnimationController _hoverCtrl;
  late Animation<double> _zoomAnim;
  late Animation<double> _fadeAnim;

  // Drives text/icon color: default color → white
  late Animation<Color?> _textColorAnim;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: widget.hoverDuration,
    );

    _zoomAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOutCubic),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut),
    );

    // Text color transitions to white as hover fills in
    _textColorAnim = ColorTween(
      begin: null, // inherits ambient text color
      end: Colors.white,
    ).animate(
      CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent _) => _hoverCtrl.forward();
  void _onExit(PointerEvent _) => _hoverCtrl.reverse();

  void _onTapDown(TapDownDetails _) => setState(() => _pressed = true);
  void _onTapUp(TapUpDetails _) {
    setState(() => _pressed = false);
    widget.onTap?.call();
  }
  void _onTapCancel() => setState(() => _pressed = false);

  @override
  Widget build(BuildContext context) {
    final pressedColor = widget.pressedColor ?? Colors.grey.shade300;
    final borderRadius =
        (widget.decoration?.borderRadius as BorderRadius?) ?? BorderRadius.zero;

    // Fallback text color from ambient theme
    final ambientColor = DefaultTextStyle.of(context).style.color
        ?? Theme.of(context).textTheme.bodyMedium?.color
        ?? Colors.black;

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1.0,
          duration: widget.duration,
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: _hoverCtrl,
            builder: (context, child) {
              // Interpolate text/icon color: ambient → white
              final textColor = _pressed
                  ? ambientColor
                  : (_textColorAnim.value ?? ambientColor);

              return Container(
                decoration: widget.decoration?.copyWith(
                  color: _pressed ? pressedColor : Colors.transparent,
                  gradient: null,
                ) ??
                    BoxDecoration(
                      color: _pressed ? pressedColor : Colors.transparent,
                    ),
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: Stack(
                    children: [
                      // Purple zoom-in overlay — behind the child
                      if (!_pressed)
                        Positioned.fill(
                          child: FadeTransition(
                            opacity: _fadeAnim,
                            child: Transform.scale(
                              scale: _zoomAnim.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: widget.hoverColor,
                                  borderRadius: borderRadius,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Child with animated text + icon color
                      DefaultTextStyle.merge(
                        style: TextStyle(color: textColor),
                        child: IconTheme.merge(
                          data: IconThemeData(color: textColor),
                          child: child!,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}