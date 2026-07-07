enum StreamType {
  live,
  movie,
  series,
}

class StreamModel {
  final String name;
  final String url;
  final String? tvgId;
  final String? tvgName;
  final String? tvgLogo;
  final String? groupTitle;
  final int duration;
  final StreamType streamType;
  final bool isFavorite;
  final int? streamId;

  StreamModel({
    required this.name,
    required this.url,
    this.tvgId,
    this.tvgName,
    this.tvgLogo,
    this.groupTitle,
    this.duration = -1,
    this.streamType = StreamType.live,
    this.isFavorite = false,
    this.streamId,
  });

  StreamModel copyWith({
    String? name,
    String? url,
    String? tvgId,
    String? tvgName,
    String? tvgLogo,
    String? groupTitle,
    int? duration,
    StreamType? streamType,
    bool? isFavorite,
    int? streamId,
  }) {
    return StreamModel(
      name: name ?? this.name,
      url: url ?? this.url,
      tvgId: tvgId ?? this.tvgId,
      tvgName: tvgName ?? this.tvgName,
      tvgLogo: tvgLogo ?? this.tvgLogo,
      groupTitle: groupTitle ?? this.groupTitle,
      duration: duration ?? this.duration,
      streamType: streamType ?? this.streamType,
      isFavorite: isFavorite ?? this.isFavorite,
      streamId: streamId ?? this.streamId,
    );
  }

  @override
  String toString() {
    return 'StreamModel(name: $name, type: $streamType, groupTitle: $groupTitle, url: $url, isFavorite: $isFavorite, streamId: $streamId)';
  }
}
