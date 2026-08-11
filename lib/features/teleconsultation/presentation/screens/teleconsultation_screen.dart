import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/api_endpoints.dart';

enum _CallStatus { idle, connecting, ringing, connected, ended }

class TeleconsultationScreen extends ConsumerStatefulWidget {
  final String appointmentId;
  final String? patientName;

  const TeleconsultationScreen({
    super.key,
    required this.appointmentId,
    this.patientName,
  });

  @override
  ConsumerState<TeleconsultationScreen> createState() =>
      _TeleconsultationScreenState();
}

class _TeleconsultationScreenState extends ConsumerState<TeleconsultationScreen>
    with SingleTickerProviderStateMixin {
  _CallStatus _status = _CallStatus.idle;
  int _durationSeconds = 0;
  Timer? _timer;

  // Camera
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _isMicOn = true;
  bool _isCameraOn = true;
  String? _cameraError;

  // Audio bars
  final _rand = Random();
  List<double> _barHeights = [0.3, 0.5, 0.7, 0.5, 0.3];
  Timer? _audioTimer;

  // Chat
  bool _showChat = false;
  final List<Map<String, String>> _chatMessages = [];
  final _chatController = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    _audioTimer?.cancel();
    _chatController.dispose();
    _stopCamera();
    super.dispose();
  }

  Future<void> _initCamera() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      if (mounted) {
        setState(() => _cameraError = 'Permissions caméra/micro refusées');
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraError = 'Aucune caméra disponible');
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraController!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'Erreur caméra: ${e.toString()}');
      }
    }
  }

  void _stopCamera() {
    _cameraController?.dispose();
    _cameraController = null;
    _cameraReady = false;
  }

  void _startAudioAnimation() {
    _audioTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!mounted || !_isMicOn || _status != _CallStatus.connected) return;
      setState(() {
        _barHeights = List.generate(5, (i) => 0.2 + _rand.nextDouble() * 0.8);
      });
    });
  }

  void _stopAudioAnimation() {
    _audioTimer?.cancel();
    _audioTimer = null;
    if (mounted) setState(() => _barHeights = [0.15, 0.15, 0.15, 0.15, 0.15]);
  }

  Future<void> _startCall() async {
    setState(() => _status = _CallStatus.connecting);
    await _initCamera();
    if (!mounted) return;

    setState(() => _status = _CallStatus.ringing);
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    setState(() => _status = _CallStatus.connected);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _durationSeconds++);
    });
    _startAudioAnimation();

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(ApiEndpoints.startVideo(widget.appointmentId));
    } catch (_) {}
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    _stopAudioAnimation();
    _stopCamera();
    if (mounted) setState(() => _status = _CallStatus.ended);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(ApiEndpoints.endVideo(widget.appointmentId));
    } catch (_) {}
  }

  void _toggleMic() {
    setState(() => _isMicOn = !_isMicOn);
    if (_isMicOn) {
      _startAudioAnimation();
    } else {
      _stopAudioAnimation();
    }
  }

  void _toggleCamera() {
    if (_cameraController == null || !_cameraReady) return;
    setState(() => _isCameraOn = !_isCameraOn);
    if (_isCameraOn) {
      _cameraController!.resumePreview();
    } else {
      _cameraController!.pausePreview();
    }
  }

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, min(2, name.length)).toUpperCase();
  }

  void _sendChat() {
    if (_chatController.text.trim().isEmpty) return;
    setState(() {
      _chatMessages.add({
        'sender': 'me',
        'text': _chatController.text.trim(),
        'time': TimeOfDay.now().format(context),
      });
    });
    _chatController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final patientLabel = widget.patientName ?? 'Patient';

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(patientLabel),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildVideoArea(patientLabel)),
                  if (_showChat && _status == _CallStatus.connected)
                    _buildChatPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String patientLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF161B22),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.close, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Téléconsultation',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                Text(patientLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          if (_status == _CallStatus.connected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(_durationSeconds),
                    style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoArea(String patientLabel) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_status == _CallStatus.idle)
          _buildIdleScreen()
        else if (_status == _CallStatus.connecting)
          _buildConnectingScreen()
        else if (_status == _CallStatus.ringing)
          _buildRingingScreen(patientLabel)
        else if (_status == _CallStatus.connected)
          _buildConnectedScreen(patientLabel)
        else if (_status == _CallStatus.ended)
          _buildEndedScreen(),
      ],
    );
  }

  Widget _buildIdleScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.videocam,
                  size: 40, color: Color(0xFFA78BFA)),
            ),
            const SizedBox(height: 24),
            const Text('Téléconsultation',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
                'Démarrez la séance pour rejoindre votre patient',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14)),
            if (_cameraError != null) ...[
              const SizedBox(height: 12),
              Text(_cameraError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _startCall,
              icon: const Icon(Icons.video_call),
              label: const Text('Démarrer la séance',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF7C3AED)),
          SizedBox(height: 20),
          Text('Connexion en cours...',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 8),
          Text('Démarrage de la caméra',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildRingingScreen(String patientLabel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(patientLabel),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(patientLabel,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('En attente de connexion...',
              style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 1.0),
                  duration: Duration(milliseconds: 600 + i * 200),
                  curve: Curves.easeInOut,
                  builder: (_, v, __) => Opacity(
                    opacity: v,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          color: Color(0xFF7C3AED), shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedScreen(String patientLabel) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Remote (patient) side — placeholder
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1B4B), Color(0xFF0D1117)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7C3AED),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(patientLabel),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(patientLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),

        // Audio bars — top right
        Positioned(
          top: 16,
          right: 16,
          child: _buildAudioBars(),
        ),

        // Local camera — bottom right
        Positioned(
          bottom: 100,
          right: 16,
          child: _buildLocalCamera(),
        ),

        // Controls — bottom center
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: _buildControls(),
        ),
      ],
    );
  }

  Widget _buildAudioBars() {
    final isActive = _isMicOn && _status == _CallStatus.connected;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(5, (i) {
        final height = isActive ? 8.0 + (_barHeights[i] * 24.0) : 4.0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 4,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF7C3AED)
                : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildLocalCamera() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 120,
        height: 90,
        child: !_isCameraOn
            ? Container(
                color: const Color(0xFF161B22),
                child: const Center(
                  child: Icon(Icons.videocam_off,
                      color: Colors.white54, size: 28),
                ),
              )
            : _cameraReady && _cameraController != null
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(-1.0, 1.0),
                    child: CameraPreview(_cameraController!),
                  )
                : Container(
                    color: const Color(0xFF161B22),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF7C3AED), strokeWidth: 2),
                    ),
                  ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Mic button with pulsing ring
        Stack(
          alignment: Alignment.center,
          children: [
            if (_isMicOn && _status == _CallStatus.connected)
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                ),
              ),
            _CircleButton(
              icon: _isMicOn ? Icons.mic : Icons.mic_off,
              isActive: _isMicOn,
              activeColor: const Color(0xFF7C3AED),
              onTap: _toggleMic,
            ),
          ],
        ),
        const SizedBox(width: 16),
        _CircleButton(
          icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
          isActive: _isCameraOn,
          activeColor: const Color(0xFF7C3AED),
          onTap: _toggleCamera,
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: _endCall,
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call_end, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(width: 16),
        _CircleButton(
          icon: Icons.chat_bubble_outline,
          isActive: _showChat,
          activeColor: const Color(0xFF7C3AED),
          onTap: () => setState(() => _showChat = !_showChat),
        ),
      ],
    );
  }

  Widget _buildEndedScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF7C3AED),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Séance terminée',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Durée : ${_formatDuration(_durationSeconds)}',
                style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retour aux rendez-vous'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPanel() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(left: BorderSide(color: Color(0xFF30363D))),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Chat',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          const Divider(color: Color(0xFF30363D), height: 1),
          Expanded(
            child: _chatMessages.isEmpty
                ? const Center(
                    child: Text('Aucun message',
                        style: TextStyle(color: Colors.white38, fontSize: 13)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _chatMessages.length,
                    itemBuilder: (_, i) {
                      final msg = _chatMessages[i];
                      return Align(
                        alignment: msg['sender'] == 'me'
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: msg['sender'] == 'me'
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF21262D),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(msg['text']!,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(color: Color(0xFF30363D), height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF21262D),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendChat(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendChat,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C3AED),
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.send, color: Colors.white, size: 16),
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

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.red.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.red[300],
          size: 26,
        ),
      ),
    );
  }
}
