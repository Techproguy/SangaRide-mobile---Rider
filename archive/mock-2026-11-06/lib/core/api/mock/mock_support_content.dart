import 'package:sanga_ride/core/api/mock/mock_region.dart';

abstract final class MockSupportContent {
  static Map<String, dynamic> get contact => {
    'phone': MockRegion.supportPhone,
    'hours': '24/7',
    'chatAvailable': true,
    'chatWaitMinutes': 2,
  };

  static const List<Map<String, dynamic>> topics = [
    {'id': 'trips', 'label': 'Trips', 'icon': 'route'},
    {'id': 'payments', 'label': 'Payments', 'icon': 'payment'},
    {'id': 'deliveries', 'label': 'Deliveries', 'icon': 'delivery'},
    {'id': 'account', 'label': 'Account', 'icon': 'account'},
    {'id': 'safety', 'label': 'Safety', 'icon': 'safety'},
  ];

  static const List<String> popularIds = ['del_track', 'trip_late', 'trip_dropoff', 'trip_cancel', 'saf_report'];

  static const List<Map<String, dynamic>> articles = [
    {
      'id': 'trip_book',
      'topic': 'trips',
      'title': 'How to book a ride',
      'summary': 'From where to go to meeting your driver',
      'body': [
        {
          'type': 'paragraph',
          'text': 'Booking takes a few taps. Tell us where you are going and pick the ride that suits you.',
        },
        {
          'type': 'bullets',
          'items': [
            'Search for your drop-off on the home screen',
            'Choose a ride type and how you want to pay',
            'Pick a driver offer you like',
            'Share your PIN with the driver when they arrive',
          ],
        },
      ],
    },
    {
      'id': 'trip_late',
      'topic': 'trips',
      'title': 'What to do if your driver is late',
      'summary': 'Checking, calling and changing drivers',
      'body': [
        {'type': 'paragraph', 'text': 'Check the live map first. Your driver may be stuck in traffic or close by.'},
        {
          'type': 'bullets',
          'items': [
            'Message or call your driver from the trip screen',
            'Wait a few minutes if they are close',
            'Cancel for free if they are taking too long',
          ],
        },
        {'type': 'paragraph', 'text': 'Still stuck? Report an issue and we will step in.'},
      ],
    },
    {
      'id': 'trip_dropoff',
      'topic': 'trips',
      'title': 'Can I change my drop-off location?',
      'summary': 'Add or change a stop during your trip',
      'body': [
        {'type': 'paragraph', 'text': 'Yes. You can change where you are going while your trip is on.'},
        {
          'type': 'bullets',
          'items': ['Open your trip and tap Stops', 'Search for the new place', 'Check the updated fare and confirm'],
        },
        {'type': 'paragraph', 'text': 'Your driver sees the new route straight away.'},
      ],
    },
    {
      'id': 'trip_cancel',
      'topic': 'trips',
      'title': 'How cancellation works',
      'summary': 'When it is free and when a fee applies',
      'body': [
        {
          'type': 'paragraph',
          'text': 'Cancelling is free before a driver is confirmed. After that, a small fee can apply if your driver is already on the way.',
        },
        {'type': 'paragraph', 'text': 'We never charge you when the driver is the reason for the cancellation.'},
      ],
    },
    {
      'id': 'trip_scheduled',
      'topic': 'trips',
      'title': 'How scheduled rides work',
      'summary': 'Plan ahead and get a reminder',
      'body': [
        {
          'type': 'paragraph',
          'text': 'Book a ride for later and we line up a driver for you. You will find it under Scheduled rides in the menu.',
        },
        {
          'type': 'bullets',
          'items': [
            'We remind you before it begins',
            'You can change or cancel it any time before pickup',
            'Your driver is confirmed closer to the time',
          ],
        },
      ],
    },
    {
      'id': 'trip_lost',
      'topic': 'trips',
      'title': 'I left something in the car',
      'summary': 'Getting your things back',
      'body': [
        {
          'type': 'paragraph',
          'text': 'Open the trip in your ride history and tap Contact driver. Most drivers return lost items quickly.',
        },
        {'type': 'paragraph', 'text': 'If you cannot reach them, report an issue and we will help you get it back.'},
      ],
    },
    {
      'id': 'pay_methods',
      'topic': 'payments',
      'title': 'Ways to pay for a ride',
      'summary': 'Cash and card, side by side',
      'body': [
        {
          'type': 'paragraph',
          'text': 'Pay your driver in cash at the end of your trip, or pay with your card in the app.',
        },
        {'type': 'paragraph', 'text': 'You can switch how you pay before you confirm a ride.'},
      ],
    },
    {
      'id': 'pay_fare',
      'topic': 'payments',
      'title': 'How your fare is worked out',
      'summary': 'Base fare, distance, time and demand',
      'body': [
        {'type': 'paragraph', 'text': 'Your fare is built from a few simple parts. You see it before you book.'},
        {
          'type': 'bullets',
          'items': [
            'A base fare to start the trip',
            'Distance travelled',
            'Time spent on the trip',
            'Extra when lots of people need rides',
          ],
        },
      ],
    },
    {
      'id': 'pay_refund',
      'topic': 'payments',
      'title': 'Getting a refund',
      'summary': 'When refunds happen and how long they take',
      'body': [
        {
          'type': 'paragraph',
          'text': 'If you were charged by mistake, report an issue and pick Payment. We check the trip and refund what is yours.',
        },
        {'type': 'paragraph', 'text': 'Card refunds usually reach your bank within a few working days.'},
      ],
    },
    {
      'id': 'pay_receipt',
      'topic': 'payments',
      'title': 'Finding a receipt',
      'summary': 'Share or save your trip receipt',
      'body': [
        {
          'type': 'paragraph',
          'text': 'Open any finished trip in your ride history to see its receipt. You can share it from there.',
        },
      ],
    },
    {
      'id': 'del_track',
      'topic': 'deliveries',
      'title': 'How to track my delivery',
      'summary': 'Follow your package on the map',
      'body': [
        {'type': 'paragraph', 'text': 'Once a driver picks up your package you can follow it live on the map.'},
        {
          'type': 'bullets',
          'items': [
            'Open Ride history or the home screen to find your delivery',
            'Tap the delivery to see the live map',
            'Share the tracking link with your recipient',
          ],
        },
      ],
    },
    {
      'id': 'del_prohibited',
      'topic': 'deliveries',
      'title': 'What you can and cannot send',
      'summary': 'Items we are not able to carry',
      'body': [
        {'type': 'paragraph', 'text': 'We cannot carry anything dangerous, illegal or restricted by law.'},
        {
          'type': 'bullets',
          'items': [
            'No weapons or explosives',
            'No illegal drugs',
            'No live animals',
            'Be honest about what is in the package',
          ],
        },
      ],
    },
    {
      'id': 'del_recipient',
      'topic': 'deliveries',
      'title': 'When your recipient is not around',
      'summary': 'What happens if nobody collects it',
      'body': [
        {
          'type': 'paragraph',
          'text': 'Your driver will call the recipient and wait a few minutes. If nobody answers, we get in touch with you to decide what happens next.',
        },
      ],
    },
    {
      'id': 'acct_phone',
      'topic': 'account',
      'title': 'Changing your phone number',
      'summary': 'Move your account to a new number',
      'body': [
        {
          'type': 'paragraph',
          'text': 'Open Profile, tap your phone number and enter the new one. We text a code to make sure it is yours.',
        },
      ],
    },
    {
      'id': 'acct_verify',
      'topic': 'account',
      'title': 'Why verify your account',
      'summary': 'A safer ride for everyone',
      'body': [
        {'type': 'paragraph', 'text': 'Verified riders help drivers feel safe and get you matched faster.'},
        {
          'type': 'bullets',
          'items': ['Take a quick selfie', 'Upload a valid ID', 'Reviews usually take up to 24 hours'],
        },
      ],
    },
    {
      'id': 'acct_delete',
      'topic': 'account',
      'title': 'Deleting your account',
      'summary': 'What happens and how to change your mind',
      'body': [
        {'type': 'paragraph', 'text': 'You can delete your account from Profile. It is removed after 30 days.'},
        {'type': 'paragraph', 'text': 'Log back in within those 30 days and your account stays right where it was.'},
      ],
    },
    {
      'id': 'saf_emergency',
      'topic': 'safety',
      'title': 'What to do in an emergency',
      'summary': 'Get help fast',
      'body': [
        {
          'type': 'paragraph',
          'text': 'If you are in danger, get to a safe place and use the SOS button in Safety Centre.',
        },
        {
          'type': 'bullets',
          'items': [
            'Your emergency contacts are alerted',
            'The Sanga safety team is alerted',
            'Your live location is shared',
          ],
        },
      ],
    },
    {
      'id': 'saf_share',
      'topic': 'safety',
      'title': 'Sharing your trip with someone',
      'summary': 'Let a friend follow along',
      'body': [
        {
          'type': 'paragraph',
          'text': 'Share your trip from the trip screen. The person you pick can follow your ride live on a map.',
        },
      ],
    },
    {
      'id': 'saf_report',
      'topic': 'safety',
      'title': 'How to report a safety issue',
      'summary': 'Tell us what happened',
      'body': [
        {
          'type': 'paragraph',
          'text': 'Open Safety Centre and choose Report a safety issue, or report an issue from Support and pick Safety concern.',
        },
      ],
    },
  ];

