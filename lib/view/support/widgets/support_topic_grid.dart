import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/support/support_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SupportTopicGrid extends StatelessWidget {
  const SupportTopicGrid({super.key, required this.topics, required this.onSelected});

  static const int _columns = 3;
  static const double _tileHeight = 92;

  final List<SupportTopic> topics;
  final ValueChanged<SupportTopic> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: _columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: SangaSpacing.sm,
      crossAxisSpacing: SangaSpacing.sm,
      mainAxisExtent: _tileHeight,
      children: [for (final topic in topics) _TopicTile(topic: topic, onTap: () => onSelected(topic))],
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic, required this.onTap});

  final SupportTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: topic.label,
      excludeSemantics: true,
      child: Material(
        color: SangaColors.chipBlue,
        borderRadius: SangaRadii.field,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(SangaSpacing.xs),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: SangaSpacing.xs,
              children: [
                Icon(SupportCopy.topicIconOf(topic.icon), size: 26, color: SangaColors.primary),
                Text(
                  topic.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SangaTextStyles.tileLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
