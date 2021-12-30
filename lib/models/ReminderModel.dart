class ReminderModel {
  int id;
  String reminderDate;
  String reminderTime;
  String reminderInterval;

  ReminderModel(
      this.id, this.reminderDate, this.reminderTime, this.reminderInterval);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reminderDate': reminderDate,
      'reminderTime': reminderTime,
      'reminderInterval': reminderInterval
    };
  }

}
