import 'package:credit_card_type_detector/credit_card_type_detector.dart';
class CreditCard {

  String? number;
  String? holder; //titular
  String? expirationDate;
  String? securityCode;
  String? brand; //bandeira

  void setHolder(String? name) => holder = name;
  void setExpirationDate(String? date) => expirationDate = date;
  void setCVV(String? cvv) => securityCode = cvv;
  void setNumber(String? number) {
    this.number = number;
    final types = detectCCType((number ?? '').replaceAll(' ', ''));
    // a Cloud Function authorizeCreditCard espera os nomes da versão antiga
    // do detector (VISA, MASTERCARD, AMEX, DINERSCLUB, ...)
    brand = types.isEmpty ? null : switch(types.first.type) {
      'american_express' => 'AMEX',
      'diners_club' => 'DINERSCLUB',
      final type => type.toUpperCase(),
    };
  }

  Map<String, dynamic> toJson(){

    return {
      'cardNumber': number?.replaceAll(' ', ''),
      'holder': holder,
      'expirationDate': expirationDate,
      'securityCode': securityCode,
      'brand': brand,
    };

  }

  @override
  String toString() {
    return 'CreditCard{number: $number, holder: $holder, expirationDate: $expirationDate, securityCode: $securityCode, brand: $brand}';
  }
}
