import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/property_provider.dart';
import '../widgets/property_card.dart';
import '../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(filteredPropertiesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Recherche',
          style: TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.primary),
            onPressed: () {
              // TODO: Show advanced filter bottom sheet
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une ville...',
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                ref
                    .read(searchFilterProvider.notifier)
                    .update((state) => {...state, 'city': value});
              },
            ),
          ),

          // Filter Chips (Property Type)
          const PropertyTypeFilters(),

          const Divider(height: 32, color: AppColors.border),

          // Properties List
          Expanded(
            child: propertiesAsync.when(
              data: (properties) {
                if (properties.isEmpty) {
                  return const Center(child: Text('No properties found.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: properties.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return PropertyCard(
                      property: properties[index],
                      onTap: () {
                        context.push('/property/${properties[index].id}');
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class PropertyTypeFilters extends ConsumerWidget {
  const PropertyTypeFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(searchFilterProvider);
    final types = ['', 'house', 'apartment', 'land', 'office'];
    final labels = ['All', 'House', 'Apartment', 'Land', 'Office'];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: types.length,
        itemBuilder: (context, index) {
          final isSelected = filters['type'] == types[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              backgroundColor: Colors.white,
              label: Text(labels[index]),
              selected: isSelected,
              onSelected: (selected) {
                ref
                    .read(searchFilterProvider.notifier)
                    .update((state) => {...state, 'type': types[index]});
              },
              selectedColor: AppColors.primary.withOpacity(0.1),
              checkmarkColor: AppColors.primary,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.muted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
