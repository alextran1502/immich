import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:immich_mobile/constants/hive_box.dart';
import 'package:immich_mobile/utils/dio_http_interceptor.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final networkServiceProvider = Provider((_) => NetworkService());

class NetworkService {
  late final Dio dio;

  NetworkService() {
    dio = Dio();
    dio.interceptors.add(AuthenticatedRequestInterceptor());
  }

  Future<dynamic> deleteRequest({required String url, dynamic data}) async {
    try {
      var savedEndpoint = Hive.box(userInfoBox).get(serverEndpointKey);
      Response res = await dio.delete('$savedEndpoint/$url', data: data);

      if (res.statusCode == 200) {
        return res;
      }
    } on DioError catch (e) {
      debugPrint("DioError: ${e.response}");
    } catch (e) {
      debugPrint("ERROR deleteRequest: ${e.toString()}");
    }
  }

  Future<dynamic> getRequest(
      {required String url,
        bool isByteResponse = false,
        bool isStreamReponse = false}) async {
    try {
      var savedEndpoint = Hive.box(userInfoBox).get(serverEndpointKey);

      if (isByteResponse) {
        Response<List<int>> res = await dio.get<List<int>>(
          '$savedEndpoint/$url',
          options: Options(responseType: ResponseType.bytes),
        );

        if (res.statusCode == 200) {
          return res;
        }
      } else if (isStreamReponse) {
        Response<ResponseBody> res = await dio.get<ResponseBody>(
          '$savedEndpoint/$url',
          options: Options(responseType: ResponseType.stream),
        );

        if (res.statusCode == 200) {
          return res;
        }
      } else {
        Response res = await dio.get('$savedEndpoint/$url');
        if (res.statusCode == 200) {
          return res;
        }
      }
    } on DioError catch (e) {
      debugPrint("DioError: ${e.response}");
    } catch (e) {
      debugPrint("ERROR getRequest: ${e.toString()}");
    }
  }

  Future<dynamic> postRequest({required String url, dynamic data}) async {
    try {
      var savedEndpoint = Hive.box(userInfoBox).get(serverEndpointKey);
      var validUrl = Uri.parse('$savedEndpoint/$url').toString();
      var res = await dio.post(validUrl, data: data);

      return res;
    } on DioError catch (e) {
      debugPrint("[postRequest] DioError: ${e.response}");
      return null;
    } catch (e) {
      debugPrint("ERROR PostRequest: $e");
      return null;
    }
  }

  Future<dynamic> putRequest({required String url, dynamic data}) async {
    try {
      var savedEndpoint = Hive.box(userInfoBox).get(serverEndpointKey);
      var validUrl = Uri.parse('$savedEndpoint/$url').toString();
      var res = await dio.put(validUrl, data: data);

      return res;
    } on DioError catch (e) {
      debugPrint("DioError: ${e.response}");
      return null;
    } catch (e) {
      debugPrint("ERROR PutRequest: $e");
      return null;
    }
  }

  Future<dynamic> patchRequest({required String url, dynamic data}) async {
    try {
      var savedEndpoint = Hive.box(userInfoBox).get(serverEndpointKey);
      var validUrl = Uri.parse('$savedEndpoint/$url').toString();
      var res = await dio.patch(validUrl, data: data);

      return res;
    } on DioError catch (e) {
      debugPrint("DioError: ${e.response}");
    } catch (e) {
      debugPrint("ERROR PatchRequest: $e");
    }
  }

  Future<bool> pingServer() async {
    try {
      var savedEndpoint = Hive.box(userInfoBox).get(serverEndpointKey);
      var validUrl = Uri.parse('$savedEndpoint/server-info/ping').toString();

      debugPrint("ping server at url $validUrl");

      var res = await dio.get(validUrl);
      var jsonRespsonse = jsonDecode(res.toString());

      return jsonRespsonse["res"] == "pong";
    } on DioError catch (e) {
      debugPrint("[PING SERVER] DioError: ${e.response} - $e");
      return false;
    } catch (e) {
      debugPrint("ERROR PingServer: $e");
      return false;
    }
  }
}