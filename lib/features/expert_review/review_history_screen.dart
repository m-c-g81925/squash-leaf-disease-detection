import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReviewHistoryScreen extends StatelessWidget {
  const ReviewHistoryScreen({super.key});

  Color _statusColor(String status) {
    return status == "reviewed"
        ? const Color(0xFF2F7D45)
        : const Color(0xFFB56A00);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F5),
      appBar: AppBar(
        title: const Text(
          'Review history',
          style: TextStyle(
            color: Color(0xFF1F2923),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("expert_reviews")
            .orderBy("submittedAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF179E43)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No review history yet."),
            );
          }

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final data = reviews[index].data() as Map<String, dynamic>;

              final aiPrediction = data["aiPrediction"] ?? "Unknown";
              final confidence = data["confidence"] ?? 0;
              final status = data["status"] ?? "pending";
              final expertDiagnosis =
                  data["expertDiagnosis"]?.toString().isEmpty ?? true
                      ? "Waiting for expert feedback"
                      : data["expertDiagnosis"];
              final recommendation =
                  data["recommendation"]?.toString().isEmpty ?? true
                      ? "Waiting for recommendation"
                      : data["recommendation"];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status == "reviewed" ? "Reviewed" : "Pending",
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "System Prediction: $aiPrediction",
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "Confidence: $confidence%",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),

                    const Divider(height: 25),

                    const Text(
                      "Expert Diagnosis",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      expertDiagnosis,
                      style: const TextStyle(fontSize: 13),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      "Recommendation",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      recommendation,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}