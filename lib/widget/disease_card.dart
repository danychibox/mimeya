import 'package:flutter/material.dart';
import 'package:mimeya/providers/classifier_provider.dart';
import 'package:percent_indicator/percent_indicator.dart';

class DiseaseCard extends StatelessWidget {
  final DiseasePrediction prediction;
  final int rank;

  const DiseaseCard({
    super.key,
    required this.prediction,
    required this.rank,
  });

  Color _getRankColor() {
    switch (rank) {
      case 1: return Colors.amber;
      case 2: return Colors.blueGrey;
      case 3: return Colors.brown;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getRankColor(),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '#$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.diseaseName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        prediction.plantType,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                CircularPercentIndicator(
                  radius: 30,
                  lineWidth: 5,
                  percent: prediction.confidence,
                  center: Text(
                    '${(prediction.confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  progressColor: prediction.color,
                  backgroundColor: const Color.fromARGB(255, 201, 189, 189),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: prediction.confidence,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(prediction.color),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 16),
            Text(
              prediction.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green[100]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Traitement: ${prediction.treatment}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}