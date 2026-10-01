import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ChatInput extends StatefulWidget {
  final Future<void> Function(String text) onSend;
  final Future<void> Function(File photo)? onSendPhoto;
  final Future<void> Function(File video)? onSendVideo;
  final Future<void> Function(File audio)? onSendVoice;
  final bool isSending;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onSendPhoto,
    this.onSendVideo,
    this.onSendVoice,
    this.isSending = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  final _recorder = AudioRecorder();

  bool _hasText = false;
  bool _isPickingMedia = false;

  // Recording state
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _recorder.dispose();
    _recordingTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Text ───────────────────────────────────────────────────────────────────

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    _controller.clear();
    setState(() => _hasText = false);
    await widget.onSend(text);
  }

  // ── Media ──────────────────────────────────────────────────────────────────

  bool get _isBusy => widget.isSending || _isPickingMedia || _isRecording;

  Future<void> _pickAndSendPhoto(ImageSource source) async {
    if (_isBusy) return;
    setState(() => _isPickingMedia = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked != null && widget.onSendPhoto != null) {
        await widget.onSendPhoto!(File(picked.path));
      }
    } finally {
      if (mounted) setState(() => _isPickingMedia = false);
    }
  }

  Future<void> _pickAndSendVideo(ImageSource source) async {
    if (_isBusy) return;
    setState(() => _isPickingMedia = true);
    try {
      final picked = await _picker.pickVideo(source: source);
      if (picked != null && widget.onSendVideo != null) {
        await widget.onSendVideo!(File(picked.path));
      }
    } finally {
      if (mounted) setState(() => _isPickingMedia = false);
    }
  }

  void _showGalleryPicker(BuildContext context) {
    if (_isBusy) return;
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.image_rounded, color: cs.primary),
              ),
              title: const Text('Photo'),
              subtitle: const Text('Send a photo from your gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.secondaryContainer,
                child:
                    Icon(Icons.videocam_rounded, color: cs.secondary),
              ),
              title: const Text('Video'),
              subtitle: const Text('Send a video from your gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendVideo(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Voice recording ────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (_isBusy) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to record voice messages.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingSeconds++);
    });
  }

  Future<void> _stopAndSend() async {
    _recordingTimer?.cancel();
    final path = await _recorder.stop();
    setState(() => _isRecording = false);

    if (path != null && widget.onSendVoice != null) {
      await widget.onSendVoice!(File(path));
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    await _recorder.stop();
    // Delete the file — we don't want to send it
    setState(() {
      _isRecording = false;
      _recordingSeconds = 0;
    });
  }

  String get _formattedDuration {
    final m = _recordingSeconds ~/ 60;
    final s = _recordingSeconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: cs.outline.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: _isRecording
          ? _buildRecordingBar(cs, theme)
          : _buildInputBar(cs, theme),
    );
  }

  // Recording bar: [✕ cancel]  ● 0:05  [✓ send]
  Widget _buildRecordingBar(ColorScheme cs, ThemeData theme) {
    return Row(
      children: [
        // Cancel button
        IconButton(
          icon: Icon(Icons.close_rounded, color: cs.onSurface.withValues(alpha: 0.5)),
          onPressed: _cancelRecording,
          tooltip: 'Cancel',
        ),
        // Pulsing dot + duration
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _pulseController,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formattedDuration,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Recording…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        // Send button
        IconButton(
          icon: widget.isSending
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                )
              : Icon(Icons.check_circle_rounded, color: cs.primary, size: 32),
          onPressed: widget.isSending ? null : _stopAndSend,
          tooltip: 'Send voice message',
        ),
      ],
    );
  }

  // Normal input bar
  Widget _buildInputBar(ColorScheme cs, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Camera button
        IconButton(
          icon: _isPickingMedia
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: cs.primary),
                )
              : Icon(Icons.camera_alt_outlined, color: cs.primary),
          onPressed:
              _isBusy ? null : () => _pickAndSendPhoto(ImageSource.camera),
        ),

        // Text field
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: TextField(
              controller: _controller,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Message…',
                filled: true,
                fillColor: cs.onSurface.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
        ),
        const SizedBox(width: 4),

        // Send / mic+gallery buttons
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: _hasText
              ? IconButton(
                  key: const ValueKey('send'),
                  icon: widget.isSending
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        )
                      : Icon(Icons.send_rounded, color: cs.primary),
                  onPressed: _isBusy ? null : _handleSend,
                )
              : Row(
                  key: const ValueKey('actions'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mic — tap to start recording
                    IconButton(
                      icon: Icon(Icons.mic_outlined, color: cs.primary),
                      onPressed: _isBusy ? null : _startRecording,
                    ),
                    // Gallery picker
                    IconButton(
                      icon: Icon(Icons.image_outlined, color: cs.primary),
                      onPressed: _isBusy
                          ? null
                          : () => _showGalleryPicker(context),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
