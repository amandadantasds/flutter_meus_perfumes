import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; //importando as dependencias

void main() {
  runApp(const PerfumesApp());
} //rodando o app

class PerfumesApp extends StatelessWidget {
  const PerfumesApp({super.key});

  @override
  Widget build(BuildContext context) { //construindo a interface principal do app
    return MaterialApp(
      title: 'Meus Perfumes', //dando um título
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), //adicionando cor 
      ),
      home: const RmEntryScreen(), //chamando a tela de entrada do rm como home
      debugShowCheckedModeBanner: false,
    );
  }
}

/// --------------------- Model ---------------------
/// 
/// Criando o modelo esperado pela API
class Perfume {
  final String id;
  final String rm;
  final String imagem;
  final String nome;
  final String ml;

  Perfume({
    required this.id,
    required this.rm,
    required this.imagem,
    required this.nome,
    required this.ml,
  });

  factory Perfume.fromJson(Map<String, dynamic> json) {
    // cobre tanto `id` quanto `_id`
    return Perfume(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      rm: json['rm']?.toString() ?? '',
      imagem: json['imagem']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      ml: json['ml']?.toString() ?? '',
    );
  } // Cria um objeto perfume a partir de um json retornado pela API

  Map<String, dynamic> toJson() {
    return {'rm': rm, 'imagem': imagem, 'nome': nome, 'ml': ml};
  } //Cria um json do objeto perfume
}

/// --------------------- RM Entry Screen ---------------------
class RmEntryScreen extends StatefulWidget {
  const RmEntryScreen({super.key});

  @override
  State<RmEntryScreen> createState() => _RmEntryScreenState();
} //Cria a tela RM Screen que pode ter seu campo de rm alterado, por isso é Stateful

class _RmEntryScreenState extends State<RmEntryScreen> {
  final TextEditingController _rmController = TextEditingController(); //controla o que é digitado no campo de RM
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedRm();
  } //roda ao iniciar a tela

  Future<void> _loadSavedRm() async { //carrega o rm salvo 
    setState(() => _loading = true); //DEIXA A TELA COM CARREGANDO ENQUANTO BUSCA O RM
    final sp = await SharedPreferences.getInstance(); //ACESSA O CACHE DO CELULAR
    final saved = sp.getString('rm') ?? ''; //BUSCA O RM, SE ENCONTRAR USA O ENCONTRADO SE NÃO USA VAZIO
    _rmController.text = saved; //COLOCA O RM ENCONTRADO NO CAMPO DE TEXTO
    setState(() => _loading = false);
  }

  Future<void> _saveAndContinue() async {
    final rm = _rmController.text.trim(); //PEGA O TEXTO E FAZ UM TRATAMENTO PARA TIRAR OS ESPAÇOS
    if (rm.isEmpty) { // SE A PESSOA NÃO DIGITOU NADA, APARECE A MENSAGEM:
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, informe o RM')));
      return;
    }// SE A PESSOA DIGITOU:
    final sp = await SharedPreferences.getInstance();
    await sp.setString('rm', rm); //SALVA O RM NO CACHE 

    // MANDA PARA TELA DE LISTA PASSANDO O RM COMO PARAMETRO PARA QUE SEJA POSSÍVEL BUSCAR A LISTA DO USUÁRIO ESPECÍFICO
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PerfumeListScreen(rm: rm)),
    );
  }

//CONSTRUÇÃO DA TELA DE SOLICITAÇÃO DO RM
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informe seu RM'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _rmController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      labelText: 'RM',
                      border: OutlineInputBorder(),
                      hintText: 'Ex: 123456',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _saveAndContinue,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continuar'),
                  ),
                ],
              ),
            ),
    );
  }
}

/// --------------------- Perfume List Screen ---------------------
class PerfumeListScreen extends StatefulWidget {
  final String rm;
  const PerfumeListScreen({super.key, required this.rm}); //RECEBE O RM

  @override
  State<PerfumeListScreen> createState() => _PerfumeListScreenState();
}

