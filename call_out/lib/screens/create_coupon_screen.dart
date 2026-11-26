// lib/screens/create_coupon_screen.dart
import 'package:flutter/material.dart';
import '../state/app_state.dart';

class CreateCouponScreen extends StatefulWidget {
  final AppState state;
  final String? presetReceiver;

  const CreateCouponScreen({
    super.key,
    required this.state,
    this.presetReceiver,
  });

  @override
  State<CreateCouponScreen> createState() => _CreateCouponScreenState();
}

class _CreateCouponScreenState extends State<CreateCouponScreen> {
  final _formKey = GlobalKey<FormState>();
  final _giverCtrl = TextEditingController(text: 'Luca');
  final _receiverCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime? _expiry;

  // Quick-pick durations in months/years
  static final _quickDurations = <Duration>[
    const Duration(days: 30), // 1 month
    const Duration(days: 90), // 3 months
    const Duration(days: 180), // 6 months
    const Duration(days: 365), // 1 year
    const Duration(days: 730), // 2 years
  ];

  @override
  void initState() {
    super.initState();
    if (widget.presetReceiver != null &&
        widget.presetReceiver!.trim().isNotEmpty) {
      _receiverCtrl.text = widget.presetReceiver!;
    }
  }

  @override
  void dispose() {
    _giverCtrl.dispose();
    _receiverCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDateTime() async {
    final now = DateTime.now();
    final initialDate = (_expiry ?? now.add(const Duration(days: 30))).dateOnly;
    final d = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      initialDate: initialDate,
    );
    if (d == null) return;

    final initialTime = TimeOfDay.fromDateTime(
      _expiry ?? now.add(const Duration(hours: 2)),
    );
    final t = await showTimePicker(context: context, initialTime: initialTime);
    if (t == null) return;

    final picked = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() => _expiry = picked);
  }

  void _applyQuickDuration(Duration delta) {
    final now = DateTime.now();
    setState(() => _expiry = now.add(delta));
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_expiry == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please set an expiry')));
      return;
    }
    if (_expiry!.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expiry must be in the future')),
      );
      return;
    }

    final coupon = Coupon(
      id: Coupon.newId(),
      giver: _giverCtrl.text.trim().toTitleCase(),
      receiver: _receiverCtrl.text.trim().toTitleCase(),
      note: _noteCtrl.text.trim(),
      expiresAt: _expiry!,
      status: CouponStatus.active,
    );

    widget.state.addCoupon(coupon);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Coupon created')));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final friends = widget.state.friends;

    return Scaffold(
      appBar: AppBar(title: const Text('Create coupon')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _giverCtrl,
              decoration: const InputDecoration(labelText: 'From (giver)'),
              validator: _required,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _receiverCtrl,
              decoration: const InputDecoration(labelText: 'To (receiver)'),
              validator: _required,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'What is this for?',
                hintText: 'e.g., Movie night, study sesh…',
              ),
              maxLength: 80,
              validator: _required,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),

            // Quick expiry chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in _quickDurations)
                  ChoiceChip(
                    label: Text(_niceDuration(d)),
                    selected:
                        _expiry != null &&
                        (_expiry!.difference(DateTime.now()).inDays ==
                            d.inDays),
                    onSelected: (_) => _applyQuickDuration(d),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              icon: const Icon(Icons.event),
              label: Text(
                _expiry == null
                    ? 'Pick expiry date & time'
                    : 'Expires: ${_expiry!.yyyyMmDdHhMm}',
              ),
              onPressed: _pickExpiryDateTime,
            ),
            const SizedBox(height: 20),

            FilledButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Create coupon'),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- helpers ----------

String _pad2(int n) => n < 10 ? '0$n' : '$n';

extension _DateOnly on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);
  String get yyyyMmDdHhMm =>
      '$year-${_pad2(month)}-${_pad2(day)} ${_pad2(hour)}:${_pad2(minute)}';
}

extension _TitleCase on String {
  String toTitleCase() {
    final words = trim().split(RegExp(r'\s+'));
    return words
        .map(
          (w) => w.isEmpty
              ? ''
              : w[0].toUpperCase() + w.substring(1).toLowerCase(),
        )
        .join(' ');
  }
}

String _niceDuration(Duration d) {
  final days = d.inDays;
  if (days >= 365) {
    final years = days ~/ 365;
    return years == 1 ? '1y' : '${years}y';
  }
  if (days >= 30) {
    final months = days ~/ 30;
    return months == 1 ? '1m' : '${months}m';
  }
  return '${days}d';
}
