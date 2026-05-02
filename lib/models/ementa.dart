class Ementa {
  final List<String> pratos;
  final List<String> bebidas;
  final List<String> sobremesas;

  Ementa({List<String>? pratos, List<String>? bebidas, List<String>? sobremesas})
      : pratos = pratos ?? [],
        bebidas = bebidas ?? [],
        sobremesas = sobremesas ?? [];

  Ementa copiarCom({List<String>? pratos, List<String>? bebidas, List<String>? sobremesas}) =>
      Ementa(
        pratos: pratos ?? List.from(this.pratos),
        bebidas: bebidas ?? List.from(this.bebidas),
        sobremesas: sobremesas ?? List.from(this.sobremesas),
      );

  Map<String, dynamic> toJson() => {
        'pratos': pratos,
        'bebidas': bebidas,
        'sobremesas': sobremesas,
      };

  factory Ementa.fromJson(Map<String, dynamic> json) => Ementa(
        pratos: List<String>.from(json['pratos'] ?? []),
        bebidas: List<String>.from(json['bebidas'] ?? []),
        sobremesas: List<String>.from(json['sobremesas'] ?? []),
      );
}
