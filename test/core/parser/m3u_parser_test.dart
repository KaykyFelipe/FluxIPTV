import 'package:flutter_test/flutter_test.dart';
import 'package:flux_iptv/core/parser/m3u_parser.dart';

void main() {
  group('M3UParser', () {
    test('Parses a valid M3U string correctly', () {
      const mockM3U = '''#EXTM3U
#EXTINF:-1 tvg-id="123" tvg-name="Globo" tvg-logo="http://logo.com/globo.png" group-title="TV Aberta",Rede Globo
http://stream.url/globo.m3u8
#EXTINF:0 tvg-id="" tvg-name="SBT" tvg-logo="http://logo.com/sbt.png" group-title="TV Aberta",SBT HD
http://stream.url/sbt.m3u8
''';

      final streams = M3UParser.parse(mockM3U);

      expect(streams.length, 2);
      
      expect(streams[0].name, 'Rede Globo');
      expect(streams[0].url, 'http://stream.url/globo.m3u8');
      expect(streams[0].tvgId, '123');
      expect(streams[0].tvgName, 'Globo');
      expect(streams[0].tvgLogo, 'http://logo.com/globo.png');
      expect(streams[0].groupTitle, 'TV Aberta');
      expect(streams[0].duration, -1);

      expect(streams[1].name, 'SBT HD');
      expect(streams[1].url, 'http://stream.url/sbt.m3u8');
      expect(streams[1].groupTitle, 'TV Aberta');
    });

    test('Throws FormatException on invalid header', () {
      const invalidM3U = '''#EXTINF:-1,Canal
http://url.com''';

      expect(() => M3UParser.parse(invalidM3U), throwsFormatException);
    });
  });
}
