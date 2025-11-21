import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'challenge_model.dart';
import 'data.dart';
import 'digital_mode.dart';
import 'analog_mode.dart';
import 'storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.loadProgress(challenges);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const paperColor = Color(0xFFFDFBF7);
    const inkColor = Color(0xFF2C2C2C);

    return MaterialApp(
      title: 'Copywork Gym',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paperColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: inkColor,
          primary: inkColor,
          surface: paperColor,
        ),
        cardTheme: const CardTheme(
          color: Colors.white,
          elevation: 2,
          surfaceTintColor: Colors.white, // Avoid tint on M3
        ),
        textTheme: GoogleFonts.merriweatherTextTheme().apply(
          bodyColor: inkColor,
          displayColor: inkColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: paperColor,
          elevation: 0,
          foregroundColor: inkColor,
          centerTitle: true,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    // Calculate Total Exp
    double totalExp = challenges.fold(0.0, (sum, item) => sum + item.score);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('Assets/logo.png', height: 32),
            const SizedBox(width: 12),
            const Text('Copywork Gym'),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Total Exp Section
          Container(
            padding: const EdgeInsets.all(24.0),
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Column(
              children: [
                Text(
                  'Total Experience',
                  style: GoogleFonts.merriweather(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  totalExp.toStringAsFixed(1), // Support decimals
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C2C2C),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Challenges List
          Expanded(
            child: ListView.builder(
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                return ChallengeTile(
                  challenge: challenge,
                  onReturn: () {
                    setState(() {});
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChallengeTile extends StatelessWidget {
  final CopyworkChallenge challenge;
  final VoidCallback? onReturn;

  const ChallengeTile({super.key, required this.challenge, this.onReturn});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              challenge.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exp: ${challenge.score}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Tooltip(
                      message:
                          'Analog: ${challenge.totalManualReps} | Digital: ${challenge.totalDigitalReps}',
                      triggerMode:
                          TooltipTriggerMode.tap, // For mobile long-press/tap
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Reps: ${challenge.totalReps}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (challenge.isCompleted)
                  const Icon(Icons.check_circle, color: Colors.green, size: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2C),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // Show Mode Selection Dialog
                    final mode = await showDialog<String>(
                      context: context,
                      builder: (BuildContext context) {
                        return SimpleDialog(
                          title: const Text('Choose your Mode'),
                          children: <Widget>[
                            SimpleDialogOption(
                              onPressed: () {
                                Navigator.pop(context, 'digital');
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                    'Digital (Type) +${challenge.potentialDigitalReward} Exp'),
                              ),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                Navigator.pop(context, 'analog');
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                    'Analog (Handwrite) +${challenge.potentialManualReward} Exp'),
                              ),
                            ),
                          ],
                        );
                      },
                    );

                    if (mode == null) return;

                    bool? result;
                    if (context.mounted) {
                      if (mode == 'digital') {
                        result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DigitalModeScreen(challenge: challenge),
                          ),
                        );
                      } else if (mode == 'analog') {
                        result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AnalogModeScreen(challenge: challenge),
                          ),
                        );
                      }
                    }

                    if (result == true && onReturn != null) {
                      onReturn!();
                    }
                  },
                  child: const Text('Start'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
