import 'dart:convert' as system_convert;
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:iris_tools/api/converter.dart';
import 'package:iris_tools/api/helpers/jsonHelper.dart';
import 'package:iris_tools/api/helpers/listHelper.dart';
import 'package:iris_tools/api/helpers/urlHelper.dart';

import '/managers/settingsManager.dart';
import '/system/httpProcess.dart';

/*
  Net:
- get-data : no need queryParam, must send a json as body that have 'Request' key
- set-data : no need queryParam, must send a param named 'Json' and wrap 'Request', 'DeviceId' key
 */

class HttpCenter {
	HttpCenter._();

	static String baseUri = '';
	static String? proxyUri;

	static BaseOptions _getOptions(){
		return BaseOptions(
			connectTimeout: SettingsManager.serverHackState? 3000: 46000,
		);
	}

	static HttpRequester send(HttpItem item, {Duration? timeout}){
		item.prepareMultiParts();
		final itemRes = HttpRequester();
		Dio dio;
		//prin-t(StackTrace.current);

		try {
			if(timeout == null) {
			  dio = Dio(_getOptions());
			}
			else {
				final bo = _getOptions();
				bo.connectTimeout = timeout.inMilliseconds;
				dio = Dio(bo);
			}

			//dio.options.baseUrl = baseUri;
			var uri = item.fullUri?? (baseUri + (item.pathSection?? ''));
			uri = correctUri(uri)!;

			///  add proxy
			if(proxyUri != null || item.proxyAddress != null) {
				(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
					client.findProxy = (uri) {
						return 'PROXY ${item.proxyAddress?? proxyUri}';
					};

					client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
				};
			}

			dio.interceptors.add(
					InterceptorsWrapper(
							onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
								options.headers['Connection'] = 'close';
								itemRes.requestOptions = options;

								return handler.next(options);
								//return handler.resolve(response);
								//return handler.reject(dioError);
							},
							 onResponse: (Response<dynamic> res, ResponseInterceptorHandler handler) {
								itemRes._responseObj = res;
								itemRes.isOk = !(res is Error || res is Exception || res.statusCode != 200 || res.data == null);

								if(HttpProcess.onResponse(res)) {
									handler.next(res);
								}
							},
							onError: (DioError err, ErrorInterceptorHandler handler) async{
								/*if(Settings.serverHackState) {
									Response res = await ServerHack.hack(dio, item);
									itemRes._responseObj = res;
									itemRes.isOk = !(res is Error || res is Exception || res.statusCode != 200 || res.data == null);

									handler.resolve(res);
									return;
								}*/

								final ro = RequestOptions(path: uri);
								final res = Response<DioError>(requestOptions: ro,
										data: DioError(requestOptions: ro, error: err.error, type: DioErrorType.response));

								itemRes._responseObj = res;
								err.response = res;

								//handler.next(err);
								handler.resolve(res);
							}
					)
			);

			final cancelToken = CancelToken();
			itemRes.dio = dio;
			itemRes.canceller = cancelToken;

			itemRes._responseFuture = dio.request<dynamic>(
				uri,
				cancelToken: cancelToken,
				options: item.options,
				queryParameters: item.uriQueries,
				data: item.body,
				onReceiveProgress: item.onReceiveProgress,
				onSendProgress: item.onSendProgress,
			)
					.timeout(Duration(milliseconds: dio.options.connectTimeout + 2000), onTimeout: () async{

						/*if(Settings.serverHackState) {
							Response res = await ServerHack.hack(dio, item);
							itemRes._responseObj = res;
							itemRes.isOk = !(res is Error || res is Exception || res.statusCode != 200 || res.data == null);

							return res;
						}*/

						final ro = RequestOptions(path: uri);
						final res = Response<DioError>(requestOptions: ro, data: DioError(requestOptions: ro));
						itemRes._responseObj = res;
						return res;
						//bad: throw DioError(requestOptions: RequestOptions(path: uri));
						//return Future.error(DioError(requestOptions: RequestOptions(path: uri)));
			});
		}
		catch (e) {
			itemRes._responseFuture = Future.error(e);
		}

