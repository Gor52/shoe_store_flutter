import 'package:pocketbase/pocketbase.dart';
import '../core/api_client.dart'; 

class Brand {
  final String id;
  final String name;
  final String country; 
  final String logo;
  final RecordModel record;

  Brand({
    required this.id,
    required this.name,
    required this.country,
    required this.logo,
    required this.record,
  });

  factory Brand.fromRecord(RecordModel record) {
    return Brand(
      id: record.id,
      name: record.getStringValue('name'),
      country: record.getStringValue('country'), 
      logo: record.getStringValue('logo'),
      record: record,
    );
  }


  bool get hasValidLogo => logo.isNotEmpty;
  String? get logoUrl => hasValidLogo ? pb.files.getUrl(record, logo).toString() : null;
}