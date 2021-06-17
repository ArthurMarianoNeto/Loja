import 'package:cloud_functions/cloud_functions.dart';
import 'package:loja/models/credit_card.dart';
import 'package:loja/models/user.dart';

class CieloPayment {

  final CloudFunctions functions = CloudFunctions.instance;

  Future<void> authorize({CreditCard creditCard, num price, String orderId, User user}) async {

    final Map<String, dynamic> dataSale = {
      'merchantOrderId': orderId,
      'amount': (price * 100).toInt(),
      'softDescriptor': 'Mega Moda', //maximo 1 caracteres
      'installments': 1, // numero de parcelas
      'creditCard': creditCard.toJson(),
      'cpf': user.cpf,
      'paymentType': 'CreditCard',
    };

    final HttpsCallable callable = functions.getHttpsCallable(
        functionName: 'authorizeCreditCard'
    );
    final response = await callable.call(dataSale);
    print(response.data);
  }

}