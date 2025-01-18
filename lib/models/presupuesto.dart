class Presupuesto {
  String description = "";
  double percentage = 0.0;
  double? amount;
  List<String>? tags;

  Presupuesto({required this.description, required this.percentage, this.amount, this.tags});

  Presupuesto.fromJson(Map<String, dynamic> json) {
    description = json['description'];
    percentage = json['percentage'];
    amount = json['amount'];
    tags = json['tags'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['description'] = description;
    data['percentage'] = percentage;
    data['amount'] = amount;
    data['tags'] = tags;
    return data;
  }
}
