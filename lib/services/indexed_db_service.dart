// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import '../models/salary_record.dart';

class IndexedDbService {
  static const String _dbName = 'AuraBudgetDB';
  static const String _storeName = 'salary_records';

  /// Saves full salary records (including binary images) to Browser IndexedDB (Multi-Gigabyte storage quota)
  static Future<bool> saveFullRecords(List<SalaryRecord> records, String userId) async {
    if (!kIsWeb || userId.isEmpty) return false;
    
    try {

      final recordsJson = jsonEncode(records.map((r) => r.toJson(includeBinary: true)).toList());

      js.context.callMethod('eval', [
        '''
        (function(dataStr) {
          try {
            var request = indexedDB.open("$_dbName", 1);
            request.onupgradeneeded = function(e) {
              var db = e.target.result;
              if (!db.objectStoreNames.contains("$_storeName")) {
                db.createObjectStore("$_storeName");
              }
            };
            request.onsuccess = function(e) {
              var db = e.target.result;
              var tx = db.transaction("$_storeName", "readwrite");
              var store = tx.objectStore("$_storeName");
              store.put(dataStr, "records_key_" + "$userId");
              tx.oncomplete = function() {
                console.log("[IndexedDbService] Full records successfully saved to IndexedDB!");
              };
            };
          } catch(err) {
            console.error("[IndexedDbService] IndexedDB save error:", err);
          }
        })(${jsonEncode(recordsJson)});
        '''
      ]);

      return true;
    } catch (e) {
      debugPrint('[IndexedDbService] Error saving to IndexedDB: $e');
      return false;
    }
  }

  /// Loads full salary records (with binary images) from Browser IndexedDB
  static Future<List<SalaryRecord>?> loadFullRecords(String userId) async {
    if (!kIsWeb || userId.isEmpty) return null;

    try {
      final completer = Completer<List<SalaryRecord>?>();

      js.context['onIndexedDbLoaded'] = (dynamic rawDataStr) {
        if (rawDataStr != null && rawDataStr is String && rawDataStr.isNotEmpty) {
          try {
            final List<dynamic> parsed = jsonDecode(rawDataStr);
            final records = parsed.map((item) => SalaryRecord.fromJson(item)).toList();
            completer.complete(records);
            return;
          } catch (e) {
            debugPrint('[IndexedDbService] Parse error on load: $e');
          }
        }
        completer.complete(null);
      };

      js.context.callMethod('eval', [
        '''
        (function() {
          try {
            var request = indexedDB.open("$_dbName", 1);
            request.onupgradeneeded = function(e) {
              var db = e.target.result;
              if (!db.objectStoreNames.contains("$_storeName")) {
                db.createObjectStore("$_storeName");
              }
            };
            request.onsuccess = function(e) {
              var db = e.target.result;
              var tx = db.transaction("$_storeName", "readonly");
              var store = tx.objectStore("$_storeName");
              var getReq = store.get("records_key_" + "$userId");
              getReq.onsuccess = function() {
                if (window.onIndexedDbLoaded) {
                  window.onIndexedDbLoaded(getReq.result || null);
                }
              };
              getReq.onerror = function() {
                if (window.onIndexedDbLoaded) window.onIndexedDbLoaded(null);
              };
            };
            request.onerror = function() {
              if (window.onIndexedDbLoaded) window.onIndexedDbLoaded(null);
            };
          } catch(err) {
            if (window.onIndexedDbLoaded) window.onIndexedDbLoaded(null);
          }
        })();
        '''
      ]);

      return await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint('[IndexedDbService] Load error: $e');
      return null;
    }
  }
}
