import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../../../core/utils/image_filter_math.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../shared/widgets/liquid_glass.dart';

class TextOverlayItem {
  String id;
  String text;
  Offset position; // relative offset (x, y)
  Color color;
  Color? backgroundColor;
  double fontSize;
  bool hasBackground;

  TextOverlayItem({
    required this.id,
    required this.text,
    this.position = const Offset(50, 50),
    this.color = Colors.white,
    this.backgroundColor = Colors.black54,
    this.fontSize = 24.0,
    this.hasBackground = true,
  });
}

class PhotoEditorScreen extends StatefulWidget {
  final XFile initialImage;

  const PhotoEditorScreen({
    super.key,
    required this.initialImage,
  });

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  final GlobalKey _previewKey = GlobalKey();

  // Active filter & adjustments
  FilterPreset _selectedPreset = ImageFilterMath.presets[0];
  double _brightness = 0.0;   // -100 to 100
  double _contrast = 1.0;     // 0.5 to 2.0
  double _saturation = 1.0;   // 0.0 to 2.0
  int _rotationQuarterTurns = 0; // 0, 1, 2, 3

  // Active editor tab: 0 = Filters, 1 = Adjustments, 2 = Text Overlays
  int _activeTab = 0;

  // Text overlays
  final List<TextOverlayItem> _textOverlays = [];

  bool _isSaving = false;

  List<double> get _computedMatrix {
    return ImageFilterMath.buildCustomMatrix(
      baseMatrix: _selectedPreset.matrix,
      brightness: _brightness,
      contrast: _contrast,
      saturation: _saturation,
    );
  }

  void _rotateImage() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _resetAdjustments() {
    setState(() {
      _brightness = 0.0;
      _contrast = 1.0;
      _saturation = 1.0;
      _selectedPreset = ImageFilterMath.presets[0];
    });
  }

