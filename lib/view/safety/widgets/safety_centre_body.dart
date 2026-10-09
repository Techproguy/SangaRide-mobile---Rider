import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride/view/safety/widgets/emergency_contacts_card.dart';
import 'package:sanga_ride/view/safety/widgets/ride_details_card.dart';
import 'package:sanga_ride/view/safety/widgets/safety_tools.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

class SafetyCentreBody extends StatelessWidget {
  const SafetyCentreBody({
    super.key,
    required this.centre,
    required this.onAddContact,
    required this.onCallContact,
    required this.onRemoveContact,
    required this.onShareTrip,
    required this.onTripDetails,
    required this.onReport,
    this.removingContactId,
  });

  final SafetyCentre centre;
  final VoidCallback onAddContact;
  final ValueChanged<EmergencyContact> onCallContact;
  final ValueChanged<EmergencyContact> onRemoveContact;
  final VoidCallback onShareTrip;
  final VoidCallback onTripDetails;
  final VoidCallback onReport;
  final String? removingContactId;

  @override
  Widget build(BuildContext context) {
    final trip = centre.trip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: SangaSpacing.md,
      children: [
        EmergencyContactsCard(
          contacts: centre.contacts,
          removingId: removingContactId,
          onAdd: centre.canAddContact ? onAddContact : null,
          onCall: onCallContact,
          onRemove: onRemoveContact,
        ),
        if (trip != null) RideDetailsCard(trip: trip),
        const SizedBox(height: SangaSpacing.xs),
        SafetyTools(
          onShare: trip == null ? null : onShareTrip,
          onTripDetails: trip == null ? null : onTripDetails,
          onReport: onReport,
        ),
      ],
    );
  }
}
