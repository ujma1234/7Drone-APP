class Robot {
  String title;
  List<String> candidates;
  int answer;

  Robot({this.title, this.candidates, this.answer});

  Robot.fromMap(Map<String, dynaamic> map)
    : title = map['title'],
      candidates = map['candidates'],
      answer = map['answer'],
}