import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

/// Widget for collecting store address information
class AddressForm extends StatefulWidget {
  final GlobalKey<FormBuilderState> formKey;
  final Map<String, dynamic>? initialAddress;

  const AddressForm({super.key, required this.formKey, this.initialAddress});

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  String? selectedState;
  List<String> availableCities = [];

  // Iraq states and their cities
  static const Map<String, List<String>> iraqStatesAndCities = {
    'Baghdad': ['Baghdad', 'Abu Ghraib', 'Taji', 'Mahmudiyah', 'Tarmiyah'],
    'Basra': ['Basra', 'Zubair', 'Umm Qasr', 'Qurna', 'Abu Al-Khaseeb'],
    'Nineveh': ['Mosul', 'Sinjar', 'Tal Afar', 'Hamdaniya', 'Sheikhan'],
    'Erbil': ['Erbil', 'Makhmur', 'Koya', 'Shaqlawa', 'Soran'],
    'Najaf': ['Najaf', 'Kufa', 'Mishkhab', 'Manathera', 'Haidariya'],
    'Karbala': ['Karbala', 'Ain Tamr', 'Hindiya', 'Hur', 'Razzaza'],
    'Sulaymaniyah': ['Sulaymaniyah', 'Halabja', 'Rania', 'Dokan', 'Penjwin'],
    'Anbar': ['Ramadi', 'Fallujah', 'Hit', 'Haditha', 'Ana', 'Qaim'],
    'Diyala': ['Baqubah', 'Muqdadiyah', 'Khalis', 'Balad Ruz', 'Khanaqin'],
    'Kirkuk': ['Kirkuk', 'Hawija', 'Dibis', 'Daquq', 'Multaqa'],
    'Maysan': [
      'Amarah',
      'Majar al-Kabir',
      'Qalat Salih',
      'Ali al-Gharbi',
      'Kahla',
    ],
    'Muthanna': ['Samawah', 'Rumaitha', 'Khidr', 'Salman', 'Warka'],
    'Qadisiyyah': ['Diwaniyah', 'Afak', 'Hamza', 'Ghamas', 'Mahaweel'],
    'Saladin': ['Tikrit', 'Samarra', 'Baiji', 'Tuz Khurmatu', 'Daur'],
    'Dhi Qar': [
      'Nasiriyah',
      'Shatra',
      'Suq al-Shuyukh',
      'Rifai',
      'Qalat Sukkar',
    ],
    'Wasit': ['Kut', 'Hay', 'Badra', 'Aziziyah', 'Numaniyah'],
    'Babylon': ['Hillah', 'Mahawil', 'Hashimiyah', 'Musayyib', 'Qasim'],
    'Dohuk': ['Dohuk', 'Zakho', 'Simele', 'Shekhan', 'Amedi'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      selectedState = widget.initialAddress!['state'] as String?;
      if (selectedState != null &&
          iraqStatesAndCities.containsKey(selectedState)) {
        availableCities = iraqStatesAndCities[selectedState]!;
      }
    }
  }

  void _onStateChanged(String? state) {
    setState(() {
      selectedState = state;
      availableCities = state != null ? iraqStatesAndCities[state]! : [];
    });

    // Clear city selection when state changes
    widget.formKey.currentState?.fields['city']?.didChange(null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FormBuilder(
      key: widget.formKey,
      initialValue: widget.initialAddress ?? {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Store Address',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Provide your store\'s physical address for customer visits',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),

          // Country (Iraq - disabled field)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(12),
              color: colorScheme.surfaceContainer.withOpacity(0.5),
            ),
            child: Row(
              children: [
                const Text('🇮🇶', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Iraq',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Hidden field to store country code
          FormBuilderTextField(
            name: 'countryCode',
            initialValue: 'IQ',
            style: const TextStyle(height: 0, color: Colors.transparent),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 16),

          // State Dropdown
          FormBuilderDropdown<String>(
            name: 'state',
            decoration: InputDecoration(
              labelText: 'State/Province *',
              hintText: 'Select state',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
              prefixIcon: Icon(
                Icons.location_city,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            items:
                iraqStatesAndCities.keys
                    .map(
                      (state) =>
                          DropdownMenuItem(value: state, child: Text(state)),
                    )
                    .toList(),
            onChanged: _onStateChanged,
            validator: FormBuilderValidators.required(
              errorText: 'Please select a state',
            ),
          ),

          const SizedBox(height: 16),

          // City Dropdown
          FormBuilderDropdown<String>(
            name: 'city',
            decoration: InputDecoration(
              labelText: 'City *',
              hintText:
                  selectedState != null ? 'Select city' : 'Select state first',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
              prefixIcon: Icon(
                Icons.location_on,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            items:
                availableCities
                    .map(
                      (city) =>
                          DropdownMenuItem(value: city, child: Text(city)),
                    )
                    .toList(),
            validator: FormBuilderValidators.required(
              errorText: 'Please select a city',
            ),
          ),

          const SizedBox(height: 16),

          // Street Address
          FormBuilderTextField(
            name: 'street',
            decoration: InputDecoration(
              labelText: 'Street Address *',
              hintText: 'Enter street address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
              prefixIcon: Icon(Icons.home, color: colorScheme.onSurfaceVariant),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(
                errorText: 'Street address is required',
              ),
              FormBuilderValidators.minLength(
                5,
                errorText: 'Address too short',
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // Postal Code (Optional)
          FormBuilderTextField(
            name: 'postalCode',
            decoration: InputDecoration(
              labelText: 'Postal Code',
              hintText: 'Enter postal code (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
              prefixIcon: Icon(
                Icons.markunread_mailbox,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Additional Info (Optional)
          FormBuilderTextField(
            name: 'additionalInfo',
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Additional Info',
              hintText: 'Apartment, suite, floor, etc. (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
              prefixIcon: Icon(
                Icons.info_outline,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
