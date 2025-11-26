import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlassSidebarItem {
  final String title;
  final IconData icon;
  final String route;

  GlassSidebarItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

class GlassSidebar extends StatefulWidget {
  final List<GlassSidebarItem> items;
  final String currentRoute;
  final Function(String) onItemTap;
  final bool isCollapsed;

  const GlassSidebar({
    Key? key,
    required this.items,
    required this.currentRoute,
    required this.onItemTap,
    this.isCollapsed = false,
  }) : super(key: key);

  @override
  State<GlassSidebar> createState() => _GlassSidebarState();
}

class _GlassSidebarState extends State<GlassSidebar> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isCollapsed ? 80 : 260,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
            ),
            child: Column(
              children: [
                // Logo section
                Container(
                  height: 100,
                  padding: const EdgeInsets.all(20),
                  child: widget.isCollapsed
                      ? Image.asset(
                          'assets/images/logo_app.png',
                          width: 40,
                          height: 40,
                        )
                      : Row(
                          children: [
                            Image.asset(
                              'assets/images/logo_app.png',
                              width: 40,
                              height: 40,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'UNP Art Space',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
                const Divider(
                  color: Colors.white12,
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: 20),
                // Menu items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      final isActive = widget.currentRoute == item.route;
                      final isHovered = _hoveredIndex == index;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: MouseRegion(
                          onEnter: (_) =>
                              setState(() => _hoveredIndex = index),
                          onExit: (_) => setState(() => _hoveredIndex = null),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              gradient: isActive
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                    )
                                  : null,
                              color: isHovered && !isActive
                                  ? Colors.white.withOpacity(0.05)
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive
                                    ? Colors.transparent
                                    : isHovered
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.transparent,
                                width: 1,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF6366F1)
                                            .withOpacity(0.3),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => widget.onItemTap(item.route),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: widget.isCollapsed
                                      ? Icon(
                                          item.icon,
                                          color: Colors.white,
                                          size: 24,
                                        )
                                      : Row(
                                          children: [
                                            Icon(
                                              item.icon,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: isActive
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
