// lib/screens/leads_screen.dart
// A comprehensive leads management screen featuring country/department/seniority filters, search functionality, lead sorting, business card display with contact actions (call/WhatsApp/email), and a bottom sheet filter interface with built-in flag picker for country selection.
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/business_card_provider.dart';
import '../models/business_card.dart';
import '../models/country_code.dart';
import '../widgets/business_cards/country_search_dialog_leads.dart';
import '../providers/tag_provider.dart';
import '../models/tag.dart';
import '../widgets/business_cards/tag_bottom_sheet.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

enum LeadType {
  eventBadge,
  leadCaptureForm,
  businessCard,
  manuallyAdded,
  poplUserToPoplUser
}

enum SortOption {
  dateNewest('Date Added (Newest -> Oldest)'),
  dateOldest('Date Added (Oldest -> Newest)'),
  nameAZ('Alphabetical (A -> Z)'),
  nameZA('Alphabetical (Z -> A)');

  final String label;
  const SortOption(this.label);
}


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
      context.read<TagProvider>().loadTags(userId);
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
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: const Text('Filter', 
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Tags Section
                    _buildTagsSection(context),
                    const SizedBox(height: 16),
                    
                    // Sort By
                    _buildSortBySection(setState),
                    const SizedBox(height: 16),
                    
                    // Lead Type
                    _buildLeadTypeSection(context),
                    const SizedBox(height: 16),
                    
                    // Existing Filters
                    _buildExistingFilters(setState),
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      onPressed: () {
                        _applyFilters();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.light 
                          ? Colors.black 
                          : Colors.white,
                        foregroundColor: Theme.of(context).brightness == Brightness.light 
                          ? Colors.white 
                          : Colors.black,
                      ),
                      child: const Text('Apply Filters'),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagsSection(BuildContext context) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tags feature coming soon!')),
      ),
      child: Card(
        child: ListTile(
          title: const Text('Tags'),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  Widget _buildSortBySection(StateSetter setState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort By', style: TextStyle(fontSize: 16)),
            ...SortOption.values.map((option) => RadioListTile(
              value: option.name,
              groupValue: sortBy,
              title: Text(option.label),
              onChanged: (value) => setState(() => sortBy = value!),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadTypeSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lead Type', style: TextStyle(fontSize: 16)),
            ...LeadType.values.map((type) => CheckboxListTile(
              value: type == LeadType.businessCard,
              title: Text(type.name.replaceAll(RegExp(r'(?=[A-Z])'), ' ')
                  .split(' ')
                  .map((e) => e.capitalize())
                  .join(' ')),
              onChanged: (bool? value) {
                if (type != LeadType.businessCard) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('This feature is coming soon!')),
                  );
                  return;
                }
                // Handle business card filter
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingFilters(StateSetter setState) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Country Filter
      InkWell(
        onTap: () async {
          final selected = await showDialog<CountryCode>(
            context: context,
            builder: (context) => const CountrySearchDialogLeads(),
          );
          if (selected != null) {
            setState(() => selectedCountry = selected.name);
            _applyFilters();
          }
        },
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Country'),
          child: Row(
            children: [
              if (selectedCountry != null)
                CountryCodes.codes
                    .firstWhere((c) => c.name == selectedCountry)
                    .getFlagWidget(width: 24, height: 16),
              const SizedBox(width: 8),
              Text(selectedCountry ?? 'Select Country'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),

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
      const SizedBox(height: 16),

      // Job Seniority Filter
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
    ],
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
  
  void _showTagBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => TagBottomSheet(
        selectedTags: List<String>.from(card.tags),
        onTagsSelected: (selectedTags) async {
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            await context.read<BusinessCardProvider>().updateCardTags(
              userId,
              card.id,
              selectedTags,
            );
            // Pop the bottom sheet after updating
            if (context.mounted) {
              Navigator.pop(context);
            }
          }
        },
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (String result) {
        switch (result) {
          case 'edit':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Edit feature coming soon!')),
            );
            break;
          case 'tags':
            _showTagBottomSheet(context);
            break;
          case 'notes':
            _showNotesDialog(context, card);
            break;
          case 'delete':
            _showDeleteConfirmation(context);
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'tags',
          child: Row(
            children: [
              Icon(Icons.label_outline, size: 20),
              SizedBox(width: 8),
              Text('Add Tags'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'notes',
          child: Row(
            children: [
              Icon(Icons.note_add_outlined, size: 20),
              SizedBox(width: 8),
              Text('Add Notes'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
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
              context.read<BusinessCardProvider>().deleteCard(card.id, card.fileUrl, userId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNotesDialog(BuildContext context, BusinessCard card) {
    final notesController = TextEditingController(text: card.notes);
    final initialNotes = card.notes; // Store initial value
    bool hasUnsavedChanges = false;

    // Add listener to track changes
    notesController.addListener(() {
      hasUnsavedChanges = notesController.text != initialNotes;
    });

    showDialog(
      context: context,
      builder: (context) => PopScope( // Add PopScope for back button handling
        canPop: !hasUnsavedChanges,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Discard Changes?'),
              content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Discard'),
                ),
              ],
            ),
          );

          if (confirmed == true && context.mounted) {
            Navigator.pop(context);
          }
        },
        child: AlertDialog(
          title: const Text('Notes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: notesController,
                maxLines: null,
                minLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add notes here...',
                  border: OutlineInputBorder(),
                ),
              ),
              if (card.notes.isNotEmpty)
                const SizedBox(height: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Delete Notes', 
                    style: TextStyle(color: Colors.red)
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Notes'),
                        content: const Text('Are you sure you want to delete these notes?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final userId = FirebaseAuth.instance.currentUser?.uid;
                              if (userId != null) {
                                await context.read<BusinessCardProvider>()
                                  .updateCardNotes(userId, card.id, '');
                              }
                              if (context.mounted) {
                                Navigator.pop(context); // Close confirmation
                                Navigator.pop(context); // Close notes dialog
                              }
                            },
                            child: const Text('Delete', 
                              style: TextStyle(color: Colors.red)
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (hasUnsavedChanges) {
                  final shouldDiscard = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Discard Changes?'),
                      content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Discard'),
                        ),
                      ],
                    ),
                  );
                  if (shouldDiscard == true && context.mounted) {
                    Navigator.pop(context);
                  }
                } else {
                  Navigator.pop(context);
                }
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  try {
                    await context.read<BusinessCardProvider>()
                      .updateCardNotes(userId, card.id, notesController.text);
                      
                    if (context.mounted) {
                      // First pop the notes dialog
                      Navigator.of(context, rootNavigator: true).pop();
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notes saved successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error saving notes: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
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
            leading: card.fileUrl.isNotEmpty
              ? CircleAvatar(backgroundImage: NetworkImage(card.fileUrl))
              : CircleAvatar(child: Text(card.name[0])),
            title: Text(card.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(card.title),
                Text(card.brandName.isNotEmpty ? card.brandName : card.legalName),
                const SizedBox(height: 8),
                if (card.tags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: card.tags.map((tagId) => Consumer<TagProvider>(
                      builder: (context, tagProvider, _) {
                        final tag = tagProvider.tags.firstWhere(
                          (t) => t.id == tagId,
                          orElse: () => Tag(id: '', name: 'Unknown', color: '#000000', userId: ''),
                        );
                        
                        final color = Color(int.parse(tag.color.substring(1, 7), radix: 16) + 0xFF000000);
                        final isLight = ThemeData.estimateBrightnessForColor(color) == Brightness.light;

                        return Chip(
                          label: Text(
                            tag.name,
                            style: TextStyle(
                              color: isLight ? Colors.black : Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: color,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        );
                      },
                    )).toList(),
                  ),
              ],
            ),
            trailing: _buildPopupMenu(context),
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