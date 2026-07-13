import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_iptv/core/database/local_storage.dart';

class SettingsState {
  final bool hwDecoding;
  final int bufferSize;
  final bool autoPlay;
  final String parentalPin;
  final int epgTimeShift;
  final bool timeFormat24h;

  SettingsState({
    this.hwDecoding = true,
    this.bufferSize = 1,
    this.autoPlay = false,
    this.parentalPin = '',
    this.epgTimeShift = 0,
    this.timeFormat24h = true,
  });

  SettingsState copyWith({
    bool? hwDecoding,
    int? bufferSize,
    bool? autoPlay,
    String? parentalPin,
    int? epgTimeShift,
    bool? timeFormat24h,
  }) {
    return SettingsState(
      hwDecoding: hwDecoding ?? this.hwDecoding,
      bufferSize: bufferSize ?? this.bufferSize,
      autoPlay: autoPlay ?? this.autoPlay,
      parentalPin: parentalPin ?? this.parentalPin,
      epgTimeShift: epgTimeShift ?? this.epgTimeShift,
      timeFormat24h: timeFormat24h ?? this.timeFormat24h,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState();
  }

  Future<void> _loadSettings() async {
    final data = await SettingsStorage.getAllSettings();
    state = SettingsState(
      hwDecoding: data['hwDecoding'],
      bufferSize: data['bufferSize'],
      autoPlay: data['autoPlay'],
      parentalPin: data['parentalPin'],
      epgTimeShift: data['epgTimeShift'],
      timeFormat24h: data['timeFormat24h'],
    );
  }

  Future<void> updateHwDecoding(bool value) async {
    await SettingsStorage.saveSetting(SettingsStorage.keyHwDecoding, value);
    state = state.copyWith(hwDecoding: value);
  }

  Future<void> updateBufferSize(int value) async {
    await SettingsStorage.saveSetting(SettingsStorage.keyBufferSize, value);
    state = state.copyWith(bufferSize: value);
  }

  Future<void> updateAutoPlay(bool value) async {
    await SettingsStorage.saveSetting(SettingsStorage.keyAutoPlay, value);
    state = state.copyWith(autoPlay: value);
  }

  Future<void> updateParentalPin(String value) async {
    await SettingsStorage.saveSetting(SettingsStorage.keyParentalPin, value);
    state = state.copyWith(parentalPin: value);
  }

  Future<void> updateEpgTimeShift(int value) async {
    await SettingsStorage.saveSetting(SettingsStorage.keyEpgTimeShift, value);
    state = state.copyWith(epgTimeShift: value);
  }

  Future<void> updateTimeFormat(bool is24h) async {
    await SettingsStorage.saveSetting(SettingsStorage.keyTimeFormat24h, is24h);
    state = state.copyWith(timeFormat24h: is24h);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
