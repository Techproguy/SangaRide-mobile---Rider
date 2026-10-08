import 'package:flutter/material.dart';
import 'package:sanga_ride/core/format/time_format.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/notifications/notification_copy.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class NotificationRow extends StatelessWidget {
  const NotificationRow({super.key, required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return Semantics(
      button: onTap != null,
      label: '${isUnread ? 'Unread. ' : ''}${notification.title}. ${notification.body}',
      excludeSemantics: true,
      child: Material(
        color: isUnread ? SangaColors.chipBlue : SangaColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: SangaRadii.field,
          side: BorderSide(color: isUnread ? SangaColors.primarySoft : SangaColors.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(SangaSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: SangaSpacing.sm,
              children: [
                SangaIconBadge(size: 34, child: Icon(notification.kind.icon)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: SangaSpacing.xxs,
                    children: [
                      Row(
                        spacing: SangaSpacing.xs,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SangaTextStyles.cardTitle.copyWith(
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          if (isUnread)
                            const DecoratedBox(
                              decoration: BoxDecoration(color: SangaColors.primary, shape: BoxShape.circle),
                              child: SizedBox.square(dimension: 8),
                            ),
                        ],
                      ),
                      Text(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SangaTextStyles.cardSubtitle.copyWith(fontSize: 13, color: SangaColors.textMid),
                      ),
                      Text(TimeFormat.ago(notification.createdAt), style: SangaTextStyles.caption),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Padding(
                    padding: EdgeInsets.only(top: SangaSpacing.xs),
                    child: SangaListRow.chevron,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
