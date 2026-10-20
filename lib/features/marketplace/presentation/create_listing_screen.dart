import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/models/listing.dart';
import '../../../core/services/marketplace_repository.dart';
import '../../../core/state/session_controller.dart';
import '../../../core/theme/app_theme.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _location = TextEditingController();
  final TextEditingController _contact = TextEditingController();

  String _category = listingCategories.first;
  Uint8List? _imageBytes;
  bool _posting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _location.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final Uint8List? bytes = result?.files.single.bytes;
    if (bytes != null) setState(() => _imageBytes = bytes);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String userId = sessionController.profile?.id ?? '';
    if (userId.isEmpty) return;

    setState(() => _posting = true);
    final MarketplaceRepository repo = const MarketplaceRepository();
    try {
      String? imageUrl;
      if (_imageBytes != null) {
        imageUrl = await repo.uploadImage(userId, _imageBytes!);
      }
      await repo.create(
        userId: userId,
        title: _title.text,
        description: _description.text,
        priceNaira: double.tryParse(_price.text.trim()) ?? 0,
        category: _category,
        location: _location.text,
        contactInfo: _contact.text,
        imageUrl: imageUrl,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(SessionController.describeError(error))),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Sell something')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: <Widget>[
            GestureDetector(
              onTap: _pickImage,
              child: AspectRatio(
                aspectRatio: 1.4,
                child: ClipRRect(
                  borderRadius: AppRadii.lg,
                  child: Container(
                    color: AppColours.surfaceMuted,
                    child: _imageBytes == null
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  color: AppColours.textFaint,
                                  size: 32,
                                ),
                                SizedBox(height: AppSpacing.sm),
                                Text('Add a photo (optional)'),
                              ],
                            ),
                          )
                        : Image.memory(_imageBytes!, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Title', style: text.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _title,
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Category', style: text.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: listingCategories.map((String c) {
                return ChoiceChip(
                  label: Text(c[0].toUpperCase() + c.substring(1)),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Price (₦)', style: text.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              validator: (String? v) =>
                  (v == null || double.tryParse(v.trim()) == null)
                      ? 'Enter a number'
                      : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Description', style: text.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(controller: _description, minLines: 3, maxLines: 6),
            const SizedBox(height: AppSpacing.lg),
            Text('Location', style: text.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(hintText: 'e.g. Enugu'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Contact (phone or email)', style: text.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _contact,
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _posting ? null : _submit,
              child: _posting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    )
                  : const Text('Post listing'),
            ),
          ],
        ),
      ),
    );
  }
}
