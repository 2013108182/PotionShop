/// Serializable state contains only witnessed facts, never unrevealed story text.
class ResidentProgress {
  bool met = false;
  int storyIndex = 0, lastOfferedDay = 0;
  String? pendingReview;
  int? deliveredDay;
  final Map<String, int> successfulServices = {};
  final Set<String> knownFactIds = {}, completedBeatIds = {}, fulfilledPromiseIds = {};
  int get trustStage => completedBeatIds.any((id) => id.endsWith('.ending'))
      ? 2 : successfulServices.isNotEmpty && knownFactIds.isNotEmpty ? 1 : 0;
  String get trustLabel => ['낯익은 손님', '이야기를 나누는 이웃', '믿고 부탁하는 사이'][trustStage];
  Map<String, dynamic> toJson() => {'met': met, 'storyIndex': storyIndex,
    'lastOfferedDay': lastOfferedDay, 'pendingReview': pendingReview, 'deliveredDay': deliveredDay,
    'successfulServices': successfulServices, 'knownFactIds': knownFactIds.toList(),
    'completedBeatIds': completedBeatIds.toList(), 'fulfilledPromiseIds': fulfilledPromiseIds.toList()};
  static ResidentProgress fromJson(Map<String, dynamic> data) {
    final p = ResidentProgress();
    if (data['met'] is! bool) throw const FormatException('Invalid resident');
    p.met = data['met'] as bool;
    p.storyIndex = checkedInt(data['storyIndex'], 0, 4);
    p.lastOfferedDay = checkedInt(data['lastOfferedDay'], 0, 1000000);
    p.pendingReview = data['pendingReview'] as String?;
    p.deliveredDay = data['deliveredDay'] == null ? null : checkedInt(data['deliveredDay'], 1, 1000000);
    for (final entry in (data['successfulServices'] as Map<String, dynamic>).entries) {
      p.successfulServices[entry.key] = checkedInt(entry.value, 1, 1000000);
    }
    p.knownFactIds.addAll((data['knownFactIds'] as List).cast<String>());
    p.completedBeatIds.addAll((data['completedBeatIds'] as List).cast<String>());
    p.fulfilledPromiseIds.addAll((data['fulfilledPromiseIds'] as List).cast<String>());
    return p;
  }
}

int checkedInt(dynamic value, int min, int max) {
  if (value is! int || value < min || value > max) throw const FormatException('Invalid number');
  return value;
}

class DiaryEntry {
  final String id, residentId, kind, title, text;
  final int day;
  bool read;
  DiaryEntry({required this.id, required this.residentId, required this.kind,
    required this.title, required this.text, required this.day, this.read = false});
  Map<String, dynamic> toJson() => {'id': id, 'residentId': residentId, 'kind': kind,
    'title': title, 'text': text, 'day': day, 'read': read};
  static DiaryEntry fromJson(Map<String, dynamic> d) {
    if (d['read'] is! bool) throw const FormatException('Invalid diary');
    return DiaryEntry(id: d['id'] as String, residentId: d['residentId'] as String,
      kind: d['kind'] as String, title: d['title'] as String, text: d['text'] as String,
      day: checkedInt(d['day'], 1, 1000000), read: d['read'] as bool);
  }
}

class VisitPlan {
  final String visitId, residentId, name, text;
  final String? potionId, storyBeatId;
  final int day;
  const VisitPlan({required this.visitId, required this.day, required this.residentId,
    required this.name, required this.text, this.potionId, this.storyBeatId});
  Map<String, dynamic> toJson() => {'visitId': visitId, 'day': day, 'residentId': residentId,
    'name': name, 'text': text, 'potionId': potionId, 'storyBeatId': storyBeatId};
  static VisitPlan fromJson(Map<String, dynamic> d) => VisitPlan(
    visitId: d['visitId'] as String, day: checkedInt(d['day'], 1, 1000000),
    residentId: d['residentId'] as String, name: d['name'] as String,
    text: d['text'] as String, potionId: d['potionId'] as String?, storyBeatId: d['storyBeatId'] as String?);
}
