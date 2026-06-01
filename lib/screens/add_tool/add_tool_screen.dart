import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tool_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tool_provider.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/custom_app_bar.dart';

class AddToolScreen extends StatefulWidget {
  const AddToolScreen({super.key});

  @override
  State<AddToolScreen> createState() => _AddToolScreenState();
}

class _AddToolScreenState extends State<AddToolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _storageService = StorageService();

  ToolCategory _selectedCategory = ToolCategory.powerTools;
  String? _selectedLocation;
  List<File> _selectedImages = [];

  final List<String> _locations = [
    'Dhaka', 'Gazipur', 'Savar', 'Narayanganj', 'Tongi',
    'Narsingdi', 'Chittagong', 'Sylhet', 'Rajshahi', 'Khulna',
    'Barisal', 'Rangpur', 'Mymensingh', 'Comilla', 'Other',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _storageService.pickMultipleImages(maxImages: 5);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages = [..._selectedImages, ...images]
            .take(5)
            .toList();
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final image = await _storageService.pickImageFromCamera();
    if (image != null) {
      setState(() {
        _selectedImages = [..._selectedImages, image].take(5).toList();
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submitTool() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add at least 1 image'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final auth = context.read<AppAuthProvider>();
    final toolProvider = context.read<ToolProvider>();

    final toolId = await toolProvider.addTool(
      name: _nameCtrl.text.trim(),
      category: _selectedCategory,
      pricePerDay: double.parse(_priceCtrl.text),
      description: _descCtrl.text.trim(),
      location: _selectedLocation ?? '',
      ownerId: auth.userId,
      ownerName: auth.userName,
      ownerImage: auth.userModel?.profileImage,
      imageFiles: _selectedImages,
    );

    if (mounted) {
      if (toolId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Tool listed successfully!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(toolProvider.error ?? 'Failed to add tool'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final toolProvider = context.watch<ToolProvider>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'List Your Tool'),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image Picker ─────────────────────────────────
                  _sectionTitle('Photos'),
                  const SizedBox(height: 4),
                  Text(
                    'Add up to 5 photos of your tool',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Add image button
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                width: 1.5,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    color: AppTheme.primaryColor, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  'Add Photo',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${_selectedImages.length}/5',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor.withOpacity(0.6),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Selected images
                        ..._selectedImages.asMap().entries.map((entry) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  image: DecorationImage(
                                    image: FileImage(entry.value),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 14,
                                child: GestureDetector(
                                  onTap: () => _removeImage(entry.key),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                              if (entry.key == 0)
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.primaryColor.withOpacity(0.85),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Cover',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 9),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Tool Name ────────────────────────────────────
                  _sectionTitle('Tool Name *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Bosch Power Drill',
                      prefixIcon: Icon(Icons.build_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Tool name is required';
                      if (val.trim().length < 3) return 'Name is too short';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Category ─────────────────────────────────────
                  _sectionTitle('Category *'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 42,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: ToolCategory.values.length,
                      itemBuilder: (_, i) {
                        final cat = ToolCategory.values[i];
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isSelected ? AppTheme.primaryGradient : null,
                              color: isSelected
                                  ? null
                                  : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(AppRadius.circular),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Text(
                              '${cat.emoji} ${cat.displayName}',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).textTheme.bodyMedium?.color,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Price ────────────────────────────────────────
                  _sectionTitle('Price per Day (৳) *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'e.g., 150',
                      prefixIcon: Icon(Icons.currency_exchange_rounded),
                      prefixText: '৳ ',
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Price is required';
                      final price = double.tryParse(val);
                      if (price == null) return 'Enter a valid price';
                      if (price <= 0) return 'Price must be greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Location ─────────────────────────────────────
                  _sectionTitle('Location *'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    decoration: const InputDecoration(
                      hintText: 'Select area',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    items: _locations
                        .map((loc) =>
                            DropdownMenuItem(value: loc, child: Text(loc)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedLocation = val),
                    validator: (val) =>
                        val == null ? 'Please select a location' : null,
                  ),
                  const SizedBox(height: 20),

                  // ── Description ──────────────────────────────────
                  _sectionTitle('Description *'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Describe the tool — condition, brand, what it\'s good for...',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.description_outlined),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Description is required';
                      if (val.trim().length < 20) return 'Please add more detail (min 20 chars)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Upload progress
                  if (toolProvider.isUploading)
                    Column(
                      children: [
                        LinearProgressIndicator(
                          value: toolProvider.uploadProgress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation(
                              AppTheme.primaryColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Uploading images... ${(toolProvider.uploadProgress * 100).toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  GradientButton(
                    text: 'List My Tool',
                    isLoading: toolProvider.isUploading,
                    onPressed: _submitTool,
                    icon: const Icon(Icons.upload_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.labelLarge);
  }

  void _showImageSourceDialog() {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 images allowed')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppTheme.primaryColor),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    color: AppTheme.secondaryColor),
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
