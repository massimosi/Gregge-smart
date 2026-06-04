import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/tag_model.dart';
import '../widgets/summary_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, TagModel> _tags = {};
  bool _scanning = false;
  static const int _companyId = 0xFFFF;

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _toggleScan() async {
    if (_scanning) {
      await FlutterBluePlus.stopScan();
      setState(() => _scanning = false);
      return;
    }
    setState(() => _scanning = true);
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 60),
      continuousUpdates: true,
    );
    FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final mfData = r.advertisementData.manufacturerData;
        if (!mfData.containsKey(_companyId)) continue;
        final payload = mfData[_companyId]!;
        final id = r.device.remoteId.str;
        if (_tags.containsKey(id)) {
          _tags[id]!.lastSeen = DateTime.now();
          _tags[id]!.rssi = r.rssi;
        } else {
          _tags[id] = TagModel.fromPayload(id: id, payload: payload, rssi: r.rssi);
        }
        setState(() {});
      }
    });
    FlutterBluePlus.isScanning.listen((s) {
      if (!s && mounted) setState(() => _scanning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tagList = _tags.values.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));
    final live = tagList.where((t) => t.isLive).length;
    final lost = tagList.where((t) => t.isLost).length;

    return Scaffold(
      body: SafeArea(child: Column(children: [
        _header(),
        SummaryBar(total: tagList.length, live: live, lost: lost),
        _scanButton(),
        _sectionHeader(tagList.length),
        Expanded(
          child: tagList.isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                  itemCount: tagList.length,
                  itemBuilder: (ctx, i) => _TagCard(
                    tag: tagList[i],
                    onNameChanged: (n) => setState(() => _tags[tagList[i].id]!.customName = n),
                  ),
                ),
        ),
      ])),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
    child: Row(children: [
      const Text('🐑', style: TextStyle(fontSize: 22)),
      const SizedBox(width: 8),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('GREGGE SMART', style: TextStyle(fontFamily: 'monospace',
            fontSize: 11, fontWeight: FontWeight.bold,
            color: Color(0xFF2DFF6E), letterSpacing: 2)),
        Text('v1.0 · BLE SCANNER', style: TextStyle(fontSize: 9, color: Color(0xFF6A9E78))),
      ]),
      const Spacer(),
      Container(width: 8, height: 8, decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _scanning ? const Color(0xFF2DFF6E) : const Color(0xFFFFB830),
        boxShadow: [BoxShadow(
          color: _scanning ? const Color(0xFF2DFF6E) : const Color(0xFFFFB830),
          blurRadius: 8,
        )],
      )),
      const SizedBox(width: 6),
      Text(_scanning ? 'SCAN' : 'OFF', style: const TextStyle(
          fontFamily: 'monospace', fontSize: 10, color: Color(0xFF6A9E78))),
    ]),
  );

  Widget _scanButton() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
    child: GestureDetector(
      onTap: _toggleScan,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(
            color: _scanning ? const Color(0xFFFFB830) : const Color(0xFF2DFF6E),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _scanning ? '⏹  FERMA SCANSIONE' : '▶  AVVIA SCANSIONE BLE',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'monospace', fontSize: 13,
            fontWeight: FontWeight.bold, letterSpacing: 3,
            color: _scanning ? const Color(0xFFFFB830) : const Color(0xFF2DFF6E),
          ),
        ),
      ),
    ),
  );

  Widget _sectionHeader(int count) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text('TAG RILEVATI', style: TextStyle(fontFamily: 'monospace',
          fontSize: 10, color: Color(0xFF6A9E78), letterSpacing: 3)),
      Text(count > 0 ? '$count tag' : '—', style: const TextStyle(
          fontFamily: 'monospace', fontSize: 10, color: Color(0xFF1A9940))),
    ]),
  );

  Widget _emptyState() => const Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('📡', style: TextStyle(fontSize: 48)),
      SizedBox(height: 16),
      Text('Nessun tag rilevato.\nAvvia la scansione BLE.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Color(0xFF6A9E78), height: 1.6)),
    ],
  ));
}

class _TagCard extends StatefulWidget {
  final TagModel tag;
  final Function(String) onNameChanged;
  const _TagCard({required this.tag, required this.onNameChanged});
  @override
  State<_TagCard> createState() => _TagCardState();
}

