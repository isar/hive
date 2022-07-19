class WebWorkerOperation {
  final String command;
  final double label;
  final String database;
  final String? objectStore;
  final Object? key;
  final Object? value;
  final String? transaction;

  const WebWorkerOperation({
    required this.command,
    required this.label,
    required this.database,
    this.objectStore,
    this.key,
    this.value,
    this.transaction,
  });

  factory WebWorkerOperation.fromJson(Map<String, dynamic> json) =>
      WebWorkerOperation(
        command: json['command'] as String,
        label: json['label'] as double,
        database: json['database'] as String,
        objectStore: json['objectStore'] as String?,
        key: json['key'],
        value: json['value'],
        transaction: json['transaction'] as String?,
      );

  Map<String, dynamic> toJson() => {
        "command": command,
        "label": label,
        'database': database,
        'objectStore': objectStore,
        'key': key,
        'value': value,
        'transaction': transaction,
      };
}
