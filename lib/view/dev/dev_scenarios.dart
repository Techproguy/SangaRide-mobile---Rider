class DevScenario {
  const DevScenario({required this.area, required this.trigger, required this.effect});

  final String area;
  final String trigger;
  final String effect;
}

abstract final class DevScenarios {
  static const List<DevScenario> all = [
    DevScenario(
      area: 'Sign in',
      trigger: 'Phone +2348000000000 on login',
      effect: 'The number is not registered: the code request fails with a 404.',
    ),
    DevScenario(
      area: 'Sign in',
      trigger: 'Code 1234',
      effect: 'The only OTP the mock accepts, everywhere a code is asked for.',
    ),
    DevScenario(
      area: 'Sign up',
      trigger: 'Start sign up',
      effect:
          'Marks onboarding as unfinished (about you, selfie, home) until each step is saved. A relaunch resumes it.',
    ),
    DevScenario(
      area: 'Profile',
      trigger: 'Email taken@example.com',
      effect: 'Saving the email fails with email_taken.',
    ),
    DevScenario(
      area: 'Profile',
      trigger: 'Change phone to +2348022222222',
      effect: 'Changing the phone fails with phone_taken.',
    ),
    DevScenario(
      area: 'Matching',
      trigger: 'Pricing mode saver',
      effect: 'The search ends with no_driver_found instead of offers.',
    ),
    DevScenario(
      area: 'Matching',
      trigger: 'Driver Ibrahim S. in the offers',
      effect: 'The offer is withdrawn: holding or confirming it fails with offer_unavailable.',
    ),
    DevScenario(
      area: 'Trip chat',
      trigger: 'Message containing #fail',
      effect: 'The first send of that message fails with a 503. A retry of the same message succeeds.',
    ),
    DevScenario(
      area: 'Trip chat',
      trigger: 'Message containing #drivercancel',
      effect: 'The driver cancels the trip right after the message is sent.',
    ),
    DevScenario(
      area: 'Add stop',
      trigger: 'An added stop that adds more than 14 km',
      effect: 'The driver declines the stop with stop_declined.',
    ),
    DevScenario(
      area: 'Delivery',
      trigger: 'Item name or description containing #expired',
      effect: 'The delivery request fails with quote_expired.',
    ),
    DevScenario(
      area: 'Delivery',
      trigger: 'Item name containing weapon, gun, explosive, drug, alcohol or fireworks',
      effect: 'The request fails with item_prohibited and a reason.',
    ),
    DevScenario(
      area: 'Delivery',
      trigger: 'Item name containing #refuse',
      effect: 'The recipient refuses the package after the sender confirms the pickup, and the trip is cancelled.',
    ),
    DevScenario(
      area: 'Delivery',
      trigger: 'Item name containing #return',
      effect: 'After arriving at the drop off the driver brings the package back (returning, then returned).',
    ),
    DevScenario(
      area: 'Delivery',
      trigger: 'Recipient phone that is not a Nigerian mobile, repeats one digit or ends 000000',
      effect: 'The request fails with invalid_recipient_phone.',
    ),
    DevScenario(
      area: 'Pay a trip',
      trigger: 'Card number ending 0002',
      effect: 'The bank declines the card with card_declined.',
    ),
    DevScenario(
      area: 'Wallet',
      trigger: 'Top up with card ending 0002',
      effect: 'The top up is declined with card_declined and a failed entry appears in the ledger.',
    ),
    DevScenario(
      area: 'Wallet',
      trigger: 'Top up with card ending 9995',
      effect: 'The top up fails with insufficient_funds.',
    ),
    DevScenario(
      area: 'Wallet',
      trigger: 'Transfer top up of an amount ending in 7',
      effect: 'The transfer never arrives and expires after 30 minutes. Other amounts settle after about 6 seconds.',
    ),
    DevScenario(
      area: 'Wallet',
      trigger: 'Amount under 500 or over 500000',
      effect: 'The top up fails with amount_out_of_range.',
    ),
    DevScenario(
      area: 'Groups',
      trigger: 'Join code JOIN2026',
      effect: 'Joins the business group behind that code (Ray). A second join fails with already_in_group.',
    ),
    DevScenario(area: 'Groups', trigger: 'Join code OLDCODE1', effect: 'Fails with expired_code.'),
    DevScenario(
      area: 'Groups',
      trigger: 'Ride purpose containing decline',
      effect: 'When a ride needs an admin to approve it, the admin declines after about 5 seconds (approval_declined). Other purposes are approved after about 8 seconds.',
    ),
    DevScenario(
      area: 'Verification',
      trigger: 'ID type voters_card',
      effect: 'The review rejects the document (image_unclear) after about 20 seconds. Other types are verified.',
    ),
    DevScenario(
      area: 'Airport',
      trigger: 'Flight number ending 0',
      effect: 'Flight not found, unless it is BA75 or P47120.',
    ),
    DevScenario(
      area: 'Airport',
      trigger: 'Flight number starting with 5',
      effect: 'The flight lands at another airport (wrong_airport), unless it is BA75 or P47120.',
    ),
    DevScenario(
      area: 'Airport',
      trigger: 'Flight number ending 5, 6, 7, 8 or 9',
      effect: 'Ending 5 or 6 (today): scheduled 30 minutes or 3 hours ago. Ending 7 is diverted, 8 is cancelled, 9 is delayed.',
    ),
    DevScenario(
      area: 'Safety',
      trigger: 'Start SOS while one is running',
      effect: 'Fails with sos_already_active and returns the running SOS. Clear mock data ends it.',
    ),
    DevScenario(
      area: 'Session',
      trigger: 'Token lifetime 2 min',
      effect: 'Access tokens expire after 2 minutes: the next call refreshes once, then replays.',
    ),
  ];
}
