import 'package:flutter_test/flutter_test.dart';
import 'package:lrs_sangeet_duniya/services/source_rights_preflight.dart';

void main() {
  final url = Uri.parse('https://example.org/music/license');
  test('candidate never enables playback automatically', () {
    final decision = reviewMusicSource(
      sourceId: 'music-library', documentation: url,
      termsReviewed: true, streamingRightsConfirmed: true,
      downloadingRightsConfirmed: false, freeUseConfirmed: true,
    );
    expect(decision.eligibleForManualReview, isTrue);
    expect(decision.streamingEnabled, isFalse);
    expect(decision.downloadsEnabled, isFalse);
  });
  test('unlicensed downloading fails closed', () {
    final decision = reviewMusicSource(
      sourceId: 'music-library', documentation: url,
      termsReviewed: true, streamingRightsConfirmed: true,
      downloadingRightsConfirmed: false, freeUseConfirmed: true, seeksDownload: true,
    );
    expect(decision.eligibleForManualReview, isFalse);
    expect(decision.blockers, contains('download_rights_unverified'));
  });
}
