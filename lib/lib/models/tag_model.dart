import 'dart:math';

class TagModel {
  final String id;
  final DateTime firstSeen;
  DateTime lastSeen;
  int rssi;
  String? customName;
  int tagId;
  int animalId;
  int type;
  double battVoltage;
  int battPercent;
  int flags;
  int bootCount;
  int uptime;
  bool checksumOk;
  List<int> rawBytes;

  TagModel({
    required this.id, required this.firstSeen, required this.lastSeen,
    required this.rssi, required this.tagId, required this.animalId,
    required this.type, required this.battVoltage, required this.battPercent,
    required this.flags, required this.bootCount, required this.uptime,
    required this.checksumOk, required this.rawBytes, this.customName,
  });

  factory TagModel.fromPayload({
    required String id,
    required List<int> payload,
    required int rssi,
  }) {
    final b = payload;
    final now = DateTime.now();
    if (b.length < 16) {
      return TagModel(
        id: id, firstSeen: now, lastSeen: now, rssi: rssi,
        tagId: 0, animalId: 0, type: 0, battVoltage: 0,
        battPercent: 0, flags: 0, bootCount: 0, uptime: 0,
        checksumOk: false, rawBytes: b,
      );
    }
    int xor = 0;
    for (int i = 0; i < 16; i++) xor ^= b[i];
    final checksumOk = b.length >= 17 ? b[16] == (xor & 0xFF) : true;
    return TagModel(
      id: id, firstSeen: now, lastSeen: now, rssi: rssi,
      tagId: (b[1] << 8) | b[0],
      animalId: (b[5] << 24) | (b[4] << 16) | (b[3] << 8) | b[2],
      type: b[6],
      battVoltage: b[7] / 100.0,
      battPercent: b[8],
      flags: b.length > 9 ? b[9] : 0,
      bootCount: b.length > 11 ? (b[11] << 8) | b[10] : 0,
      uptime: b.length > 15 ? (b[15] << 24) | (b[14] << 16) | (b[13] << 8) | b[12] : 0,
      checksumOk: checksumOk,
      rawBytes: b,
    );
  }

  String get displayName => customName ?? 'Tag #${tagId.toString().padLeft(4, '0')}';
  String get animalCode => animalId == 0 ? '—' : 'IT${animalId.toString().padLeft(9, '0')}';
  bool get isLive => DateTime.now().difference(lastSeen).inSeconds < 30;
  bool get isStale => !isLive && DateTime.now().difference(lastSeen).inSeconds < 60;
  bool get isLost => DateTime.now().difference(lastSeen).inSeconds >= 60;
  int get distance => pow(10, (-59 - rssi) / 25.0).round();
  int get signalLevel {
    if (rssi >= -60) return 4;
    if (rssi >= -70) return 3;
    if (rssi >= -80) return 2;
    return 1;
  }
  String get uptimeFormatted {
    final h = uptime ~/ 3600;
    final m = (uptime % 3600) ~/ 60;
    final s = uptime % 60;
    if (h > 0) return '${h}h${m}m';
    if (m > 0) return '${m}m${s}s';
    return '${s}s';
  }
  String get rawHex => rawBytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');
}
