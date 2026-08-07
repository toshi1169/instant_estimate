class TransportVehicle {
  const TransportVehicle({
    required this.id,
    required this.name,
    required this.initialCapacityCubicMeters,
    this.maximumPayloadTons,
    this.approximateCapacityLabel,
    this.isCrawler = false,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final double initialCapacityCubicMeters;
  final double? maximumPayloadTons;
  final String? approximateCapacityLabel;
  final bool isCrawler;
  final bool isCustom;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'initialCapacityCubicMeters': initialCapacityCubicMeters,
    'maximumPayloadTons': maximumPayloadTons,
    'approximateCapacityLabel': approximateCapacityLabel,
    'isCrawler': isCrawler,
    'isCustom': isCustom,
  };

  factory TransportVehicle.fromJson(Map<String, Object?> json) {
    return TransportVehicle(
      id: json['id'] as String,
      name: json['name'] as String,
      initialCapacityCubicMeters: (json['initialCapacityCubicMeters'] as num)
          .toDouble(),
      maximumPayloadTons: (json['maximumPayloadTons'] as num?)?.toDouble(),
      approximateCapacityLabel: json['approximateCapacityLabel'] as String?,
      isCrawler: json['isCrawler'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? true,
    );
  }
}

abstract final class InitialTransportVehicles {
  static const standard = <TransportVehicle>[
    TransportVehicle(
      id: 'light_truck',
      name: '軽トラック',
      maximumPayloadTons: 0.35,
      approximateCapacityLabel: '約0.5m³',
      initialCapacityCubicMeters: 0.5,
    ),
    TransportVehicle(
      id: 'truck_1t',
      name: '1tトラック',
      maximumPayloadTons: 1,
      approximateCapacityLabel: '約1.2m³',
      initialCapacityCubicMeters: 1,
    ),
    TransportVehicle(
      id: 'dump_2t',
      name: '2tダンプ',
      maximumPayloadTons: 2,
      approximateCapacityLabel: '約1.8m³',
      initialCapacityCubicMeters: 1.5,
    ),
    TransportVehicle(
      id: 'dump_3t',
      name: '3tダンプ',
      maximumPayloadTons: 3,
      approximateCapacityLabel: '約2.5m³',
      initialCapacityCubicMeters: 2,
    ),
    TransportVehicle(
      id: 'dump_4t',
      name: '4tダンプ',
      maximumPayloadTons: 4,
      approximateCapacityLabel: '約3.5m³',
      initialCapacityCubicMeters: 3,
    ),
    TransportVehicle(
      id: 'dump_8t',
      name: '8tダンプ',
      maximumPayloadTons: 8,
      approximateCapacityLabel: '約5.5m³',
      initialCapacityCubicMeters: 5,
    ),
    TransportVehicle(
      id: 'dump_10t',
      name: '10tダンプ',
      maximumPayloadTons: 10,
      approximateCapacityLabel: '約6.5m³',
      initialCapacityCubicMeters: 6,
    ),
    TransportVehicle(
      id: 'dump_12t',
      name: '12tダンプ',
      maximumPayloadTons: 12,
      approximateCapacityLabel: '約7.5m³',
      initialCapacityCubicMeters: 7,
    ),
    TransportVehicle(
      id: 'semi_trailer',
      name: 'セミトレーラー（土砂）',
      maximumPayloadTons: 20,
      approximateCapacityLabel: '約12〜15m³',
      initialCapacityCubicMeters: 12,
    ),
  ];

  static const crawlers = <TransportVehicle>[
    TransportVehicle(
      id: 'crawler_05t',
      name: 'クローラーダンプ 0.5t',
      initialCapacityCubicMeters: 0.3,
      approximateCapacityLabel: '約0.3m³',
      isCrawler: true,
    ),
    TransportVehicle(
      id: 'crawler_1t',
      name: 'クローラーダンプ 1t',
      initialCapacityCubicMeters: 0.5,
      approximateCapacityLabel: '約0.5m³',
      isCrawler: true,
    ),
    TransportVehicle(
      id: 'crawler_2t',
      name: 'クローラーダンプ 2t',
      initialCapacityCubicMeters: 1,
      approximateCapacityLabel: '約1.0m³',
      isCrawler: true,
    ),
    TransportVehicle(
      id: 'crawler_3t',
      name: 'クローラーダンプ 3t',
      initialCapacityCubicMeters: 1.5,
      approximateCapacityLabel: '約1.5m³',
      isCrawler: true,
    ),
  ];

  static const all = <TransportVehicle>[...standard, ...crawlers];

  static const defaultVehicleId = 'dump_4t';
}
