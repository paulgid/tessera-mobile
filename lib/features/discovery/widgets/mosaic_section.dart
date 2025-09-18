import 'package:flutter/material.dart';
import '../discovery_screen.dart';
import 'mosaic_preview_card.dart';

class MosaicSection extends StatelessWidget {
  final String title;
  final String icon;
  final List<MosaicPreview> mosaics;
  final VoidCallback onSeeAll;

  const MosaicSection({
    super.key,
    required this.title,
    required this.icon,
    required this.mosaics,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (mosaics.isEmpty) return const SizedBox();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onSeeAll,
                child: Row(
                  children: const [
                    Text('See All'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: mosaics.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == mosaics.length - 1 ? 0 : 12,
                ),
                child: MosaicPreviewCard(
                  mosaic: mosaics[index],
                  variant: CardVariant.compact,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
