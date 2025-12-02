import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/artwork_model.dart';

class AiAnalysisCard extends StatelessWidget {
  final ArtworkModel artwork;
  final bool isCompact;

  const AiAnalysisCard({
    Key? key,
    required this.artwork,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only show if AI is suspected
    if (!artwork.isAiSuspected) {
      return const SizedBox.shrink();
    }

    final score = artwork.aiGeneratedScore ?? 0.0;
    final isHighRisk = artwork.isHighRisk;
    final isMediumRisk = artwork.isMediumRisk;

    // Color selection based on risk level
    final warningColor = isHighRisk
        ? const Color(0xFFFF6584)
        : const Color(0xFFFFA726);

    final backgroundColor = isHighRisk
        ? const Color(0xFF2D1F2A)
        : const Color(0xFF2D2820);

    final iconBackgroundColor = isHighRisk
        ? const Color(0xFFFF6584).withOpacity(0.2)
        : const Color(0xFFFFA726).withOpacity(0.2);

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: isCompact ? 8 : 12,
        horizontal: isCompact ? 0 : 0,
      ),
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: warningColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: warningColor.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: warningColor,
                  size: isCompact ? 18 : 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terindikasi Konten AI',
                      style: GoogleFonts.poppins(
                        color: warningColor,
                        fontSize: isCompact ? 13 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      artwork.riskLevel,
                      style: GoogleFonts.poppins(
                        color: warningColor.withOpacity(0.7),
                        fontSize: isCompact ? 11 : 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              // Score badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: warningColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: warningColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  artwork.scorePercentage,
                  style: GoogleFonts.poppins(
                    color: warningColor,
                    fontSize: isCompact ? 12 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          if (!isCompact) ...[
            const SizedBox(height: 16),

            // Progress bar with gradient
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Skor Probabilitas AI',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(score * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        // Progress fill with gradient
                        FractionallySizedBox(
                          widthFactor: score,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isHighRisk
                                    ? [
                                        const Color(0xFFFF6584),
                                        const Color(0xFFFF6584).withOpacity(0.8),
                                      ]
                                    : isMediumRisk
                                        ? [
                                            const Color(0xFFFFA726),
                                            const Color(0xFFFFA726).withOpacity(0.8),
                                          ]
                                        : [
                                            const Color(0xFFFFD54F),
                                            const Color(0xFFFFD54F).withOpacity(0.8),
                                          ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Scale markers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildScaleMarker('0%', Colors.white38),
                    _buildScaleMarker('50%', Colors.white38),
                    _buildScaleMarker('80%', const Color(0xFFFFA726)),
                    _buildScaleMarker('100%', const Color(0xFFFF6584)),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScaleMarker(String label, Color color) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
