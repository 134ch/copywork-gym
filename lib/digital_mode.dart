import 'package:flutter/material.dart';
import 'challenge_model.dart';
import 'data.dart';
import 'storage_service.dart';

class DigitalModeScreen extends StatefulWidget {
  final CopyworkChallenge challenge;

  const DigitalModeScreen({super.key, required this.challenge});

  @override
  State<DigitalModeScreen> createState() => _DigitalModeScreenState();
}

class _DigitalModeScreenState extends State<DigitalModeScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isMatch = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _checkMatch(String value) {
    setState(() {
      _isMatch = value == widget.challenge.content;
    });
  }

  // Build highlighted text with character-by-character comparison
  Widget _buildHighlightedText() {
    final targetText = widget.challenge.content;
    final userInput = _controller.text;
    final List<TextSpan> spans = [];

    for (int i = 0; i < targetText.length; i++) {
      Color textColor;

      if (i < userInput.length) {
        // User has typed this character
        if (userInput[i] == targetText[i]) {
          textColor = Colors.green; // Correct
        } else {
          textColor = Colors.red; // Incorrect
        }
      } else {
        textColor = Colors.grey.shade700; // Pending
      }

      spans.add(TextSpan(
        text: targetText[i],
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          height: 1.5,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  void _finishChallenge() async {
    if (_isMatch) {
      // Update the challenge in the global list
      final index =
          challenges.indexWhere((c) => c.dayId == widget.challenge.dayId);
      if (index != -1) {
        challenges[index] = widget.challenge.completeDigital();
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
        title: const Text('Digital Mode'),
      ),
      body: Column(
        children: [
          // Top Half: Challenge Content with highlighting
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey.shade100,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: _buildHighlightedText(),
              ),
            ),
          ),
          const Divider(height: 1),
          // Bottom Half: User Input
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      enableInteractiveSelection: false, // Disable paste
                      decoration: const InputDecoration(
                        hintText: 'Type the text exactly as shown above...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _checkMatch,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isMatch ? _finishChallenge : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMatch ? Colors.blue : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Finish'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
