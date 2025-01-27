// lib/widgets/business_cards/country_search_dialog_leads.dart
// A dialog widget for searching and selecting countries in the leads screen, displaying country flags and names without dial codes, while maintaining the same UI/UX as the country code selector.
import 'package:flutter/material.dart';
import '../../models/country_code.dart';

class CountrySearchDialogLeads extends StatefulWidget {
  const CountrySearchDialogLeads({super.key});

  @override
  State<CountrySearchDialogLeads> createState() => _CountrySearchDialogLeadsState();
}

class _CountrySearchDialogLeadsState extends State<CountrySearchDialogLeads> {
  late TextEditingController _searchController;
  late List<CountryCode> _filteredCountries;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredCountries = CountryCodes.codes;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      _filteredCountries = CountryCodes.codes.where((country) {
        return country.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search country',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: _filterCountries,
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredCountries.length,
                  itemBuilder: (context, index) {
                    final country = _filteredCountries[index];
                    return ListTile(
                      leading: country.getFlagWidget(
                        width: 24,
                        height: 16,
                      ),
                      title: Text(country.name),
                      onTap: () => Navigator.pop(context, country),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}