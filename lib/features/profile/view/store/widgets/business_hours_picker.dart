import 'package:flutter/material.dart';

/// Widget for selecting business hours for each day of the week
class BusinessHoursPicker extends StatefulWidget {
  final Map<String, dynamic>? initialHours;
  final Function(Map<String, dynamic>) onHoursChanged;

  const BusinessHoursPicker({
    super.key,
    this.initialHours,
    required this.onHoursChanged,
  });

  @override
  State<BusinessHoursPicker> createState() => _BusinessHoursPickerState();
}

class _BusinessHoursPickerState extends State<BusinessHoursPicker> {
  static const List<String> daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const Map<String, String> dayLabels = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  late Map<String, dynamic> businessHours;
  String? expandedDay;

  @override
  void initState() {
    super.initState();
    businessHours = Map.from(widget.initialHours ?? {});

    // Initialize with default hours if empty
    for (final day in daysOfWeek) {
      businessHours[day] ??= {
        'isOpen': true,
        'openTime': '09:00',
        'closeTime': '18:00',
      };
    }
  }

  void _updateHours() {
    widget.onHoursChanged(businessHours);
  }

  void _toggleDay(String day, bool isOpen) {
    setState(() {
      businessHours[day]['isOpen'] = isOpen;
    });
    _updateHours();
  }

  void _updateTime(String day, String timeType, TimeOfDay time) {
    setState(() {
      businessHours[day][timeType] =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    });
    _updateHours();
  }

  Future<void> _selectTime(String day, String timeType) async {
    final currentTime = businessHours[day][timeType] as String;
    final timeParts = currentTime.split(':');
    final currentTimeOfDay = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTimeOfDay,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      _updateTime(day, timeType, selectedTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Business Hours',
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Set your store\'s operating hours for each day',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 16),

        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              children:
                  daysOfWeek.map((day) {
                    final dayData = businessHours[day] as Map<String, dynamic>;
                    final isOpen = dayData['isOpen'] as bool;
                    final isExpanded = expandedDay == day;

                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              expandedDay = isExpanded ? null : day;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Day name
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    dayLabels[day]!,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),

                                // Status or hours
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    isOpen
                                        ? '${dayData['openTime']} - ${dayData['closeTime']}'
                                        : 'Closed',
                                    style: textTheme.bodySmall?.copyWith(
                                      color:
                                          isOpen
                                              ? colorScheme.onSurface
                                              : colorScheme.onSurface
                                                  .withOpacity(0.6),
                                    ),
                                  ),
                                ),

                                // Toggle switch
                                Switch.adaptive(
                                  value: isOpen,
                                  onChanged: (value) => _toggleDay(day, value),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),

                                // Expand icon
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Expanded time picker
                        if (isExpanded && isOpen)
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTimeButton(
                                    context,
                                    'Open Time',
                                    dayData['openTime'] as String,
                                    () => _selectTime(day, 'openTime'),
                                    colorScheme,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'to',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTimeButton(
                                    context,
                                    'Close Time',
                                    dayData['closeTime'] as String,
                                    () => _selectTime(day, 'closeTime'),
                                    colorScheme,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (day != daysOfWeek.last)
                          Divider(
                            height: 1,
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeButton(
    BuildContext context,
    String label,
    String time,
    VoidCallback onTap,
    ColorScheme colorScheme,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
