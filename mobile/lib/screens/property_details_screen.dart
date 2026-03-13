import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../models/property_model.dart';
import '../core/constants/app_colors.dart';
import 'package:intl/intl.dart';
import '../providers/property_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/auth_provider.dart';

class PropertyDetailsScreen extends ConsumerWidget {
  final String propertyId;

  const PropertyDetailsScreen({required this.propertyId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);
    final favoritesAsync = ref.watch(favoritesProvider);
    final authState = ref.watch(authProvider);
    final isFavorite = favoritesAsync.maybeWhen(
      data: (favorites) => favorites.any((fav) => fav.id == propertyId),
      orElse: () => false,
    );

    final currencyFormat = NumberFormat.currency(
      locale: 'fr',
      symbol: 'XOF',
      decimalDigits: 0,
    );

    return propertiesAsync.when(
      data: (properties) {
        final PropertyModel property;
        try {
          property = properties.firstWhere((p) => p.id == propertyId);
        } catch (e) {
          return Scaffold(body: const Center(child: Text('Property not found')));
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          body: CustomScrollView(
            slivers: [
              // Image Header
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                stretch: true,
                backgroundColor: AppColors.primary,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black26,
                    child: IconButton(
                      icon: const Icon(Icons.home, color: Colors.white),
                      onPressed: () => GoRouter.of(context).go('/search'),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        itemCount: property.images.isNotEmpty
                            ? property.images.length
                            : 1,
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            imageUrl: property.images.isNotEmpty
                                ? property.images[index]
                                : 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?ixlib=rb-4.0.3&auto=format&fit=crop&w=800&q=80',
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                      // Gradient overlay
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black38,
                              Colors.transparent,
                              Colors.black87,
                            ],
                            stops: [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  CircleAvatar(
                    backgroundColor: Colors.black26,
                    radius: 18,
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                        color: isFavorite ? Colors.red : Colors.white,
                        size: 20,
                      ),
                      onPressed: authState.user == null
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Veuillez vous connecter pour ajouter aux favoris'),
                                ),
                              );
                            }
                          : () async {
                              await ref.read(favoritesProvider.notifier).toggleFavorite(propertyId);
                            },
                    ),
                  ),
                  _buildCircleAction(Icons.share_rounded, () {}),
                  const SizedBox(width: 8),
                ],
              ),

              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -30, 0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type and Location
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                property.transactionType.name.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.location_on_rounded, size: 16, color: AppColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              property.location.city,
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Title
                        Text(
                          property.title,
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Price
                        Text(
                          currencyFormat.format(property.price),
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Divider(height: 1, thickness: 1, color: AppColors.border),
                        ),

                        // Features Row - Premium Style
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildPremiumFeature(Icons.king_bed_outlined, property.features.bedrooms.toString(), 'Chambres'),
                            _buildPremiumFeature(Icons.bathtub_outlined, property.features.bathrooms.toString(), 'Salles d\'eau'),
                            _buildPremiumFeature(Icons.square_foot_rounded, property.features.area.toString(), 'm²'),
                          ],
                        ),
                        
                        const SizedBox(height: 40),

                        // Description
                        Text(
                          'À propos de ce bien',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          property.description,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Location
                        Text(
                          'Emplacement',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.mutedLight,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.location_on, color: AppColors.primary, size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    property.location.address,
                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (property.ownerId.isNotEmpty) {
                        GoRouter.of(context).push('/chat/${property.ownerId}');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Impossible de contacter le propriétaire pour le moment.'),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text('CONTACTER L\'AGENT'),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () {
                    if (property.ownerId.isNotEmpty) {
                      GoRouter.of(context).push('/chat/${property.ownerId}');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Impossible de contacter le propriétaire pour le moment.'),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(body: const Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Erreur: $error'))),
    );
  }

  Widget _buildCircleAction(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: CircleAvatar(
        backgroundColor: Colors.black26,
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
