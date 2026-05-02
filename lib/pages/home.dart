import 'package:flutter/material.dart';
import 'package:casa_avo/models/pedido.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; // Necessário para o jsonEncode
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // formularios no flutter precisam de uma key global
  final _formKey = GlobalKey<FormState>();

  // controladores dos TextFormFields
  final _clienteController = TextEditingController();
  final _pratoController = TextEditingController();
  final _bebidaController = TextEditingController();
  final _doceController = TextEditingController();

  // limpar os controladores quando o widget é destruído
  @override
  void dispose() {
    _clienteController.dispose();
    _pratoController.dispose();
    _bebidaController.dispose();
    _doceController.dispose();
    super.dispose();
  }

  // indice necessario para alterar os separadores das views
  int _indiceAtual = 0;

  // onde irao ser guardados os pedidos
  List<Pedido> _listaDePedidos = [];

  // Vai buscar os dados guardados no local storage - INICIO +
  Future<void> _guardarDados() async {
    final prefs = await SharedPreferences.getInstance();
    // Transformamos a lista de objetos numa String JSON
    final String dadosString = jsonEncode(
      _listaDePedidos.map((p) => p.toJson()).toList(),
    );
    await prefs.setString('meus_pedidos', dadosString);
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dadosString = prefs.getString('meus_pedidos');

    if (dadosString != null) {
      // Decodificamos a string para uma lista dinâmica
      final List<dynamic> jsonDecoded = jsonDecode(dadosString);

      setState(() {
        // Convertemos cada item do JSON para um objeto Pedido
        _listaDePedidos = jsonDecoded
            .map((item) => Pedido.fromJson(item))
            .toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarDados(); // Carrega o que estava guardado
  }

  // Vai buscar os dados guardados no local storage - FIM +

  //VIEW principal da app
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Casa da Avó"),
        backgroundColor: Colors.amber,
        centerTitle: true,
      ),

      // O corpo agora muda conforme o índice
      body: _indiceAtual == 0 ? _buildFormulario() : _buildLista(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceAtual, // Qual aba está marcada
        onTap: (index) {
          setState(() {
            _indiceAtual = index; // Muda a aba quando clicas
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.edit_note), label: 'Pedir'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Pedidos'),
        ],
      ),
    );
  }

  // Widget do Formulário
  Widget _buildFormulario() {
    return SingleChildScrollView(
      // Para não dar erro com o teclado
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _clienteController,
              inputFormatters: [UpperCaseFirstLetterFormatter()],
              decoration: const InputDecoration(labelText: 'Para quem é?'),
            ),
            TextFormField(
              controller: _pratoController,
              inputFormatters: [UpperCaseFirstLetterFormatter()],
              decoration: const InputDecoration(labelText: 'Prato'),
            ),
            TextFormField(
              controller: _bebidaController,
              inputFormatters: [UpperCaseFirstLetterFormatter()],
              decoration: const InputDecoration(labelText: 'Bebida'),
            ),
            TextFormField(
              controller: _doceController,
              inputFormatters: [UpperCaseFirstLetterFormatter()],
              decoration: const InputDecoration(labelText: 'Sobremesa'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _salvarPedido, // Criamos uma função separada para limpar o build
              child: const Text("Enviar Pedido"),
            ),
          ],
        ),
      ),
    );
  }

  // Widget da Lista
  Widget _buildLista() {
    if (_listaDePedidos.isEmpty) {
      return const Center(child: Text("Ainda não há pedidos."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _listaDePedidos.length,
      itemBuilder: (context, index) {
        final pedido = _listaDePedidos[index];

        return Opacity(
          opacity: pedido.entregue ? 0.45 : 1.0,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pedido.cliente,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            decoration: pedido.entregue ? TextDecoration.lineThrough : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _campoIcone(Icons.restaurant, pedido.prato),
                        const SizedBox(height: 2),
                        _campoIcone(Icons.local_bar, pedido.bebida),
                        const SizedBox(height: 2),
                        _campoIcone(Icons.cake, pedido.sobremesa),
                        const SizedBox(height: 6),
                        Text(
                          _tempoRelativo(pedido.dataCriacao),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          pedido.entregue ? Icons.check_circle : Icons.check_circle_outline,
                          color: pedido.entregue ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => _confirmarEntregue(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _confirmarApagar(index),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _campoIcone(IconData icone, String valor) {
    return Row(
      children: [
        Icon(icone, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(child: Text(valor, style: const TextStyle(fontSize: 13))),
      ],
    );
  }

  Future<void> _confirmarEntregue(int index) async {
    final pedido = _listaDePedidos[index];
    final novoEstado = !pedido.entregue;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(novoEstado ? 'Marcar como entregue' : 'Marcar como não entregue'),
        content: Text(
          novoEstado
              ? 'Tens a certeza que queres marcar este pedido como entregue?'
              : 'Tens a certeza que queres marcar este pedido como não entregue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    setState(() {
      _listaDePedidos[index] = pedido.copiarCom(entregue: novoEstado);
    });
    _guardarDados();
  }

  Future<void> _confirmarApagar(int index) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar pedido'),
        content: const Text('Tens a certeza que queres apagar este pedido?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Apagar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    setState(() => _listaDePedidos.removeAt(index));
    _guardarDados();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido removido!'), duration: Duration(seconds: 1)),
      );
    }
  }

  String _tempoRelativo(DateTime data) {
    final diferenca = DateTime.now().difference(data);
    if (diferenca.inSeconds < 60) return 'há menos de um minuto';
    if (diferenca.inMinutes < 60) {
      final m = diferenca.inMinutes;
      return 'há $m ${m == 1 ? 'minuto' : 'minutos'}';
    }
    if (diferenca.inHours < 24) {
      final h = diferenca.inHours;
      return 'há $h ${h == 1 ? 'hora' : 'horas'}';
    }
    final d = diferenca.inDays;
    return 'há $d ${d == 1 ? 'dia' : 'dias'}';
  }

  void _salvarPedido() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _listaDePedidos.add(
          Pedido(
            cliente: _clienteController.text,
            prato: _pratoController.text,
            bebida: _bebidaController.text,
            sobremesa: _doceController.text,
          ),
        );
      });

      //armezanar os dados no storage local
      _guardarDados();

      _clienteController.clear();
      _pratoController.clear();
      _bebidaController.clear();
      _doceController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido adicionado! Muda de aba para ver.'),
        ),
      );
    }
  }
}

// class para capitalizar a primeira letra de cada input do formulario
class UpperCaseFirstLetterFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Capitaliza apenas a primeira letra da string inteira
    String text = newValue.text[0].toUpperCase() + newValue.text.substring(1);

    return newValue.copyWith(text: text, selection: newValue.selection);
  }
}
