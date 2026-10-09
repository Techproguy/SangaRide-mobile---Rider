import 'package:sanga_ride_core/sanga_ride_core.dart';

abstract final class SessionStorage {
  static final SecureTokenStore tokens = SecureTokenStore();

  static final DraftStore drafts = DraftStore(GetStorageKeyValueStore());
}
