import 'package:cairn/data/database.dart';
import 'package:cairn/domain/journey/backup_prompt.dart';
import 'package:cairn/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

JourneyEvent seenEvent() => JourneyEvent(
      id: 'seen',
      occurredAtUtc: DateTime.utc(2026, 7, 30),
      kind: JourneyEventKind.backupPromptSeen.name,
    );

void main() {
  final threeDays = fakeSmoker(
    start: DateTime(2026, 7, 25),
    dailyTimes: const [(9, 0)],
    days: 3,
  );
  final twoDays = fakeSmoker(
    start: DateTime(2026, 7, 25),
    dailyTimes: const [(9, 0)],
    days: 2,
  );

  test('≥ 3 jours et jamais proposé → on propose', () {
    expect(shouldOfferBackup(threeDays, const []), isTrue);
  });

  test('< 3 jours → on ne propose pas', () {
    expect(shouldOfferBackup(twoDays, const []), isFalse);
  });

  test('déjà proposé → on ne re-propose pas', () {
    expect(shouldOfferBackup(threeDays, [seenEvent()]), isFalse);
  });
}
