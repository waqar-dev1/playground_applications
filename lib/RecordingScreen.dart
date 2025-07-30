import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late AudioRecorder _audioRecorder;
  late RecorderController _waveformController;
  bool _isRecording = false;
  bool _isPaused = false;
  List<double> _webWaveformData = [];
  StreamSubscription? _amplitudeSubscription;
  int _recordingDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _waveformController = RecorderController();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration++;
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _recordingDuration = 0;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      try {
        var config = RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          sampleRate: 44100,
        );
        await _audioRecorder.start(config, path: 'recording.m4a');

        // Start waveform for Android/iOS
        if (!isWeb()) {
          await _waveformController.record(
            androidEncoder: AndroidEncoder.aac,
            androidOutputFormat: AndroidOutputFormat.mpeg4,
            iosEncoder: IosEncoder.kAudioFormatMPEG4AAC,
          );
        }

        _startTimer();
        setState(() {
          _isRecording = true;
          _isPaused = false;
        });
      } catch (e) {
        print('Error starting recording: $e');
      }
    }
  }

  Future<void> _pauseRecording() async {
    if (_isRecording && !_isPaused) {
      await _audioRecorder.pause();
      if (!isWeb()) {
        await _waveformController.pause();
      } else {
        _amplitudeSubscription?.pause();
      }
      _timer?.cancel();
      setState(() => _isPaused = true);
    }
  }

  Future<void> _resumeRecording() async {
    if (_isRecording && _isPaused) {
      await _audioRecorder.resume();
      if (!isWeb()) {
        await _waveformController.record();
      } else {
        _amplitudeSubscription?.resume();
      }
      _startTimer();
      setState(() => _isPaused = false);
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      await _audioRecorder.stop();
      if (!isWeb()) {
        await _waveformController.stop();
      }
      _stopTimer();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _webWaveformData.clear();
      });
    }
  }

  void _deleteRecording() {
    _stopRecording();
    // Add delete logic here
  }

  void _generateScript() {
    // Navigate to script generation screen
    Navigator.pushNamed(context, '/generate-script');
  }

  bool isWeb() => identical(0, 0.0);

  @override
  void dispose() {
    _audioRecorder.dispose();
    _waveformController.dispose();
    _amplitudeSubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _showOptionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                ChecklistItem(
                  title: 'ICD-10 coding',
                  isChecked: false,
                  onChanged: (value) {},
                ),
                ChecklistItem(
                  title: 'Add referral letter',
                  isChecked: true,
                  onChanged: (value) {},
                ),
                ChecklistItem(
                  title: 'Future follow-up plan',
                  isChecked: false,
                  onChanged: (value) {},
                ),
                ChecklistItem(
                  title: 'Abbreviated note',
                  isChecked: false,
                  onChanged: (value) {},
                ),
                ChecklistItem(
                  title: 'Include patient information leaflet',
                  isChecked: false,
                  onChanged: (value) {},
                ),
                ChecklistItem(
                  title: 'Operative Note',
                  isChecked: true,
                  onChanged: (value) {},
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            CustomHeaderWidget(),
            if (!_isRecording) _buildInitialState() else _buildRecordingState(),
            if (_isRecording) _buildChecklistSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Expanded(
      child: Column(
        children: [
          // Plus button positioned at top right
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, top: 20),
              child: GestureDetector(
                onTap: _showOptionsDialog,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.grey,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Voice in,',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  'meticulous notes out',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 60),
                StartSessionWidget(
                  onPressed: _startRecording,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingState() {
    return Expanded(
      child: Column(
        children: [
          // Plus button positioned at top right
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, top: 20),
              child: GestureDetector(
                onTap: _showOptionsDialog,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.grey,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Voice in,',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  'meticulous notes out',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 40),
                RecordingWidget(
                  isRecording: _isRecording,
                  isPaused: _isPaused,
                  duration: _formatDuration(_recordingDuration),
                  waveformController: _waveformController,
                  webWaveformData: _webWaveformData,
                  onPauseResume: _isPaused ? _resumeRecording : _pauseRecording,
                ),
                const SizedBox(height: 40),
                ActionButtonsWidget(
                  onDelete: _deleteRecording,
                  onGenerateScript: _generateScript,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChecklistItem(
            title: 'ICD-10 coding',
            isChecked: false,
            onChanged: (value) {},
          ),
          ChecklistItem(
            title: 'Add referral letter',
            isChecked: true,
            onChanged: (value) {},
          ),
          ChecklistItem(
            title: 'Future follow-up plan',
            isChecked: false,
            onChanged: (value) {},
          ),
          ChecklistItem(
            title: 'Abbreviated note',
            isChecked: false,
            onChanged: (value) {},
          ),
          ChecklistItem(
            title: 'Include patient information leaflet',
            isChecked: false,
            onChanged: (value) {},
          ),
          ChecklistItem(
            title: 'Operative Note',
            isChecked: true,
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }
}

class StartSessionWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const StartSessionWidget({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 200,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Start session',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Image.asset(
                'assets/icons/start_dictation.png',
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecordingWidget extends StatelessWidget {
  final bool isRecording;
  final bool isPaused;
  final String duration;
  final RecorderController waveformController;
  final List<double> webWaveformData;
  final VoidCallback onPauseResume;

  const RecordingWidget({
    super.key,
    required this.isRecording,
    required this.isPaused,
    required this.duration,
    required this.waveformController,
    required this.webWaveformData,
    required this.onPauseResume,
  });

  bool isWeb() => identical(0, 0.0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          isPaused ? 'Paused...' : 'Recording...',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          duration,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),
        // Waveform
        Container(
          height: 60,
          width: 280,
          child: isWeb()
              ? CustomPaint(
            painter: WebWaveformPainter(webWaveformData),
          )
              : AudioWaveforms(
            size: const Size(280, 60),
            recorderController: waveformController,
            waveStyle: const WaveStyle(
              waveColor: Colors.blue,
              showMiddleLine: true,
              middleLineColor: Colors.grey,
              middleLineThickness: 1,
              waveThickness: 3,
            ),
          ),
        ),
        const SizedBox(height: 30),
        // Pause/Resume button
        GestureDetector(
          onTap: onPauseResume,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isPaused ? Colors.blue : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }
}

class ActionButtonsWidget extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onGenerateScript;

  const ActionButtonsWidget({
    super.key,
    required this.onDelete,
    required this.onGenerateScript,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton(
          onPressed: onDelete,
          child: const Text(
            'Delete',
            style: TextStyle(
              color: Colors.blue,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onGenerateScript,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Generate Script',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ChecklistItem extends StatelessWidget {
  final String title;
  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  const ChecklistItem({
    super.key,
    required this.title,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: isChecked,
            onChanged: onChanged,
            activeColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomHeaderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Capture live consult',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Post-Visit dictation',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class WebWaveformPainter extends CustomPainter {
  final List<double> waveformData;

  WebWaveformPainter(this.waveformData);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Draw middle line
    final middleLinePaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      middleLinePaint,
    );

    if (waveformData.isEmpty) {
      // Draw default waveform bars when no data
      final barWidth = 3.0;
      final spacing = 6.0;
      final barCount = (size.width / (barWidth + spacing)).floor();

      for (int i = 0; i < barCount; i++) {
        final x = i * (barWidth + spacing);
        final height = (i % 3 + 1) * 10.0; // Varying heights
        final rect = Rect.fromLTWH(
          x,
          (size.height - height) / 2,
          barWidth,
          height,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
          paint,
        );
      }
      return;
    }

    final path = Path();
    final widthPerSample = size.width / waveformData.length;
    for (int i = 0; i < waveformData.length; i++) {
      final x = i * widthPerSample;
      final y = (1 - waveformData[i]) * size.height / 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}