import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/supa_card.dart';
import 'package:fl_chart/fl_chart.dart';

class FlipMetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String subValue;
  final double progress;
  final IconData icon;
  final Color color;
  final List<FlSpot> chartData;

  const FlipMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subValue,
    required this.progress,
    required this.icon,
    required this.color,
    required this.chartData,
  });

  @override
  State<FlipMetricCard> createState() => _FlipMetricCardState();
}

class _FlipMetricCardState extends State<FlipMetricCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _rotation = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  void _flip() {
    if (_controller.isAnimating) return;
    
    // Increment rotation by 180 degrees (pi)
    final double start = _rotation;
    final double end = _rotation + pi;
    
    setState(() {
      _animation = Tween<double>(begin: start, end: end).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
      );
      
      _controller.forward(from: 0).then((_) {
        _rotation = end;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value;
          // Determine front or back based on rotation count
          // (angle / pi).floor() % 2 == 0 means front
          final isFrontHalf = ((angle + pi / 2) / pi).floor() % 2 == 0;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // Slightly increased perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFrontHalf
                ? _buildFront()
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildBack(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return SupaCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: _flip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, size: 18, color: widget.color),
              ),
              Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.value,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'JetBrains Mono',
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 40,
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          widget.chartData.length.clamp(0, 10),
                          (i) => BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: widget.chartData[i].y,
                                color: widget.color.withOpacity(0.4),
                                width: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.subValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                    ),
                  ),
                  Text(
                    '${(widget.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: widget.progress.clamp(0.0, 1.0),
                  backgroundColor: AppColors.bgOverlay,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return SupaCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: _flip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${widget.title} Trend',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Icon(Icons.show_chart, size: 14, color: widget.color),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                barGroups: widget.chartData.map((spot) {
                  return BarChartGroupData(
                    x: spot.x.toInt(),
                    barRods: [
                      BarChartRodData(
                        toY: spot.y,
                        color: widget.color,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                      ),
                    ],
                  );
                }).toList(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.toStringAsFixed(0),
                        TextStyle(color: widget.color, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

