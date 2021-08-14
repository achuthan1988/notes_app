class LabelModel {
  int id;
  String labelTitle;

  LabelModel(this.labelTitle);

  LabelModel.param(this.id, this.labelTitle);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'labelTitle': labelTitle,
    };
  }
}
