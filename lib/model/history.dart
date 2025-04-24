class HistoryItem {
  final int id;
  final String zabytek;
  final String question;
  final String answer;

  HistoryItem({
    required this.id,
    required this.zabytek,
    required this.question,
    required this.answer,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] as int,
      zabytek: json['zabytek'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
    );
  }
}