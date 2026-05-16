import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// 請求定位權限
  Future<LocationPermission?> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 檢查定位服務是否開啟
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return permission;
  }

  /// 取得當前位置對應的城市名稱
  Future<String?> getCurrentCity() async {
    final permission = await requestPermission();
    if (permission == null || permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      // 取得當前經緯度
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // 反向地理編碼取得城市
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        // 優先順序：administrativeArea (直轄市/縣), subAdministrativeArea, locality
        return placemark.administrativeArea ?? placemark.subAdministrativeArea ?? placemark.locality;
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
    
    return null;
  }

  /// 根據城市名稱匹配地區代碼
  static String? mapCityToRegionCode(String? city, Map<String, String> regionCodes) {
    if (city == null) return null;

    // 清理城市名稱 (例如：台北市 -> 台北)
    final cleanCity = city.replaceAll('市', '').replaceAll('縣', '');
    
    // 台北/新北 特殊處理
    if (cleanCity == '台北' || cleanCity == '新北') {
      return regionCodes['台北/新北'];
    }
    
    // 宜蘭/花蓮/台東 特殊處理
    if (cleanCity == '宜蘭' || cleanCity == '花蓮' || cleanCity == '台東') {
      return regionCodes['宜蘭/花蓮/台東'];
    }
    
    // 澎湖/金門 特殊處理
    if (cleanCity == '澎湖' || cleanCity == '金門') {
      return regionCodes['澎湖/金門'];
    }

    // 直接匹配
    for (final entry in regionCodes.entries) {
      if (entry.key.contains(cleanCity)) {
        return entry.value;
      }
    }

    return null;
  }
}
