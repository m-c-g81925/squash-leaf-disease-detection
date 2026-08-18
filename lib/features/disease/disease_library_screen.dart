import 'package:flutter/material.dart';
import 'disease_detail_screen.dart';

class DiseaseLibraryScreen extends StatelessWidget {
  const DiseaseLibraryScreen({super.key});

  final List<Map<String, dynamic>> diseases = const [
    {
      "name": "Powdery Mildew",
      "listImage": "assets/images/powderymildew.jpg",
      "detailImage": "assets/images/powderymildew1.jpg",
      "severity": "High",
      "description":
          "A fungal disease that creates white powdery spots on squash leaves.",
      "symptoms": [
        "White powdery coating on leaves",
        "Yellowing and curling leaves",
        "Stunted plant growth",
        "Reduced fruit production",
      ],
      "causes": [
        "High humidity",
        "Poor air circulation",
        "Dense plant spacing",
        "Overhead watering",
      ],
      "treatment": [
        "Remove infected leaves",
        "Apply approved fungicide",
        "Avoid wetting the leaves",
      ],
      "prevention": [
        "Inspect plants regularly",
        "Provide proper spacing",
        "Water at the base of the plant",
        "Remove infected plant parts early",
      ],
    },
    {
      "name": "Downy Mildew",
      "listImage": "assets/images/downymildew.jpg",
      "detailImage": "assets/images/downymildew1.jpg",
      "severity": "High",
      "description":
          "A serious disease that causes yellow spots and fuzzy growth under leaves.",
      "symptoms": [
        "Yellow patches on leaves",
        "Fuzzy growth under leaves",
        "Leaves turn brown",
        "Plant weakens quickly",
      ],
      "causes": [
        "Cool and wet weather",
        "High moisture",
        "Poor air circulation",
        "Infected plant debris",
      ],
      "treatment": [
        "Remove affected leaves",
        "Use fungicide if needed",
        "Improve air movement",
      ],
      "prevention": [
        "Avoid overhead watering",
        "Keep plants properly spaced",
        "Remove plant debris",
        "Monitor during rainy days",
      ],
    },
    {
      "name": "Alternaria Leaf Blight",
      "listImage": "assets/images/alternaria.jpg",
      "detailImage": "assets/images/alternaria1.jpg",
      "severity": "High",
      "description":
          "A fungal disease that causes brown spots with concentric rings on squash leaves, leading to premature leaf death.",
      "symptoms": [
        "Brown circular spots with concentric rings",
        "Yellow halo around lesions",
        "Leaves dry and fall prematurely",
        "Reduced plant vigor",
      ],
      "causes": [
        "Alternaria fungus",
        "Warm and humid weather",
        "Poor air circulation",
        "Infected crop debris",
      ],
      "treatment": [
        "Remove infected leaves",
        "Apply recommended fungicide",
        "Improve air circulation",
      ],
      "prevention": [
        "Practice crop rotation",
        "Use disease-free seeds",
        "Avoid overhead irrigation",
        "Remove infected plant debris",
      ],
    },
    {
      "name": "Leaf Curl Virus",
      "listImage": "assets/images/leafcurlvirus.jpg",
      "detailImage": "assets/images/leafcurlvirus1.jpg",
      "severity": "Critical",
      "description":
          "A viral disease that causes curling, yellowing, and deformation of squash leaves, reducing plant growth and yield.",
      "symptoms": [
        "Leaves curl upward or downward",
        "Yellowing of leaves",
        "Stunted plant growth",
        "Deformed young leaves",
      ],
      "causes": [
        "Leaf curl virus infection",
        "Spread by whiteflies",
        "Infected planting materials",
        "Presence of weed hosts",
      ],
      "treatment": [
        "Remove infected plants",
        "Control whitefly population",
        "Use virus-free seedlings",
      ],
      "prevention": [
        "Monitor and control whiteflies",
        "Remove weeds around the field",
        "Plant resistant varieties when available",
        "Maintain field sanitation",
      ],
    },
    {
      "name": "Mosaic Virus",
      "listImage": "assets/images/mosaicvirus.jpg",
      "detailImage": "assets/images/mosaicvirus1.jpg",
      "severity": "Medium",
      "description":
          "A viral disease that creates yellow-green mosaic patterns on leaves.",
      "symptoms": [
        "Mosaic leaf pattern",
        "Yellow and green patches",
        "Distorted leaves",
        "Poor fruit development",
      ],
      "causes": [
        "Virus infection",
        "Spread by aphids",
        "Infected seeds",
        "Contaminated tools",
      ],
      "treatment": [
        "Remove infected plants",
        "Control aphids",
        "Disinfect tools",
      ],
      "prevention": [
        "Use disease-free seeds",
        "Control insect pests",
        "Remove weeds",
        "Avoid touching healthy plants after infected ones",
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F5),
      appBar: AppBar(
        title: const Text(
          'Disease library',
          style: TextStyle(
            color: Color(0xFF1F2923),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2923),
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: Color(0xFFE2E7E3),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: diseases.length,
        itemBuilder: (context, index) {
          final disease = diseases[index];
          final String name =
              disease['name']?.toString() ?? 'Unknown disease';
          final String severity =
              disease['severity']?.toString() ?? 'Unknown';
          final String description =
              disease['description']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DiseaseDetailScreen(
                        disease: disease,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFDDE5DF),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          disease['listImage'],
                          height: 68,
                          width: 68,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            BuildContext context,
                            Object error,
                            StackTrace? stackTrace,
                          ) {
                            return Container(
                              height: 68,
                              width: 68,
                              color: const Color(0xFFEDF0ED),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Color(0xFF69736C),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Color(0xFF1F2923),
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF5E6962),
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: _getSeverityColor(severity),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Severity: $severity',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        _getSeverityColor(severity),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right,
                        size: 22,
                        color: Color(0xFF758078),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case "Medium":
        return const Color(0xFFB56A00);
      case "High":
        return const Color(0xFFC33A32);
      case "Critical":
        return const Color(0xFF8F211B);
      default:
        return const Color(0xFF68736B);
    }
  }
}
