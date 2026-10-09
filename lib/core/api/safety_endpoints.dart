import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class SafetyEndpoints {
  static const String centre = '/safety/centre';
  static const String sos = '/safety/sos';
  static const String sosById = '/safety/sos/:id';
  static const String sosEnd = '/safety/sos/:id/end';
  static const String contacts = '/safety/contacts';
  static const String contactById = '/safety/contacts/:id';
  static const String reports = '/safety/reports';

  static String sosOf(String id) => fillPath(sosById, {'id': id});

  static String sosEndOf(String id) => fillPath(sosEnd, {'id': id});

  static String contactOf(String id) => fillPath(contactById, {'id': id});
}
