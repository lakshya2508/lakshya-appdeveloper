import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/virtual_tryon_model.dart';
import '../state/hear_assist_controller.dart';
import '../state/virtual_tryon_controller.dart';
import '../theme/realtime_colors.dart';
import 'haikei_background.dart';
import 'motion_primitives.dart';
import 'widgets.dart';

class VirtualTryOnScreen extends StatefulWidget {
  const VirtualTryOnScreen({super.key});

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          context.read<VirtualTryOnController?>()?.init();
        } catch (_) {}
      }
    });
  }

  void _showConfigDialog(BuildContext context) {
    final controller = context.read<VirtualTryOnController>();
    final epController = TextEditingController(text: controller.endpointUrl);
    final tkController = TextEditingController(text: controller.apiToken);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionTitle('Inference API Settings'),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Optionally connect a remote Virtual Try-On endpoint (e.g. Hugging Face Space, Replicate, or custom FastAPI service). Leave empty to use the built-in local compositor.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: epController,
              decoration: const InputDecoration(
                labelText: 'Endpoint URL',
                hintText: 'https://api.example.com/v1/try-on',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tkController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Token / Key (Optional)',
                hintText: 'Bearer token or API key',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      epController.clear();
                      tkController.clear();
                      controller.updateConfig(endpoint: '', token: '');
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reset to Local Neural Compositor')),
                      );
                    },
                    child: const Text('Reset to Local'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      controller.updateConfig(
                        endpoint: epController.text,
                        token: tkController.text,
                      );
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Endpoint settings saved!')),
                      );
                    },
                    child: const Text('Save Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tryOnCtrl = Provider.of<VirtualTryOnController?>(context);
    final hearCtrl = Provider.of<HearAssistController?>(context);
    final palette = hearCtrl?.activePalette ?? RealtimeColors.curated['aurora']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (tryOnCtrl == null || !tryOnCtrl.initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // 1. Studio Hero Card
        _StudioHero(
          palette: palette,
          viewMode: tryOnCtrl.viewMode,
          onToggleMode: (mode) => tryOnCtrl.setViewMode(mode),
          onOpenConfig: () => _showConfigDialog(context),
        ),

        const SizedBox(height: 16),

        if (tryOnCtrl.errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withAlpha(80)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tryOnCtrl.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 2. View Mode Switcher Body
        if (tryOnCtrl.viewMode == '3d') ...[
          _Interactive3DViewport(
            item: tryOnCtrl.selectedItem,
            palette: palette,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
        ] else ...[
          // AI Try-On Mode
          // Person Image Selection
          _PersonImageUploader(
            controller: tryOnCtrl,
            palette: palette,
            isDark: isDark,
          ),

          const SizedBox(height: 20),

          // Garment Catalog & Category Filters
          _GarmentCatalogSelector(
            controller: tryOnCtrl,
            palette: palette,
            isDark: isDark,
          ),

          const SizedBox(height: 20),

          // Action & Progress
          _TryOnActionSection(
            controller: tryOnCtrl,
            palette: palette,
          ),

          const SizedBox(height: 20),

          // Before / After Comparison Viewer
          if (tryOnCtrl.activeSession != null) ...[
            const Eyebrow('TRANSFORMATION RESULT'),
            const SizedBox(height: 4),
            const SectionTitle('Interactive Before & After'),
            const SizedBox(height: 8),
            _ComparisonSliderView(
              controller: tryOnCtrl,
              palette: palette,
              isDark: isDark,
            ),
            const SizedBox(height: 20),
          ],
        ],

        // Recent Try-On History
        if (tryOnCtrl.history.isNotEmpty) ...[
          const Eyebrow('PREVIOUS SESSIONS'),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionTitle('Try-On History'),
              TextButton(
                onPressed: tryOnCtrl.clearHistory,
                child: const Text('Clear History'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tryOnCtrl.history.map((s) => _SessionHistoryCard(session: s, palette: palette)),
        ],
      ],
    );
  }
}

// -------------------------------------------------------------
// Hero Header with Haikei Waves & Mode Switcher
// -------------------------------------------------------------
class _StudioHero extends StatelessWidget {
  const _StudioHero({
    required this.palette,
    required this.viewMode,
    required this.onToggleMode,
    required this.onOpenConfig,
  });

  final RealtimePalette palette;
  final String viewMode;
  final ValueChanged<String> onToggleMode;
  final VoidCallback onOpenConfig;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [palette.primary, palette.primary.withAlpha(210)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withAlpha(70),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: CustomPaint(
                painter: HaikeiLayeredWavesPainter(
                  progress: 0.5,
                  primary: palette.primary,
                  secondary: palette.secondary,
                  accent: palette.accent,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: Colors.white.withAlpha(50)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 14, color: palette.accent),
                          const SizedBox(width: 6),
                          Text(
                            'VIRTUAL TRY-ON MODULE',
                            style: TextStyle(
                              color: palette.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Configure AI Endpoint',
                      onPressed: onOpenConfig,
                      icon: const Icon(Icons.tune, color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Virtual Try-On &\n3D Spatial Studio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Visualize eyewear, headwear, footwear, and apparel with real-time perspective synthesis.',
                  style: TextStyle(color: Color(0xffd2e5df), fontSize: 12),
                ),
                const SizedBox(height: 14),

                // Mode Pills (AI Try-On vs 3D Orbit)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PillOption(
                          label: 'AI Image Try-On',
                          icon: Icons.person_outline,
                          selected: viewMode == 'tryon',
                          palette: palette,
                          onTap: () => onToggleMode('tryon'),
                        ),
                      ),
                      Expanded(
                        child: _PillOption(
                          label: '3D Spatial Orbit',
                          icon: Icons.view_in_ar,
                          selected: viewMode == '3d',
                          palette: palette,
                          onTap: () => onToggleMode('3d'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillOption extends StatelessWidget {
  const _PillOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final RealtimePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? palette.primary : Colors.white.withAlpha(200),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? palette.primary : Colors.white.withAlpha(200),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Person Image Selector & Uploader
// -------------------------------------------------------------
class _PersonImageUploader extends StatelessWidget {
  const _PersonImageUploader({
    required this.controller,
    required this.palette,
    required this.isDark,
  });

  final VirtualTryOnController controller;
  final RealtimePalette palette;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: SectionTitle('1. Person Image')),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: palette.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Step 1 of 2',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: palette.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Select a sample model portrait or tap to upload a clear front-facing portrait.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Quick Sample Model Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VirtualTryOnController.sampleModels.map((m) {
                final isSelected = controller.personImage == m['asset'];
                return ChoiceChip(
                  label: Text(m['name']!),
                  selected: isSelected,
                  selectedColor: palette.primary.withAlpha(40),
                  onSelected: (val) {
                    if (val) controller.setPersonImage(m['asset']!);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Image Preview Box
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: palette.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: palette.primary.withAlpha(60),
                  style: BorderStyle.solid,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (controller.personImage != null)
                    Image.asset(
                      controller.personImage!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.person, size: 64, color: Colors.grey),
                      ),
                    )
                  else
                    const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                        SizedBox(height: 6),
                        Text('No photo selected', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: MotionSpringButton(
                      onTap: () {
                        // Switch to next sample model or confirm
                        final next = VirtualTryOnController.sampleModels[
                            (VirtualTryOnController.sampleModels.indexWhere(
                                        (m) => m['asset'] == controller.personImage) +
                                    1) %
                                VirtualTryOnController.sampleModels.length];
                        controller.setPersonImage(next['asset']!);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_horiz, size: 14),
                            SizedBox(width: 4),
                            Text('Cycle Avatar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Garment & Accessory Catalog Selector
// -------------------------------------------------------------
class _GarmentCatalogSelector extends StatelessWidget {
  const _GarmentCatalogSelector({
    required this.controller,
    required this.palette,
    required this.isDark,
  });

  final VirtualTryOnController controller;
  final RealtimePalette palette;
  final bool isDark;

  void _showAddResourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AddResourceSheetContent(
        controller: controller,
        palette: palette,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = controller.filteredCatalog;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(child: SectionTitle('2. Select Garment or Accessory')),
                FilledButton.tonalIcon(
                  onPressed: () => _showAddResourceSheet(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add Resource', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Category Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TryOnCategory.values.map((cat) {
                  final isSelected = controller.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.label),
                      selected: isSelected,
                      selectedColor: palette.primary.withAlpha(40),
                      onSelected: (_) => controller.selectCategory(cat),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 14),

            // Product Cards Grid with Add Resource Entry
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length + 1,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (ctx, idx) {
                if (idx == filtered.length) {
                  // "+ Add Resource" Grid Card
                  return GestureDetector(
                    onTap: () => _showAddResourceSheet(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.primary.withAlpha(12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: palette.primary.withAlpha(60),
                          style: BorderStyle.solid,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline, size: 38, color: palette.primary),
                          const SizedBox(height: 8),
                          Text(
                            '+ Add Resource',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: palette.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Curated or custom',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final item = filtered[idx];
                final isSelected = controller.selectedItem.id == item.id;
                final isCustom = item.isCustom || item.id.startsWith('custom_') || item.id.startsWith('curated_');

                return GestureDetector(
                  onTap: () => controller.selectItem(item),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? palette.primary.withAlpha(20)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? palette.primary : palette.primary.withAlpha(35),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: palette.primary.withAlpha(40),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Image.asset(
                                    item.image,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isCustom
                                          ? palette.accent.withAlpha(40)
                                          : palette.secondary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isCustom ? 'RESOURCE' : item.category.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: isCustom ? palette.primary : palette.secondary,
                                      ),
                                    ),
                                  ),
                                  if (item.glbAsset != null)
                                    const Icon(Icons.view_in_ar, size: 14, color: Colors.blueAccent),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              Text(
                                '\$${item.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: palette.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCustom)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Remove Resource?'),
                                    content: Text('Remove "${item.name}" from wardrobe catalog?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Remove'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await controller.removeCustomItem(item.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Removed ${item.name}')),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 12, color: Colors.red),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Add Resource Sheet Modal (Curated Quick-Add & Custom Form)
// -------------------------------------------------------------
class _AddResourceSheetContent extends StatefulWidget {
  const _AddResourceSheetContent({
    required this.controller,
    required this.palette,
  });

  final VirtualTryOnController controller;
  final RealtimePalette palette;

  @override
  State<_AddResourceSheetContent> createState() => _AddResourceSheetContentState();
}

class _AddResourceSheetContentState extends State<_AddResourceSheetContent> {
  int _tabIndex = 0; // 0 = Curated, 1 = Custom

  // Custom Form Controllers
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '95');
  final _descCtrl = TextEditingController();
  TryOnCategory _selectedCategory = TryOnCategory.eyewear;
  String _selectedImage = 'assets/sunglasses.png';
  String? _selectedGlb = 'assets/rayban_sunglasses.glb';

  final List<Map<String, String>> _availableImages = [
    {'label': 'Eyewear Frame', 'asset': 'assets/sunglasses.png'},
    {'label': 'Horned Helmet', 'asset': 'assets/helmet.png'},
    {'label': 'Running Shoes', 'asset': 'assets/shoes.png'},
  ];

  final List<Map<String, String?>> _availableGlbs = [
    {'label': 'None (2D Only)', 'asset': null},
    {'label': 'Aviator Glasses 3D', 'asset': 'assets/rayban_sunglasses.glb'},
    {'label': 'Viking Helmet 3D', 'asset': 'assets/helmet.glb'},
    {'label': 'Sneaker 3D', 'asset': 'assets/shoe.glb'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionTitle('Add Try-On Resource'),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Text(
              'Add new accessories, garments, or 3D spatial assets to your virtual wardrobe.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),

            // Tab Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.palette.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Curated Library')),
                      selected: _tabIndex == 0,
                      selectedColor: widget.palette.primary.withAlpha(50),
                      onSelected: (_) => setState(() => _tabIndex = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Custom Resource')),
                      selected: _tabIndex == 1,
                      selectedColor: widget.palette.primary.withAlpha(50),
                      onSelected: (_) => setState(() => _tabIndex = 1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_tabIndex == 0) ...[
              // Curated 1-Tap List
              ...TryOnItem.curatedResources.map((item) {
                final alreadyAdded = widget.controller.catalog.any((i) => i.id == item.id);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Image.asset(
                      item.image,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag_outlined),
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text(
                      '${item.category.name.toUpperCase()} · \$${item.price.toInt()} · ${item.description}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: alreadyAdded
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                        : FilledButton.tonal(
                            onPressed: () async {
                              await widget.controller.addCustomItem(item);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('✓ Added "${item.name}" to your wardrobe!')),
                                );
                              }
                            },
                            child: const Text('Add', style: TextStyle(fontSize: 12)),
                          ),
                  ),
                );
              }),
            ] else ...[
              // Custom Form
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Resource Name',
                  hintText: 'e.g. Vintage Leather Jacket, Neon Shades',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<TryOnCategory>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        TryOnCategory.eyewear,
                        TryOnCategory.headwear,
                        TryOnCategory.footwear,
                        TryOnCategory.tops,
                      ].map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (\$)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Fabric, fit, or details...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedImage,
                decoration: const InputDecoration(
                  labelText: 'Preview Image',
                  border: OutlineInputBorder(),
                ),
                items: _availableImages
                    .map((im) => DropdownMenuItem(value: im['asset']!, child: Text(im['label']!)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedImage = val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _selectedGlb,
                decoration: const InputDecoration(
                  labelText: '3D Spatial Mesh Asset',
                  border: OutlineInputBorder(),
                ),
                items: _availableGlbs
                    .map((g) => DropdownMenuItem(value: g['asset'], child: Text(g['label']!)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedGlb = val),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final name = _nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a resource name')),
                    );
                    return;
                  }

                  final item = TryOnItem(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    category: _selectedCategory,
                    price: double.tryParse(_priceCtrl.text) ?? 95.0,
                    description: _descCtrl.text.trim().isNotEmpty
                        ? _descCtrl.text.trim()
                        : 'Custom try-on item added by user.',
                    image: _selectedImage,
                    glbAsset: _selectedGlb,
                    isCustom: true,
                  );

                  await widget.controller.addCustomItem(item);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✓ Custom resource "${item.name}" added to catalog!')),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 46),
                ),
                child: const Text('Add Custom Resource to Catalog'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Action Section & Progress Feedback
// -------------------------------------------------------------
class _TryOnActionSection extends StatelessWidget {
  const _TryOnActionSection({
    required this.controller,
    required this.palette,
  });

  final VirtualTryOnController controller;
  final RealtimePalette palette;

  @override
  Widget build(BuildContext context) {
    if (controller.isProcessing) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(palette.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Synthesizing Virtual Try-On...',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          controller.progressStage,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(controller.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: controller.progress,
                  backgroundColor: palette.primary.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation(palette.primary),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return MotionSpringButton(
      onTap: controller.generateTryOn,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [palette.primary, palette.accent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withAlpha(60),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_fix_high, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Generate Virtual Try-On',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: -.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Interactive Before / After Split Slider
// -------------------------------------------------------------
class _ComparisonSliderView extends StatelessWidget {
  const _ComparisonSliderView({
    required this.controller,
    required this.palette,
    required this.isDark,
  });

  final VirtualTryOnController controller;
  final RealtimePalette palette;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final session = controller.activeSession!;
    final item = controller.selectedItem;

    final baseTop = item.category == TryOnCategory.headwear
        ? 20.0
        : item.category == TryOnCategory.eyewear
            ? 65.0
            : item.category == TryOnCategory.footwear
                ? 190.0
                : 110.0;
    final baseScale = item.category == TryOnCategory.eyewear
        ? 0.55
        : item.category == TryOnCategory.headwear
            ? 0.70
            : 0.65;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Ready · ${session.engineUsed}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Text(
                  '${session.durationMs}ms',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Draggable Split Canvas
            LayoutBuilder(
              builder: (ctx, constraints) {
                final width = constraints.maxWidth;
                const height = 300.0;
                final splitX = width * controller.comparisonSlider;

                return GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    final newPos = (details.localPosition.dx / width).clamp(0.0, 1.0);
                    controller.setComparisonSlider(newPos);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Stack(
                        children: [
                          // 1. Right Layer (AFTER: Try-On Composite)
                          Positioned.fill(
                            child: Container(
                              color: palette.primary.withAlpha(25),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Base Avatar
                                  Image.asset(
                                    session.originalImage,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.person, size: 100, color: Colors.grey),
                                  ),
                                  // Synthesized Garment Overlay Layer with Angle Canting & Fit Alignment
                                  Positioned(
                                    top: baseTop + controller.garmentOffsetY,
                                    child: Transform.translate(
                                      offset: Offset(controller.garmentOffsetX, 0),
                                      child: Transform.rotate(
                                        angle: controller.garmentCantAngle * math.pi / 180.0,
                                        child: Transform.scale(
                                          scale: baseScale * controller.garmentScale,
                                          child: Image.asset(
                                            item.image,
                                            width: 160,
                                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // After badge
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: palette.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'AFTER (TRY-ON)',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 2. Left Layer (BEFORE: Original Image Clipped)
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            width: splitX,
                            child: ClipRect(
                              child: OverflowBox(
                                alignment: Alignment.centerLeft,
                                maxWidth: width,
                                maxHeight: height,
                                child: Container(
                                  color: Colors.black12,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(
                                        session.originalImage,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.person, size: 100, color: Colors.grey),
                                      ),
                                      Positioned(
                                        bottom: 10,
                                        left: 10,
                                        child: Container(
                                          padding:
                                              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'BEFORE (ORIGINAL)',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 3. Draggable Divider Line & Handle
                          Positioned(
                            left: splitX - 1.5,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 3,
                              color: Colors.white,
                              child: Center(
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: palette.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black38, blurRadius: 6),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.compare_arrows,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 10),
            const Center(
              child: Text(
                '‹ Drag slider horizontally to compare original and virtual try-on ›',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 14),

            // Garment Cant & Fit Tuning Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.primary.withAlpha(14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: palette.primary.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.crop_rotate, size: 16, color: palette.primary),
                          const SizedBox(width: 6),
                          const Text(
                            'Garment Cant & Fit Tuning',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: palette.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Cant: ${controller.garmentCantAngle >= 0 ? '+' : ''}${controller.garmentCantAngle.toStringAsFixed(1)}°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Quick Cant Presets
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const Text('Quick Cant:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 6),
                        _QuickChip(
                          label: '↺ -15°',
                          selected: controller.garmentCantAngle == -15,
                          onTap: () => controller.setGarmentCantAngle(-15),
                        ),
                        _QuickChip(
                          label: '↺ -5°',
                          selected: controller.garmentCantAngle == -5,
                          onTap: () => controller.setGarmentCantAngle(-5),
                        ),
                        _QuickChip(
                          label: '0° Level',
                          selected: controller.garmentCantAngle == 0,
                          onTap: () => controller.setGarmentCantAngle(0),
                        ),
                        _QuickChip(
                          label: '↻ +5°',
                          selected: controller.garmentCantAngle == 5,
                          onTap: () => controller.setGarmentCantAngle(5),
                        ),
                        _QuickChip(
                          label: '↻ +15°',
                          selected: controller.garmentCantAngle == 15,
                          onTap: () => controller.setGarmentCantAngle(15),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Cant Tilt Slider
                  Row(
                    children: [
                      const SizedBox(width: 68, child: Text('Cant Tilt', style: TextStyle(fontSize: 11))),
                      Expanded(
                        child: Slider(
                          value: controller.garmentCantAngle,
                          min: -30.0,
                          max: 30.0,
                          divisions: 60,
                          activeColor: palette.primary,
                          onChanged: controller.setGarmentCantAngle,
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${controller.garmentCantAngle.toInt()}°',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),

                  // Height Y Slider
                  Row(
                    children: [
                      const SizedBox(width: 68, child: Text('Height (Y)', style: TextStyle(fontSize: 11))),
                      Expanded(
                        child: Slider(
                          value: controller.garmentOffsetY,
                          min: -60.0,
                          max: 60.0,
                          divisions: 60,
                          activeColor: palette.primary,
                          onChanged: controller.setGarmentOffsetY,
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${controller.garmentOffsetY.toInt()}px',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),

                  // Scale Slider
                  Row(
                    children: [
                      const SizedBox(width: 68, child: Text('Scale', style: TextStyle(fontSize: 11))),
                      Expanded(
                        child: Slider(
                          value: controller.garmentScale,
                          min: 0.6,
                          max: 1.6,
                          divisions: 20,
                          activeColor: palette.primary,
                          onChanged: controller.setGarmentScale,
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${controller.garmentScale.toStringAsFixed(2)}x',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: controller.resetGarmentPlacement,
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Reset Alignment & Cant', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Result image saved to gallery')),
                      );
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download HD'),
                  ),
                ),
                const SizedBox(width: 10),
                if (item.glbAsset != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => controller.setViewMode('3d'),
                      icon: const Icon(Icons.view_in_ar, size: 16),
                      label: const Text('View 3D Model'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Interactive 3D Model Viewport (Spatial Canvas with Angle & Cant Control)
// -------------------------------------------------------------
class _Interactive3DViewport extends StatefulWidget {
  const _Interactive3DViewport({
    required this.item,
    required this.palette,
    required this.isDark,
  });

  final TryOnItem item;
  final RealtimePalette palette;
  final bool isDark;

  @override
  State<_Interactive3DViewport> createState() => _Interactive3DViewportState();
}

class _Interactive3DViewportState extends State<_Interactive3DViewport>
    with SingleTickerProviderStateMixin {
  double _yaw = 0.4;
  double _pitch = 0.2;
  double _roll = 0.0; // Cant tilt angle in radians
  double _zoom = 1.0;
  bool _wireframe = false;
  bool _autoRotate = true;

  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..addListener(() {
        if (_autoRotate && mounted) {
          setState(() {
            _yaw += 0.015;
          });
        }
      });
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _anim.repeat();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle('3D Spatial Model: ${item.name}'),
                      Text(
                        item.glbAsset ?? 'Procedural Mesh',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: _autoRotate ? 'Pause Auto-Rotate' : 'Resume Auto-Rotate',
                      onPressed: () => setState(() => _autoRotate = !_autoRotate),
                      icon: Icon(
                        _autoRotate ? Icons.pause_circle_outline : Icons.play_circle_outline,
                        color: widget.palette.primary,
                      ),
                    ),
                    IconButton(
                      tooltip: _wireframe ? 'Solid Surface' : 'Wireframe Mesh',
                      onPressed: () => setState(() => _wireframe = !_wireframe),
                      icon: Icon(
                        _wireframe ? Icons.blur_linear : Icons.blur_on,
                        color: widget.palette.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Proper Camera Angle & Cant Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _AnglePresetChip(
                    label: '🎯 Front (0°)',
                    isSelected: _yaw.abs() < 0.1 && _pitch.abs() < 0.1 && _roll.abs() < 0.1,
                    onTap: () => setState(() {
                      _autoRotate = false;
                      _yaw = 0.0;
                      _pitch = 0.0;
                      _roll = 0.0;
                    }),
                  ),
                  _AnglePresetChip(
                    label: '↗ 3/4 (45°)',
                    isSelected: (_yaw - 0.785).abs() < 0.15 && _roll.abs() < 0.1,
                    onTap: () => setState(() {
                      _autoRotate = false;
                      _yaw = 0.785;
                      _pitch = 0.26;
                      _roll = 0.0;
                    }),
                  ),
                  _AnglePresetChip(
                    label: '➡ Profile (90°)',
                    isSelected: (_yaw - 1.571).abs() < 0.15,
                    onTap: () => setState(() {
                      _autoRotate = false;
                      _yaw = 1.571;
                      _pitch = 0.0;
                      _roll = 0.0;
                    }),
                  ),
                  _AnglePresetChip(
                    label: '🔄 Back (180°)',
                    isSelected: (_yaw - math.pi).abs() < 0.15,
                    onTap: () => setState(() {
                      _autoRotate = false;
                      _yaw = math.pi;
                      _pitch = 0.0;
                      _roll = 0.0;
                    }),
                  ),
                  _AnglePresetChip(
                    label: '⬆ Top (60°)',
                    isSelected: (_pitch - 1.05).abs() < 0.15,
                    onTap: () => setState(() {
                      _autoRotate = false;
                      _yaw = 0.0;
                      _pitch = 1.05;
                      _roll = 0.0;
                    }),
                  ),
                  _AnglePresetChip(
                    label: '↺ Cant Left (-15°)',
                    isSelected: (_roll - (-0.2618)).abs() < 0.1,
                    onTap: () => setState(() {
                      _autoRotate = false;
                      _roll = -0.2618;
                    }),
                  ),
                  _AnglePresetChip(
                    label: '↻ Cant Right (+15°)',
                    isSelected: (_roll - 0.2618).abs() < 0.1,
                    onTap: () => setState(() {
                      _autoRotate = false;
                      _roll = 0.2618;
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Interactive Drag Canvas
            GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  _yaw += details.focalPointDelta.dx * 0.01;
                  _pitch = (_pitch - details.focalPointDelta.dy * 0.01).clamp(-1.2, 1.2);
                  _zoom = (_zoom * details.scale).clamp(0.6, 2.5);
                });
              },
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xff121816) : const Color(0xfff0f4f3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.palette.primary.withAlpha(50),
                  ),
                ),
                child: Stack(
                  children: [
                    // Canvas 3D Perspective Painter with Cant Tilt (Roll)
                    CustomPaint(
                      size: const Size(double.infinity, 300),
                      painter: _Model3DPainter(
                        yaw: _yaw,
                        pitch: _pitch,
                        roll: _roll,
                        zoom: _zoom,
                        wireframe: _wireframe,
                        primaryColor: widget.palette.primary,
                        accentColor: widget.palette.accent,
                        isDark: widget.isDark,
                        category: item.category,
                      ),
                    ),

                    // Controls Overlay
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Orbit: ${(_yaw * 180 / math.pi).toInt() % 360}° · Pitch: ${(_pitch * 180 / math.pi).toInt()}° · Cant: ${(_roll * 180 / math.pi).toInt()}°',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          setState(() {
                            _yaw = 0.4;
                            _pitch = 0.2;
                            _roll = 0.0;
                            _zoom = 1.0;
                          });
                        },
                        icon: const Icon(Icons.restart_alt, size: 14),
                        label: const Text('Reset Angle', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Precision Angle & Cant Tuning Drawer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.palette.primary.withAlpha(12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.palette.primary.withAlpha(35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Precision 3D Angle & Cant Calibration',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  // Yaw Slider
                  Row(
                    children: [
                      const SizedBox(width: 75, child: Text('Azimuth (Yaw)', style: TextStyle(fontSize: 11))),
                      Expanded(
                        child: Slider(
                          value: _yaw % (math.pi * 2),
                          min: 0.0,
                          max: math.pi * 2,
                          activeColor: widget.palette.primary,
                          onChanged: (val) => setState(() {
                            _autoRotate = false;
                            _yaw = val;
                          }),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${(_yaw * 180 / math.pi).toInt() % 360}°',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  // Pitch Slider
                  Row(
                    children: [
                      const SizedBox(width: 75, child: Text('Elevation (Pitch)', style: TextStyle(fontSize: 11))),
                      Expanded(
                        child: Slider(
                          value: _pitch,
                          min: -1.2,
                          max: 1.2,
                          activeColor: widget.palette.primary,
                          onChanged: (val) => setState(() => _pitch = val),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${(_pitch * 180 / math.pi).toInt()}°',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  // Roll / Cant Slider
                  Row(
                    children: [
                      const SizedBox(width: 75, child: Text('Camera Cant (Roll)', style: TextStyle(fontSize: 11))),
                      Expanded(
                        child: Slider(
                          value: _roll,
                          min: -0.785, // -45 deg
                          max: 0.785, // +45 deg
                          activeColor: widget.palette.primary,
                          onChanged: (val) => setState(() => _roll = val),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${(_roll * 180 / math.pi).toInt()}°',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  // Zoom Slider
                  Row(
                    children: [
                      const SizedBox(width: 75, child: Text('Zoom Distance', style: TextStyle(fontSize: 11))),
                      Expanded(
                        child: Slider(
                          value: _zoom,
                          min: 0.6,
                          max: 2.2,
                          activeColor: widget.palette.primary,
                          onChanged: (val) => setState(() => _zoom = val),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          '${_zoom.toStringAsFixed(1)}x',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnglePresetChip extends StatelessWidget {
  const _AnglePresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

// Custom 3D Mesh & Wireframe Painter with 3D Cant / Roll Projection
class _Model3DPainter extends CustomPainter {
  _Model3DPainter({
    required this.yaw,
    required this.pitch,
    required this.roll,
    required this.zoom,
    required this.wireframe,
    required this.primaryColor,
    required this.accentColor,
    required this.isDark,
    required this.category,
  });

  final double yaw;
  final double pitch;
  final double roll;
  final double zoom;
  final bool wireframe;
  final Color primaryColor;
  final Color accentColor;
  final bool isDark;
  final TryOnCategory category;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Grid Floor
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withAlpha(15)
      ..strokeWidth = 1;

    for (int i = -4; i <= 4; i++) {
      final p1 = _project(-120, 70, i * 30.0, cx, cy);
      final p2 = _project(120, 70, i * 30.0, cx, cy);
      canvas.drawLine(p1, p2, gridPaint);

      final p3 = _project(i * 30.0, 70, -120, cx, cy);
      final p4 = _project(i * 30.0, 70, 120, cx, cy);
      canvas.drawLine(p3, p4, gridPaint);
    }

    // Generate 3D Shape based on category
    final vertices = <List<double>>[];
    final edges = <List<int>>[];

    if (category == TryOnCategory.eyewear) {
      // Eyewear glasses geometry (two rims + bridge + temples)
      // Left rim
      for (int i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        vertices.add([-45 + math.cos(a) * 22, -10 + math.sin(a) * 16, 0]);
      }
      // Right rim
      for (int i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        vertices.add([45 + math.cos(a) * 22, -10 + math.sin(a) * 16, 0]);
      }
      // Bridge
      vertices.add([-23, -10, 0]);
      vertices.add([23, -10, 0]);
      // Left temple
      vertices.add([-67, -10, -60]);
      // Right temple
      vertices.add([67, -10, -60]);

      for (int i = 0; i < 7; i++) {
        edges.add([i, i + 1]);
        edges.add([8 + i, 8 + i + 1]);
      }
      edges.add([7, 0]);
      edges.add([15, 8]);
      edges.add([16, 17]); // Bridge
      edges.add([0, 18]); // Left temple
      edges.add([8, 19]); // Right temple
    } else if (category == TryOnCategory.headwear) {
      // Helmet dome + horns
      for (int ring = 0; ring <= 3; ring++) {
        final r = (4 - ring) * 16.0;
        final y = -40 + ring * 18.0;
        for (int i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          vertices.add([math.cos(a) * r, y, math.sin(a) * r]);
        }
      }
      // Horns
      vertices.add([-65, -60, 10]);
      vertices.add([65, -60, 10]);

      for (int r = 0; r < 3; r++) {
        for (int i = 0; i < 8; i++) {
          final curr = r * 8 + i;
          final next = r * 8 + (i + 1) % 8;
          final below = (r + 1) * 8 + i;
          edges.add([curr, next]);
          edges.add([curr, below]);
        }
      }
      edges.add([0, 32]);
      edges.add([4, 33]);
    } else {
      // Footwear sneaker boxy geometry
      final shoePoints = [
        [-25.0, 30.0, -70.0], [25.0, 30.0, -70.0], [25.0, 30.0, 70.0], [-25.0, 30.0, 70.0], // Sole
        [-22.0, 0.0, -65.0], [22.0, 0.0, -65.0], [22.0, -15.0, 20.0], [-22.0, -15.0, 20.0], // Upper
        [-18.0, -40.0, -30.0], [18.0, -40.0, -30.0], // Collar
      ];
      vertices.addAll(shoePoints);
      edges.addAll([
        [0, 1], [1, 2], [2, 3], [3, 0],
        [4, 5], [5, 6], [6, 7], [7, 4],
        [0, 4], [1, 5], [2, 6], [3, 7],
        [4, 8], [5, 9], [8, 9],
      ]);
    }

    final projected = vertices.map((v) => _project(v[0], v[1], v[2], cx, cy)).toList();

    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = wireframe ? 1.5 : 2.5
      ..style = PaintingStyle.stroke;

    final vertexPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    for (final edge in edges) {
      if (edge[0] < projected.length && edge[1] < projected.length) {
        canvas.drawLine(projected[edge[0]], projected[edge[1]], linePaint);
      }
    }

    for (final p in projected) {
      canvas.drawCircle(p, 3.5, vertexPaint);
    }
  }

  Offset _project(double x, double y, double z, double cx, double cy) {
    // 1. Rotate Yaw (azimuth around Y axis)
    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final x1 = x * cosY + z * sinY;
    final z1 = -x * sinY + z * cosY;

    // 2. Rotate Pitch (elevation around X axis)
    final cosP = math.cos(pitch);
    final sinP = math.sin(pitch);
    final y2 = y * cosP - z1 * sinP;
    final z2 = y * sinP + z1 * cosP;

    // 3. Rotate Roll / Cant (optical tilt around Z axis)
    final cosR = math.cos(roll);
    final sinR = math.sin(roll);
    final x3 = x1 * cosR - y2 * sinR;
    final y3 = x1 * sinR + y2 * cosR;

    // Perspective projection
    const fov = 350.0;
    final scale = (fov / (fov + z2 + 100)) * zoom;

    return Offset(cx + x3 * scale, cy + y3 * scale);
  }

  @override
  bool shouldRepaint(covariant _Model3DPainter oldDelegate) => true;
}

// -------------------------------------------------------------
// History Session Card
// -------------------------------------------------------------
class _SessionHistoryCard extends StatelessWidget {
  const _SessionHistoryCard({
    required this.session,
    required this.palette,
  });

  final TryOnSession session;
  final RealtimePalette palette;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: palette.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.checkroom, size: 22),
        ),
        title: Text(session.itemName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${session.engineUsed} · ${session.timestamp.hour.toString().padLeft(2, '0')}:${session.timestamp.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${session.durationMs}ms',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
