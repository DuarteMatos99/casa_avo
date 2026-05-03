import 'dart:async';
import 'package:flutter/material.dart';
import 'package:casa_avo/models/pedido.dart';
import 'package:casa_avo/models/ementa.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; // Necessário para o jsonEncode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // formularios no flutter precisam de uma key global
  final _formKey = GlobalKey<FormState>();

  // controladores dos TextFormFields
  final _clienteController = TextEditingController();
  final _pratoController = TextEditingController();
  final _bebidaController = TextEditingController();
  final _doceController = TextEditingController();
  final _paginaControlador = PageController();
  late final TabController _ementaTabControlador;

  // limpar os controladores quando o widget é destruído
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _temporizadorPurga?.cancel();
    _clienteController.dispose();
    _pratoController.dispose();
    _bebidaController.dispose();
    _doceController.dispose();
    _paginaControlador.dispose();
    _ementaTabControlador.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    if (estado == AppLifecycleState.resumed) _purgarExpirados();
  }

  // indice necessario para alterar os separadores das views
  int _indiceAtual = 0;

  // onde irao ser guardados os pedidos
  List<Pedido> _listaDePedidos = [];

  Ementa _ementa = Ementa();

  Key _chaveFormulario = UniqueKey();
  int? _indicePedidoEmEdicao;
  Timer? _temporizadorPurga;

  static const _limiteExpiracao = Duration(hours: 8);

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
      final agora = DateTime.now();
      final lista = jsonDecoded
          .map((item) => Pedido.fromJson(item))
          .where((p) => agora.difference(p.dataCriacao) < _limiteExpiracao)
          .toList();

      if (!mounted) return;
      setState(() {
        _listaDePedidos = lista;
      });
      await _guardarDados();
    }
  }

  void _purgarExpirados() {
    if (!mounted) return;
    final agora = DateTime.now();
    final lista = _listaDePedidos
        .where((p) => agora.difference(p.dataCriacao) < _limiteExpiracao)
        .toList();
    if (lista.length != _listaDePedidos.length) {
      setState(() => _listaDePedidos = lista);
      _guardarDados();
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
    WidgetsBinding.instance.addObserver(this);
    _ementaTabControlador = TabController(length: 3, vsync: this);
    _carregarDados(); // Carrega o que estava guardado
    _carregarEmenta();
    _temporizadorPurga = Timer.periodic(
      _limiteExpiracao,
      (_) => _purgarExpirados(),
    );
  }

  // Vai buscar os dados guardados no local storage - FIM +

  //VIEW principal da app
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Casa da Avó",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8C292C), Color(0xFF5C1A1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_indiceAtual == 1 && _listaDePedidos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Apagar todos',
              onPressed: _confirmarApagarTodos,
            ),
        ],
      ),

      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: _indiceAtual == 2
            ? null
            : (details) {
                final v = details.primaryVelocity ?? 0;
                if (v > 150 && _indiceAtual > 0) {
                  _paginaControlador.animateToPage(
                    _indiceAtual - 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else if (v < -150 && _indiceAtual < 2) {
                  _paginaControlador.animateToPage(
                    _indiceAtual + 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
        child: PageView(
          controller: _paginaControlador,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _indiceAtual = index),
          children: [_buildFormulario(), _buildLista(), _buildEmenta()],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceAtual,
        onDestinationSelected: (index) {
          setState(() => _indiceAtual = index);
          _paginaControlador.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.edit_note), label: 'Pedir'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Pedidos'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Ementa'),
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
      fillColor: const Color(0xFFEAE6DC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF8C292C), width: 2),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _indicePedidoEmEdicao != null
                          ? 'Editar pedido'
                          : 'Novo pedido',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Preenche os campos abaixo.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              TextFormField(
                controller: _clienteController,
                inputFormatters: [UpperCaseFirstLetterFormatter()],
                decoration: _decoracaoCampo(
                  'Para quem é?',
                  Icons.person_outline,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
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
                    backgroundColor: const Color(0xFF8C292C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _salvarPedido,
                  child: Text(
                    _indicePedidoEmEdicao != null
                        ? "Guardar Pedido"
                        : "Enviar Pedido",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (_indicePedidoEmEdicao != null) const SizedBox(height: 12),
              if (_indicePedidoEmEdicao != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _cancelarEdicao,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text("Cancelar edição"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 90, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Sem pedidos ainda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vai ao separador Pedir para começar.',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: _buildCartaoResumo(),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _listaDePedidos.length,
            itemBuilder: (context, index) {
              final pedido = _listaDePedidos[index];

              return Dismissible(
                key: ValueKey(pedido.dataCriacao.millisecondsSinceEpoch),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    _editarPedido(index);
                    return false;
                  }
                  return showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Apagar pedido'),
                      content: const Text(
                        'Tens a certeza que queres apagar este pedido?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text(
                            'Apagar',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) {
                  setState(() => _listaDePedidos.removeAt(index));
                  _guardarDados();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pedido removido!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                background: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                secondaryBackground: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 5, color: const Color(0xFF8C292C)),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: const Color(0xFFEDD5D5),
                                  child: Text(
                                    pedido.cliente.isNotEmpty
                                        ? pedido.cliente[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF8C292C),
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pedido.cliente,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          if (pedido.prato.isNotEmpty)
                                            _chip(
                                              Icons.restaurant,
                                              pedido.prato,
                                            ),
                                          if (pedido.bebida.isNotEmpty)
                                            _chip(
                                              Icons.local_bar,
                                              pedido.bebida,
                                            ),
                                          if (pedido.sobremesa.isNotEmpty)
                                            _chip(Icons.cake, pedido.sobremesa),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _tempoRelativo(pedido.dataCriacao),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: Colors.blueGrey,
                                      ),
                                      onPressed: () => _editarPedido(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () => _confirmarApagar(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCartaoResumo() {
    Map<String, int> contarItens(List<String> itens) {
      final contagem = <String, int>{};
      for (final item in itens) {
        if (item.isNotEmpty) contagem[item] = (contagem[item] ?? 0) + 1;
      }
      final ordenado = contagem.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return Map.fromEntries(ordenado);
    }

    final pratos = contarItens(_listaDePedidos.map((p) => p.prato).toList());
    final bebidas = contarItens(_listaDePedidos.map((p) => p.bebida).toList());
    final sobremesas = contarItens(
      _listaDePedidos.map((p) => p.sobremesa).toList(),
    );
    final total = _listaDePedidos.length;

    String textoResumoCompleto() {
      final linhas = <String>[
        'Resumo · $total ${total == 1 ? 'pedido' : 'pedidos'}',
      ];
      if (pratos.isNotEmpty) {
        linhas.add('\nPratos:');
        for (final e in pratos.entries) linhas.add('  (${e.value}×) ${e.key}');
      }
      if (bebidas.isNotEmpty) {
        linhas.add('\nBebidas:');
        for (final e in bebidas.entries) linhas.add('  (${e.value}×) ${e.key}');
      }
      if (sobremesas.isNotEmpty) {
        linhas.add('\nSobremesas:');
        for (final e in sobremesas.entries)
          linhas.add('  (${e.value}×) ${e.key}');
      }
      return linhas.join('\n');
    }

    void copiarResumo() {
      Clipboard.setData(ClipboardData(text: textoResumoCompleto()));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resumo copiado!'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    void abrirResumoCompleto() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.65,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 4, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Resumo · $total ${total == 1 ? 'pedido' : 'pedidos'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          size: 18,
                          color: Colors.black54,
                        ),
                        tooltip: 'Copiar resumo',
                        onPressed: () {
                          copiarResumo();
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pratos.isNotEmpty) ...[
                          _secaoResumoCompleto(
                            Icons.restaurant,
                            'Pratos',
                            pratos,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (bebidas.isNotEmpty) ...[
                          _secaoResumoCompleto(
                            Icons.local_bar,
                            'Bebidas',
                            bebidas,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (sobremesas.isNotEmpty)
                          _secaoResumoCompleto(
                            Icons.cake,
                            'Sobremesas',
                            sobremesas,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFFF5F0E8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: abrirResumoCompleto,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Resumo · $total ${total == 1 ? 'pedido' : 'pedidos'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.copy,
                      size: 18,
                      color: Colors.black54,
                    ),
                    onPressed: copiarResumo,
                    tooltip: 'Copiar resumo',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              if (pratos.isNotEmpty) _linhaResumo(Icons.restaurant, pratos),
              if (bebidas.isNotEmpty) _linhaResumo(Icons.local_bar, bebidas),
              if (sobremesas.isNotEmpty) _linhaResumo(Icons.cake, sobremesas),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secaoResumoCompleto(
    IconData icone,
    String titulo,
    Map<String, int> contagem,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icone, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ...contagem.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.only(left: 22, top: 2),
            child: Text(
              '(${e.value}×) ${e.key}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  Widget _linhaResumo(IconData icone, Map<String, int> contagem) {
    final texto = contagem.entries
        .map((e) => '(${e.value}×) ${e.key}')
        .join('  ·  ');
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmenta() {
    return Column(
      children: [
        TabBar(
          controller: _ementaTabControlador,
          labelColor: const Color(0xFF8C292C),
          indicatorColor: const Color(0xFF8C292C),
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Pratos'),
            Tab(icon: Icon(Icons.local_bar), text: 'Bebidas'),
            Tab(icon: Icon(Icons.cake), text: 'Sobremesas'),
          ],
        ),
        Expanded(
          child: NotificationListener<OverscrollNotification>(
            onNotification: (n) {
              if (n.overscroll < 0 && _ementaTabControlador.index == 0) {
                _paginaControlador.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
              return false;
            },
            child: TabBarView(
              controller: _ementaTabControlador,
              children: [
                _SecaoEmenta(
                  itens: _ementa.pratos,
                  onAdicionar: (item) {
                    if (!_ementa.pratos.contains(item)) {
                      setState(() {
                        _ementa = _ementa.copiarCom(
                          pratos: [..._ementa.pratos, item],
                        );
                      });
                      _guardarEmenta();
                    }
                  },
                  onRemover: (index) {
                    final novos = List<String>.from(_ementa.pratos)
                      ..removeAt(index);
                    setState(() => _ementa = _ementa.copiarCom(pratos: novos));
                    _guardarEmenta();
                  },
                  onApagarTodos: () {
                    setState(() => _ementa = _ementa.copiarCom(pratos: []));
                    _guardarEmenta();
                  },
                ),
                _SecaoEmenta(
                  itens: _ementa.bebidas,
                  onAdicionar: (item) {
                    if (!_ementa.bebidas.contains(item)) {
                      setState(() {
                        _ementa = _ementa.copiarCom(
                          bebidas: [..._ementa.bebidas, item],
                        );
                      });
                      _guardarEmenta();
                    }
                  },
                  onRemover: (index) {
                    final novos = List<String>.from(_ementa.bebidas)
                      ..removeAt(index);
                    setState(() => _ementa = _ementa.copiarCom(bebidas: novos));
                    _guardarEmenta();
                  },
                  onApagarTodos: () {
                    setState(() => _ementa = _ementa.copiarCom(bebidas: []));
                    _guardarEmenta();
                  },
                ),
                _SecaoEmenta(
                  itens: _ementa.sobremesas,
                  onAdicionar: (item) {
                    if (!_ementa.sobremesas.contains(item)) {
                      setState(() {
                        _ementa = _ementa.copiarCom(
                          sobremesas: [..._ementa.sobremesas, item],
                        );
                      });
                      _guardarEmenta();
                    }
                  },
                  onRemover: (index) {
                    final novos = List<String>.from(_ementa.sobremesas)
                      ..removeAt(index);
                    setState(
                      () => _ementa = _ementa.copiarCom(sobremesas: novos),
                    );
                    _guardarEmenta();
                  },
                  onApagarTodos: () {
                    setState(() => _ementa = _ementa.copiarCom(sobremesas: []));
                    _guardarEmenta();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icone, String texto) {
    return Chip(
      avatar: Icon(icone, size: 14, color: const Color(0xFF8C292C)),
      label: Text(texto, style: const TextStyle(fontSize: 12)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      side: const BorderSide(color: Color(0xFFD4C9B0)),
      backgroundColor: const Color(0xFFF5F0E8),
    );
  }

  Future<void> _confirmarApagarTodos() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar todos os pedidos'),
        content: const Text('Tens a certeza? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Apagar todos',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    setState(() => _listaDePedidos.clear());
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
            child: const Text(
              'Apagar',
              style: TextStyle(color: Colors.redAccent),
            ),
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
          content: Text('Pedido removido!'),
          duration: Duration(seconds: 1),
        ),
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
    _paginaControlador.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
          final dataOriginal =
              _listaDePedidos[_indicePedidoEmEdicao!].dataCriacao;
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
      _paginaControlador.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

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
    String prato,
    String bebida,
    String sobremesa,
  ) async {
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
        _ementa = _ementa.copiarCom(
          sobremesas: [..._ementa.sobremesas, sobremesa],
        );
      }
    });
    _guardarEmenta();
  }
}

class _SecaoEmenta extends StatefulWidget {
  final List<String> itens;
  final void Function(String) onAdicionar;
  final void Function(int) onRemover;
  final VoidCallback onApagarTodos;

  const _SecaoEmenta({
    required this.itens,
    required this.onAdicionar,
    required this.onRemover,
    required this.onApagarTodos,
  });

  @override
  State<_SecaoEmenta> createState() => _SecaoEmentaState();
}

class _SecaoEmentaState extends State<_SecaoEmenta> {
  final _controlador = TextEditingController();
  bool _carregando = false;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Future<void> _importarDaImagem() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar da ementa'),
        content: const Text(
          'Queres fazer upload de uma foto da ementa para extrair os itens automaticamente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    setState(() => _carregando = true);
    try {
      final picker = ImagePicker();
      final imagem = await picker.pickImage(source: ImageSource.gallery);
      if (imagem == null) return;

      final reconhecedor = TextRecognizer(script: TextRecognitionScript.latin);
      try {
        final inputImage = InputImage.fromFilePath(imagem.path);
        final resultado = await reconhecedor.processImage(inputImage);
        final candidatos = resultado.blocks
            .expand((b) => b.lines)
            .map((l) => l.text.trim())
            .where(_linhaValida)
            .map(_normalizarCapitalizacao)
            .toSet()
            .toList();

        if (!mounted) return;

        if (candidatos.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhum texto reconhecido na imagem.'),
            ),
          );
          return;
        }

        await _mostrarCandidatos(candidatos);
      } finally {
        await reconhecedor.close();
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  static const _termosIgnorados = [
    'segunda-feira',
    'segunda',
    'terça-feira',
    'terca-feira',
    'terça',
    'terca',
    'quarta-feira',
    'quarta',
    'quinta-feira',
    'quinta',
    'sexta-feira',
    'sexta',
    'sábado',
    'sabado',
    'domingo',
    'reservas',
    'pronto a comer',
    'casa da avó',
    'casa da avo',
    'comida caseira',
    'all images',
    'all photos',
    'reels',
    'mentions',
    'feita com',
    'de sempre',
    'e sabor',
    'menu de',
  ];

  static const _palavrasMinusculas = {
    'de',
    'da',
    'do',
    'das',
    'dos',
    'e',
    'ou',
    'a',
    'o',
    'as',
    'os',
    'em',
    'com',
    'para',
    'por',
    'que',
    'ao',
    'à',
    'aos',
    'às',
  };

  bool _linhaValida(String linha) {
    if (linha.length < 3) return false;
    if (RegExp(r'\d').hasMatch(linha)) return false;
    final semEspeciais = linha
        .replaceAll(RegExp(r'[.,€$%+\-*/\\()\[\]{}|<>@#!?;:_=]'), '')
        .trim();
    if (semEspeciais.length < 3) return false;
    final linhaLower = linha.toLowerCase().trim();
    for (final termo in _termosIgnorados) {
      if (linhaLower == termo || linhaLower.contains(termo)) return false;
    }
    return true;
  }

  String _normalizarCapitalizacao(String texto) {
    if (texto.isEmpty) return texto;
    final apenasLetras = texto.replaceAll(RegExp(r'[^a-zA-ZÀ-ÿ]'), '');
    if (apenasLetras.isNotEmpty && apenasLetras == apenasLetras.toUpperCase()) {
      final palavras = texto.split(' ');
      return palavras
          .asMap()
          .entries
          .map((e) {
            final p = e.value;
            if (p.isEmpty) return p;
            final pLower = p.toLowerCase();
            if (e.key > 0 && _palavrasMinusculas.contains(pLower))
              return pLower;
            return p[0].toUpperCase() + p.substring(1).toLowerCase();
          })
          .join(' ');
    }
    return texto[0].toUpperCase() + texto.substring(1);
  }

  Future<void> _mostrarCandidatos(List<String> candidatos) async {
    final selecionados = List<bool>.filled(candidatos.length, true);
    int? indiceEmEdicao;
    final ctrlEdicao = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setEstado) {
          void confirmarEdicao() {
            final texto = ctrlEdicao.text.trim();
            if (texto.isNotEmpty && indiceEmEdicao != null) {
              setEstado(() {
                candidatos[indiceEmEdicao!] = texto;
                indiceEmEdicao = null;
                ctrlEdicao.clear();
              });
            }
          }

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 4, 0),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Seleciona os itens a adicionar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: candidatos.length,
                      itemBuilder: (ctx, i) => ListTile(
                        onTap: () =>
                            setEstado(() => selecionados[i] = !selecionados[i]),
                        leading: Checkbox(
                          value: selecionados[i],
                          activeColor: const Color(0xFF8C292C),
                          onChanged: (val) =>
                              setEstado(() => selecionados[i] = val ?? false),
                        ),
                        title: Text(
                          candidatos[i],
                          style: TextStyle(
                            color: selecionados[i]
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: indiceEmEdicao == i
                                ? const Color(0xFF8C292C)
                                : Colors.blueGrey,
                          ),
                          onPressed: () => setEstado(() {
                            indiceEmEdicao = i;
                            ctrlEdicao.text = candidatos[i];
                          }),
                        ),
                      ),
                    ),
                  ),
                  if (indiceEmEdicao != null) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 12,
                        bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ctrlEdicao,
                              autofocus: true,
                              inputFormatters: [
                                UpperCaseFirstLetterFormatter(),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Editar item',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onSubmitted: (_) => confirmarEdicao(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8C292C),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: confirmarEdicao,
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8C292C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            for (int i = 0; i < candidatos.length; i++) {
                              if (selecionados[i])
                                widget.onAdicionar(candidatos[i]);
                            }
                            Navigator.of(ctx).pop();
                          },
                          child: const Text(
                            'Adicionar selecionados',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
    ctrlEdicao.dispose();
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
                  decoration: InputDecoration(
                    hintText: 'Novo item...',
                    prefixIcon: const Icon(Icons.edit_note, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFEAE6DC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF8C292C),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  onSubmitted: (val) {
                    if (val.isNotEmpty) {
                      widget.onAdicionar(val);
                      _controlador.clear();
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF8C292C)),
                onPressed: () {
                  if (_controlador.text.isNotEmpty) {
                    widget.onAdicionar(_controlador.text);
                    _controlador.clear();
                  }
                },
              ),
              IconButton(
                icon: _carregando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF8C292C),
                        ),
                      )
                    : const Icon(
                        Icons.document_scanner,
                        color: Color(0xFF8C292C),
                      ),
                onPressed: _carregando ? null : _importarDaImagem,
                tooltip: 'Importar da imagem',
              ),
              if (widget.itens.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                  tooltip: 'Apagar todos',
                  onPressed: () async {
                    final confirmado = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Apagar todos'),
                        content: const Text(
                          'Tens a certeza? Esta ação não pode ser desfeita.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text(
                              'Apagar todos',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmado == true) widget.onApagarTodos();
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
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
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
