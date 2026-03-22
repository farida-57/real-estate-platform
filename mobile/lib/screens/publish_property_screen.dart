import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/property_provider.dart';
import '../models/property_model.dart';

class PublishPropertyScreen extends ConsumerStatefulWidget {
  const PublishPropertyScreen({super.key});

  @override
  ConsumerState<PublishPropertyScreen> createState() =>
      _PublishPropertyScreenState();
}

class _PublishPropertyScreenState extends ConsumerState<PublishPropertyScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();

  TransactionType _transactionType = TransactionType.rent;
  String _propertyType = 'house';
  // Location is entered via text fields above
  List<XFile> _images = [];
  final Set<String> _selectedAmenities = {};

  final List<Map<String, String>> _amenitiesOptions = const [
    {'id': 'pool', 'label': 'Piscine'},
    {'id': 'garage', 'label': 'Garage'},
    {'id': 'garden', 'label': 'Jardin'},
    {'id': 'ac', 'label': 'Climatisation'},
    {'id': 'generator', 'label': 'Groupe Électrogène'},
    {'id': 'borehole', 'label': 'Forage'},
    {'id': 'security', 'label': 'Sécurité 24/7'},
    {'id': 'kitchen', 'label': 'Cuisine Équipée'},
    {'id': 'balcony', 'label': 'Balcon'},
    {'id': 'terrace', 'label': 'Terrasse'},
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        _images.addAll(selectedImages);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      // For now, use simple data without file uploads
      final propertyData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'transactionType': _transactionType.name,
        'propertyType': _propertyType,
        'location': {
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
        },
        'features': {
          'area': double.parse(_areaController.text),
          'bedrooms': int.parse(_bedroomsController.text),
          'bathrooms': int.parse(_bathroomsController.text),
        },
        'amenities': _selectedAmenities.toList(),
        'images': [], // Empty for now
        'documents': {
          'idCard': '',
          'titleDeedOrLease': '',
        },
      };

      try {
        final success = await ref
            .read(propertiesProvider.notifier)
            .createProperty(propertyData);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Propriété publiée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/search');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la publication. Vérifiez votre connexion.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isOwner = authState.user?.role == 'owner';

    if (!isOwner) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Publier une propriété'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Fonctionnalité réservée aux propriétaires',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Créez un compte propriétaire pour publier vos biens',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Publier un bien',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.foreground),
      ),
      body: Form(
        key: _formKey,
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onSurface: AppColors.foreground,
              onBackground: AppColors.background,
            ),
          ),
          child: Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepTapped: (step) => setState(() => _currentStep = step),
            onStepContinue: () {
              if (_currentStep < 3) {
                setState(() => _currentStep += 1);
              } else {
                _handleSubmit();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              }
            },
            controlsBuilder: (BuildContext context, ControlsDetails details) {
              return Padding(
                padding: const EdgeInsets.only(top: 32.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(_currentStep < 3 ? 'SUIVANT' : 'PUBLIER'),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('RETOUR'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Infos'),
                isActive: _currentStep >= 0,
                content: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre de l\'annonce',
                        hintText: 'Ex: Belle villa avec piscine',
                      ),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Prix (XOF)',
                        hintText: 'Ex: 150000',
                        suffixText: 'XOF',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<TransactionType>(
                      value: _transactionType,
                      decoration: const InputDecoration(
                        labelText: 'Type de transaction',
                      ),
                      items: TransactionType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.name.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _transactionType = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _propertyType,
                      decoration: const InputDecoration(
                        labelText: 'Type de bien',
                      ),
                      items: ['house', 'apartment', 'land', 'office']
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _propertyType = v!),
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Détails'),
                isActive: _currentStep >= 1,
                content: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _areaController,
                            decoration: const InputDecoration(
                              labelText: 'Surface (m²)',
                              suffixText: 'm²',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Requis' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _bedroomsController,
                            decoration: const InputDecoration(
                              labelText: 'Chambres',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Requis' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _bathroomsController,
                            decoration: const InputDecoration(
                              labelText: 'Salles de bain',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? 'Requis' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Décrivez le bien en détail...',
                      ),
                      maxLines: 4,
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Équipements & Prestations',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _amenitiesOptions.map((amenity) {
                        final id = amenity['id']!;
                        final label = amenity['label']!;
                        final isSelected = _selectedAmenities.contains(id);

                        return FilterChip(
                          label: Text(label),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.foreground,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAmenities.add(id);
                              } else {
                                _selectedAmenities.remove(id);
                              }
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary.withOpacity(0.1),
                          checkmarkColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Lieu'),
                isActive: _currentStep >= 2,
                content: Column(
                  children: [
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Ville',
                        hintText: 'Ex: Ouagadougou',
                        prefixIcon: Icon(
                          Icons.location_city,
                          color: AppColors.muted,
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse précise',
                        hintText: 'Ex: Ouaga 2000, Secteur 15',
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: AppColors.muted,
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Position sur la carte',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        color: AppColors.mutedLight,
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.map_outlined, size: 48, color: AppColors.primary),
                              SizedBox(height: 8),
                              Text(
                                'Entrez la ville et l\'adresse ci-dessus',
                                style: TextStyle(color: AppColors.muted),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Médias'),
                isActive: _currentStep >= 3,
                content: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Ajoutez les photos de votre bien',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Formats acceptés: JPG, PNG',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('PARCOURIR'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_images.isNotEmpty) ...[
                      const Text(
                        'Photos sélectionnées',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _images.map((image) {
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(
                                  image.path,
                                ), // In flutter web/desktop XFile path might work, otherwise needs logic
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _images.remove(image);
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_images.length} image(s) sélectionnée(s)',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
