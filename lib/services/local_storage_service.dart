/// Stub service for local persistence of in-progress inspection drafts.
/// In production this would use shared_preferences or hive.
class LocalStorageService {
  final Map<String, Map<String, dynamic>> _drafts = {};

  Future<void> saveDraft(
      String facilityId, Map<String, dynamic> formData) async {
    _drafts[facilityId] = Map.of(formData);
  }

  Future<Map<String, dynamic>?> loadDraft(String facilityId) async {
    return _drafts[facilityId];
  }

  Future<void> deleteDraft(String facilityId) async {
    _drafts.remove(facilityId);
  }

  bool hasDraft(String facilityId) => _drafts.containsKey(facilityId);
}
