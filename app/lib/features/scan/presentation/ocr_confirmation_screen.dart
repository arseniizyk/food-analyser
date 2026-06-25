import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../analysis/presentation/analysis_result_bottom_sheet.dart';
import '../domain/scan_session.dart';
import 'scan_controller.dart';

class OcrConfirmationScreen extends ConsumerStatefulWidget {
  const OcrConfirmationScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<OcrConfirmationScreen> createState() =>
      _OcrConfirmationScreenState();
}

class _OcrConfirmationScreenState extends ConsumerState<OcrConfirmationScreen> {
  final TextEditingController _ingredientsController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _ingredientsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(scanControllerProvider, (previous, next) {
      if (ModalRoute.of(context)?.isCurrent != true) {
        return;
      }

      final session = next.value;
      final analysis = session?.analysis;

      if (session?.step == ScanStep.completed && analysis != null) {
        showAnalysisResultBottomSheet(
          context: context,
          analysisId: analysis.id,
          onScanAnother: () {
            Navigator.of(context).pop();
            ref.read(scanControllerProvider.notifier).reset();
            context.go('/app/scan');
          },
        );
      }
    });

    final scanState = ref.watch(scanControllerProvider);
    final session = scanState.value;

    if (!_initialized && session?.extractedText != null) {
      _ingredientsController.text = session!.extractedText!;
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm ingredients'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () =>
              context.go('/app/scan/ingredients/${widget.sessionId}'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _ImagePreview(imagePath: session?.ingredientsImagePath),
            const SizedBox(height: 16),
            _ConfidenceBanner(text: _ingredientsController.text),
            const SizedBox(height: 16),
            TextField(
              controller: _ingredientsController,
              minLines: 7,
              maxLines: 12,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Recognized ingredients',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            if (scanState.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  scanState.error.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton.icon(
              onPressed:
                  scanState.isLoading ||
                      _ingredientsController.text.trim().isEmpty
                  ? null
                  : () => ref
                        .read(scanControllerProvider.notifier)
                        .analyzeConfirmedIngredients(
                          _ingredientsController.text,
                        ),
              icon: scanState.isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(scanState.isLoading ? 'Analyzing...' : 'Analyze'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: scanState.isLoading
                  ? null
                  : () =>
                        context.go('/app/scan/ingredients/${widget.sessionId}'),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Retake photo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    final hasFile = path != null && !path.startsWith('/mock') && File(path).existsSync();

    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasFile
          ? Image.file(
              File(path),
              fit: BoxFit.cover,
              width: double.infinity,
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 88,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: const Icon(Icons.receipt_long),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Ingredients photo',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(path ?? 'No image available'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ConfidenceBanner extends StatelessWidget {
  const _ConfidenceBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final wordCount = text
        .split(RegExp(r'[\s,;]+'))
        .where((word) => word.trim().isNotEmpty)
        .length;
    final isLowConfidence = wordCount < 4;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLowConfidence
            ? const Color(0xFFFFF4D6)
            : const Color(0xFFE6F4EA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isLowConfidence
                ? Icons.warning_amber_outlined
                : Icons.check_circle_outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isLowConfidence
                  ? 'Needs review: OCR confidence is low or text is short.'
                  : 'Good recognition: review before analyzing.',
            ),
          ),
        ],
      ),
    );
  }
}
