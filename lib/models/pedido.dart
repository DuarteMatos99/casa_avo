class Pedido {
  final String cliente;
  final String prato;
  final String bebida;
  final String sobremesa;
  final DateTime dataCriacao;

  Pedido({
    required this.cliente,
    required this.prato,
    required this.bebida,
    required this.sobremesa,
    DateTime? dataCriacao,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  @override
  String toString() {
    return 'Pedido(cliente: $cliente, prato: $prato, bebida: $bebida, sobremesa: $sobremesa)';
  }

  Map<String, dynamic> toJson() => {
    'cliente': cliente,
    'prato': prato,
    'bebida': bebida,
    'sobremesa': sobremesa,
    'dataCriacao': dataCriacao.toIso8601String(),
  };

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
    cliente: json['cliente'],
    prato: json['prato'],
    bebida: json['bebida'],
    sobremesa: json['sobremesa'],
    dataCriacao: json['dataCriacao'] != null
        ? DateTime.parse(json['dataCriacao'])
        : DateTime.now(),
  );
}
