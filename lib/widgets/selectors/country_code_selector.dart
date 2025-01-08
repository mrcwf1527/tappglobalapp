// lib/widgets/selectors/country_code_selector.dart
// Under TAPP! Global Flutter Project
import 'package:flutter/material.dart';
import '../responsive_layout.dart';
import '../../models/country_code.dart';

class CountryCodeSelectorButton extends StatelessWidget {
  final CountryCode selectedCountry;
  final Function(CountryCode) onSelect;
  final double height;

  const CountryCodeSelectorButton({
    super.key,
    required this.selectedCountry,
    required this.onSelect,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final selected = await showDialog<CountryCode>(
          context: context,
          builder: (context) => const CountrySearchDialog(),
        );
        if (selected != null) {
          onSelect(selected);
        }
      },
      child: Container(
        height: height,
        width: ResponsiveLayout.isDesktop(context) ? 300 : 50,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.grey[700]! 
              : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: selectedCountry.getFlagWidget(
            width: 24,
            height: 16,
          ),
        ),
      ),
    );
  }
}

class CountrySearchDialog extends StatefulWidget {
  const CountrySearchDialog({super.key});

  @override
  State<CountrySearchDialog> createState() => _CountrySearchDialogState();
}

class _CountrySearchDialogState extends State<CountrySearchDialog> {
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
        return country.name.toLowerCase().contains(query.toLowerCase()) ||
               country.dialCode.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container( // Add this container
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
                      subtitle: Text(country.dialCode),
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