  static const List<Map<String, dynamic>> issueCategories = [
    {
      'code': 'driver_not_moving',
      'title': 'Driver not moving',
      'subtitle': 'Driver has stopped for too long',
      'icon': 'griddy-icons:private-driver-filled',
      'appliesTo': ['ride', 'delivery'],
      'requiresDescription': false,
      'reported': 'Driver stopped for too long',
      'investigating': 'Our team is checking with your driver',
      'needsAction': true,
      'options': [
        {'id': 'check_driver', 'label': 'Ask support to check on the driver', 'hint': 'We will call them for you'},
        {'id': 'cancel_free', 'label': 'Cancel without a fee', 'hint': 'You will not be charged'},
      ],
    },
    {
      'code': 'cannot_reach_driver',
      'title': 'Cannot reach driver',
      'subtitle': 'Driver is not responding',
      'icon': 'griddy-icons:phone-disabled-filled',
      'appliesTo': ['ride', 'delivery'],
      'requiresDescription': false,
      'reported': 'Driver not responding',
      'investigating': 'Our team is trying to reach your driver',
      'needsAction': true,
      'options': [
        {'id': 'wait_more', 'label': 'Wait a few more minutes', 'hint': 'We will keep trying the driver'},
        {'id': 'cancel_free', 'label': 'Cancel without a fee', 'hint': 'You will not be charged'},
        {'id': 'new_driver', 'label': 'Find me a new driver', 'hint': 'We will match you again'},
      ],
    },
    {
      'code': 'wrong_location',
      'title': 'Wrong location',
      'subtitle': 'Driver is at a different location',
      'icon': 'griddy-icons:location-off-filled',
      'appliesTo': ['ride', 'delivery'],
      'requiresDescription': false,
      'reported': 'Driver at the wrong spot',
      'investigating': 'Our team is checking the pickup details',
      'needsAction': true,
      'options': [
        {'id': 'resend_pin', 'label': 'Send my pickup pin to the driver again', 'hint': 'We will message them for you'},
        {'id': 'cancel_free', 'label': 'Cancel without a fee', 'hint': 'You will not be charged'},
      ],
    },
    {
      'code': 'extra_payment_requested',
      'title': 'Driver requested extra payment',
      'subtitle': 'Additional payment query',
      'icon': 'griddy-icons:payments-filled',
      'appliesTo': ['ride', 'delivery'],
      'requiresDescription': false,
      'reported': 'Extra payment requested',
      'investigating': 'Our team is reviewing the trip fare',
      'resolved': 'We reminded your driver that fares are paid in the app',
    },
    {
      'code': 'unable_to_complete_delivery',
      'title': 'Unable to complete delivery',
      'subtitle': 'Driver cannot deliver the package',
      'icon': 'griddy-icons:package-off-filled',
      'appliesTo': ['delivery'],
      'requiresDescription': false,
      'reported': 'Delivery could not be completed',
      'investigating': 'Our team is checking what happened',
      'needsAction': true,
      'options': [
        {'id': 'retry_delivery', 'label': 'Try the delivery again', 'hint': 'We will arrange another attempt'},
        {'id': 'return_package', 'label': 'Return the package to me', 'hint': 'We will arrange the return'},
      ],
    },
    {
      'code': 'safety_concern',
      'title': 'Safety concern',
      'subtitle': 'I feel something is wrong',
      'icon': 'griddy-icons:shield-filled',
      'appliesTo': ['ride', 'delivery'],
      'requiresDescription': false,
      'reported': 'Safety concern raised',
      'investigating': 'Our safety team is looking into it',
      'resolved': 'Our safety team has noted this and will follow up if needed',
    },
    {
      'code': 'lost_item',
      'title': 'Lost item',
      'subtitle': 'I left something behind',
      'icon': 'griddy-icons:inventory-filled',
      'appliesTo': ['ride', 'delivery'],
      'requiresDescription': true,
      'reported': 'Lost item reported',
      'investigating': 'Our team is contacting your driver',
      'resolved': 'We reached your driver and passed on your details',
    },
    {
      'code': 'other',
      'title': 'Other',
      'subtitle': 'Not listed above',
      'icon': 'griddy-icons:info-filled',
      'appliesTo': ['ride', 'delivery'],
      'requiresDescription': true,
      'reported': 'Report received',
      'investigating': 'Our team is reading your note',
      'resolved': 'We passed this to the right team',
    },
  ];
}
