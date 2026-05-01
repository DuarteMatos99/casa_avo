// lib/models/pedido.dart

class Pedido {
  final String cliente;
  final String prato;
  final String bebida;
  final String sobremesa;

  Pedido({
    required this.cliente,
    required this.prato,
    required this.bebida,
    required this.sobremesa,
  });

  @override
  String toString() {
    return 'Pedido(cliente: $cliente, prato: $prato, bebida: $bebida, sobremesa: $sobremesa)';
  }
}
