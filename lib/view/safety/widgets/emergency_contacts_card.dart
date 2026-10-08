import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class EmergencyContactsCard extends StatelessWidget {
  const EmergencyContactsCard({
    super.key,
    required this.contacts,
    required this.onCall,
    required this.onRemove,
    this.removingId,
    this.onAdd,
  });

  static const double _removingOpacity = 0.4;

  final List<EmergencyContact> contacts;
  final ValueChanged<EmergencyContact> onCall;
  final ValueChanged<EmergencyContact> onRemove;
  final String? removingId;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return SangaSectionCard(
      title: 'Emergency contacts',
      subtitle: 'We’ll let them know if you need help',
      action: onAdd == null ? null : SangaSquareAction(label: 'Add emergency contact', onPressed: onAdd),
      children: [
        if (contacts.isEmpty)
          SangaInlineMessage(
            title: 'No contacts yet',
            message: 'Add someone you trust. We’ll let them know if you ever need help.',
            actionLabel: onAdd == null ? null : 'Add a contact',
            onAction: onAdd,
          ),
        for (final contact in contacts)
          Opacity(
            opacity: contact.id == removingId ? _removingOpacity : 1,
            child: SangaContactRow(
              name: contact.name,
              phone: contact.displayPhone,
              onCall: () => onCall(contact),
              onRemove: removingId == null ? () => onRemove(contact) : null,
            ),
          ),
      ],
    );
  }
}
