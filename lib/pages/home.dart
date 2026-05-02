import 'package:flutter/material.dart';
import 'package:casa_avo/models/pedido.dart';
import 'package:casa_avo/models/ementa.dart';
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

  Ementa _ementa = Ementa();

  Key _chaveFormulario = UniqueKey();
  int? _indicePedidoEmEdicao;

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
        _listaDePedidos = jsonDecoded.map((item) => Pedido.fromJson(item)).toList();
      });
    }
  }

  Future<void> _guardarEmenta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ementa', jsonEncode(_ementa.toJson()));
  }

  Future<void> _carregarEmenta() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dadosString = prefs.getString('ementa');
    if (dadosString != null) {
      setState(() {
        _ementa = Ementa.fromJson(jsonDecode(dadosString));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarDados(); // Carrega o que estava guardado
    _carregarEmenta();
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
      body: _indiceAtual == 0
          ? _buildFormulario()
          : _indiceAtual == 1
              ? _buildLista()
              : _buildEmenta(),

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
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Ementa'),
        ],
      ),
    );
  }

  // Widget do Formulário
  InputDecoration _decoracaoCampo(String rotulo, IconData icone) {
    return InputDecoration(
      labelText: rotulo,
      prefixIcon: Icon(icone),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.amber, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  Widget _buildFormulario() {
    return SingleChildScrollView(
      // Para não dar erro com o teclado
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: KeyedSubtree(
          key: _chaveFormulario,
          child: Column(
            children: [
              TextFormField(
                controller: _clienteController,
                inputFormatters: [UpperCaseFirstLetterFormatter()],
                decoration: _decoracaoCampo('Para quem é?', Icons.person_outline),
              ),
              const SizedBox(height: 12),
              _campoAutoComplete(
                opcoes: _ementa.pratos,
                controlador: _pratoController,
                rotulo: 'Prato',
                icone: Icons.restaurant,
              ),
              const SizedBox(height: 12),
              _campoAutoComplete(
                opcoes: _ementa.bebidas,
                controlador: _bebidaController,
                rotulo: 'Bebida',
                icone: Icons.local_bar,
              ),
              const SizedBox(height: 12),
              _campoAutoComplete(
                opcoes: _ementa.sobremesas,
                controlador: _doceController,
                rotulo: 'Sobremesa',
                icone: Icons.cake,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _salvarPedido,
                  child: Text(
                    _indicePedidoEmEdicao != null ? "Guardar Pedido" : "Enviar Pedido",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              if (_indicePedidoEmEdicao != null)
                TextButton(
                  onPressed: _cancelarEdicao,
                  child: const Text("Cancelar edição"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoAutoComplete({
    required List<String> opcoes,
    required TextEditingController controlador,
    required String rotulo,
    required IconData icone,
  }) {
    return Autocomplete<String>(
      initialValue: controlador.text.isNotEmpty
          ? TextEditingValue(text: controlador.text)
          : null,
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return const Iterable<String>.empty();
        return opcoes.where(
          (o) => o.toLowerCase().contains(value.text.toLowerCase()),
        );
      },
      onSelected: (String selecao) {
        controlador.text = selecao;
      },
      fieldViewBuilder: (context, campoControlador, focoNo, aoSubmeter) {
        return TextFormField(
          controller: campoControlador,
          focusNode: focoNo,
          inputFormatters: [UpperCaseFirstLetterFormatter()],
          decoration: _decoracaoCampo(rotulo, icone),
          onChanged: (val) => controlador.text = val,
        );
      },
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

        return Card(
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
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                  onPressed: () => _editarPedido(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmarApagar(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmenta() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.amber[800],
            indicatorColor: Colors.amber,
            tabs: const [
              Tab(icon: Icon(Icons.restaurant), text: 'Pratos'),
              Tab(icon: Icon(Icons.local_bar), text: 'Bebidas'),
              Tab(icon: Icon(Icons.cake), text: 'Sobremesas'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _SecaoEmenta(
                  itens: _ementa.pratos,
                  onAdicionar: (item) {
                    if (!_ementa.pratos.contains(item)) {
                      setState(() {
                        _ementa = _ementa.copiarCom(pratos: [..._ementa.pratos, item]);
                      });
                      _guardarEmenta();
                    }
                  },
                  onRemover: (index) {
                    final novos = List<String>.from(_ementa.pratos)..removeAt(index);
                    setState(() => _ementa = _ementa.copiarCom(pratos: novos));
                    _guardarEmenta();
                  },
                ),
                _SecaoEmenta(
                  itens: _ementa.bebidas,
                  onAdicionar: (item) {
                    if (!_ementa.bebidas.contains(item)) {
                      setState(() {
                        _ementa = _ementa.copiarCom(bebidas: [..._ementa.bebidas, item]);
                      });
                      _guardarEmenta();
                    }
                  },
                  onRemover: (index) {
                    final novos = List<String>.from(_ementa.bebidas)..removeAt(index);
                    setState(() => _ementa = _ementa.copiarCom(bebidas: novos));
                    _guardarEmenta();
                  },
                ),
                _SecaoEmenta(
                  itens: _ementa.sobremesas,
                  onAdicionar: (item) {
                    if (!_ementa.sobremesas.contains(item)) {
                      setState(() {
                        _ementa =
                            _ementa.copiarCom(sobremesas: [..._ementa.sobremesas, item]);
                      });
                      _guardarEmenta();
                    }
                  },
                  onRemover: (index) {
                    final novos = List<String>.from(_ementa.sobremesas)..removeAt(index);
                    setState(() => _ementa = _ementa.copiarCom(sobremesas: novos));
                    _guardarEmenta();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
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
        const SnackBar(
            content: Text('Pedido removido!'), duration: Duration(seconds: 1)),
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

  void _editarPedido(int index) {
    final pedido = _listaDePedidos[index];
    setState(() {
      _indicePedidoEmEdicao = index;
      _clienteController.text = pedido.cliente;
      _pratoController.text = pedido.prato;
      _bebidaController.text = pedido.bebida;
      _doceController.text = pedido.sobremesa;
      _chaveFormulario = UniqueKey();
      _indiceAtual = 0;
    });
  }

  void _cancelarEdicao() {
    setState(() {
      _indicePedidoEmEdicao = null;
      _clienteController.clear();
      _pratoController.clear();
      _bebidaController.clear();
      _doceController.clear();
      _chaveFormulario = UniqueKey();
    });
  }

  void _salvarPedido() {
    if (_formKey.currentState!.validate()) {
      final prato = _pratoController.text;
      final bebida = _bebidaController.text;
      final sobremesa = _doceController.text;

      setState(() {
        if (_indicePedidoEmEdicao != null) {
          final dataOriginal = _listaDePedidos[_indicePedidoEmEdicao!].dataCriacao;
          _listaDePedidos[_indicePedidoEmEdicao!] = Pedido(
            cliente: _clienteController.text,
            prato: prato,
            bebida: bebida,
            sobremesa: sobremesa,
            dataCriacao: dataOriginal,
          );
          _indicePedidoEmEdicao = null;
        } else {
          _listaDePedidos.add(
            Pedido(
              cliente: _clienteController.text,
              prato: prato,
              bebida: bebida,
              sobremesa: sobremesa,
            ),
          );
        }
        _chaveFormulario = UniqueKey();
        _indiceAtual = 1;
      });

      //armezanar os dados no storage local
      _guardarDados();

      _clienteController.clear();
      _pratoController.clear();
      _bebidaController.clear();
      _doceController.clear();

      _ofereceAdicionarAEmenta(prato, bebida, sobremesa);
    }
  }

  Future<void> _ofereceAdicionarAEmenta(
      String prato, String bebida, String sobremesa) async {
    final List<String> emFalta = [];
    if (prato.isNotEmpty && !_ementa.pratos.contains(prato)) {
      emFalta.add('Prato: $prato');
    }
    if (bebida.isNotEmpty && !_ementa.bebidas.contains(bebida)) {
      emFalta.add('Bebida: $bebida');
    }
    if (sobremesa.isNotEmpty && !_ementa.sobremesas.contains(sobremesa)) {
      emFalta.add('Sobremesa: $sobremesa');
    }

    if (emFalta.isEmpty) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar à ementa?'),
        content: Text(
          'Os seguintes itens não estão na ementa:\n\n${emFalta.map((e) => '• $e').join('\n')}\n\nQueres adicioná-los?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    setState(() {
      if (prato.isNotEmpty && !_ementa.pratos.contains(prato)) {
        _ementa = _ementa.copiarCom(pratos: [..._ementa.pratos, prato]);
      }
      if (bebida.isNotEmpty && !_ementa.bebidas.contains(bebida)) {
        _ementa = _ementa.copiarCom(bebidas: [..._ementa.bebidas, bebida]);
      }
      if (sobremesa.isNotEmpty && !_ementa.sobremesas.contains(sobremesa)) {
        _ementa = _ementa.copiarCom(sobremesas: [..._ementa.sobremesas, sobremesa]);
      }
    });
    _guardarEmenta();
  }
}

class _SecaoEmenta extends StatefulWidget {
  final List<String> itens;
  final void Function(String) onAdicionar;
  final void Function(int) onRemover;

  const _SecaoEmenta({
    required this.itens,
    required this.onAdicionar,
    required this.onRemover,
  });

  @override
  State<_SecaoEmenta> createState() => _SecaoEmentaState();
}

class _SecaoEmentaState extends State<_SecaoEmenta> {
  final _controlador = TextEditingController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controlador,
                  inputFormatters: [UpperCaseFirstLetterFormatter()],
                  decoration: const InputDecoration(hintText: 'Novo item...'),
                  onSubmitted: (val) {
                    if (val.isNotEmpty) {
                      widget.onAdicionar(val);
                      _controlador.clear();
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.amber),
                onPressed: () {
                  if (_controlador.text.isNotEmpty) {
                    widget.onAdicionar(_controlador.text);
                    _controlador.clear();
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.itens.isEmpty
              ? const Center(child: Text('Sem itens na ementa.'))
              : ListView.builder(
                  itemCount: widget.itens.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(widget.itens[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => widget.onRemover(index),
                    ),
                  ),
                ),
        ),
      ],
    );
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