class _TagCardState extends State<_TagCard> {
  bool _expanded = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.tag.customName ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _stateColor {
    if (widget.tag.isLive) return const Color(0xFF2DFF6E);
    if (widget.tag.isStale) return const Color(0xFFFFB830);
    return const Color(0xFFFF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2318),
        border: Border.all(
          color: widget.tag.isLive ? const Color(0xFF1A9940) : const Color(0xFF2A1A0A),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _stateColor,
                boxShadow: widget.tag.isLive
                    ? [BoxShadow(color: _stateColor, blurRadius: 8)] : null,
              )),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.tag.displayName, style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFD4F0DC))),
                Text(widget.tag.animalCode, style: const TextStyle(
                    fontFamily: 'monospace', fontSize: 9, color: Color(0xFF6A9E78))),
                Text(
                  widget.tag.isLive ? 'ora'
                      : '${DateTime.now().difference(widget.tag.lastSeen).inSeconds}s fa',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF6A9E78)),
                ),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(children: [
                  ...List.generate(4, (i) => Container(
                    width: 3,
                    height: [4.0, 7.0, 10.0, 14.0][i],
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: i < widget.tag.signalLevel ? _stateColor : const Color(0xFF1E3D28),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  )),
                  const SizedBox(width: 5),
                  Text('${widget.tag.rssi}', style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 10, color: Color(0xFF6A9E78))),
                ]),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D3320),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text('~${widget.tag.distance}m', style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 11, color: Color(0xFF2DFF6E))),
                ),
              ]),
            ]),
          ),
        ),
        if (_expanded) _detail(),
      ]),
    );
  }

  Widget _detail() {
    final t = widget.tag;
    final battColor = t.battPercent > 50
        ? const Color(0xFF2DFF6E)
        : t.battPercent > 20 ? const Color(0xFFFFB830) : const Color(0xFFFF4444);

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E3D28))),
        color: Color(0xFF0B1C12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 10, runSpacing: 10, children: [
          _cell('TAG ID', '#${t.tagId.toString().padLeft(4, '0')}', Colors.white),
          _cell('TIPO', t.type == 0 ? 'SLAVE' : 'MASTER', Colors.white),
          _cell('BATTERIA', '${t.battPercent}% · ${t.battVoltage.toStringAsFixed(2)}V', battColor),
          _cell('UPTIME', t.uptimeFormatted, Colors.white),
          _cell('BOOT #', '${t.bootCount}', Colors.white),
          _cell('CHECKSUM', t.checksumOk ? 'OK ✓' : 'ERR ✗',
              t.checksumOk ? const Color(0xFF2DFF6E) : const Color(0xFFFF4444)),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2318),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('RAW HEX', style: TextStyle(
                fontSize: 9, color: Color(0xFF6A9E78), letterSpacing: 2)),
            const SizedBox(height: 6),
            Text(t.rawHex, style: const TextStyle(
                fontFamily: 'monospace', fontSize: 10,
                color: Color(0xFF1A9940), height: 1.8)),
          ]),
        ),
        const SizedBox(height: 10),
        const Text('NOME PERSONALIZZATO', style: TextStyle(
            fontSize: 9, color: Color(0xFF6A9E78), letterSpacing: 2)),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: TextField(
            controller: _ctrl,
            style: const TextStyle(color: Color(0xFFD4F0DC), fontSize: 13),
            decoration: InputDecoration(
              hintText: 'es. Pecora Bianca 3',
              hintStyle: const TextStyle(color: Color(0xFF6A9E78)),
              filled: true,
              fillColor: const Color(0xFF0F2318),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF1E3D28)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF1E3D28)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_ctrl.text.trim().isNotEmpty) {
                widget.onNameChanged(_ctrl.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Salvato: ${_ctrl.text.trim()}'),
                  backgroundColor: const Color(0xFF0F2318),
                  duration: const Duration(seconds: 2),
                ));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D3320),
                border: Border.all(color: const Color(0xFF1A9940)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('SALVA', style: TextStyle(
                  fontFamily: 'monospace', fontSize: 10,
                  color: Color(0xFF2DFF6E), letterSpacing: 1)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _cell(String key, String val, Color c) => Container(
    width: 140,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFF162E1E),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(key, style: const TextStyle(fontSize: 8, color: Color(0xFF6A9E78), letterSpacing: 2)),
      const SizedBox(height: 4),
      Text(val, style: TextStyle(fontFamily: 'monospace', fontSize: 13,
          fontWeight: FontWeight.bold, color: c)),
    ]),
  );
}
