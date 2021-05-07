// definindo um padrão de endereço para o software inteiro independente do
// cep aberto, agora posso usar qualquer outra API de endereço
// arquivo dificilmente será modificado

class Address {

  Address({this.street, this.number, this.complement, this.district,
    this.zipCode, this.city, this.state, this.lat, this.long});

  String street;
  String number;
  String complement;
  String district; // bairro
  String zipCode;
  String city;
  String state;

  double lat;
  double long;

}