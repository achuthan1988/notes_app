class ReminderModel {
  int id;
  String reminderDate;
  String reminderTime;
  String reminderInterval;

  ReminderModel(this.reminderDate, this.reminderTime, this.reminderInterval);

  ReminderModel.param(
      this.id, this.reminderDate, this.reminderTime, this.reminderInterval);

  factory ReminderModel.fromJson(dynamic json) {
    return ReminderModel.param(
        json['id'] as int,
        json['reminderDate'] as String,
        json['reminderTime'] as String,
        json['reminderInterval'] as String);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminderDate': reminderDate,
      'reminderTime': reminderTime,
      'reminderInterval': reminderInterval
    };
  }
}
