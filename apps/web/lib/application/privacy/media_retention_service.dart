import '../local_repository.dart';

/// Opportunistic purge of evidence photos past the retention window.
class MediaRetentionService {
  const MediaRetentionService(this._repository);

  final LocalRepository _repository;

  Future<int> purgeExpired({required int retentionDays}) {
    return _repository.purgeExpiredMedia(retentionDays: retentionDays);
  }
}
