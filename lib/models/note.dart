class Note {
  String? title;
  DateTime? date;
  bool? finished;
  String? text;

  Note(String title) {
    this.title = title;
    this.date = DateTime.now();
    this.finished = false;
    text = "";
  }

  setText(String content) {
    text = content;
  }

  Note.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        date = DateTime.parse(json['date']),
        finished = json['finished'],
        text = json['text'];

  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date!.toIso8601String(),
        'finished': finished,
        'text': text,
      };
}
