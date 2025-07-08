import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';
import 'package:sensors_plus/sensors_plus.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const EmotionMusicApp());
}

class EmotionMusicApp extends StatelessWidget {
  const EmotionMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emotion Music Player',
      theme: ThemeData.dark(),
      home: const EmotionHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EmotionHomePage extends StatefulWidget {
  const EmotionHomePage({super.key});

  @override
  State<EmotionHomePage> createState() => _EmotionHomePageState();
}

class _EmotionHomePageState extends State<EmotionHomePage> with TickerProviderStateMixin {
  late CameraController _cameraController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _emotion = 'Neutral';
  bool _loading = false;
  bool _cameraReady = false;
  bool _isPlaying = false;

  Map<String, List<Color>> emotionGradients = {
    'Happy': [Colors.yellow.shade300, Colors.orange.shade700],
    'Sad': [Colors.blueGrey.shade800, Colors.indigo.shade900],
    'Angry': [Colors.deepOrange.shade800, Colors.red.shade900],
    'Neutral': [Colors.grey.shade600, Colors.blueGrey.shade800],
    'Surprise': [Colors.purple.shade400, Colors.pink.shade600],
    'Fear': [Colors.black, Colors.grey.shade800],
    'Disgust': [Colors.green.shade800, Colors.lime.shade600],
  };

  final Map<String, String> emotionMusic = {
    'Happy': 'assets/music/happy.mp3',
    'Sad': 'assets/music/sad.mp3',
    'Angry': 'assets/music/angry.mp3',
    'Neutral': 'assets/music/neutral.mp3',
    'Surprise': 'assets/music/surprise.mp3',
    'Fear': 'assets/music/fear.mp3',
    'Disgust': 'assets/music/disgust.mp3',
  };
  double _x = 0, _y = 0;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  late AnimationController _waveGlowController;
  late Animation<double> _waveGlow;
  late AnimationController _jumpController;
  late Animation<Offset> _jumpAnimation;
  bool _glowReady = false;

  @override
  void initState() {
    super.initState();
    accelerometerEventStream().listen((event) {
      setState(() {
        _x = event.x.clamp(-10.0, 10.0);
        _y = event.y.clamp(-10.0, 10.0);
      });
    });
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.linear),
    );