		return itemRes;
	}

	static HttpRequester download(HttpItem item, String savePath, {Duration? timeout}){
		final itemRes = HttpRequester();
		Dio dio;
		//rint(StackTrace.current);

		try {
			final bo = _getOptions();
			bo.connectTimeout = timeout != null ? timeout.inMilliseconds: 32000;
			dio = Dio();

			var uri = item.fullUri?? (baseUri + (item.pathSection?? ''));
			uri = correctUri(uri)!;

			if(proxyUri != null || item.proxyAddress != null) {
				(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
					client.findProxy = (uri) {
						return 'PROXY ${item.proxyAddress?? proxyUri}';
					};

					client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
				};
			}

			dio.interceptors.add(
					InterceptorsWrapper(
							onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
								options.headers['Connection'] = 'close';
								itemRes.requestOptions = options;

								handler.next(options);
							},

							onResponse: (Response<dynamic> res, ResponseInterceptorHandler handler) {
								itemRes._responseObj = res;

								itemRes.isOk = !(res is Error || res is Exception
										|| (res.statusCode != 200 && res.statusCode != 206) || res.data == null);

								handler.next(res);
							},

							onError: (DioError err, ErrorInterceptorHandler handler) {
								final ro = RequestOptions(path: uri);
								final Response res = Response<ResponseBody>(requestOptions: ro, data: ResponseBody.fromBytes([], 404));
								//Response res = Response<ResponseBody>(requestOptions: ro, data: ResponseBody.fromString('$err', 404));
								//Response res = Response<DioError>(requestOptions: ro, data: DioError(requestOptions: ro));
								itemRes._responseObj = res;
								err.response = res;
								itemRes.isOk = false;

								//handler.next(err);   < this take log error
								//handler.reject(err); < this take log error
								handler.resolve(res);
						})
			);

			final cancelToken = CancelToken();
			itemRes.dio = dio;
			itemRes.canceller = cancelToken;

			itemRes._responseFuture = dio.download(
					uri,
					savePath,
				cancelToken: cancelToken,
				options: item.options,
				queryParameters: item.uriQueries,
				data: item.body,
				onReceiveProgress: item.onReceiveProgress,
			);
		}
		catch (e) {
			itemRes._responseFuture = Future.error(e);
		}

		return itemRes;
	}

	// https://stackoverflow.com/questions/56638826/downloading-progress-in-darthttp
	static HttpRequester getHeaders(HttpItem item ,{Duration? timeout}){
		final itemRes = HttpRequester();

		try {
			//HttpClient g = HttpClient();  this is used in dio

			final client = http.Client();
			//final HttpClient client = HttpClient(); client.openUrl(request.method, Uri.parse(uri))

			var uri = item.fullUri?? (baseUri + (item.pathSection?? ''));
			uri = correctUri(uri)!;
			final http.BaseRequest request = http.Request(item.method?? 'GET', Uri.parse(uri));
			request.persistentConnection = false;
			request.headers['Range'] = 'bytes=0-'; // > Content-Range: bytes 0-1023/146515

			Future<http.StreamedResponse?> send = client.send(request);

			send = send
					.timeout(timeout?? Duration(seconds: 26),)
					.catchError((e){ // TimeoutException
						return null;
						//client.close();
					});

			itemRes._responseFuture = send.then((http.StreamedResponse? response) {
				if(response == null || response is Error) {
					return null;//Response<http.StreamedResponse>(data: null, requestOptions: RequestOptions(path: uri));
				}

				//Map headers = response.headers;
				itemRes.isOk = true;

				client.close();
				return Response<http.StreamedResponse>(data: response, requestOptions: RequestOptions(path: uri));
				/*
				int received = 0;
				int length = response.contentLength;

				StreamSubscription listen;
				listen = response.stream.listen((List<int> bytes) {
					received += bytes.length;

					if(received > 200) {
						client.close();
						listen.cancel();
					}
				},
				onDone: (){
					client.close();
					listen.cancel();
				},
				onError: (e){
					client.close();
					listen.cancel();
				},
				cancelOnError: true
				);*/
			});
		}
		catch (e) {
			itemRes._responseFuture = Future.error(e);
		}

		return itemRes;
	}
	///=====================================================================================================
	static void cancelAndClose(HttpRequester? request, {String passTag = 'my'}) {
		if(request != null){
			if(!(request.canceller?.isCancelled?? true)) {
			  request.canceller!.cancel(passTag);
			}

			request.dio?.close();
		}
	}

	static String? correctUri(String? uri) {
		if(uri == null) {
		  return null;
		}

		//return uri.replaceAll(RegExp('/{2,}'), "/").replaceFirst(':\/', ':\/\/');
		return uri.replaceAll(RegExp('(?<!:)(/{2,})'), '/');
	}
}
///========================================================================================================
class HttpRequester {
	late Future<Response?> _responseFuture;
	Response? _responseObj;
	RequestOptions? requestOptions;
	CancelToken? canceller;
	Dio? dio;
	bool isOk = false;
	Map<String, dynamic>? parts;

