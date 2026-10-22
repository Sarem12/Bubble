import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Mathematical model for image filtering and digital signal processing.
/// Implements linear algebra, matrix transforms, point operations,
/// and convolution kernels directly over raw in-memory pixel buffers.
class FilterPreset {
  final String id;
  final String name;
  final IconData icon;
  final List<double> matrix; // 4x5 Color Matrix for 60fps GPU preview
  final String description;

  const FilterPreset({
    required this.id,
    required this.name,
    required this.icon,
    required this.matrix,
    required this.description,
  });
}

class ImageFilterMath {
  // ---------------------------------------------------------------------------
  // 1. 4x5 COLOR MATRICES (GPU PIPELINE FOR REAL-TIME 60FPS CAMERA & VIEWPORT)
  // ---------------------------------------------------------------------------

  /// Standard Identity Matrix (Raw Camera Buffer)
  static const List<double> identityMatrix = <double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  /// Luminance Grayscale: Gray = 0.2126R + 0.7152G + 0.0722B
  static const List<double> grayscaleMatrix = <double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ];

  /// High-Contrast Noir (Contrast scaling around midpoint 128 + Luminance)
  static const List<double> noirMatrix = <double>[
    0.35, 0.75, 0.10, 0, -35,
    0.35, 0.75, 0.10, 0, -35,
    0.35, 0.75, 0.10, 0, -35,
    0,    0,    0,    1, 0,
  ];

  /// Sepia / Vintage Photographic 3x3 Matrix:
  /// R' = 0.393R + 0.769G + 0.189B
  /// G' = 0.349R + 0.686G + 0.168B
  /// B' = 0.272R + 0.534G + 0.131B
  static const List<double> sepiaMatrix = <double>[
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0,     0,     0,     1, 0,
  ];

  /// Warm Golden Hour (Red/Yellow boost + slight exposure lift)
  static const List<double> warmMatrix = <double>[
    1.15, 0.00, 0.00, 0, 10,
    0.00, 1.05, 0.00, 0, 5,
    0.00, 0.00, 0.85, 0, -10,
    0.00, 0.00, 0.00, 1, 0,
  ];

  /// Cyberpunk Neon / Cool Cyan (Cyan & Magenta split-tone)
  static const List<double> cyberMatrix = <double>[
    1.10, 0.00, 0.10, 0, 5,
    0.00, 1.15, 0.15, 0, 10,
    0.10, 0.00, 1.30, 0, 20,
    0.00, 0.00, 0.00, 1, 0,
  ];

  /// Vivid / Pop (Saturation and micro-contrast amplification)
  static const List<double> vividMatrix = <double>[
    1.30, -0.15, -0.15, 0, 0,
    -0.15, 1.30, -0.15, 0, 0,
    -0.15, -0.15, 1.30, 0, 0,
    0.00,  0.00,  0.00, 1, 0,
  ];

  /// Invert / Digital Negative: R' = 255 - R
  static const List<double> invertMatrix = <double>[
    -1,  0,  0, 0, 255,
     0, -1,  0, 0, 255,
     0,  0, -1, 0, 255,
     0,  0,  0, 1, 0,
  ];

  /// Emerald Forest (Green channel luminance elevation)
  static const List<double> emeraldMatrix = <double>[
    0.85, 0.15, 0.00, 0, -10,
    0.05, 1.25, 0.05, 0, 15,
    0.00, 0.15, 0.85, 0, -10,
    0.00, 0.00, 0.00, 1, 0,
  ];

  /// High Contrast (Scalar factor = 1.6, anchor = 128)
  static const List<double> highContrastMatrix = <double>[
    1.6, 0,   0,   0, -76.8,
    0,   1.6, 0,   0, -76.8,
    0,   0,   1.6, 0, -76.8,
    0,   0,   0,   1, 0,
  ];

  /// List of All Built-In Filter Presets
  static const List<FilterPreset> presets = [
    FilterPreset(
      id: 'normal',
      name: 'Normal',
      icon: Icons.camera_rounded,
      matrix: identityMatrix,
      description: 'Raw uncompressed camera buffer without post-processing.',
    ),
    FilterPreset(
      id: 'vivid',
      name: 'Vivid',
      icon: Icons.flare_rounded,
      matrix: vividMatrix,
      description: 'High vibrance with amplified color separation matrix.',
    ),
    FilterPreset(
      id: 'warm',
      name: 'Golden',
      icon: Icons.wb_sunny_rounded,
      matrix: warmMatrix,
      description: 'Warm color grading with amber and red channel emphasis.',
    ),
    FilterPreset(
      id: 'cyber',
      name: 'Cyber',
      icon: Icons.electric_bolt_rounded,
      matrix: cyberMatrix,
      description: 'Futuristic cyan and magenta spectral grade.',
    ),
    FilterPreset(
      id: 'bw',
      name: 'B&W',
      icon: Icons.filter_b_and_w_rounded,
      matrix: grayscaleMatrix,
      description: 'Photometric luminance weighting (0.2126R + 0.7152G + 0.0722B).',
    ),
    FilterPreset(
      id: 'noir',
      name: 'Noir',
      icon: Icons.dark_mode_rounded,
      matrix: noirMatrix,
      description: 'High-contrast cinematic black and white with deep shadows.',
    ),
    FilterPreset(
      id: 'sepia',
      name: 'Sepia',
      icon: Icons.photo_filter_rounded,
      matrix: sepiaMatrix,
      description: 'Classic chemical print tone transformation.',
    ),
    FilterPreset(
      id: 'emerald',
      name: 'Emerald',
      icon: Icons.park_rounded,
      matrix: emeraldMatrix,
      description: 'Lush green luminance and organic forest tones.',
    ),
    FilterPreset(
      id: 'contrast',
      name: 'Punch',
      icon: Icons.contrast_rounded,
      matrix: highContrastMatrix,
      description: 'Dynamic range expansion around the 128 midpoint.',
    ),
    FilterPreset(
      id: 'invert',
      name: 'Negative',
      icon: Icons.invert_colors_rounded,
      matrix: invertMatrix,
      description: 'Per-channel inverted complement (255 - C).',
    ),
  ];

  // ---------------------------------------------------------------------------
  // 2. DYNAMIC MATRIX COMPOSITION (BRIGHTNESS, CONTRAST, SATURATION)
  // ---------------------------------------------------------------------------

  /// Creates a combined 4x5 color matrix applying:
  /// - Base preset matrix
  /// - Brightness offset (additive scalar: -100 to +100)
  /// - Contrast factor (multiplicative scaling around 128: 0.5 to 2.0)
  /// - Saturation multiplier (color distance from luminance: 0.0 to 2.0)
  static List<double> buildCustomMatrix({
    List<double> baseMatrix = identityMatrix,
    double brightness = 0.0, // -100 to +100
    double contrast = 1.0,   // 0.5 to 2.0
    double saturation = 1.0, // 0.0 to 2.0
  }) {
    // 1. Saturation Matrix
    final double sr = (1 - saturation) * 0.2126;
    final double sg = (1 - saturation) * 0.7152;
    final double sb = (1 - saturation) * 0.0722;

    final List<double> satM = [
      sr + saturation, sg,              sb,              0, 0,
      sr,              sg + saturation, sb,              0, 0,
      sr,              sg,              sb + saturation, 0, 0,
      0,               0,               0,               1, 0,
    ];

    // 2. Contrast & Brightness Matrix
    // R_new = (R - 128) * contrast + 128 + brightness = R * contrast + (128 * (1 - contrast) + brightness)
    final double cOffset = 128.0 * (1.0 - contrast) + brightness;

    final List<double> conBrightM = [
      contrast, 0,        0,        0, cOffset,
      0,        contrast, 0,        0, cOffset,
      0,        0,        contrast, 0, cOffset,
      0,        0,        0,        1, 0,
    ];

    // Multiply: conBrightM * (satM * baseMatrix)
    final step1 = multiply4x5(satM, baseMatrix);
    return multiply4x5(conBrightM, step1);
  }

  /// Multiplies two 4x5 color matrices: C = A * B
  static List<double> multiply4x5(List<double> a, List<double> b) {
    final result = List<double>.filled(20, 0.0);
    for (int y = 0; y < 4; y++) {
      for (int x = 0; x < 4; x++) {
        double sum = 0.0;
        for (int i = 0; i < 4; i++) {
          sum += a[y * 5 + i] * b[i * 5 + x];
        }
        result[y * 5 + x] = sum;
      }
      // Offset column (x = 4)
      double offsetSum = a[y * 5 + 4];
      for (int i = 0; i < 4; i++) {
        offsetSum += a[y * 5 + i] * b[i * 5 + 4];
      }
      result[y * 5 + 4] = offsetSum;
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // 3. LOW-LEVEL IN-MEMORY BYTE BUFFER PIXEL PROCESSING (CPU / IMAGE SAVE)
  // ---------------------------------------------------------------------------

  /// Processes an in-memory byte buffer (JPEG/PNG) by applying the custom 4x5
  /// matrix and per-pixel point operations, returning encoded JPEG bytes.
  static Uint8List processImageBytes({
    required Uint8List rawBytes,
    required List<double> matrix,
    int? rotateDegrees,
  }) {
    final img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded == null) return rawBytes;

    img.Image working = decoded;
    if (rotateDegrees != null && rotateDegrees != 0) {
      working = img.copyRotate(working, angle: rotateDegrees);
    }

    // Direct in-memory pixel buffer iteration:
    // Memory offset = (y * width + x) * 4
    final int width = working.width;
    final int height = working.height;

    // Cache matrix components for speed
    final double m00 = matrix[0],  m01 = matrix[1],  m02 = matrix[2],  m03 = matrix[3],  m04 = matrix[4];
    final double m10 = matrix[5],  m11 = matrix[6],  m12 = matrix[7],  m13 = matrix[8],  m14 = matrix[9];
    final double m20 = matrix[10], m21 = matrix[11], m22 = matrix[12], m23 = matrix[13], m24 = matrix[14];
    final double m30 = matrix[15], m31 = matrix[16], m32 = matrix[17], m33 = matrix[18], m34 = matrix[19];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = working.getPixel(x, y);
        final num r = pixel.r;
        final num g = pixel.g;
        final num b = pixel.b;
        final num a = pixel.a;

        // Matrix multiplication + offset addition
        final double newR = (r * m00 + g * m01 + b * m02 + a * m03 + m04).clamp(0.0, 255.0);
        final double newG = (r * m10 + g * m11 + b * m12 + a * m13 + m14).clamp(0.0, 255.0);
        final double newB = (r * m20 + g * m21 + b * m22 + a * m23 + m24).clamp(0.0, 255.0);
        final double newA = (r * m30 + g * m31 + b * m32 + a * m33 + m34).clamp(0.0, 255.0);

        pixel.r = newR.round();
        pixel.g = newG.round();
        pixel.b = newB.round();
        pixel.a = newA.round();
      }
    }

    return Uint8List.fromList(img.encodeJpg(working, quality: 90));
  }
}
