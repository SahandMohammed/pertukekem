import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

/// Widget for managing store contact information
class ContactInfoList extends StatefulWidget {
  final List<Map<String, String>> initialContacts;
  final Function(List<Map<String, String>>) onContactsChanged;

  const ContactInfoList({
    super.key,
    required this.initialContacts,
    required this.onContactsChanged,
  });

  @override
  State<ContactInfoList> createState() => _ContactInfoListState();
}

class _ContactInfoListState extends State<ContactInfoList> {
  late List<Map<String, String>> contacts;
  final List<GlobalKey<FormBuilderState>> formKeys = [];

  @override
  void initState() {
    super.initState();
    contacts = List.from(widget.initialContacts);
    if (contacts.isEmpty) {
      // Add one default contact field
      _addContact();
    }
    _initializeFormKeys();
  }

  void _initializeFormKeys() {
    formKeys.clear();
    for (int i = 0; i < contacts.length; i++) {
      formKeys.add(GlobalKey<FormBuilderState>());
    }
  }

  void _addContact() {
    setState(() {
      contacts.add({'type': 'phone', 'value': ''});
      formKeys.add(GlobalKey<FormBuilderState>());
    });
    widget.onContactsChanged(contacts);
  }

  void _removeContact(int index) {
    if (contacts.length > 1) {
      setState(() {
        contacts.removeAt(index);
        formKeys.removeAt(index);
      });
      widget.onContactsChanged(contacts);
    }
  }

  void _updateContact(int index, String type, String value) {
    contacts[index] = {'type': type, 'value': value};
    widget.onContactsChanged(contacts);
  }

  bool validateAllContacts() {
    bool isValid = true;
    for (int i = 0; i < formKeys.length; i++) {
      if (formKeys[i].currentState?.validate() == false) {
        isValid = false;
      }
    }
    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Information',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add phone numbers or email addresses',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            if (contacts.length < 5)
              IconButton.filledTonal(
                onPressed: _addContact,
                icon: const Icon(Icons.add, size: 20),
                tooltip: 'Add contact',
                style: IconButton.styleFrom(minimumSize: const Size(40, 40)),
              ),
          ],
        ),
        const SizedBox(height: 16),

        ...contacts.asMap().entries.map((entry) {
          final index = entry.key;
          final contact = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildContactField(index, contact, colorScheme),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildContactField(
    int index,
    Map<String, String> contact,
    ColorScheme colorScheme,
  ) {
    return FormBuilder(
      key: formKeys[index],
      initialValue: contact,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Contact type dropdown
                  Expanded(
                    flex: 2,
                    child: FormBuilderDropdown<String>(
                      name: 'type',
                      decoration: InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'phone',
                          child: Text('📞 Phone'),
                        ),
                        DropdownMenuItem(
                          value: 'email',
                          child: Text('📧 Email'),
                        ),
                        DropdownMenuItem(
                          value: 'whatsapp',
                          child: Text('💬 WhatsApp'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _updateContact(index, value, contact['value'] ?? '');
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Contact value field
                  Expanded(
                    flex: 3,
                    child: FormBuilderTextField(
                      name: 'value',
                      decoration: InputDecoration(
                        labelText: _getValueLabel(contact['type'] ?? 'phone'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      keyboardType:
                          contact['type'] == 'email'
                              ? TextInputType.emailAddress
                              : TextInputType.phone,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                          errorText: 'This field is required',
                        ),
                        if (contact['type'] == 'email')
                          FormBuilderValidators.email(
                            errorText: 'Please enter a valid email',
                          ),
                        if (contact['type'] == 'phone' ||
                            contact['type'] == 'whatsapp')
                          FormBuilderValidators.minLength(
                            8,
                            errorText: 'Phone number too short',
                          ),
                      ]),
                      onChanged: (value) {
                        _updateContact(
                          index,
                          contact['type'] ?? 'phone',
                          value ?? '',
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Remove button
                  if (contacts.length > 1)
                    IconButton(
                      onPressed: () => _removeContact(index),
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      tooltip: 'Remove contact',
                      style: IconButton.styleFrom(
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getValueLabel(String type) {
    switch (type) {
      case 'email':
        return 'Email Address';
      case 'whatsapp':
        return 'WhatsApp Number';
      case 'phone':
      default:
        return 'Phone Number';
    }
  }
}
