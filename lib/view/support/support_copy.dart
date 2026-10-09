import 'package:flutter/material.dart';
import 'package:sanga_ride/model/models.dart';
import 'package:sanga_ride_ui/sanga_ride_ui.dart';

abstract final class SupportCopy {
  static IconData topicIconOf(SupportTopicIcon icon) => switch (icon) {
    SupportTopicIcon.flight => Icons.flight_takeoff_rounded,
    SupportTopicIcon.accident => Icons.car_crash_outlined,
    SupportTopicIcon.lostItem => Icons.luggage_outlined,
    SupportTopicIcon.route => Icons.route_outlined,
    SupportTopicIcon.cancel => Icons.highlight_off_rounded,
    SupportTopicIcon.refund => Icons.currency_exchange_rounded,
    SupportTopicIcon.payment => Icons.payments_outlined,
    SupportTopicIcon.account => Icons.person_outline_rounded,
    SupportTopicIcon.safety => Icons.shield_outlined,
    SupportTopicIcon.delivery => Icons.inventory_2_outlined,
    SupportTopicIcon.help => Icons.help_outline_rounded,
  };

  static IconData issueIconOf(IssueIcon icon) => switch (icon) {
    IssueIcon.notMoving => Icons.pause_circle_outline_rounded,
    IssueIcon.unreachable => Icons.phone_disabled_outlined,
    IssueIcon.location => Icons.wrong_location_outlined,
    IssueIcon.payment => Icons.payments_outlined,
    IssueIcon.incomplete => Icons.unpublished_outlined,
    IssueIcon.package => Icons.inventory_2_outlined,
    IssueIcon.safety => Icons.shield_outlined,
    IssueIcon.account => Icons.person_outline_rounded,
    IssueIcon.receipt => Icons.receipt_long_outlined,
    IssueIcon.other => Icons.info_outline_rounded,
  };

  static String contextLabelOf(IssueContext context) => switch (context) {
    IssueContext.trip => 'A ride',
    IssueContext.delivery => 'A delivery',
    IssueContext.payment => 'A payment',
    IssueContext.account => 'My account',
  };

  static String statusLabelOf(TicketStatus status) => switch (status) {
    TicketStatus.reported => 'Received',
    TicketStatus.investigating => 'Looking into it',
    TicketStatus.actionNeeded => 'Your move',
    TicketStatus.resolved => 'Resolved',
    TicketStatus.closed => 'Closed',
    TicketStatus.unknown => 'Updating',
  };

  static Widget statusTagOf(TicketStatus status) {
    final label = statusLabelOf(status);
    return switch (status) {
      TicketStatus.reported ||
      TicketStatus.investigating ||
      TicketStatus.unknown => SangaTag.scheduled(label: label, icon: Icons.schedule_rounded),
      TicketStatus.actionNeeded => SangaTag.urgent(label: label, icon: Icons.touch_app_outlined),
      TicketStatus.resolved || TicketStatus.closed => SangaTag.success(label: label),
    };
  }

  static const String reportSent = 'Report sent';
  static const String trackIt = 'Track it';
  static const String done = 'Done';
  static const String whatHappened = 'What happened?';
  static const String whichTrip = 'Which trip? (optional)';
  static const String anythingElse = 'Anything else we should know? (optional)';
  static const String shareAsMuch = 'Share as much as you can';
  static const String submitReport = 'Submit report';
  static const String whatsThisAbout = 'What’s this about?';
  static const String helpArticles = 'Help articles';
  static const String helpArticle = 'Help article';
  static const String noArticles = 'No articles here yet';
  static const String tryDifferentWords = 'Try different words, or talk to our team.';
  static const String checkBackSoon = 'Check back soon, or talk to our team.';
  static const String contactSupport = 'Contact support';
  static const String searchArticles = 'Search for help articles';
  static const String contactSubtitle = 'Chat, call or report an issue';
  static const String myReports = 'My reports';
  static const String followUp = 'Follow up on issues you reported';
  static const String commonTopics = 'Common topics';
  static const String popularArticles = 'Popular articles';
  static const String support = 'Support';
  static const String sortThisOut = 'How would you like to sort this?';
  static const String confirm = 'Confirm';
  static const String chatWithSupport = 'Chat with support';
  static const String yourReport = 'Your report';
  static const String noReports = 'No reports yet';
  static const String noReportsMessage = 'If something goes wrong on a trip, you can tell us here.';
  static const String endChatTitle = 'End this chat?';
  static const String endChatMessage = 'You can always start a new one if you need us again.';
  static const String endChat = 'End chat';
  static const String keepChatting = 'Keep chatting';
  static const String customerSupport = 'Customer support';
  static const String callSupport = 'Call support';
  static const String hangTight = 'Hang tight';
  static const String sayHi = 'Say hi';
  static const String agentJoining = 'An agent will join you shortly.';
  static const String tellUsWhatsGoingOn = 'Tell us what’s going on.';
  static const String chatEnded = 'This chat has ended.';
  static const String backToSupport = 'Back to support';
  static const String chatUnavailable = 'Chat isn’t available';
  static const String chatWithTeam = 'Chat with our team';
  static const String liveChat = 'Live chat';
  static const String sendDetailedReport = 'Send us a detailed report';
  static const String chatResting = 'Live chat is resting right now. You can still call us or send a report.';
  static const String hereToHelp = 'We’re here to help';
  static const String tripYouCameFrom = 'The trip you came from';
  static const String notAboutTrip = 'Not about a trip';
  static const String wasHelpful = 'Was this helpful?';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String gladHelped = 'Glad that helped. Thanks for telling us.';
  static const String sorryAboutThat = 'Sorry about that. Our team can help.';
  static const String timelineReported = 'Report received';
  static const String timelineInvestigating = 'We’re on it';
  static const String timelineActionRequested = 'Over to you';
  static const String timelineActionTaken = 'You chose';
  static const String timelineResolved = 'Resolved';
  static const String resolution = 'Resolution';
  static const String resolutionDetail = 'We’ll update you here';

  static String reportSentMessage(String reference) => 'Your reference is $reference. We’ll keep you posted.';

  static String nothingFound(String text) => 'Nothing found for “$text”';

  static String ticketReference(String reference) => 'Reference $reference';

  static String callFailed(String phone) => 'We couldn’t open your phone app. You can reach us on $phone.';

  static String chatWithTeamWait(int minutes) => '$chatWithTeam · about $minutes min wait';

  static String speakWithTeam(String hours) => 'Speak with our team · $hours';

  static const String chatReconnecting = 'Trouble reaching support. We’ll keep trying.';
  static const String chatLost = 'You’re offline. Messages will send when you’re back.';

  static String waitLine(SupportChat chat, SupportContact? contact) {
    final position = chat.queuePosition;
    final minutes = contact?.chatWaitMinutes ?? 0;
    final place = position <= 1 ? 'You’re next in line' : 'You’re number $position in line';
    return minutes > 0 ? '$place. About $minutes min wait.' : '$place.';
  }
}
