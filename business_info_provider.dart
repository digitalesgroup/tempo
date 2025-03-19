import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modelo para la información del negocio
class BusinessInfo {
  final String name;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String taxId;

  BusinessInfo({
    this.name = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.taxId = '',
  });

  // Copia con parámetros modificados
  BusinessInfo copyWith({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? taxId,
  }) {
    return BusinessInfo(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      taxId: taxId ?? this.taxId,
    );
  }
}

// Provider para la información del negocio
final businessInfoProvider =
    StateNotifierProvider<BusinessInfoNotifier, BusinessInfo>((ref) {
  return BusinessInfoNotifier();
});

class BusinessInfoNotifier extends StateNotifier<BusinessInfo> {
  BusinessInfoNotifier() : super(BusinessInfo()) {
    _loadBusinessInfo();
  }

  Future<void> _loadBusinessInfo() async {
    final prefs = await SharedPreferences.getInstance();

    state = BusinessInfo(
      name: prefs.getString('businessName') ?? 'Luxe Spa',
      address: prefs.getString('businessAddress') ?? '',
      phone: prefs.getString('businessPhone') ?? '',
      email: prefs.getString('businessEmail') ?? '',
      website: prefs.getString('businessWebsite') ?? '',
      taxId: prefs.getString('businessTaxId') ?? '',
    );
  }

  Future<void> updateBusinessInfo(BusinessInfo info) async {
    state = info;
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('businessName', info.name);
    await prefs.setString('businessAddress', info.address);
    await prefs.setString('businessPhone', info.phone);
    await prefs.setString('businessEmail', info.email);
    await prefs.setString('businessWebsite', info.website);
    await prefs.setString('businessTaxId', info.taxId);
  }
}
