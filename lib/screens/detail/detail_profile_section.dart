import 'package:flutter/material.dart';

import '../../models/akasha_item.dart';
import '../../models/enums.dart';
import '../../services/works_registry.dart';
import '../../utils/helpers.dart';
import '../../utils/registry_extension_labels.dart';
import '../../widgets/poster_image.dart';
import '../../widgets/star_rating.dart';

/// 상세 화면 상단 프로필(포스터·메타데이터)
class DetailProfileSection extends StatelessWidget {
  final AkashaItem item;

  const DetailProfileSection({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final gradColors = categoryGradient(item.category);
    final dotColor = myStatusDotColor(item.myStatusLabel);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: PosterImage(
                item: item,
                fit: BoxFit.cover,
                width: 140,
                height: 190,
              ),
            ),
          ),
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
                Row(
                  children: [
                    StarRating(rating: item.rating, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      item.rating.toStringAsFixed(1),
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
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        '${item.releaseYear}년',
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
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
                        item.combinedStatusLabel,
                        style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                      ),
                    ),
                  ],
                ),
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
                if (item.isHallOfFame) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
