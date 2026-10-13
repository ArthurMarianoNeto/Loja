import 'package:flutter_test/flutter_test.dart';
import 'package:loja/models/address.dart';
import 'package:loja/models/cep_aberto_address.dart';
import 'package:loja/models/credit_card.dart';
import 'package:loja/models/item_size.dart';
import 'package:loja/models/section.dart';
import 'package:loja/models/section_item.dart';

void main() {
  group('Address', () {
    test('fromMap/toMap preservam os campos', () {
      final map = {
        'street': 'Rua A',
        'number': '10',
        'complement': 'apto 1',
        'district': 'Centro',
        'zipCode': '01.001-000',
        'city': 'São Paulo',
        'state': 'SP',
        'lat': -23.5,
        'long': -46.6,
      };

      expect(Address.fromMap(map).toMap(), map);
    });

    test('aceita coordenadas inteiras vindas do Firestore', () {
      final address = Address.fromMap({'lat': -23, 'long': -46});

      expect(address.lat, -23.0);
      expect(address.long, -46.0);
    });
  });

  test('CepAbertoAddress.fromMap converte latitude/longitude em texto', () {
    final address = CepAbertoAddress.fromMap({
      'altitude': 760,
      'cep': '01001000',
      'latitude': '-23.5503',
      'longitude': '-46.6339',
      'logradouro': 'Praça da Sé',
      'bairro': 'Sé',
      'cidade': {'ddd': 11, 'ibge': '3550308', 'nome': 'São Paulo'},
      'estado': {'sigla': 'SP'},
    });

    expect(address.latitude, -23.5503);
    expect(address.longitude, -46.6339);
    expect(address.altitude, 760.0);
    expect(address.cidade.nome, 'São Paulo');
    expect(address.estado.sigla, 'SP');
  });

  group('ItemSize', () {
    test('hasStock depende do estoque', () {
      expect(ItemSize(name: 'P', price: 10, stock: 2).hasStock, isTrue);
      expect(ItemSize(name: 'P', price: 10, stock: 0).hasStock, isFalse);
      expect(ItemSize().hasStock, isFalse);
    });

    test('clone gera uma cópia independente', () {
      final size = ItemSize(name: 'M', price: 20, stock: 5);
      final clone = size.clone()..stock = 1;

      expect(size.stock, 5);
      expect(clone.toMap(), {'name': 'M', 'price': 20, 'stock': 1});
    });
  });

  group('CreditCard', () {
    test('detecta a bandeira com os nomes esperados pela Cloud Function', () {
      final card = CreditCard();

      card.setNumber('4111 1111 1111 1111');
      expect(card.brand, 'VISA');
      card.setNumber('5555 5555 5555 4444');
      expect(card.brand, 'MASTERCARD');
      card.setNumber('3782 822463 10005');
      expect(card.brand, 'AMEX');
      card.setNumber('3056 9309 0259 04');
      expect(card.brand, 'DINERSCLUB');
    });

    test('número desconhecido fica sem bandeira', () {
      final card = CreditCard()..setNumber('0000 0000 0000 0000');

      expect(card.brand, isNull);
    });

    test('toJson envia o número sem espaços', () {
      final card = CreditCard()
        ..setNumber('4111 1111 1111 1111')
        ..setHolder('Fulano de Tal')
        ..setExpirationDate('11/2029')
        ..setCVV('123');

      expect(card.toJson(), {
        'cardNumber': '4111111111111111',
        'holder': 'Fulano de Tal',
        'expirationDate': '11/2029',
        'securityCode': '123',
        'brand': 'VISA',
      });
    });
  });

  group('Section', () {
    test('valid exige título e ao menos uma imagem', () {
      final section = Section(type: 'List');
      expect(section.valid(), isFalse);
      expect(section.error, 'Título inválido');

      section.name = 'Promoções';
      expect(section.valid(), isFalse);
      expect(section.error, 'Insira ao menos uma imagem');

      section.addItem(SectionItem(image: 'https://exemplo.com/a.png'));
      expect(section.valid(), isTrue);
      expect(section.error, isNull);
    });

    test('clone copia os itens sem compartilhar a lista', () {
      final section = Section(
        id: 's1',
        name: 'Promoções',
        type: 'Staggered',
        items: [SectionItem(image: 'a.png', product: 'p1')],
      );
      final clone = section.clone();
      clone.removeItem(clone.items.first);

      expect(section.items, hasLength(1));
      expect(clone.id, 's1');
      expect(clone.items, isEmpty);
    });
  });
}
