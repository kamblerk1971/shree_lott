import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shreelott/screens/helpers/batting_grid_view.dart';

import '../consts/app_colors.dart';

/// Show slot selection dialog
Future<List<TimeOfDay>?> showSlotDialog(
  BuildContext context, {
  List<TimeOfDay> selectedTimes = const [],
}) {
  return showDialog<List<TimeOfDay>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _SlotDialog(preselected: selectedTimes),
  );
}

/// Slot dialog widget
class _SlotDialog extends StatefulWidget {
  final List<TimeOfDay> preselected;

  const _SlotDialog({required this.preselected});

  @override
  State<_SlotDialog> createState() => _SlotDialogState();
}

class _SlotDialogState extends State<_SlotDialog> {
  late final List<_SlotItem> slots;

  @override
  void initState() {
    super.initState();
    slots = _generateSlots(widget.preselected);
  }

  @override
  Widget build(BuildContext context) {
    final selectable = slots.where((e) => !e.disabled).toList();
    final allSelected =
        selectable.isNotEmpty && selectable.every((e) => e.selected);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          // Background image
          // Positioned.fill(
          //   child: Image.asset(
          //     "assets/bg_image_1.png",
          //     fit: BoxFit.cover,
          //     errorBuilder: (context, error, stackTrace) {
          //       return Container(
          //         decoration: BoxDecoration(
          //           gradient: AppColors.premiumDarkGradient,
          //         ),
          //       );
          //     },
          //   ),
          // ),

          // Center card
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.95,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: RadialGradient(
                    center: const Alignment(0.3, -0.3),
                    radius: 1.2,
                    colors: [
                      AppColors.primaryMedium.withOpacity(0.95),
                      AppColors.primaryDarker,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                  border: Border.all(
                    color: AppColors.accentGold.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: AppColors.premiumCardShadow,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDarker.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Select Slot Time',
                            style: TextStyle(
                              color: AppColors.accentGold,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Grid of slots (10 per row)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: slots.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 10,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 3,
                            ),
                        itemBuilder: (context, index) {
                          return _slotTile(slots[index]);
                        },
                      ),

                      const SizedBox(height: 20),

                      // Select All / Clear row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Checkbox(
                            value: allSelected,
                            checkColor: AppColors.textDark,
                            fillColor: MaterialStateProperty.resolveWith<Color>(
                              (states) {
                                if (states.contains(MaterialState.selected)) {
                                  return AppColors.accentGold;
                                }
                                return AppColors.textPrimary;
                              },
                            ),
                            side: const BorderSide(
                              color: AppColors.accentGold,
                              width: 2,
                            ),
                            onChanged: (v) {
                              setState(() {
                                for (final s in selectable) {
                                  s.selected = v ?? false;
                                }
                              });
                            },
                          ),
                          const Text(
                            'Select All Slot',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                          const Spacer(),
                          ModernBtn(
                            text: "Clear ALl",
                            bgColor: Colors.green,
                            width: 100,
                            height: 40,
                            onTap: () {
                              setState(() {
                                for (final s in slots) {
                                  s.selected = false;
                                }
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.bottomRight,
                        child: ModernBtn(
                          text: "Confirm",
                          bgColor: Colors.yellow,
                          textColor: Colors.black,
                          width: 150,
                          height: 40,
                          onTap: () {
                            Navigator.pop(
                              context,
                              slots
                                  .where((e) => e.selected)
                                  .map((e) => e.time)
                                  .toList(),
                            );
                          },
                        ),
                      ),
                      // Confirm button
                      // Align(
                      //   alignment: Alignment.centerRight,
                      //   child: ElevatedButton(
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: AppColors.accentGold,
                      //       foregroundColor: AppColors.textDark,
                      //       padding: const EdgeInsets.symmetric(
                      //         horizontal: 28,
                      //         vertical: 14,
                      //       ),
                      //       elevation: 8,
                      //       shadowColor: AppColors.accentGold.withOpacity(0.5),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(10),
                      //       ),
                      //     ),
                      //     onPressed: () {
                      //
                      //     },
                      //     child: const Text(
                      //       'Confirm',
                      //       style: TextStyle(fontWeight: FontWeight.bold),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Slot tile widget
  Widget _slotTile(_SlotItem item) {
    return InkWell(
      onTap: item.disabled
          ? null
          : () => setState(() => item.selected = !item.selected),
      child: Row(
        children: [
          Checkbox(
            value: item.selected,
            checkColor: AppColors.textDark,
            fillColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (states.contains(MaterialState.selected)) {
                return AppColors.accentGold;
              }
              return AppColors.textPrimary;
            }),
            side: const BorderSide(color: AppColors.accentGold, width: 2),
            onChanged: item.disabled
                ? null
                : (v) => setState(() => item.selected = v ?? false),
          ),
          Expanded(
            child: Text(
              _format(item.time),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: item.disabled
                    ? AppColors.textSecondary
                    : AppColors.accentGold,
                fontWeight: item.selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Generate slot items for the day
  List<_SlotItem> _generateSlots(List<TimeOfDay> preselected) {
    final now = DateTime.now();
    final start = _roundToQuarter(now);
    final maxSlot = DateTime(now.year, now.month, now.day, 21, 30);

    final result = <_SlotItem>[];
    DateTime current = start;

    while (!current.isAfter(maxSlot)) {
      final time = TimeOfDay(hour: current.hour, minute: current.minute);

      final isPreselected = preselected.any(
        (t) => t.hour == time.hour && t.minute == time.minute,
      );

      result.add(
        _SlotItem(
          time: time,
          selected: isPreselected,
          disabled: current.isBefore(now),
        ),
      );

      current = current.add(const Duration(minutes: 15));
    }

    return result;
  }

  /// Round time to nearest quarter hour
  DateTime _roundToQuarter(DateTime dt) {
    final minute = ((dt.minute + 14) ~/ 15) * 15;

    return DateTime(
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      minute % 60,
    ).add(Duration(hours: minute >= 60 ? 1 : 0));
  }

  /// Format time to readable string
  String _format(TimeOfDay t) {
    return DateFormat('hh:mm a').format(DateTime(0, 1, 1, t.hour, t.minute));
  }
}

/// Slot item model
class _SlotItem {
  final TimeOfDay time;
  bool selected;
  final bool disabled;

  _SlotItem({required this.time, this.selected = false, this.disabled = false});
}
