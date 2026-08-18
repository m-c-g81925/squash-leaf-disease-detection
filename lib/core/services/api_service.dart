import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ApiService {
  ApiService._();

  static const String _modelPath = 'assets/models/model.tflite';
  static const String _labelsPath = 'assets/models/labels.txt';
  static const int _imageSize = 224;

  static Interpreter? _interpreter;
  static List<String> _labels = <String>[];
  static Future<void>? _initializationFuture;

  static Future<void> _initialize() {
    _initializationFuture ??= _loadModelAndLabels();
    return _initializationFuture!;
  }

  static Future<void> _loadModelAndLabels() async {
    try {
      final InterpreterOptions options = InterpreterOptions()
        ..threads = 4;

      _interpreter = await Interpreter.fromAsset(
        _modelPath,
        options: options,
      );

      final String labelsText =
          await rootBundle.loadString(_labelsPath);

      _labels = labelsText
          .split(RegExp(r'\r?\n'))
          .map((String label) => label.trim())
          .where((String label) => label.isNotEmpty)
          .toList(growable: false);

      final List<int> inputShape =
          _interpreter!.getInputTensor(0).shape;
      final List<int> outputShape =
          _interpreter!.getOutputTensor(0).shape;

      debugPrint('TFLite model loaded successfully.');
      debugPrint('Input shape: $inputShape');
      debugPrint('Output shape: $outputShape');
      debugPrint('Labels: $_labels');

      if (inputShape.length != 4 ||
          inputShape[0] != 1 ||
          inputShape[1] != _imageSize ||
          inputShape[2] != _imageSize ||
          inputShape[3] != 3) {
        throw StateError(
          'Unexpected model input shape: $inputShape',
        );
      }

      if (outputShape.length != 2 ||
          outputShape[0] != 1 ||
          outputShape[1] != _labels.length) {
        throw StateError(
          'Model output count does not match labels. '
          'Output shape: $outputShape, labels: ${_labels.length}',
        );
      }
    } catch (error) {
      _interpreter?.close();
      _interpreter = null;
      _labels = <String>[];
      _initializationFuture = null;
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> predictDisease(
    File imageFile,
  ) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('Selected image does not exist.');
      }

      await _initialize();

      final Interpreter? interpreter = _interpreter;

      if (interpreter == null || _labels.isEmpty) {
        throw StateError(
          'The TensorFlow Lite model is not ready.',
        );
      }

      final Uint8List imageBytes =
          await imageFile.readAsBytes();

      final img.Image? decodedImage =
          img.decodeImage(imageBytes);

      if (decodedImage == null) {
        throw const FormatException(
          'Unable to decode the selected image.',
        );
      }

      // Match the Python backend:
      // 1. RGB image
      // 2. Resize directly to 224 x 224
      // 3. Feed raw float32-like RGB values in the 0-255 range.
      //
      // Do NOT apply MobileNetV2 preprocess_input here because
      // preprocess_input is already embedded inside the trained model.
      final img.Image resizedImage = img.copyResize(
        decodedImage,
        width: _imageSize,
        height: _imageSize,
        interpolation: img.Interpolation.linear,
      );

      final List<List<List<List<double>>>> input =
          <List<List<List<double>>>>[
        List<List<List<double>>>.generate(
          _imageSize,
          (int y) => List<List<double>>.generate(
            _imageSize,
            (int x) {
              final img.Pixel pixel =
                  resizedImage.getPixel(x, y);

              return <double>[
                pixel.r.toDouble(),
                pixel.g.toDouble(),
                pixel.b.toDouble(),
              ];
            },
            growable: false,
          ),
          growable: false,
        ),
      ];

      final int outputCount =
          interpreter.getOutputTensor(0).shape.last;

      final List<List<double>> output =
          <List<double>>[
        List<double>.filled(outputCount, 0.0),
      ];

      interpreter.run(input, output);

      final List<double> probabilities = output.first;

      int predictedIndex = 0;
      double highestProbability = probabilities.first;

      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > highestProbability) {
          highestProbability = probabilities[i];
          predictedIndex = i;
        }
      }

      final String disease = _labels[predictedIndex];
      final double confidence = highestProbability * 100.0;

      final Map<String, double> allPredictions =
          <String, double>{};

      for (int i = 0; i < _labels.length; i++) {
        allPredictions[_labels[i]] =
            probabilities[i] * 100.0;
      }

      debugPrint('TFLite prediction: $disease');
      debugPrint(
        'TFLite confidence: '
        '${confidence.toStringAsFixed(2)}%',
      );
      debugPrint(
        'TFLite predictions: $allPredictions',
      );

      return <String, dynamic>{
        'disease': disease,
        'confidence':
            double.parse(confidence.toStringAsFixed(2)),
        'all_predictions': allPredictions.map(
          (String label, double value) =>
              MapEntry<String, double>(
            label,
            double.parse(value.toStringAsFixed(2)),
          ),
        ),
      };
    } catch (error, stackTrace) {
      debugPrint(
        'On-device prediction error: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = <String>[];
    _initializationFuture = null;
  }
}
