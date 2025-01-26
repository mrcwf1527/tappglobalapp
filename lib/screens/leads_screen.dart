// lib/screens/leads_screen.dart
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/business_card_provider.dart';
import '../models/business_card.dart';
import '../models/country_code.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? selectedCountry;
  String? selectedDepartment;
  String? selectedSeniority;
  String sortBy = 'dateNewest';

  final List<String> departments = [
    'Sales', 'Marketing', 'Operations', 'Finance', 
    'Human Resources', 'Information Technology',
    'Research & Development', 'Customer Service',
    'Legal', 'Administration', 'Others'
  ];

  final List<String> seniorities = [
    'C-Suite', 'Executive', 'Senior Management',
    'Mid Level', 'Entry Level', 'Intern', 'Others'
  ];

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      context.read<BusinessCardProvider>().loadCards(userId);
    } else {
      debugPrint('No user logged in');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search leads...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            context.read<BusinessCardProvider>().updateSearch(value);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Consumer<BusinessCardProvider>(
        builder: (context, provider, child) {
          final cards = provider.cards;
          
          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    Theme.of(context).brightness == Brightness.light
                      ? 'assets/images/scanning_businesscard_black.png'
                      : 'assets/images/scanning_businesscard_white.png',
                    width: 200,
                    height: 200,
                  ),
                  const SizedBox(height: 16),
                  const Text('No leads yet. Scan your first business card!'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return BusinessCardTile(card: card);
            },
          );
        },
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter & Sort', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Country Filter
              DropdownButtonFormField<String>(
                value: selectedCountry,
                decoration: const InputDecoration(labelText: 'Country'),
                items: CountryCodes.codes.map((country) => DropdownMenuItem(
                  value: country.name,
                  child: Text(country.name),
                )).toList(),
                onChanged: (value) {
                  setState(() => selectedCountry = value);
                  _applyFilters();
                },
              ),
              
              // Department Filter
              DropdownButtonFormField<String>(
                value: selectedDepartment,
                decoration: const InputDecoration(labelText: 'Department'),
                items: departments.map((dept) => DropdownMenuItem(
                  value: dept,
                  child: Text(dept),
                )).toList(),
                onChanged: (value) {
                  setState(() => selectedDepartment = value);
                  _applyFilters();
                },
              ),
              
              // Seniority Filter
              DropdownButtonFormField<String>(
                value: selectedSeniority,
                decoration: const InputDecoration(labelText: 'Job Seniority'),
                items: seniorities.map((seniority) => DropdownMenuItem(
                  value: seniority,
                  child: Text(seniority),
                )).toList(),
                onChanged: (value) {
                  setState(() => selectedSeniority = value);
                  _applyFilters();
                },
              ),
              
              // Sort Options
              DropdownButtonFormField<String>(
                value: sortBy,
                decoration: const InputDecoration(labelText: 'Sort By'),
                items: const [
                  DropdownMenuItem(value: 'dateNewest', child: Text('Date Added (Newest First)')),
                  DropdownMenuItem(value: 'dateOldest', child: Text('Date Added (Oldest First)')),
                  DropdownMenuItem(value: 'nameAZ', child: Text('Name (A-Z)')),
                  DropdownMenuItem(value: 'nameZA', child: Text('Name (Z-A)')),
                  DropdownMenuItem(value: 'seniorityHigh', child: Text('Seniority (Highest First)')),
                  DropdownMenuItem(value: 'seniorityLow', child: Text('Seniority (Lowest First)')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => sortBy = value);
                    _applyFilters();
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Clear Filters Button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    selectedCountry = null;
                    selectedDepartment = null;
                    selectedSeniority = null;
                    sortBy = 'dateNewest';
                  });
                  _applyFilters();
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyFilters() {
    context.read<BusinessCardProvider>().updateFilters(
      country: selectedCountry,
      department: selectedDepartment,
      seniority: selectedSeniority,
      sortBy: sortBy,
    );
  }
}

class BusinessCardTile extends StatelessWidget {
  final BusinessCard card;

  const BusinessCardTile({
    super.key,
    required this.card,
  });

  void _showPhoneOptions(BuildContext context, List<String> phones, bool isWhatsApp) async {
    if (phones.isEmpty) return;
    
    if (phones.length == 1) {
      _launchPhone(phones[0], isWhatsApp);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isWhatsApp ? 'Choose number for WhatsApp' : 'Choose number to call'),
            const SizedBox(height: 16),
            ...phones.map((phone) => ListTile(
              title: Text(phone),
              onTap: () {
                Navigator.pop(context);
                _launchPhone(phone, isWhatsApp);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showEmailOptions(BuildContext context, List<String> emails) async {
    if (emails.isEmpty) return;
    
    if (emails.length == 1) {
      _launchEmail(emails[0]);
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose email address'),
            const SizedBox(height: 16),
            ...emails.map((email) => ListTile(
              title: Text(email),
              onTap: () {
                Navigator.pop(context);
                _launchEmail(email);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _launchPhone(String phone, bool isWhatsApp) async {
    final uri = isWhatsApp 
      ? Uri.parse('https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}')
      : Uri.parse('tel:$phone');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showMoreOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement Add Tags feature
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Tags feature coming soon!')),
              );
            },
            child: const Text('Add Tags'),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement Add Notes feature
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add Notes feature coming soon!')),
              );
            },
            child: const Text('Add Notes'),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lead'),
        content: const Text('Are you sure you want to delete this lead?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<BusinessCardProvider>().deleteCard(card.id, card.imageUrl, userId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: card.imageUrl.isNotEmpty
              ? CircleAvatar(backgroundImage: NetworkImage(card.imageUrl))
              : CircleAvatar(child: Text(card.name[0])),
            title: Text(card.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.title),
                Text(card.brandName),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showMoreOptions(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.phone),
                  onPressed: () => _showPhoneOptions(context, card.phone, false),
                  ),
                  IconButton(
                  icon: const FaIcon(FontAwesomeIcons.whatsapp),
                  onPressed: () => _showPhoneOptions(context, card.phone, true),
                  ),
                  IconButton(
                  icon: const FaIcon(FontAwesomeIcons.envelope),
                  onPressed: () => _showEmailOptions(context, card.email),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}