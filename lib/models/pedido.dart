class Pedido {
  final String cliente;
  final String prato;
  final String bebida;
  final String sobremesa;
  final DateTime dataCriacao;
  final bool entregue;

  Pedido({
    required this.cliente,
    required this.prato,
    required this.bebida,
    required this.sobremesa,
    DateTime? dataCriacao,
    this.entregue = false,
  }) : dataCriacao = dataCriacao ?? DateTime.now();

  Pedido copiarCom({bool? entregue}) => Pedido(
    cliente: cliente,
    prato: prato,
    bebida: bebida,
    sobremesa: sobremesa,
    dataCriacao: dataCriacao,
    entregue: entregue ?? this.entregue,
  );

  Map<String, dynamic> toJson() => {
    'cliente': cliente,
    'prato': prato,
    'bebida': bebida,
    'sobremesa': sobremesa,
    'dataCriacao': dataCriacao.toIso8601String(),
    'entregue': entregue,
  };

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
    cliente: json['cliente'],
    prato: json['prato'] ?? '',
    bebida: json['bebida'] ?? '',
    sobremesa: json['sobremesa'] ?? '',
    dataCriacao: json['dataCriacao'] != null
        ? DateTime.parse(json['dataCriacao'])
        : DateTime.now(),
    entregue: json['entregue'] ?? false,
  );
}