    _waveGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _waveGlow = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _waveGlowController, curve: Curves.easeInOut),
    );

    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _jumpAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.05),
    ).chain(CurveTween(curve: Curves.easeInOut)).animate(_jumpController);

    _jumpController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _jumpController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _jumpController.forward();
      }
    });

    setState(() => _glowReady = true);

    _initializeApp();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _audioPlayer.dispose();
    _glowController.dispose();
    _waveGlowController.dispose();
    _jumpController.dispose();
    super.dispose();
  }

  Color getAutoTextColor(List<Color> gradientColors) {
    final avgColor = Color.lerp(gradientColors.first, gradientColors.last, 0.5)!;
    final luminance = avgColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Color getAccentColor(String emotion) {
    switch (emotion) {
      case 'Happy':
        return Colors.deepOrange;
      case 'Sad':
        return Colors.blueAccent;
      case 'Angry':
        return Colors.redAccent;
      case 'Surprise':
        return Colors.pinkAccent;
      case 'Fear':
        return Colors.grey;
      case 'Disgust':
        return Colors.limeAccent;
      case 'Neutral':
      default:
        return Colors.greenAccent;
    }
  }

  BoxShadow neonGlow(Color color) {
    return BoxShadow(
      color: color.withValues(alpha: 0.8),
      blurRadius: 16,
      spreadRadius: 1,
      offset: const Offset(0, 0),
    );
  }

  Future<void> _initializeApp() async {
    try {
      await _initCamera();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Init Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _initCamera() async {
    try {
      final frontCam = cameras.firstWhere(
            (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCam,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController.initialize();

      setState(() => _cameraReady = true);
    } catch (e) {
      throw Exception('Camera initialization failed: $e');
    }
  }

  Future<void> _sendFrame() async {
    try {
      setState(() => _loading = true);
      _jumpController.forward();  // start jumping

      final image = await _cameraController.takePicture();
      final bytes = await image.readAsBytes();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://emotionrecognitionflask.onrender.com/predict'),
      );
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: 'frame.jpg'));
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);
      final detectedEmotion = data['emotion'];

      if (_emotion != detectedEmotion) {
        setState(() => _emotion = detectedEmotion);
        await _playEmotionMusic(detectedEmotion);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      _jumpController.stop(); // stop jumping
      setState(() => _loading = false);
    }
  }

  Future<void> _playEmotionMusic(String emotion) async {
    try {
      final path = emotionMusic[emotion] ?? emotionMusic['Neutral']!;
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(path.replaceFirst('assets/', '')));
      setState(() => _isPlaying = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Audio error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_glowReady) return const SizedBox();
    final textColor = getAutoTextColor(emotionGradients[_emotion] ?? [Colors.black, Colors.grey.shade900]);
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: double.infinity,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_y * 0.01)
          ..rotateY(_x * 0.01),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: emotionGradients[_emotion] ?? [Colors.black, Colors.grey.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '🎵 Emotion-Aware Music Player',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      shadows: [
                        Shadow(blurRadius: 10, color: getAccentColor(_emotion), offset: Offset(0, 0)),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: textColor.computeLuminance() > 0.5
                          ? Colors.black.withValues(alpha: 3) // for light text like white
                          : Colors.white.withValues(alpha: 2), // for dark text like black
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: getAccentColor(_emotion), width: 1.5),
                    ),
                    child: Text(
                      'Detected Emotion: $_emotion',
                      style: TextStyle(fontSize: 18, color: textColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_cameraReady)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: getAccentColor(_emotion), width: 2),
                        ),
                        child: CameraPreview(_cameraController),
                      ),
                    )
                  else
                    CircularProgressIndicator(color: getAccentColor(_emotion)),
                  const SizedBox(height: 20),
                  SlideTransition(
                    position: _loading ? _jumpAnimation : AlwaysStoppedAnimation(Offset.zero),
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _sendFrame,
                      icon: Icon(Icons.camera_alt, color: textColor),
                      label: Text(
                        _loading ? "Detecting..." : "Capture Emotion",
                        style: TextStyle(color: textColor),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: textColor.computeLuminance() > 0.5
                            ? const Color(0xFF000000).withValues(alpha: 180)
                            : const Color(0xFFFFFFFF).withValues(alpha: 25),
                        elevation: 14,
                        shadowColor: getAccentColor(_emotion),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(color: getAccentColor(_emotion), width: 2),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: getAccentColor(_emotion).withAlpha(30),
                      border: Border.all(
                        color: getAccentColor(_emotion),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: getAccentColor(_emotion).withAlpha(40),
                          blurRadius: 10 + (_glowAnimation.value * 1.5),
                          spreadRadius: 1.2,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Emotion + Lottie wave
                        Row(
                          children: [
                            Icon(Icons.music_note, color: getAccentColor(_emotion)),
                            const SizedBox(width: 6),
                            Text(
                              _emotion,
                              style: TextStyle(
                                color: getAutoTextColor(emotionGradients[_emotion] ?? [Colors.black]),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_isPlaying)
                              AnimatedBuilder(
                                animation: _waveGlow,
                                builder: (context, child) {
                                  return ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      getAccentColor(_emotion).withValues(alpha: _waveGlow.value),
                                      BlendMode.modulate,
                                    ),
                                    child: Lottie.asset(
                                      'assets/animations/sound_wave.json',
                                      height: 30,
                                      width: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.stop_circle_outlined),
                              iconSize: 30,
                              color: Colors.redAccent,
                              onPressed: () async {
                                await _audioPlayer.stop();
                                setState(() => _isPlaying = false);
                              },
                            ),
                            Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateX(_y * 0.007)
                                ..rotateY(_x * 0.007),
                              alignment: Alignment.center,
                              child: IconButton(
                                icon: Icon(
                                  _isPlaying ? Icons.pause_circle : Icons.play_circle,
                                  color: getAccentColor(_emotion),
                                ),
                                iconSize: 34,
                                onPressed: () async {
                                  if (_isPlaying) {
                                    await _audioPlayer.pause();
                                  } else {
                                    await _audioPlayer.resume();
                                  }
                                  setState(() => _isPlaying = !_isPlaying);
                                },
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
