import 'package:flutter_test/flutter_test.dart';
import 'package:lrs_sangeet_duniya/services/sangeeta_command_parser.dart';

void main() {
  const parser = SangeetaCommandParser();

  test('wake mode ignores speech without Hey Sangeeta', () {
    final command = parser.parse('play Golden Horizon', requireWakeWord: true);
    expect(command.accepted, isFalse);
  });

  test('wake mode accepts Hey Sangeeta and extracts play query', () {
    final command = parser.parse(
      'Hey Sangeeta play song Golden Horizon',
      requireWakeWord: true,
    );
    expect(command.accepted, isTrue);
    expect(command.kind, SangeetaCommandKind.playSong);
    expect(command.argument, 'golden horizon');
  });

  test('required v2.2 commands are parsed', () {
    expect(parser.parse('volume up').kind, SangeetaCommandKind.volumeUp);
    expect(parser.parse('volume down').kind, SangeetaCommandKind.volumeDown);
    expect(parser.parse('open playlist').kind, SangeetaCommandKind.openPlaylist);
    expect(parser.parse('download song').kind, SangeetaCommandKind.downloadSong);
    expect(parser.parse('search song hello').kind, SangeetaCommandKind.searchSong);
  });
}
