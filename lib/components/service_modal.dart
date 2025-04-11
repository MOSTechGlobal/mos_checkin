import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/theme_bloc.dart';

class ServicesModal extends StatefulWidget {
  final Set<Map<String, dynamic>> allServices;
  final Set<Map<String, dynamic>> currentServices;
  final String agreementCode;
  final Function(Set<Map<String, dynamic>>) onAddServices;

  const ServicesModal({
    super.key,
    required this.allServices,
    required this.currentServices,
    required this.agreementCode,
    required this.onAddServices,
  });

  @override
  _ServicesModalState createState() => _ServicesModalState();
}

class _ServicesModalState extends State<ServicesModal> {
  Set<Map<String, dynamic>> _filteredServices = {};
  Map<String, dynamic>? _selectedService;

  @override
  void initState() {
    super.initState();
    _filteredServices = Set.from(widget.allServices);
    _selectedService =
        widget.currentServices.isNotEmpty ? widget.currentServices.first : null;
  }

  void _filterServices(String query) {
    setState(() {
      _filteredServices = query.isEmpty
          ? widget.allServices
          : widget.allServices.where((service) {
              String code = service['Service_Code'] ?? '';
              String description = service['Description'] ?? '';
              return code.toLowerCase().contains(query.toLowerCase()) ||
                  description.toLowerCase().contains(query.toLowerCase());
            }).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeMode>(
      builder: (context, state) {
        final colorScheme = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          snap: false,
          expand: false,
          initialChildSize: 0.7,
          builder: (_, controller) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                TextField(
                  onChanged: _filterServices,
                  style: TextStyle(color: colorScheme.secondary),
                  decoration: InputDecoration(
                    labelText: 'Search Services',
                    labelStyle: TextStyle(color: colorScheme.secondary),
                    fillColor: colorScheme.secondaryContainer,
                    filled: true,
                    prefixIcon: const Icon(Icons.search),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: colorScheme.secondaryContainer),
                    ),
                    prefixIconColor: colorScheme.secondary,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: colorScheme.secondaryContainer),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: _filteredServices.length,
                    itemBuilder: (context, index) {
                      final service = _filteredServices.elementAt(index);
                      final isSelected = _selectedService == service;
                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(service['Service_Code'] ?? 'No Code',
                              style: TextStyle(color: colorScheme.secondary)),
                          subtitle:
                              Text(service['Description'] ?? 'No Description'),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedService = isSelected ? null : service;
                            });
                            if (_selectedService != null) {
                              widget.onAddServices({_selectedService!});
                            }
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
