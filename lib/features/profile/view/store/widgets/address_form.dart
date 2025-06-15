import 'package:country_picker/country_picker.dart';
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
  Country? selectedCountry;

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      final countryCode = widget.initialAddress!['countryCode'] as String?;
      if (countryCode != null) {
        selectedCountry = Country.tryParse(countryCode);
      }
    }
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

          // Country Selector
          InkWell(
            onTap: () {
              showCountryPicker(
                context: context,
                showPhoneCode: false,
                onSelect: (Country country) {
                  setState(() {
                    selectedCountry = country;
                  });
                  widget.formKey.currentState?.fields['countryCode']?.didChange(
                    country.countryCode,
                  );
                },
                countryListTheme: CountryListThemeData(
                  backgroundColor: colorScheme.surface,
                  textStyle: textTheme.bodyMedium,
                  searchTextStyle: textTheme.bodyMedium,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: colorScheme.outline),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (selectedCountry != null)
                    Text(
                      selectedCountry!.flagEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedCountry?.displayName ?? 'Select Country',
                      style: textTheme.bodyMedium?.copyWith(
                        color:
                            selectedCountry != null
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),

          // Hidden field to store country code
          FormBuilderTextField(
            name: 'countryCode',
            style: const TextStyle(height: 0, color: Colors.transparent),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            validator: FormBuilderValidators.required(
              errorText: 'Please select a country',
            ),
          ),

          const SizedBox(height: 16),

          // City
          FormBuilderTextField(
            name: 'city',
            decoration: InputDecoration(
              labelText: 'City *',
              hintText: 'Enter city name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainer,
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'City is required'),
              FormBuilderValidators.minLength(
                2,
                errorText: 'City name too short',
              ),
            ]),
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
            ),
          ),
        ],
      ),
    );
  }
}
