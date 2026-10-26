/// Candidate-source review only. This never performs streaming, caching or downloads.
class SourceRightsDecision {
  final bool eligibleForManualReview;
  final bool streamingEnabled;
  final bool downloadsEnabled;
  final List<String> blockers;
  const SourceRightsDecision(this.eligibleForManualReview, this.streamingEnabled,
      this.downloadsEnabled, this.blockers);
}

SourceRightsDecision reviewMusicSource({
  required String sourceId,
  required Uri documentation,
  required bool termsReviewed,
  required bool streamingRightsConfirmed,
  required bool downloadingRightsConfirmed,
  required bool freeUseConfirmed,
  bool seeksDownload = false,
}) {
  final reasons = <String>[];
  if (!RegExp(r'^[a-z][a-z0-9-]{2,63}$').hasMatch(sourceId)) {
    reasons.add('invalid_source_id');
  }
  if (documentation.scheme != 'https' || documentation.host.isEmpty) {
    reasons.add('https_documentation_required');
  }
  if (!termsReviewed) reasons.add('terms_not_reviewed');
  if (!freeUseConfirmed) reasons.add('free_access_not_verified');
  if (!streamingRightsConfirmed) reasons.add('streaming_rights_unverified');
  if (seeksDownload && !downloadingRightsConfirmed) {
    reasons.add('download_rights_unverified');
  }
  return SourceRightsDecision(reasons.isEmpty, false, false,
      List<String>.unmodifiable(reasons));
}
