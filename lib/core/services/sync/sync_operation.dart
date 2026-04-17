enum SyncOpType { insert, update, delete }

class SyncOperation {
  final String id;
  final SyncOpType op;
  final String table;
  final String? rowId;
  final Map<String, dynamic>? data;
  final int createdAt;
  final int attempts;

  SyncOperation({
    required this.id,
    required this.op,
    required this.table,
    this.rowId,
    this.data,
    required this.createdAt,
    this.attempts = 0,
  });

  SyncOperation copyWith({int? attempts}) => SyncOperation(
        id: id,
        op: op,
        table: table,
        rowId: rowId,
        data: data,
        createdAt: createdAt,
        attempts: attempts ?? this.attempts,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'op': op.name,
        'table': table,
        'rowId': rowId,
        'data': data,
        'createdAt': createdAt,
        'attempts': attempts,
      };

  factory SyncOperation.fromJson(Map<String, dynamic> j) => SyncOperation(
        id: j['id'] as String,
        op: SyncOpType.values.firstWhere((e) => e.name == j['op']),
        table: j['table'] as String,
        rowId: j['rowId'] as String?,
        data: j['data'] == null
            ? null
            : Map<String, dynamic>.from(j['data'] as Map),
        createdAt: j['createdAt'] as int,
        attempts: (j['attempts'] as int?) ?? 0,
      );
}
