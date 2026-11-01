import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../core/utils/fmt.dart';
import '../core/utils/money.dart';

enum FT { text, multiline, number, money, date, dropdown, toggle, section, email, phone }

class FieldSpec {
  final String key, label;
  final FT type;
  final Map<String, String> choices; // dropdown: value -> label
  final bool required;
  final dynamic initial; // money = halalas, date = DateTime/Timestamp
  final bool readOnly;

  const FieldSpec(this.key, this.label,
      {this.type = FT.text, this.choices = const {}, this.required = false, this.initial, this.readOnly = false});

  const FieldSpec.section(String title)
      : key = '',
        label = title,
        type = FT.section,
        choices = const {},
        required = false,
        initial = null,
        readOnly = false;
}

/// Builds a validated form from a list of [FieldSpec]s.
/// Money is entered in SAR and returned as int halalas; dates return Timestamp.
class DynamicForm extends StatefulWidget {
  final List<FieldSpec> fields;
  const DynamicForm({super.key, required this.fields});

  @override
  State<DynamicForm> createState() => DynamicFormState();
}

class DynamicFormState extends State<DynamicForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _tc = {};
  final Map<String, dynamic> _v = {};

  @override
  void initState() {
    super.initState();
    for (final f in widget.fields) {
      if (f.type == FT.section) continue;
      final init = f.initial;
      if (f.type == FT.dropdown || f.type == FT.toggle) {
        _v[f.key] = init;
      } else if (f.type == FT.date) {
        final d = init is Timestamp ? init.toDate() : (init is DateTime ? init : null);
        _v[f.key] = d;
        _tc[f.key] = TextEditingController(text: d == null ? '' : Fmt.date(d));
      } else if (f.type == FT.money) {
        String t = '';
        if (init is num) t = init % 100 == 0 ? '${init ~/ 100}' : (init / 100).toStringAsFixed(2);
        _tc[f.key] = TextEditingController(text: t);
      } else {
        _tc[f.key] = TextEditingController(text: init?.toString() ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _tc.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Returns the values, or null if validation failed.
  Map<String, dynamic>? collect() {
    if (!_formKey.currentState!.validate()) return null;
    final out = <String, dynamic>{};
    for (final f in widget.fields) {
      if (f.type == FT.section) continue;
      final t = _tc[f.key]?.text.trim() ?? '';
      if (f.type == FT.number) {
        out[f.key] = t.isEmpty ? null : int.tryParse(t);
      } else if (f.type == FT.money) {
        out[f.key] = t.isEmpty ? null : Money.toMinor(double.parse(t.replaceAll(',', '')));
      } else if (f.type == FT.date) {
        final d = _v[f.key] as DateTime?;
        out[f.key] = d == null ? null : Timestamp.fromDate(d);
      } else if (f.type == FT.dropdown) {
        out[f.key] = _v[f.key];
      } else if (f.type == FT.toggle) {
        out[f.key] = _v[f.key] == true;
      } else {
        out[f.key] = t;
      }
    }
    return out;
  }

  String _label(FieldSpec f) => f.required ? '${f.label} *' : f.label;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final f in widget.fields) _field(f),
      ]),
    );
  }

  Widget _field(FieldSpec f) {
    const gap = SizedBox(height: 12);
    switch (f.type) {
      case FT.section:
        return Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 2),
          child: Text(f.label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        );
      case FT.dropdown:
        final value = f.choices.containsKey(_v[f.key]) ? _v[f.key] as String : null;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(labelText: _label(f)),
            items: [
              for (final e in f.choices.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)),
            ],
            validator: (v) => f.required && v == null ? 'Required' : null,
            onChanged: f.readOnly ? null : (v) => _v[f.key] = v,
          ),
        );
      case FT.toggle:
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(f.label),
          value: _v[f.key] == true,
          onChanged: f.readOnly ? null : (v) => setState(() => _v[f.key] = v),
        );
      case FT.date:
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextFormField(
            controller: _tc[f.key],
            readOnly: true,
            decoration: InputDecoration(labelText: _label(f), suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18)),
            validator: (v) => f.required && (v == null || v.isEmpty) ? 'Required' : null,
            onTap: f.readOnly
                ? null
                : () async {
                    final cur = (_v[f.key] as DateTime?) ?? DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: cur,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      _v[f.key] = picked;
                      _tc[f.key]!.text = Fmt.date(picked);
                    }
                  },
          ),
        );
      default:
        final isMoney = f.type == FT.money;
        final isNumber = f.type == FT.number;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TextFormField(
            controller: _tc[f.key],
            readOnly: f.readOnly,
            maxLines: f.type == FT.multiline ? 3 : 1,
            keyboardType: isMoney
                ? const TextInputType.numberWithOptions(decimal: true, signed: true)
                : isNumber
                    ? TextInputType.number
                    : f.type == FT.email
                        ? TextInputType.emailAddress
                        : f.type == FT.phone
                            ? TextInputType.phone
                            : TextInputType.text,
            inputFormatters: isMoney ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]'))] : null,
            decoration: InputDecoration(labelText: _label(f), suffixText: isMoney ? 'SAR' : null),
            validator: (v) {
              final t = (v ?? '').trim();
              if (f.required && t.isEmpty) return 'Required';
              if (t.isNotEmpty && isMoney && double.tryParse(t.replaceAll(',', '')) == null) return 'Invalid amount';
              if (t.isNotEmpty && isNumber && int.tryParse(t) == null) return 'Invalid number';
              return null;
            },
          ),
        );
    }
  }
}

/// Shows [fields] in a dialog. Returns the values, or null if cancelled.
Future<Map<String, dynamic>?> showFormDialog(String title, List<FieldSpec> fields, {String saveLabel = 'Save'}) {
  final key = GlobalKey<DynamicFormState>();
  return Get.dialog<Map<String, dynamic>>(AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    title: Text(title),
    content: SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(child: DynamicForm(key: key, fields: fields)),
    ),
    actions: [
      TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
      ElevatedButton(
        onPressed: () {
          final v = key.currentState?.collect();
          if (v != null) Get.back(result: v);
        },
        child: Text(saveLabel),
      ),
    ],
  ));
}