	HttpRequester(){
		_responseFuture = Future((){});
	}

	// maybe: Future<dynamic> vs Future<Response?>
	Future<dynamic> get responseFuture => _responseFuture;
	Response? get responseObj => _responseObj;

	dynamic getBody(){
		if(_responseObj == null) {
		  return null;
		}

		return _responseObj?.data;
	}

	Map<String, dynamic>? getBodyAsJson(){
		if(_responseObj == null) {
		  return null;
		}

		final receive = _responseObj?.data.toString();
		return JsonHelper.jsonToMap<String, dynamic>(receive);
	}

	Map<String, dynamic>? getPartByJsonName(){
		final parts = getParts();

		if(parts == null) {
		  return getBodyAsJson();
		}

		final List<int>? receive = parts['Json'];

		if(receive == null) {
		  return null;
		}

		return JsonHelper.jsonToMap(Converter.bytesToStringUtf8(receive));
	}

	dynamic getPart(String name){
		final parts = getParts();

		if(parts == null) {
		  return null;
		}

		return parts[name];
	}

	Map<String, dynamic>? getParts(){
		if(parts != null) {
		  return parts;
		}

		final List<int> bytes = _responseObj?.data;

		if(bytes[0] == 13 && bytes[1] == 10 && bytes[2] == 10 && bytes[3] == 10){
			parts = _reFactorBytes(bytes);
			_responseObj?.data = null;
			return parts;
		}

		return null;
	}

	Map<String, dynamic> _reFactorBytes(List<int> bytes){
		final res = <String, dynamic>{};
		late List<int> partSplitter;
		late List<int> nameSplitter;
		var idx = 0;

		for(var i = 5; i < bytes.length; i++){
			if(bytes[i] == 13 && bytes[i+1] == 10 && bytes[i+2] == 10 && bytes[i+3] == 10) {
				partSplitter = ListHelper.slice(bytes, 4, i - 4);
				idx = i+4;
				break;
			}
		}

		for(var i = idx+1; i < bytes.length; i++){
			if(bytes[i] == 13 && bytes[i+1] == 10 && bytes[i+2] == 10 && bytes[i+3] == 10) {
				nameSplitter = ListHelper.slice(bytes, idx, i - idx);
				idx = i+4;
				break;
			}
		}

		var p = idx;
		var n = idx;

		while(true){
			p = ListHelper.indexOf(bytes, partSplitter, start: p);

			if(p > -1) {
				p += partSplitter.length;

				n = ListHelper.indexOf(bytes, nameSplitter, start: p);

				if(n > -1) {
					final nameBytes = ListHelper.slice(bytes, p, n-p);
					final name = String.fromCharCodes(nameBytes);
					final lenIndex = n + nameSplitter.length;
					final lenBytes = ListHelper.slice(bytes, lenIndex, 4);
					final len = Int8List.fromList(lenBytes).buffer.asByteData().getInt32(0, Endian.big);
					res[name] = ListHelper.slice(bytes, lenIndex+4, len);
					p += len;
				}
			}
			else {
			  break;
			}
		}

		return res;
	}

