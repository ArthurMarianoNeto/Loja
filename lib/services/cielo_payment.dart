import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:loja/models/credit_card.dart';
import 'package:loja/models/app_user.dart';

class CieloPayment {

  final FirebaseFunctions functions = FirebaseFunctions.instance;

  Future<String> authorize({required CreditCard creditCard, required num price,
    required String orderId, required AppUser user}) async {

    final Map<String, dynamic> data;
    try {
      final Map<String, dynamic> dataSale = {
        'merchantOrderId': orderId,
        'amount': (price * 100).toInt(),
        'softDescriptor': 'Mega Moda', //maximo 13 caracteres
        'installments': 1, // número de parcelas
        'creditCard': creditCard.toJson(),
        'cpf': user.cpf,
        'paymentType': 'CreditCard',
      };

      final HttpsCallable callable = functions.httpsCallable(
        'authorizeCreditCard',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
      final response = await callable.call(dataSale);
      data = Map<String, dynamic>.from(response.data as Map);
    } catch (e){
      debugPrint('$e');
      return Future.error('Falha ao processar transação. Tente novamente.');
    }

    // erro devolvido pela Cielo: a mensagem dela vai para o usuário
    if (data['success'] as bool) {
      return data['paymentId'] as String;
    } else {
      debugPrint('${data['error']['message']}');
      return Future.error(data['error']['message']);
    }
  }

  Future<void> capture(String payId) async {
  final Map<String, dynamic> captureData = {
    'payId': payId
  };
  final HttpsCallable callable = functions.httpsCallable(
        'captureCreditCard',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
  final response = await callable.call(captureData);
 // print(response.data);
  final data = Map<String, dynamic>.from(response.data as Map);

      if (data['success'] as bool) {
        debugPrint('Captura realizada com sucesso');
      } else {
        debugPrint('${data['error']['message']}');
        return Future.error(data['error']['message']);
      }
  }

  Future<void> cancel(String payId) async {
    final Map<String, dynamic> cancelData = {
      'payId': payId
    };
    final HttpsCallable callable = functions.httpsCallable(
        'cancelCreditCard',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
    final response = await callable.call(cancelData);
    final data = Map<String, dynamic>.from(response.data as Map);

    if (data['success'] as bool) {
      debugPrint('Cancelamento realizado com sucesso');
    } else {
      debugPrint('${data['error']['message']}');
      return Future.error(data['error']['message']);
    }
  }
}