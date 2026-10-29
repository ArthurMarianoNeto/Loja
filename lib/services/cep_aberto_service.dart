import 'dart:io';
import 'package:dio/dio.dart';
import 'package:loja/models/cep_aberto_address.dart';

const token = 'e2f3190c84941b02576bd1fd17600cfb';

class CepAbertoService {

  Future<CepAbertoAddress> getAddressFromCep(String cep) async {
    final cleanCep = cep.replaceAll('.', '').replaceAll('-', '');
    final endpoint = "https://www.cepaberto.com/api/v3/cep?cep=$cleanCep";

    final Dio dio = Dio();

    dio.options.headers[HttpHeaders.authorizationHeader] = 'Token token=$token';

    try {
      final response = await dio.get<Map<String, dynamic>>(endpoint);

      final data = response.data;
      if(data == null || data.isEmpty){
        return Future.error('CEP Inválido');
      }

      final CepAbertoAddress address = CepAbertoAddress.fromMap(data);
      return address;

    } on DioException {
      return Future.error('Erro ao buscar CEP');
    }
  }
}