	bool isError(){
		return _responseObj is Error || _responseObj is Exception;
	}

	bool get isDioCancelError {
		return _responseObj is DioError && (_responseObj as DioError).message == 'my';
	}

	bool isCancelError(dynamic e) {
		return e is DioError && e.message == 'my';
	}

	Response emptyError = Response<ResponseBody>(
			requestOptions: RequestOptions(path: ''), data: null);//ResponseBody.fromString('non', 404)
}
///===================================================================================================
class HttpItem {
	HttpItem();

	String? fullUri;
	String? _pathSection;
	String? proxyAddress;
	Map<String, dynamic> uriQueries = {};
	dynamic body;
	ProgressCallback? onSendProgress;
	ProgressCallback? onReceiveProgress;
	List<FormDataItem> formDataItems = [];
	Options options = Options(
		method: 'GET',
		receiveDataWhenStatusError: false,// if true: cache error in interceptors
		responseType: ResponseType.plain,
		//sendTimeout: ,
		//receiveTimeout: ,
	);

	String? get method => options.method;
	set method (String? m) {options.method = m;}

	String? get pathSection => _pathSection;

	set pathSection (String? p) {
		if(p.toString().startsWith(RegExp('^/?http.*', caseSensitive: false))) {
		  fullUri = UrlHelper.resolveUri(p);
		}
		else {
		  _pathSection = p;
		}
	}

	void addUriQuery(String key, dynamic value){
		uriQueries[key] = value;
	}

	void addMapUriQuery(Map<String, dynamic> map){
		for(var kv in map.entries) {
		  uriQueries[kv.key] = kv.value;
		}
	}

	/// response receive chunk chunk,  Response<ResponseBody> Stream<Uint8List>
	void setResponseIsStream(){
		options.responseType = ResponseType.stream;
	}

	/// response not convert to string, is List<int>
	void setResponseIsBytes(){
		options.responseType = ResponseType.bytes;
	}

	void setResponseIsPlain(){
		options.responseType = ResponseType.plain;
	}

	void setBody(String value){
		body = value;
	}

	void setBodyJson(Map js){
		body = system_convert.json.encode(js);
	}

	void addBodyField(String key, String value){
		if(body is! FormData) {
			body = FormData();
		}

		(body as FormData).fields.add(MapEntry(key, value));
	}

	void addBodyFile(String partName, String fileName, File file){
		if(body is! FormData) {
			body = FormData();
		}

		final itm = FormDataItem();
		itm.partName = partName;
		itm.fileName = fileName;
		itm.filePath = file.path;

		formDataItems.add(itm);
	}

	void addBodyBytes(String partName, String dataName, List<int> bytes){
		if(body is! FormData) {
			body = FormData();
		}

		final itm = FormDataItem();
		itm.partName = partName;
		itm.fileName = dataName;
		itm.bytes = bytes;

		formDataItems.add(itm);
	}

	void prepareMultiParts(){
		if(body is! FormData) {
			return;
		}

		final newBody = FormData();
		final oldBody = body as FormData;

		for(var f in oldBody.fields){
			newBody.fields.add(f);
		}

		for(var fd in formDataItems){
			if(fd.filePath != null){
				final m = MultipartFile.fromFileSync(fd.filePath!, filename: fd.fileName, contentType: fd.contentType);
				newBody.files.add(MapEntry(fd.partName, m));
			}
			else {
				final m = MultipartFile.fromBytes(fd.bytes!, filename: fd.fileName, contentType: fd.contentType);
				newBody.files.add(MapEntry(fd.partName, m));
			}
		}

		body = newBody;
	}
}
///=======================================================================================================
class FormDataItem {
	late String partName;
	late String fileName;
	String? filePath;
	List<int>? bytes;
	MediaType contentType = MediaType.parse('application/octet-stream');

	FormDataItem();
}
