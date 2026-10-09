import 'package:go_router/go_router.dart';
import 'package:sanga_ride/model/groups/group_models.dart';
import 'package:sanga_ride/view/groups/group_approvals_screen.dart';
import 'package:sanga_ride/view/groups/group_create_screen.dart';
import 'package:sanga_ride/view/groups/group_invite_screen.dart';
import 'package:sanga_ride/view/groups/group_join_screen.dart';
import 'package:sanga_ride/view/groups/group_member_screen.dart';
import 'package:sanga_ride/view/groups/group_screen.dart';
import 'package:sanga_ride/view/groups/groups_hub_screen.dart';
import 'package:sanga_ride/view/groups/member/member_alerts_screen.dart';
import 'package:sanga_ride/view/groups/member/member_permissions_screen.dart';
import 'package:sanga_ride/view/groups/member/member_places_screen.dart';
import 'package:sanga_ride/view/groups/member/member_relation_screen.dart';
import 'package:sanga_ride/view/groups/member/member_ride_limit_screen.dart';
import 'package:sanga_ride/view/groups/member/member_ride_types_screen.dart';
import 'package:sanga_ride/view/groups/member/member_spending_screen.dart';
import 'package:sanga_ride/view/groups/member/member_time_screen.dart';

abstract final class GroupRoutes {
  static const String hub = '/groups/kind/:kind';
  static const String create = '/groups/kind/:kind/create';
  static const String join = '/groups/kind/:kind/join';
  static const String group = '/group/:groupId';
  static const String invite = '/group/:groupId/invite';
  static const String approvals = '/group/:groupId/approvals';
  static const String member = '/group/:groupId/member/:memberId';
  static const String permissions = '/group/:groupId/member/:memberId/permissions';
  static const String spending = '/group/:groupId/member/:memberId/spending';
  static const String rideLimit = '/group/:groupId/member/:memberId/ride-limit';
  static const String places = '/group/:groupId/member/:memberId/places';
  static const String time = '/group/:groupId/member/:memberId/time';
  static const String rideTypes = '/group/:groupId/member/:memberId/ride-types';
  static const String alerts = '/group/:groupId/member/:memberId/alerts';
  static const String relation = '/group/:groupId/member/:memberId/relation';

  static const String _tabKey = 'tab';

  static String hubOf(GroupKind kind) => hub.replaceFirst(':kind', kind.code);

  static String createOf(GroupKind kind) => create.replaceFirst(':kind', kind.code);

  static String joinOf(GroupKind kind) => join.replaceFirst(':kind', kind.code);

  static String groupOf(String groupId, {GroupTab tab = GroupTab.members}) {
    final path = group.replaceFirst(':groupId', groupId);
    return tab == GroupTab.members ? path : Uri(path: path, queryParameters: {_tabKey: tab.name}).toString();
  }

  static String inviteOf(String groupId) => invite.replaceFirst(':groupId', groupId);

  static String approvalsOf(String groupId) => approvals.replaceFirst(':groupId', groupId);

  static String _memberPath(String template, String groupId, String memberId) =>
      template.replaceFirst(':groupId', groupId).replaceFirst(':memberId', memberId);

  static String memberOf(String groupId, String memberId) => _memberPath(member, groupId, memberId);

  static String permissionsOf(String groupId, String memberId) => _memberPath(permissions, groupId, memberId);

  static String spendingOf(String groupId, String memberId) => _memberPath(spending, groupId, memberId);

  static String rideLimitOf(String groupId, String memberId) => _memberPath(rideLimit, groupId, memberId);

  static String placesOf(String groupId, String memberId) => _memberPath(places, groupId, memberId);

  static String timeOf(String groupId, String memberId) => _memberPath(time, groupId, memberId);

  static String rideTypesOf(String groupId, String memberId) => _memberPath(rideTypes, groupId, memberId);

  static String alertsOf(String groupId, String memberId) => _memberPath(alerts, groupId, memberId);

  static String relationOf(String groupId, String memberId) => _memberPath(relation, groupId, memberId);

  static GroupKind _kindOf(GoRouterState state) =>
      GroupKind.tryFromCode(state.pathParameters['kind']) ?? GroupKind.family;

  static final List<RouteBase> all = [
    GoRoute(
      path: hub,
      builder: (context, state) => GroupsHubScreen(kind: _kindOf(state)),
    ),
    GoRoute(
      path: create,
      builder: (context, state) => GroupCreateScreen(kind: _kindOf(state)),
    ),
    GoRoute(
      path: join,
      builder: (context, state) => GroupJoinScreen(kind: _kindOf(state)),
    ),
    GoRoute(
      path: group,
      builder: (context, state) => GroupScreen(
        groupId: state.pathParameters['groupId']!,
        initialTab: GroupTab.values.asNameMap()[state.uri.queryParameters[_tabKey]] ?? GroupTab.members,
      ),
    ),
    GoRoute(
      path: invite,
      builder: (context, state) => GroupInviteScreen(groupId: state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: approvals,
      builder: (context, state) => GroupApprovalsScreen(groupId: state.pathParameters['groupId']!),
    ),
    GoRoute(
      path: member,
      builder: (context, state) =>
          GroupMemberScreen(groupId: state.pathParameters['groupId']!, memberId: state.pathParameters['memberId']!),
    ),
    GoRoute(
      path: permissions,
      builder: (context, state) => MemberPermissionsScreen(
        groupId: state.pathParameters['groupId']!,
        memberId: state.pathParameters['memberId']!,
      ),
    ),
    GoRoute(
      path: spending,
      builder: (context, state) =>
          MemberSpendingScreen(groupId: state.pathParameters['groupId']!, memberId: state.pathParameters['memberId']!),
    ),
    GoRoute(
      path: rideLimit,
      builder: (context, state) =>
          MemberRideLimitScreen(groupId: state.pathParameters['groupId']!, memberId: state.pathParameters['memberId']!),
    ),
    GoRoute(
      path: places,
      builder: (context, state) =>
          MemberPlacesScreen(groupId: state.pathParameters['groupId']!, memberId: state.pathParameters['memberId']!),
    ),
    GoRoute(
      path: time,
      builder: (context, state) =>
          MemberTimeScreen(groupId: state.pathParameters['groupId']!, memberId: state.pathParameters['memberId']!),
    ),
    GoRoute(
      path: rideTypes,
      builder: (context, state) =>
          MemberRideTypesScreen(groupId: state.pathParameters['groupId']!, memberId: state.pathParameters['memberId']!),
    ),
    GoRoute(
      path: relation,
      builder: (context, state) =>
          MemberRelationScreen(groupId: state.pathParameters['groupId']!, memberId: state.pathParameters['memberId']!),
    ),
    GoRoute(
      path: alerts,
      builder: (context, state) =>
          MemberAlertsScreen(groupId: state.pathParameters['groupId']!, memberId: state.pathParameters['memberId']!),
    ),
  ];
}
