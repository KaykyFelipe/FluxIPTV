import 'dart:convert';
import 'package:flux_iptv/core/models/stream_model.dart';

class M3UParser {
  /// Parses a given M3U string into a list of [StreamModel].
  static List<StreamModel> parse(String content) {
    final lines = const LineSplitter().convert(content);
    final streams = <StreamModel>[];
    
    if (lines.isEmpty || !lines[0].trim().toUpperCase().startsWith('#EXTM3U')) {
      throw const FormatException('Invalid M3U file format. Missing #EXTM3U header.');
    }

    String? currentTvgId;
    String? currentTvgName;
    String? currentTvgLogo;
    String? currentGroupTitle;
    int currentDuration = -1;
    String? currentName;

    final extInfRegex = RegExp(r'^#EXTINF:\s*(-?\d+)');
    final tvgIdRegex = RegExp(r'tvg-id="([^"]*)"');
    final tvgNameRegex = RegExp(r'tvg-name="([^"]*)"');
    final tvgLogoRegex = RegExp(r'tvg-logo="([^"]*)"');
    final groupTitleRegex = RegExp(r'group-title="([^"]*)"');

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      if (line.toUpperCase().startsWith('#EXTINF:')) {
        final extInfMatch = extInfRegex.firstMatch(line);
        if (extInfMatch != null) {
          currentDuration = int.tryParse(extInfMatch.group(1) ?? '-1') ?? -1;
        }
        
        currentTvgId = tvgIdRegex.firstMatch(line)?.group(1);
        currentTvgName = tvgNameRegex.firstMatch(line)?.group(1);
        currentTvgLogo = tvgLogoRegex.firstMatch(line)?.group(1);
        currentGroupTitle = groupTitleRegex.firstMatch(line)?.group(1);

        // Name is usually after the comma
        final commaIndex = line.lastIndexOf(',');
        if (commaIndex != -1 && commaIndex < line.length - 1) {
          currentName = line.substring(commaIndex + 1).trim();
        } else {
          currentName = 'Unknown Channel';
        }
      } else if (!line.startsWith('#')) {
        // It's a URL
        if (currentName != null) {
          StreamType type = StreamType.live;
          if (currentGroupTitle != null) {
            final lowerGroup = currentGroupTitle.toLowerCase();
            if (lowerGroup.contains('filme') || lowerGroup.contains('movie') || lowerGroup.contains('vod')) {
              type = StreamType.movie;
            } else if (lowerGroup.contains('serie') || lowerGroup.contains('série')) {
              type = StreamType.series;
            }
          }

          streams.add(StreamModel(
            name: currentName,
            url: line,
            tvgId: currentTvgId,
            tvgName: currentTvgName,
            tvgLogo: currentTvgLogo,
            groupTitle: currentGroupTitle,
            duration: currentDuration,
            streamType: type,
          ));
        }
        // Reset variables for next entry
        currentName = null;
        currentTvgId = null;
        currentTvgName = null;
        currentTvgLogo = null;
        currentGroupTitle = null;
        currentDuration = -1;
      }
    }

    return streams;
  }
}
