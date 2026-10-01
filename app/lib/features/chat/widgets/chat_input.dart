import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatInput extends StatefulWidget {
  final Future<void> Function(String text) onSend;
  final Future<void> Function(File photo)? onSendPhoto;
  final Future<void> Function(File video)? onSendVideo;
  final bool isSending;

  const ChatInput({
    super.key,
    required this.onSend,
    this.onSendPhoto,
    this.onSendVideo,
    this.isSending = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _controller = TextEditingController();
  final _picker = ImagePicker();
  bool _hasText = false;
  bool _isPickingMedia = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Text send ──────────────────────────────────────────────────────────────

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;

    _controller.clear();
    setState(() => _hasText = false);
    await widget.onSend(text);
  }

  // ── Media helpers ──────────────────────────────────────────────────────────

  bool get _isBusy => widget.isSending || _isPickingMedia;

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

  /// Shows a bottom sheet to choose photo or video from the gallery.
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
                child: Icon(Icons.videocam_rounded,
                    color: cs.secondary),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Camera button — takes a photo directly
          IconButton(
            icon: _isPickingMedia
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  )
                : Icon(Icons.camera_alt_outlined, color: cs.primary),
            onPressed:
                _isBusy ? null : () => _pickAndSendPhoto(ImageSource.camera),
          ),

          // Text input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: _controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message...',
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

          // Send / action buttons
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: _hasText
                // ── Send button ─────────────────────────────────────────────
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
                // ── Mic + Gallery buttons ───────────────────────────────────
                : Row(
                    key: const ValueKey('actions'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.mic_outlined, color: cs.primary),
                        onPressed: () {
                          // TODO: Voice recording (feat/voice-messages)
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.image_outlined, color: cs.primary),
                        onPressed:
                            _isBusy ? null : () => _showGalleryPicker(context),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
