abstract final class SafetyEndpoints {
  static const String centre = '/safety/centre';
  static const String sos = '/safety/sos';
  static const String sosById = '/safety/sos/:id';
  static const String sosEnd = '/safety/sos/:id/end';
  static const String contacts = '/safety/contacts';
  static const String contactById = '/safety/contacts/:id';
  static const String reports = '/safety/reports';

  static String sosOf(String id) => sosById.replaceFirst(':id', id);

  static String sosEndOf(String id) => sosEnd.replaceFirst(':id', id);

  static String contactOf(String id) => contactById.replaceFirst(':id', id);
}