class _PerfumeListScreenState extends State<PerfumeListScreen> {
  static const String baseUrl =
      'https://generic-items-api-a785ff596d21.herokuapp.com'; // DEFINE A URL DA API
  List<Perfume> perfumes = []; //MONTA O VETOR QUE VAI RETORNAR OS PERFUMES
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPerfumes(); //CARREGA OS PERFUMES
  }

  Future<void> fetchPerfumes() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse('$baseUrl/api/meusperfumes/${widget.rm}'); //DEFINE A URL FINAL QUE SERÁ ACESSADA
      final res = await http.get(url); //RECEBE O RETORNO DA API
      if (res.statusCode == 200) {//VERIFICA SE O STATUS É SUCESSO
        final body = jsonDecode(res.body); //TRANSFORMA O BODY
        if (body is List) { // SE O BODY FOR UMA LISTA
          perfumes = body.map((e) => Perfume.fromJson(e)).toList(); // SE FOR TRANSFORMA EM UMA LISTA DE PERFUMES
        } else {
          perfumes = []; //SE NÃO, RETORNA O ARRAY VAZIO
        }
      } else { //SE O STATUS NÃO FOR SUCESSO, RETORNA UM ERRO
        perfumes = [];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar: ${res.statusCode}')),
        );
      }
    } catch (e) {//SE DER ERRO NA INTERNET, RETORNA ERRO DE REDE
      perfumes = [];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro de rede: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deletePerfume(String id) async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse('$baseUrl/api/meusperfumes/${widget.rm}/$id');
      final res = await http.delete(url);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excluído com sucesso')));
        await fetchPerfumes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro de rede: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void openAddForm() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PerfumeFormScreen(rm: widget.rm)),
    );

    // se salvou (retornou true), recarrega a lista
    if (result == true) {
      fetchPerfumes();
    }
  }

  Future<void> _changeRm() async {
    // permite mudar RM: limpa o saved RM e volta para a tela de entrada
    final sp = await SharedPreferences.getInstance();
    await sp.remove('rm');
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RmEntryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meus Perfumes — RM: ${widget.rm}'),
        actions: [
          IconButton(
            tooltip: 'Mudar RM',
            onPressed: _changeRm,
            icon: const Icon(Icons.switch_account),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: fetchPerfumes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddForm,
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : perfumes.isEmpty
              ? const Center(child: Text('Nenhum perfume cadastrado para este RM'))
              : RefreshIndicator(
                  onRefresh: fetchPerfumes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: perfumes.length,
                    itemBuilder: (context, i) {
                      final p = perfumes[i];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: SizedBox(
                            width: 64,
                            height: 64,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: p.imagem.isNotEmpty
                                  ? Image.network(
                                      p.imagem,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                                      loadingBuilder: (c, w, chunk) {
                                        if (chunk == null) return w!;
                                        return const Center(child: CircularProgressIndicator());
                                      },
                                    )
                                  : const Icon(Icons.image_not_supported, size: 40),
                            ),
                          ),
                          title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('ml: ${p.ml}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Confirmar exclusão'),
                                  content: Text('Excluir "${p.nome}" ?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await deletePerfume(p.id);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

/// --------------------- Perfume Form Screen ---------------------
class PerfumeFormScreen extends StatefulWidget {
  final String rm;
  const PerfumeFormScreen({super.key, required this.rm});

  @override
  State<PerfumeFormScreen> createState() => _PerfumeFormScreenState();
}

class _PerfumeFormScreenState extends State<PerfumeFormScreen> {
  static const String baseUrl = 'https://generic-items-api-a785ff596d21.herokuapp.com';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _imagemController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _mlController = TextEditingController();
  bool _saving = false;
  String _imagePreviewUrl = '';

  @override
  void initState() {
    super.initState();
    _imagemController.addListener(_onImageChanged);
  }

  void _onImageChanged() {
    setState(() {
      _imagePreviewUrl = _imagemController.text.trim();
    });
  }

  Future<void> _savePerfume() async {
    if (!_formKey.currentState!.validate()) return;

    final perfume = Perfume(
      id: '',
      rm: widget.rm,
      imagem: _imagemController.text.trim(),
      nome: _nomeController.text.trim(),
      ml: _mlController.text.trim(),
    );

    setState(() => _saving = true);
    try {
      final url = Uri.parse('$baseUrl/api/meusperfumes');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(perfume.toJson()),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfume salvo com sucesso')));
        Navigator.of(context).pop(true); // retorna true indicando que salvou
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: ${res.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro de rede: $e')));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _imagemController.removeListener(_onImageChanged);
    _imagemController.dispose();
    _nomeController.dispose();
    _mlController.dispose();
    super.dispose();
  }

  Widget _imagePreviewWidget() {
    final url = _imagePreviewUrl;
    if (url.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: SizedBox(
        height: 180,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (c, e, s) => Container(
              color: Colors.grey[200],
              child: const Center(child: Icon(Icons.broken_image, size: 48)),
            ),
            loadingBuilder: (c, w, chunk) {
              if (chunk == null) return w!;
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Perfume')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Mostrar RM no topo (carregado do shared prefs e passado via parâmetro)
            Row(
              children: [
                const Icon(Icons.badge, size: 20),
                const SizedBox(width: 8),
                Text('RM: ${widget.rm}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _imagemController,
                    decoration: const InputDecoration(
                      labelText: 'URL da imagem (imagem)',
                      border: OutlineInputBorder(),
                      hintText: 'https://...jpg',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Imagem é obrigatória';
                      if (!v.trim().startsWith('http')) return 'Informe uma URL válida';
                      return null;
                    },
                  ),
                  // preview
                  _imagePreviewWidget(),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome é obrigatório' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mlController,
                    decoration: const InputDecoration(labelText: 'ml', border: OutlineInputBorder(), hintText: 'Ex: 50'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'ml é obrigatório' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                      label: Text(_saving ? 'Salvando...' : 'Salvar'),
                      onPressed: _saving ? null : _savePerfume,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}