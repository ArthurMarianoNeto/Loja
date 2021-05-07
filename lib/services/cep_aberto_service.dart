import 'dart:io';
import 'package:dio/dio.dart';
import 'package:loja/models/cep_aberto_address.dart';
import 'package:loja/screens/address/components/cep_imput_field.dart';

const token = 'e2f3190c84941b02576bd1fd17600cfb';

class CepAbertoService {

  Future<CepAbertoAddress> getAddressFromCep(String cep) async {
    final cleanCep = cep.replaceAll('.', '').replaceAll('-', '');
    final endpoint = "https://www.cepaberto.com/api/v3/cep?cep=$cleanCep";

    final Dio dio = Dio();

    dio.options.headers[HttpHeaders.authorizationHeader] = 'Token token=$token';

    try {
      final response = await dio.get<Map<String, dynamic>>(endpoint);

      if(response.data.isEmpty){
        return Future.error('CEP Inválido');
      }

    //  print(response.data);
      final CepAbertoAddress address = CepAbertoAddress.fromMap(response.data);
      return address;

    } on DioError catch (e){
      return Future.error('Erro ao buscar CEP');
    }
  }
}