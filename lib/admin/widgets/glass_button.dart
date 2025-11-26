import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum GlassButtonType { primary, secondary, outline, danger, success }

class GlassButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final GlassButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double? height;
  final double? fontSize;

  const GlassButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = GlassButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.fontSize,
  }) : super(key: key);

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isHovered = false;

  LinearGradient _getGradient() {
    switch (widget.type) {
      case GlassButtonType.primary:
        return const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        );
      case GlassButtonType.secondary:
        return const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
        );
      case GlassButtonType.danger:
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        );
      case GlassButtonType.success:
        return const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        );
      case GlassButtonType.outline:
        return const LinearGradient(
          colors: [Colors.transparent, Colors.transparent],
        );
    }
  }

  Color _getBorderColor() {
    switch (widget.type) {
      case GlassButtonType.outline:
        return Colors.white.withOpacity(0.2);
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.width,
        height: widget.height ?? 48,
        decoration: BoxDecoration(
          gradient: widget.type == GlassButtonType.outline
              ? null
              : _getGradient(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getBorderColor(),
            width: widget.type == GlassButtonType.outline ? 1.5 : 0,
          ),
          boxShadow: _isHovered && !widget.isLoading
              ? [
                  BoxShadow(
                    color: _getGradient().colors.first.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: widget.type == GlassButtonType.outline
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: _buildButtonContent(),
                ),
              )
            : _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isLoading ? null : widget.onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: widget.fontSize ?? 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
