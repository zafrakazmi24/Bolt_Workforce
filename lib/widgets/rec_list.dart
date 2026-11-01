import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/constants/app_colors.dart';
import '../core/data/rec.dart';

Color statusColor(String s) {
  switch (s) {
    case 'Paid': case 'Approved': case 'Active': case 'Settled': case 'Present':
    case 'Available': case 'Posted': case 'Closed': case 'Issued':
      return AppColors.success;
    case 'Partial': case 'Pending': case 'Submitted': case 'Reviewed': case 'Draft':
    case 'Temporary': case 'On Hold': case 'Partially Paid': case 'Assigned':
      return AppColors.warning;
    case 'Unpaid': case 'Rejected': case 'Cancelled': case 'Reversed': case 'Offboarded':
    case 'Expired': case 'Absent': case 'Retired':
      return AppColors.danger;
    default:
      return Colors.blueGrey;
  }
}

class StatusChip extends StatelessWidget {
  final String label;
  final Color? color;
  const StatusChip(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(.14), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

/// Standard card row used by every list.
class RecCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  final Widget? trailing;
  final VoidCallback? onTap;
  const RecCard({super.key, required this.title, this.lines = const [], this.trailing, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                for (final l in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(l, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ),
              ]),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ]),
        ),
      ),
    );
  }
}

/// Loading / error / data wrapper for a Rec stream.
class RecStream extends StatelessWidget {
  final Stream<List<Rec>> stream;
  final Widget Function(BuildContext, List<Rec>) builder;
  const RecStream({super.key, required this.stream, required this.builder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Rec>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Could not load data.\n${snap.error}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
          ));
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return builder(context, snap.data!);
      },
    );
  }
}

/// Search + quick-filter chips + list, over a Rec stream.
class RecList extends StatefulWidget {
  final Stream<List<Rec>> stream;
  final String Function(Rec) searchText;
  final Map<String, bool Function(Rec)> filters;
  final bool Function(Rec)? extra; // additional filter controlled by the screen
  final Widget Function(BuildContext, Rec) itemBuilder;
  final int Function(Rec, Rec)? sort;
  final Widget Function(List<Rec> shown)? header;
  final String emptyText;

  const RecList({
    super.key,
    required this.stream,
    required this.searchText,
    required this.itemBuilder,
    this.filters = const {},
    this.extra,
    this.sort,
    this.header,
    this.emptyText = 'Nothing here yet',
  });

  @override
  State<RecList> createState() => _RecListState();
}

class _RecListState extends State<RecList> {
  String _q = '';
  String? _filter;

  @override
  Widget build(BuildContext context) {
    return RecStream(
      stream: widget.stream,
      builder: (context, all) {
        var shown = all.where((r) {
          if (widget.extra != null && !widget.extra!(r)) return false;
          if (_filter != null && !widget.filters[_filter]!(r)) return false;
          if (_q.isNotEmpty && !widget.searchText(r).toLowerCase().contains(_q)) return false;
          return true;
        }).toList();
        if (widget.sort != null) shown.sort(widget.sort);
        return Column(children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search', isDense: true),
            onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
          ),
          if (widget.filters.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(spacing: 8, runSpacing: 0, children: [
                  for (final k in widget.filters.keys)
                    FilterChip(
                      label: Text(k, style: const TextStyle(fontSize: 12)),
                      selected: _filter == k,
                      onSelected: (v) => setState(() => _filter = v ? k : null),
                    ),
                ]),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(children: [
              if (widget.header != null) widget.header!(shown),
              if (shown.isEmpty)
                Padding(padding: const EdgeInsets.all(40), child: Center(child: Text(widget.emptyText, style: const TextStyle(color: Colors.grey))))
              else
                for (final r in shown) widget.itemBuilder(context, r),
              const SizedBox(height: 80),
            ]),
          ),
        ]);
      },
    );
  }
}

/// Small key/value row for detail sheets.
class KV extends StatelessWidget {
  final String k, v;
  const KV(this.k, this.v, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 130, child: Text(k, style: TextStyle(fontSize: 12.5, color: Colors.grey[600]))),
          Expanded(child: Text(v.isEmpty ? '-' : v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ]),
      );
}

void toast(String title, String msg, {bool error = false}) => Get.snackbar(
      title, msg,
      backgroundColor: error ? AppColors.danger : null,
      colorText: error ? Colors.white : null,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      duration: Duration(seconds: error ? 5 : 3),
    );

Future<bool> confirm(String title, String text, {String yes = 'Yes'}) async {
  final r = await Get.dialog<bool>(AlertDialog(
    title: Text(title),
    content: Text(text),
    actions: [
      TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
      ElevatedButton(onPressed: () => Get.back(result: true), child: Text(yes)),
    ],
  ));
  return r == true;
}
