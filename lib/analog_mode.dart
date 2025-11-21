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
  XFile? _evidenceImage;
  List<String> _pastImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load past images
    final history = await StorageService.loadImagePaths(widget.challenge.dayId);

    // Load current evidence if exists (only for non-web for now)
    XFile? currentEvidence;
    if (!kIsWeb && widget.challenge.evidenceImagePath != null) {
      final file = File(widget.challenge.evidenceImagePath!);
      if (file.existsSync()) {
        currentEvidence = XFile(widget.challenge.evidenceImagePath!);
      }
    }

    if (mounted) {
      setState(() {
        _pastImages = history;
        _evidenceImage = currentEvidence;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _evidenceImage = pickedFile;
        });
      }
    } catch (e) {
      // Handle error (e.g., permission denied)
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _evidenceImage = null;
    });
  }

  void _completeChallenge() async {
    if (_evidenceImage == null) return;

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
      // Update history
      final newHistory = List<String>.from(_pastImages);
      newHistory.add(_evidenceImage!.path);
      await StorageService.saveImagePaths(widget.challenge.dayId, newHistory);

      // Update the challenge in the global list
      final index =
          challenges.indexWhere((c) => c.dayId == widget.challenge.dayId);
      if (index != -1) {
        // Pass the image path to completeManual
        challenges[index] =
            widget.challenge.completeManual(evidencePath: _evidenceImage?.path);
        // Save progress
        await StorageService.saveProgress(challenges[index]);
      }
      if (mounted) {
        Navigator.pop(
            context, true); // Return true to indicate completion/update
      }
    }
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

                    // Evidence Section
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Evidence (Required)",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_evidenceImage == null)
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
                      )
                    else
                      Column(
                        children: [
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.network(
                                      _evidenceImage!.path,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_evidenceImage!.path),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.refresh, color: Colors.red),
                            label: const Text("Remove / Retake",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),

                    // Past Attempts Section
                    if (_pastImages.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Past Attempts",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _pastImages.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final path = _pastImages[index];
                            return Column(
                              children: [
                                Container(
                                  height: 120,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: kIsWeb
                                        ? Image.network(
                                            path,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Center(
                                                    child: Icon(
                                                        Icons.broken_image)),
                                          )
                                        : Image.file(
                                            File(path),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error,
                                                    stackTrace) =>
                                                const Center(
                                                    child: Icon(
                                                        Icons.broken_image)),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Attempt #${index + 1}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
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
                onPressed: _evidenceImage != null ? _completeChallenge : null,
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
