import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../application/local_repository.dart';
import '../../../application/providers/app_providers.dart';
import '../../../domain/verification/verification_models.dart';
import '../../../infrastructure/l10n/l10n_ext.dart';

/// Result of return / lost condition capture before money settlement.
class ReturnConditionCapture {
  const ReturnConditionCapture({
    this.conditionNote,
    this.mediaIds = const <String>[],
    this.checklist,
  });

  final String? conditionNote;
  final List<String> mediaIds;
  final Map<String, bool>? checklist;
}

/// Shows condition capture UI based on [ConditionMode] before settlement.
Future<ReturnConditionCapture?> showReturnConditionSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String rentalId,
  required ConditionMode mode,
  required List<String> checklistItems,
  bool isLost = false,
}) async {
  if (mode == ConditionMode.basic) {
    return const ReturnConditionCapture();
  }
  return showModalBottomSheet<ReturnConditionCapture>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return _ReturnConditionSheet(
        rentalId: rentalId,
        mode: mode,
        checklistItems: checklistItems,
        isLost: isLost,
      );
    },
  );
}

class _ReturnConditionSheet extends ConsumerStatefulWidget {
  const _ReturnConditionSheet({
    required this.rentalId,
    required this.mode,
    required this.checklistItems,
    required this.isLost,
  });

  final String rentalId;
  final ConditionMode mode;
  final List<String> checklistItems;
  final bool isLost;

  @override
  ConsumerState<_ReturnConditionSheet> createState() =>
      _ReturnConditionSheetState();
}

class _ReturnConditionSheetState extends ConsumerState<_ReturnConditionSheet> {
  final TextEditingController _noteController = TextEditingController();
  final Map<String, bool> _checklist = <String, bool>{};
  final List<String> _mediaIds = <String>[];
  final List<Uint8List> _previews = <Uint8List>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final String item in widget.checklistItems) {
      _checklist[item] = false;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  int get _maxPhotos =>
      widget.mode == ConditionMode.advanced ? 3 : 1;

  Future<void> _pickPhoto() async {
    if (_mediaIds.length >= _maxPhotos) {
      return;
    }
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (file == null || !mounted) {
      return;
    }
    final Uint8List bytes = await file.readAsBytes();
    final LocalRepository repo = ref.read(repositoryProvider);
    final attachment = await repo.attachMedia(
      'rental',
      widget.rentalId,
      bytes,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _mediaIds.add(attachment.id);
      _previews.add(bytes);
    });
  }

  bool get _canContinue {
    if (widget.mode == ConditionMode.standard) {
      return true;
    }
    if (widget.mode == ConditionMode.advanced) {
      final bool checklistOk = widget.checklistItems.every(
        (String item) => _checklist[item] == true,
      );
      return checklistOk && _mediaIds.isNotEmpty;
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_canContinue || _saving) {
      return;
    }
    setState(() => _saving = true);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(
      ReturnConditionCapture(
        conditionNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        mediaIds: List<String>.from(_mediaIds),
        checklist: widget.mode == ConditionMode.advanced
            ? Map<String, bool>.from(_checklist)
            : null,
      ),
    );
  }

  String _checklistLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'scratches':
        return l10n.verificationChecklistScratches;
      case 'missingParts':
        return l10n.verificationChecklistMissingParts;
      case 'powersOn':
        return l10n.verificationChecklistPowersOn;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool advanced = widget.mode == ConditionMode.advanced;
    final bool standard = widget.mode == ConditionMode.standard || advanced;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.isLost
                  ? l10n.returnConditionLostTitle
                  : l10n.returnConditionTitle,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (standard)
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.returnConditionNoteLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            if (standard) const SizedBox(height: 12),
            if (standard || advanced)
              OutlinedButton.icon(
                onPressed: _mediaIds.length >= _maxPhotos ? null : _pickPhoto,
                icon: const Icon(Icons.photo_camera_outlined),
                label: Text(
                  l10n.returnConditionAddPhoto(_mediaIds.length, _maxPhotos),
                ),
              ),
            if (_previews.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _previews.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (BuildContext context, int index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _previews[index],
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            ],
            if (advanced) ...<Widget>[
              const SizedBox(height: 12),
              Text(l10n.returnConditionChecklistHeading, style: textTheme.titleSmall),
              ...widget.checklistItems.map(
                (String item) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_checklistLabel(l10n, item)),
                  value: _checklist[item] ?? false,
                  onChanged: (bool? value) {
                    setState(() => _checklist[item] = value ?? false);
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _canContinue && !_saving ? _submit : null,
              child: Text(l10n.continueAction),
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only thumbnail grid for rental detail evidence section.
class RentalMediaThumbnailGrid extends ConsumerWidget {
  const RentalMediaThumbnailGrid({
    super.key,
    required this.rentalId,
  });

  final String rentalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<MediaAttachment>>(
      future: ref.read(repositoryProvider).listMedia('rental', rentalId),
      builder: (BuildContext context, AsyncSnapshot<List<MediaAttachment>> snap) {
        final List<MediaAttachment> items = snap.data ?? const <MediaAttachment>[];
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (BuildContext context, int index) {
              return FutureBuilder<Uint8List?>(
                future: ref.read(repositoryProvider).readMediaBytes(items[index].id),
                builder: (BuildContext context, AsyncSnapshot<Uint8List?> bytes) {
                  if (!bytes.hasData || bytes.data == null) {
                    return const SizedBox(
                      width: 72,
                      height: 72,
                      child: ColoredBox(color: Colors.black12),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      bytes.data!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
