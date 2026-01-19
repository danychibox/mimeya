import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';

class DiseasePrediction {
  final String className;
  final String diseaseName;
  final String plantType;
  final double confidence;
  final String description;
  final String treatment;
  final Color color;

  DiseasePrediction({
    required this.className,
    required this.confidence,
  })  : diseaseName = _extractDiseaseName(className),
        plantType = _extractPlantType(className),
        description = _getDescription(className),
        treatment = _getTreatment(className),
        color = _getColor(className);

  static String _extractDiseaseName(String className) {
    if (className.contains('healthy')) return 'Healthy';
    if (className.contains('Bacterial_spot')) return 'Bacterial Spot';
    if (className.contains('Early_blight')) return 'Early Blight';
    if (className.contains('Late_blight')) return 'Late Blight';
    if (className.contains('Leaf_Mold')) return 'Leaf Mold';
    if (className.contains('Septoria')) return 'Septoria Leaf Spot';
    if (className.contains('Spider_mites')) return 'Spider Mites';
    if (className.contains('Target_Spot')) return 'Target Spot';
    if (className.contains('YellowLeaf__Curl_Virus')) return 'Yellow Leaf Curl Virus';
    if (className.contains('mosaic_virus')) return 'Mosaic Virus';
    return 'Unknown Disease';
  }

  static String _extractPlantType(String className) {
    if (className.contains('Tomato')) return 'Tomato';
    if (className.contains('Potato')) return 'Potato';
    if (className.contains('Pepper')) return 'Pepper';
    return 'Unknown Plant';
  }

  static String _getDescription(String className) {
    final disease = _extractDiseaseName(className);
    final descriptions = {
      'Healthy': 'Plant is healthy and thriving',
      'Bacterial Spot': 'Caused by bacteria, appears as small water-soaked spots',
      'Early Blight': 'Fungal disease with concentric rings on leaves',
      'Late Blight': 'Destructive fungal disease affecting leaves and stems',
      'Leaf Mold': 'Fungal growth on leaf surfaces',
      'Septoria Leaf Spot': 'Small circular spots with gray centers',
      'Spider Mites': 'Tiny pests causing stippling on leaves',
      'Target Spot': 'Concentric rings resembling target patterns',
      'Yellow Leaf Curl Virus': 'Viral disease causing leaf curling and yellowing',
      'Mosaic Virus': 'Viral disease causing mosaic patterns on leaves',
    };
    return descriptions[disease] ?? 'No description available';
  }

  static String _getTreatment(String className) {
    final disease = _extractDiseaseName(className);
    final treatments = {
      'Healthy': 'Continue current care practices',
      'Bacterial Spot': 'Use copper-based bactericides, remove infected leaves',
      'Early Blight': 'Apply fungicides, improve air circulation',
      'Late Blight': 'Use systemic fungicides, destroy infected plants',
      'Leaf Mold': 'Apply sulfur-based fungicides, reduce humidity',
      'Septoria Leaf Spot': 'Remove infected leaves, apply chlorothalonil',
      'Spider Mites': 'Use miticides, increase humidity',
      'Target Spot': 'Apply fungicides, practice crop rotation',
      'Yellow Leaf Curl Virus': 'Remove infected plants, control whiteflies',
      'Mosaic Virus': 'Remove infected plants, control aphids',
    };
    return treatments[disease] ?? 'Consult with agricultural expert';
  }

  static Color _getColor(String className) {
    if (className.contains('healthy')) return Colors.green;
    if (className.contains('Bacterial')) return Colors.orange;
    if (className.contains('blight')) return Colors.red;
    if (className.contains('virus')) return Colors.purple;
    return Colors.grey;
  }
}

class ClassifierProvider extends ChangeNotifier {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isLoading = false;
  String _error = '';
  List<DiseasePrediction> _predictions = [];
  File? _currentImage;

  bool get isLoading => _isLoading;
  String get error => _error;
  List<DiseasePrediction> get predictions => _predictions;
  File? get currentImage => _currentImage;

  Future<void> loadModel() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Charger le modèle TFLite
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset('assets/tflite/plant_diagnosis.tflite', options: options);

      // Charger les labels
      final labelData = await rootBundle.loadString('assets/tflite/labels.txt');
      _labels = labelData.split('\n').where((label) => label.isNotEmpty).toList();

      _error = '';
      print('✅ Modèle chargé avec ${_labels.length} classes');
    } catch (e) {
      _error = 'Erreur de chargement: $e';
      print('❌ Erreur: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> classifyImage(File imageFile) async {
    try {
      _isLoading = true;
      _currentImage = imageFile;
      notifyListeners();

      // Préparer l'image
      final image = img.decodeImage(await imageFile.readAsBytes())!;
      final resizedImage = img.copyResize(image, width: 224, height: 224);
      
      // Convertir en format d'entrée du modèle
      final input = _imageToByteList(resizedImage);
      
      // Exécuter l'inférence
      final output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
      _interpreter!.run(input, output);

      // Traiter les résultats
      final results = output[0];
      _predictions = [];
      
      for (int i = 0; i < results.length; i++) {
        final confidence = results[i];
        if (confidence > 0.1) { // Seuil de confiance
          _predictions.add(DiseasePrediction(
            className: _labels[i],
            confidence: confidence,
          ));
        }
      }

      // Trier par confiance
      _predictions.sort((a, b) => b.confidence.compareTo(a.confidence));

      _error = '';
    } catch (e) {
      _error = 'Erreur de classification: $e';
      _predictions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

Uint8List _imageToByteList(img.Image image) {
  final input = Float32List(1 * 224 * 224 * 3);
  int pixelIndex = 0;

  for (int y = 0; y < 224; y++) {
    for (int x = 0; x < 224; x++) {
      final pixel = image.getPixel(x, y);

      input[pixelIndex++] = (pixel.r / 127.5) - 1.0;
      input[pixelIndex++] = (pixel.g / 127.5) - 1.0;
      input[pixelIndex++] = (pixel.b / 127.5) - 1.0;
    }
  }

  return input.buffer.asUint8List();
}

  void clearResults() {
    _predictions = [];
    _currentImage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }
}