import 'package:flutter/material.dart';

class EventLocationTitleField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const EventLocationTitleField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: false,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: const InputDecoration(
        labelText: 'Konum başlığı',
        hintText: 'Örn. Mühendislik Fakültesi B Blok',
        prefixIcon: Icon(Icons.edit_location_alt_rounded),
      ),
    );
  }
}
