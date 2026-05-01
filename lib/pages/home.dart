import 'package:flutter/material.dart';
import 'package:casa_avo/models/pedido.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();

  // controladores
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

  int _indiceAtual = 0; // Começa na primeira aba (Pedir)

  final List<Pedido> _listaDePedidos = [];

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
    return _listaDePedidos.isEmpty
        ? const Center(child: Text("Nenhum pedido feito ainda."))
        : ListView.builder(
            itemCount: _listaDePedidos.length,
            itemBuilder: (context, index) {
              final item = _listaDePedidos[index];
              return ListTile(
                title: Text(item.cliente),
                subtitle: Text(
                  "Prato: ${item.prato}\nBebida: ${item.bebida}\nSobremesa: ${item.sobremesa}",
                ),
              );
            },
          );
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
