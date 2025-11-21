import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'challenge_model.dart';
import 'data.dart';
import 'storage_service.dart';

class AnalogModeScreen extends StatefulWidget {
  final CopyworkChallenge challenge;

  const AnalogModeScreen({super.key, required this.challenge});

  @override
  State<AnalogModeScreen> createState() => _AnalogModeScreenState();
}

class _AnalogModeScreenState extends State<AnalogModeScreen> {
  List<XFile> _currentSessionImages = [];
  List<List<String>> _pastSessions = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load past session history
    final history =
        await StorageService.loadSessionHistory(widget.challenge.dayId);

    if (mounted) {
      setState(() {
        _pastSessions = history;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _currentSessionImages.add(pickedFile);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _currentSessionImages.removeAt(index);
    });
  }

  void _completeChallenge() async {
    if (_currentSessionImages.isEmpty) return;

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Completion'),
        content: const Text(
            'Are you sure you have written this text by hand? Honesty is key to improvement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, I Wrote It'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Create a list of paths for the current session
      final currentPaths =
          _currentSessionImages.map((img) => img.path).toList();

      // Update history
      final newHistory = List<List<String>>.from(_pastSessions);
      newHistory.add(currentPaths);
      await StorageService.saveSessionHistory(
          widget.challenge.dayId, newHistory);

      // Update the challenge in the global list
      final index =
          challenges.indexWhere((c) => c.dayId == widget.challenge.dayId);
      if (index != -1) {
        // Pass the first image path as the thumbnail/evidence path
        challenges[index] =
            widget.challenge.completeManual(evidencePath: currentPaths.first);
        // Save progress
        await StorageService.saveProgress(challenges[index]);
      }
      if (mounted) {
        Navigator.pop(
            context, true); // Return true to indicate completion/update
      }
    }
  }

  Widget _buildImageThumbnail(String path, {VoidCallback? onRemove}) {
    return Stack(
      children: [
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb
                ? Image.network(
                    path,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image)),
                  )
                : Image.file(
                    File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image)),
                  ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analog Mode'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Challenge Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFBF7), // Paper-like off-white
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.challenge.content,
                        style: const TextStyle(
                          fontFamily: 'Georgia', // Serif font for analog feel
                          fontSize: 18,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Current Session Evidence
                    const Text(
                      "Evidence (Required)",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),

                    // Horizontal list of current session images
                    if (_currentSessionImages.isNotEmpty)
                      SizedBox(
                        height: 130,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _currentSessionImages.length +
                              1, // +1 for Add button
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            if (index == _currentSessionImages.length) {
                              // Add Page Button at the end
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () =>
                                          _pickImage(ImageSource.camera),
                                      icon: const Icon(Icons.add_a_photo),
                                      tooltip: "Add Page (Camera)",
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _pickImage(ImageSource.gallery),
                                      icon:
                                          const Icon(Icons.add_photo_alternate),
                                      tooltip: "Add Page (Gallery)",
                                    ),
                                  ],
                                ),
                              );
                            }
                            return _buildImageThumbnail(
                              _currentSessionImages[index].path,
                              onRemove: () => _removeImage(index),
                            );
                          },
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text("Take Photo"),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text("Gallery"),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Past Attempts Section
                    if (_pastSessions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        "Past Attempts",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pastSessions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final sessionImages = _pastSessions[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Attempt #${index + 1} (${sessionImages.length} Pages)",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 120,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: sessionImages.length,
                                  separatorBuilder: (context, i) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, i) {
                                    return _buildImageThumbnail(
                                        sessionImages[i]);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Complete Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _currentSessionImages.isNotEmpty
                    ? _completeChallenge
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: const Text('I Wrote This By Hand'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
