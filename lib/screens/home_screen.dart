import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mimeya/providers/classifier_provider.dart';
import 'package:mimeya/widget/disease_card.dart';
import 'package:mimeya/widget/image_preview.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ClassifierProvider _classifierProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _classifierProvider = context.read<ClassifierProvider>();
      _classifierProvider.loadModel();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      await _classifierProvider.classifyImage(File(pickedFile.path));
    }
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Choisir depuis la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
      icon: const Icon(Icons.camera_alt),
      label: const Text('Analyser'),
      backgroundColor: Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌿 Plant Disease Detector'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Plant Disease Detector',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 Plant Health AI',
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Cette application utilise l\'IA pour détecter les maladies des plantes à partir de photos de feuilles.',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<ClassifierProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.predictions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinKitFadingCircle(
                    color: Colors.green,
                    size: 50.0,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chargement du modèle...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (provider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  Text(
                    'Erreur: ${provider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: provider.loadModel,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Image preview
              if (provider.currentImage != null)
                ImagePreview(imageFile: provider.currentImage!),
              
              // Predictions
              Expanded(
                child: provider.predictions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_camera,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Prenez une photo d\'une feuille\npour analyser sa santé',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.predictions.length,
                        itemBuilder: (context, index) {
                          return DiseaseCard(
                            prediction: provider.predictions[index],
                            rank: index + 1,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}