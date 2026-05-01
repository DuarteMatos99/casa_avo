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

  // Converte Objeto para JSON (para guardar)
  Map<String, dynamic> toJson() => {
    'cliente': cliente,
    'prato': prato,
    'bebida': bebida,
    'sobremesa': sobremesa,
  };

  // Converte JSON para Objeto (para ler)
  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
    cliente: json['cliente'],
    prato: json['prato'],
    bebida: json['bebida'],
    sobremesa: json['sobremesa'],
  );
}
