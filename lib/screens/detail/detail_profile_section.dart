import 'package:flutter/material.dart';

import '../../models/akasha_item.dart';
import '../../models/enums.dart';
import '../../services/works_registry.dart';
import '../../utils/registry_extension_labels.dart';
import '../../widgets/poster_image.dart';
import '../../widgets/star_rating.dart';

/// 상세 화면 상단 프로필(포스터·메타데이터)
class DetailProfileSection extends StatelessWidget {
  final AkashaItem item;
  final bool editable;
  final double? rating;
  final ValueChanged<double>? onRatingChanged;
  final String? workStatus;
  final String? myStatus;
  final ValueChanged<String>? onWorkStatusChanged;
  final ValueChanged<String>? onMyStatusChanged;
  final VoidCallback? onPosterTap;
  final bool isHallOfFame;
  final ValueChanged<bool>? onHallOfFameChanged;

  const DetailProfileSection({
    super.key,
    required this.item,
    this.editable = true,
    this.rating,
    this.onRatingChanged,
    this.workStatus,
    this.myStatus,
    this.onWorkStatusChanged,
    this.onMyStatusChanged,
    this.onPosterTap,
    this.isHallOfFame = false,
    this.onHallOfFameChanged,
  });

  AkashaItem get _displayItem => item;

  @override
  Widget build(BuildContext context) {
    final preview = _displayItem;
    final gradColors = categoryGradient(item.category);
    final dotColor = myStatusDotColor(preview.myStatusLabel);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPoster(preview, gradColors),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (item.creator.isNotEmpty)
                      Text(
                        item.creator,
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      ),
                    const SizedBox(height: 12),
                    if (editable && onRatingChanged != null)
                      InteractiveStarRating(
                        rating: rating ?? 0,
                        size: 24,
                        onChanged: onRatingChanged!,
                      )
                    else
                      Row(
                        children: [
                          StarRating(rating: preview.rating, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            preview.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    if (item.releaseYear != null)
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(
                            '${item.releaseYear}년',
                            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    if (editable &&
                        workStatus != null &&
                        myStatus != null &&
                        onWorkStatusChanged != null &&
                        onMyStatusChanged != null) ...[
                      _statusDropdown(
                        label: '작품 상태',
                        value: workStatus!,
                        options: item.workStatusOptions,
                        onChanged: onWorkStatusChanged!,
                      ),
                      const SizedBox(height: 8),
                      _statusDropdown(
                        label: '나의 상태',
                        value: myStatus!,
                        options: item.myStatusOptions,
                        onChanged: onMyStatusChanged!,
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              preview.combinedStatusLabel,
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey[400]),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Chip(
                      avatar: Icon(item.category.icon, size: 14),
                      label: Text(
                        item.category.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    ..._registryExtensionLines(),
                    if (editable && onHallOfFameChanged != null) ...[
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text(
                          '👑 Hall of Fame',
                          style: TextStyle(fontSize: 13),
                        ),
                        value: isHallOfFame,
                        onChanged: onHallOfFameChanged,
                      ),
                    ] else if (!editable && item.isHallOfFame) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('👑', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              'Hall of Fame',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPoster(AkashaItem preview, List<Color> gradColors) {
    final poster = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: PosterImage(
        item: preview,
        fit: BoxFit.cover,
        width: 140,
        height: 190,
      ),
    );

    final decorated = Container(
      width: 140,
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradColors,
        ),
        boxShadow: [
          BoxShadow(
            color: gradColors[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: poster,
    );

    if (!editable || onPosterTap == null) return decorated;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPosterTap,
        child: Stack(
          children: [
            decorated,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(10),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_search, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      '포스터 교정',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          items: options
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }

  List<Widget> _registryExtensionLines() {
    if (item.workId.isEmpty) return const [];
    final work = WorksRegistry.getWorkById(item.workId);
    if (work == null) return const [];

    final lines = formatRegistryExtensionLines(work);
    if (lines.isEmpty) return const [];

    return [
      const SizedBox(height: 8),
      ...lines.map(
        (line) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  line,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }
}
