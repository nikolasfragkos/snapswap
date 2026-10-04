import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  
  XFile? _capturedImage;
  Uint8List? _capturedImageBytes;
  String _itemName = '';
  String _selectedCategory = '';
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = [
    {'value': 'Electronics', 'label': 'Ηλεκτρονικά'},
    {'value': 'Books', 'label': 'Βιβλία'},
    {'value': 'Sports', 'label': 'Αθλητικά'},
    {'value': 'Kitchen', 'label': 'Κουζίνα'},
    {'value': 'Fitness', 'label': 'Fitness'},
    {'value': 'Fashion', 'label': 'Μόδα'},
    {'value': 'Music', 'label': 'Μουσική'},
    {'value': 'Games', 'label': 'Παιχνίδια'},
  ];

  Future<void> _captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _setCapturedImage(image);
      }
    } catch (e) {
      _pickFromGallery();
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _setCapturedImage(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Σφάλμα: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _capturedImageBytes = null;
      _itemName = '';
      _selectedCategory = '';
    });
  }

  Future<void> _setCapturedImage(XFile image) async {
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() {
      _capturedImage = image;
      _capturedImageBytes = bytes;
    });
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Επίλεξε τι θέλεις σε αντάλλαγμα'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      HapticFeedback.mediumImpact();
      
      await context.read<AppProvider>().addItem(
        itemName: _itemName,
        category: 'General',
        wantsCategory: _selectedCategory,
        imageUrl: _capturedImage!.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Το αντικείμενό σου προστέθηκε!'),
                      Text(
                        'Αναζητούμε κοντινές ανταλλαγές...',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[600],
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );

        _retakePhoto();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Σφάλμα: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Snap Your Item',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (_capturedImage != null)
                    IconButton(
                      onPressed: _retakePhoto,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _capturedImage == null
                  ? _buildCameraView()
                  : _buildPreviewAndForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF374151),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    size: 80,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Τράβα φωτογραφία του αντικειμένου σου',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: _pickFromGallery,
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _captureImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewAndForm() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: _capturedImageBytes == null
                        ? const SizedBox.shrink()
                        : Image.memory(
                            _capturedImageBytes!,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _retakePhoto,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.refresh,
                          color: Colors.grey[700],
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Στοιχεία Αντικειμένου',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Συμπλήρωσε τα παρακάτω για να βρεις ανταλλαγές',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Τι προσφέρεις;',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'π.χ. Vintage φωτογραφική μηχανή',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        _itemName = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Παρακαλώ εισάγετε το όνομα του αντικειμένου';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Τι θέλεις σε αντάλλαγμα;',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory.isEmpty 
                              ? null 
                              : _selectedCategory,
                          hint: Text(
                            'Διάλεξε κατηγορία',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, 
                              color: Colors.grey[600]),
                          items: _categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category['value'],
                              child: Text(category['label']!),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value ?? '';
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Δημοσίευση & Εύρεση Ανταλλαγών',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
