import 'package:flutter/material.dart';

class SummaryBar extends StatelessWidget {
  final int total, live, lost;
  const SummaryBar({super.key, required this.total, required this.live, required this.lost});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: Color(0xFF1E3D28))),
      ),
      child: Row(children: [
        _cell('$total', 'TOTALE', const Color(0xFF2DFF6E)),
        _divider(),
        _cell('$live', 'PRESENTI', const Color(0xFF2DFF6E)),
        _divider(),
        _cell('$lost', 'PERSI', lost > 0 ? const Color(0xFFFF4444) : const Color(0xFF2DFF6E)),
      ]),
    );
  }

  Widget _cell(String num, String label, Color color) => Expanded(
    child: Container(
      color: const Color(0xFF0F2318),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        Text(num, style: TextStyle(fontFamily: 'monospace', fontSize: 26,
            fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9,
            color: Color(0xFF6A9E78), letterSpacing: 2)),
      ]),
    ),
  );

  Widget _divider() => Container(width: 1, height: 60, color: const Color(0xFF1E3D28));
}