  void _showAddTextDialog([TextOverlayItem? existingItem]) {
    final TextEditingController textController =
        TextEditingController(text: existingItem?.text ?? '');
    Color selectedColor = existingItem?.color ?? Colors.white;
    bool hasBg = existingItem?.hasBackground ?? true;
    double fontSize = existingItem?.fontSize ?? 24.0;

    final List<Color> palette = [
      Colors.white,
      Colors.black,
      Colors.yellowAccent,
      Colors.redAccent,
      Colors.cyanAccent,
      Colors.lightGreenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
    ];

    showBubbleModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return LiquidGlassContainer(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              blur: 20,
              hasBlur: true,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 16,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        existingItem != null ? 'Edit Text' : 'Add Text Overlay',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(PhosphorIconsRegular.x, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    style: TextStyle(
                      color: selectedColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type your caption or quote...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Color Palette
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: palette.map((color) {
                      final isSelected = selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          SafeHaptics.selectionClick();
                          setModalState(() => selectedColor = color);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white24,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Background Style & Font Size
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                        children: [
                            const Flexible(
                              child: Text(
                                'Highlight Pill',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Switch(
                            value: hasBg,
                            activeTrackColor: Colors.white.withValues(alpha: 0.5),
                            activeThumbColor: Colors.white,
                            onChanged: (val) {
                              SafeHaptics.lightImpact();
                              setModalState(() => hasBg = val);
                            },
                          ),
                        ],
                      ),
                      ),
                      SizedBox(
                        width: 140,
                        child: Row(
                          children: [
                            const Icon(PhosphorIconsRegular.textT, size: 18, color: Colors.white70),
                            Expanded(
                              child: Slider(
                                value: fontSize,
                                min: 14,
                                max: 42,
                                activeColor: Colors.white,
                                onChanged: (v) => setModalState(() => fontSize = v),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LiquidGlassButton(
                    label: existingItem != null ? 'Update' : 'Add to Photo',
                    isPrimary: true,
                    onPressed: () {
                      final text = textController.text.trim();
                      if (text.isNotEmpty) {
                        setState(() {
                          if (existingItem != null) {
                            existingItem.text = text;
                            existingItem.color = selectedColor;
                            existingItem.hasBackground = hasBg;
                            existingItem.fontSize = fontSize;
                          } else {
                            _textOverlays.add(
                              TextOverlayItem(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                text: text,
                                color: selectedColor,
                                hasBackground: hasBg,
                                fontSize: fontSize,
                                position: const Offset(80, 150),
                              ),
                            );
                          }
                        });
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _exportAndSave() async {
    setState(() => _isSaving = true);
    try {
      final boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Preview boundary not ready');

      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to extract byte data');

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final String editedPath =
          '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final File savedFile = File(editedPath);
      await savedFile.writeAsBytes(pngBytes);

      if (!mounted) return;

      final choice = await showBubbleModalBottomSheet<String>(
        context: context,
        builder: (ctx) => LiquidGlassContainer(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          blur: 20,
          hasBlur: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Save Options',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(PhosphorIconsRegular.copy, color: Colors.white, size: 20),
                  ),
                  title: const Text('Save as new photo (Copy)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Keeps original and adds a new photo to your device gallery',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    SafeHaptics.lightImpact();
                    Navigator.pop(ctx, 'copy');
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(PhosphorIconsRegular.checkCircle, color: Colors.white, size: 20),
                  ),
                  title: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Save changes to this photo',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  onTap: () {
                    SafeHaptics.lightImpact();
                    Navigator.pop(ctx, 'save');
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      );

      if (choice == null) {
        // User cancelled save dialog
        return;
      }

      if (choice == 'copy') {
        try {
          await PhotoManager.editor.saveImage(
            pngBytes,
            filename: 'Bubble_Edited_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        } catch (saveErr) {
          debugPrint('Save to device gallery error: $saveErr');
        }
      }

      if (mounted) {
        Navigator.pop(context, XFile(savedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save edited photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: LiquidGlassAppBar(
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.caretLeft, color: Colors.white, size: 22),
          onPressed: () {
            SafeHaptics.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Edit',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.crop, color: Colors.white, size: 20),
            tooltip: 'Rotate 90°',
            onPressed: () {
              SafeHaptics.lightImpact();
              _rotateImage();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: LiquidGlassButton(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              label: 'Done',
              isPrimary: true,
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _exportAndSave,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. High-Performance Photo Canvas with Real-Time Matrix Transformations & Overlays
          Expanded(
            child: Center(
              child: RepaintBoundary(
                key: _previewKey,
                child: RotatedBox(
                  quarterTurns: _rotationQuarterTurns,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Active Filtered Image
                      ColorFiltered(
                        colorFilter: ColorFilter.matrix(_computedMatrix),
                        child: Image.file(
                          File(widget.initialImage.path),
                          fit: BoxFit.contain,
                        ),
                      ),

                      // Interactive Draggable Text Overlays
                      ..._textOverlays.map((item) {
                        return Positioned(
                          left: item.position.dx,
                          top: item.position.dy,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                item.position = Offset(
                                  (item.position.dx + details.delta.dx).clamp(0.0, 360.0),
                                  (item.position.dy + details.delta.dy).clamp(0.0, 600.0),
                                );
                              });
                            },
                            onTap: () => _showAddTextDialog(item),
                            onLongPress: () {
                              setState(() {
                                _textOverlays.remove(item);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: item.hasBackground ? Colors.black.withValues(alpha: 0.65) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                item.text,
                                style: TextStyle(
                                  color: item.color,
                                  fontSize: item.fontSize,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.black.withValues(alpha: 0.8),
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Active Tab Sub-Controls (Filters / Adjustments / Text)
          LiquidGlassContainer(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            blur: 20,
            hasBlur: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_activeTab == 0) _buildFiltersCarousel(),
                  if (_activeTab == 1) _buildAdjustmentsControls(),
                  if (_activeTab == 2) _buildTextControls(),
                  const SizedBox(height: 8),
                  // Tab Selection Bar (Filters, Adjust, Text)
                  _buildBottomTabBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUB-CONTROLS: FILTERS
  // ---------------------------------------------------------------------------
  Widget _buildFiltersCarousel() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: ImageFilterMath.presets.length,
        itemBuilder: (context, index) {
          final preset = ImageFilterMath.presets[index];
          final isSelected = _selectedPreset.id == preset.id;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPreset = preset;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              width: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white24,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(preset.matrix),
                        child: Image.file(
                          File(widget.initialImage.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    preset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUB-CONTROLS: ADJUSTMENTS (BRIGHTNESS, CONTRAST, SATURATION)
  // ---------------------------------------------------------------------------
  Widget _buildAdjustmentsControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          // Brightness Slider
          _buildSliderRow(
            label: 'Brightness',
            icon: Icons.wb_sunny_outlined,
            value: _brightness,
            min: -80,
            max: 80,
            displayValue: '${_brightness.round()}',
            onChanged: (v) => setState(() => _brightness = v),
          ),
          // Contrast Slider
          _buildSliderRow(
            label: 'Contrast',
            icon: Icons.contrast_rounded,
            value: _contrast,
            min: 0.5,
            max: 2.0,
            displayValue: '${((_contrast - 1.0) * 100).round()}%',
            onChanged: (v) => setState(() => _contrast = v),
          ),
          // Saturation Slider
          _buildSliderRow(
            label: 'Saturation',
            icon: Icons.palette_outlined,
            value: _saturation,
            min: 0.0,
            max: 2.0,
            displayValue: '${((_saturation - 1.0) * 100).round()}%',
            onChanged: (v) => setState(() => _saturation = v),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _resetAdjustments,
              icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Colors.white54),
              label: const Text('Reset', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(width: 8),
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            activeColor: Colors.white,
            inactiveColor: Colors.white24,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            displayValue,
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // SUB-CONTROLS: TEXT OVERLAYS
  // -------------------------------------------------------------
  Widget _buildTextControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showAddTextDialog(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Text'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          if (_textOverlays.isNotEmpty) ...[
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => setState(() => _textOverlays.clear()),
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
              label: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // BOTTOM TAB BAR (FILTERS / ADJUST / TEXT)
  // -------------------------------------------------------------
  Widget _buildBottomTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12, width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem(index: 0, label: 'Filters', icon: PhosphorIconsRegular.sparkle),
          _buildTabItem(index: 1, label: 'Adjust', icon: PhosphorIconsRegular.slidersHorizontal),
          _buildTabItem(index: 2, label: 'Text', icon: PhosphorIconsRegular.textT),
        ],
      ),
    );
  }

  Widget _buildTabItem({required int index, required String label, required IconData icon}) {
    final isSelected = _activeTab == index;
    final color = isSelected ? Colors.white : Colors.white54;

    return GestureDetector(
      onTap: () {
        SafeHaptics.selectionClick();
        setState(() => _activeTab = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: isSelected
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1,
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
