import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

const espresso = Color(0xFF1A0F08);
const roast = Color(0xFF2C1A0E);
const coffee = Color(0xFF5C3317);
const caramel = Color(0xFFC4863A);
const gold = Color(0xFFD4A843);
const cream = Color(0xFFF5EAD8);
const milk = Color(0xFFFDF6EC);
const marketGreen = Color(0xFF2D7A4F);
const marketRed = Color(0xFF9B2335);
const marketBlue = Color(0xFF2563A8);

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://cafeconectaoficial.vercel.app',
);

void main() {
  runApp(const CafeConectaApp());
}

class CafeConectaApp extends StatelessWidget {
  const CafeConectaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cafe Conecta',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: milk,
        colorScheme: ColorScheme.fromSeed(
          seedColor: caramel,
          brightness: Brightness.light,
        ),
        fontFamily: GoogleFonts.dmSans().fontFamily,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: espresso,
          indicatorColor: caramel,
          labelTextStyle: WidgetStatePropertyAll(TextStyle(color: cream)),
        ),
      ),
      home: const AuthPage(),
    );
  }
}

class ApiClient {
  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$apiBaseUrl$path');
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
    };
    late http.Response response;
    if (method == 'GET') {
      response = await http.get(uri, headers: headers);
    } else if (method == 'POST') {
      response = await http.post(uri, headers: headers, body: jsonEncode(body));
    } else if (method == 'DELETE') {
      response = await http.delete(uri, headers: headers);
    } else {
      response =
          await http.patch(uri, headers: headers, body: jsonEncode(body));
    }
    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(
          data['detail'] ?? 'Nao foi possivel concluir a operacao.');
    }
    return data;
  }

  Future<Map<String, dynamic>> login(String email, String senha) =>
      _request('POST', '/auth/login', body: {'email': email, 'senha': senha});

  Future<Map<String, dynamic>> cadastro(Map<String, dynamic> body) =>
      _request('POST', '/auth/cadastro', body: body);

  Future<List<Map<String, dynamic>>> cafes({int scoreMinimo = 0}) async {
    final data = await _request(
      'GET',
      '/cafes${scoreMinimo > 0 ? '?score_minimo=$scoreMinimo' : ''}',
    );
    return List<Map<String, dynamic>>.from(data['cafes'] ?? const []);
  }

  Future<Map<String, dynamic>> dashboard(int id) =>
      _request('GET', '/dashboard/$id');

  Future<void> criarCafe(Map<String, dynamic> body) async {
    await _request('POST', '/cafes', body: body);
  }

  Future<void> criarProposta(Map<String, dynamic> body) async {
    await _request('POST', '/propostas', body: body);
  }

  Future<void> enviarMensagem(Map<String, dynamic> body) async {
    await _request('POST', '/mensagens', body: body);
  }

  Future<int> mensagensNaoLidas(int usuarioId) async {
    final data = await _request('GET', '/mensagens/nao-lidas/$usuarioId');
    return (data['total'] as num?)?.toInt() ?? 0;
  }

  Future<List<Map<String, dynamic>>> conversas(int usuarioId) async {
    final data = await _request('GET', '/mensagens/usuario/$usuarioId');
    return List<Map<String, dynamic>>.from(data['mensagens'] ?? const []);
  }

  Future<List<Map<String, dynamic>>> conversa(
      int usuario1, int usuario2) async {
    final data = await _request(
      'GET',
      '/mensagens/conversa?usuario1=$usuario1&usuario2=$usuario2',
    );
    return List<Map<String, dynamic>>.from(data['mensagens'] ?? const []);
  }

  Future<List<Map<String, dynamic>>> propostas(int usuarioId) async {
    final data = await _request('GET', '/propostas/usuario/$usuarioId');
    return List<Map<String, dynamic>>.from(data['propostas'] ?? const []);
  }

  Future<void> atualizarProposta(int id, String status) async {
    await _request('PATCH', '/propostas/$id', body: {'status': status});
  }

  Future<List<Map<String, dynamic>>> alertas(int usuarioId) async {
    final data = await _request('GET', '/alertas/usuario/$usuarioId');
    return List<Map<String, dynamic>>.from(data['alertas'] ?? const []);
  }

  Future<void> criarAlerta(Map<String, dynamic> body) async {
    await _request('POST', '/alertas', body: body);
  }

  Future<void> deletarAlerta(int id) async {
    await _request('DELETE', '/alertas/$id');
  }

  Future<Map<String, dynamic>> cotacoes() => _request('GET', '/cotacoes');

  Future<List<Map<String, dynamic>>> historicoCotacoes() async {
    final data = await _request('GET', '/cotacoes/historico');
    return List<Map<String, dynamic>>.from(data['historico'] ?? const []);
  }

  Future<List<Map<String, dynamic>>> noticias() async {
    final data = await _request('GET', '/noticias');
    return List<Map<String, dynamic>>.from(data['noticias'] ?? const []);
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final api = ApiClient();
  final email = TextEditingController();
  final senha = TextEditingController();
  final nome = TextEditingController();
  bool cadastro = false;
  bool loading = false;
  String tipo = 'produtor';

  Future<void> submit() async {
    setState(() => loading = true);
    try {
      final result = cadastro
          ? await api.cadastro({
              'nome': nome.text.trim(),
              'email': email.text.trim(),
              'senha': senha.text,
              'tipo': tipo,
            })
          : await api.login(email.text.trim(), senha.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AppShell(user: result['usuario'])),
      );
    } catch (error) {
      if (mounted) {
        showMessage(context, error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CAFE CONECTA',
                    style: TextStyle(
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45F32))),
                const SizedBox(height: 18),
                Text(
                    cadastro
                        ? 'Entre para a rede.'
                        : 'O mercado do cafe, conectado.',
                    style: const TextStyle(
                        fontSize: 38,
                        height: 1.05,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                    cadastro
                        ? 'Crie seu perfil e comece a negociar.'
                        : 'Encontre lotes, parceiros e novas oportunidades.',
                    style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 16,
                        height: 1.4)),
                const SizedBox(height: 32),
                if (cadastro) ...[
                  TextField(
                      controller: nome,
                      decoration:
                          const InputDecoration(labelText: 'Nome completo')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                      initialValue: tipo,
                      decoration: const InputDecoration(labelText: 'Perfil'),
                      items: const [
                        DropdownMenuItem(
                            value: 'produtor', child: Text('Produtor')),
                        DropdownMenuItem(
                            value: 'comprador', child: Text('Comprador')),
                        DropdownMenuItem(
                            value: 'corretor', child: Text('Corretor'))
                      ],
                      onChanged: (value) => setState(() => tipo = value!)),
                  const SizedBox(height: 12),
                ],
                TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail')),
                const SizedBox(height: 12),
                TextField(
                    controller: senha,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Senha')),
                const SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: loading ? null : submit,
                        style: FilledButton.styleFrom(
                            padding: const EdgeInsets.all(16)),
                        child: Text(loading
                            ? 'Aguarde...'
                            : cadastro
                                ? 'Criar conta'
                                : 'Entrar'))),
                const SizedBox(height: 12),
                Center(
                    child: TextButton(
                        onPressed: () => setState(() => cadastro = !cadastro),
                        child: Text(cadastro
                            ? 'Ja tenho uma conta'
                            : 'Criar uma conta'))),
                if (apiBaseUrl.contains('SEU-PROJETO'))
                  const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text('Configure API_BASE_URL antes de testar.',
                          style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.user});
  final Map<String, dynamic> user;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final api = ApiClient();

  @override
  Widget build(BuildContext context) {
    final pages = [
      MarketplacePage(api: api, user: widget.user),
      QuotesPage(api: api),
      ProposalsPage(api: api, user: widget.user),
      AlertsPage(api: api, user: widget.user),
      ProfilePage(
        user: widget.user,
        onMessages: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MessagesPage(api: api, user: widget.user),
          ),
        ),
      ),
    ];
    return Scaffold(
      body: SafeArea(child: pages[index]),
      floatingActionButton: index == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Novo anúncio')),
                    body: NewCafePage(user: widget.user, api: api),
                  ),
                ),
              ),
              backgroundColor: caramel,
              foregroundColor: espresso,
              icon: const Icon(Icons.add),
              label: const Text('Anunciar lote'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.storefront_outlined), label: 'Catálogo'),
            NavigationDestination(
                icon: Icon(Icons.show_chart_rounded), label: 'Preços'),
            NavigationDestination(
                icon: Icon(Icons.description_outlined), label: 'Propostas'),
            NavigationDestination(
                icon: Icon(Icons.notifications_active_outlined),
                label: 'Alertas'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: 'Perfil')
          ]),
    );
  }
}

class QuotesPage extends StatefulWidget {
  const QuotesPage({super.key, required this.api});
  final ApiClient api;

  @override
  State<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  late Future<Map<String, dynamic>> quotes;
  late Future<List<Map<String, dynamic>>> history;
  late Future<List<Map<String, dynamic>>> news;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 3, vsync: this);
    _load();
  }

  void _load() {
    quotes = widget.api.cotacoes();
    history = widget.api.historicoCotacoes();
    news = widget.api.noticias();
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  void refresh() {
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: espresso,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cotações de Café',
                            style: GoogleFonts.playfairDisplay(
                                color: gold,
                                fontSize: 21,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        const Row(children: [
                          Icon(Icons.circle, size: 7, color: Color(0xFF6DFFAA)),
                          SizedBox(width: 6),
                          Text('Mercado • atualização ao vivo',
                              style: TextStyle(
                                  color: Color(0x99F5EAD8), fontSize: 11)),
                        ]),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Atualizar cotações',
                    onPressed: refresh,
                    color: cream,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              TabBar(
                controller: tabs,
                labelColor: gold,
                unselectedLabelColor: const Color(0x99F5EAD8),
                indicatorColor: caramel,
                indicatorWeight: 2,
                tabs: const [
                  Tab(text: 'Cotações'),
                  Tab(text: 'Gráfico'),
                  Tab(text: 'Notícias'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabs,
            children: [
              _QuotesTab(future: quotes),
              _HistoryTab(future: history, quotesFuture: quotes),
              _NewsTab(future: news),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuotesTab extends StatelessWidget {
  const _QuotesTab({required this.future});
  final Future<Map<String, dynamic>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: caramel));
        }
        if (snapshot.hasError) return _LoadError(message: '${snapshot.error}');
        final data = snapshot.data ?? {};
        final dollar = _asMap(data['dolar']);
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _DollarCard(data: dollar),
            const _MarketSectionTitle(
                title: 'Mercado Físico — Brasil',
                subtitle: 'Indicadores CEPEA/ESALQ'),
            _QuoteCard(
                data: _asMap(data['arabica_cepea']),
                icon: Icons.coffee_rounded,
                color: caramel,
                subtitle: 'Tipo 6 • bebida dura • saca de 60 kg'),
            _QuoteCard(
                data: _asMap(data['conilon_cepea']),
                icon: Icons.grain_rounded,
                color: marketGreen,
                subtitle: 'Conilon / robusta • saca de 60 kg'),
            const SizedBox(height: 10),
            const _MarketSectionTitle(
                title: 'Mercado Futuro — Internacional',
                subtitle: 'B3 e ICE/NY'),
            _QuoteCard(
                data: _asMap(data['cafe_b3']),
                icon: Icons.show_chart_rounded,
                color: marketBlue,
                subtitle: 'Contrato futuro ICF'),
            _QuoteCard(
                data: _asMap(data['cafe_ny']),
                icon: Icons.public_rounded,
                color: const Color(0xFF7B5EA7),
                subtitle: 'ICE Futures • Coffee C'),
            const SizedBox(height: 10),
            const _SourcesCard(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _DollarCard extends StatelessWidget {
  const _DollarCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final variation = _asMap(data['variacao']);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: espresso, borderRadius: BorderRadius.circular(11)),
      child: Row(children: [
        const Icon(Icons.attach_money_rounded, size: 28, color: gold),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Dólar Comercial • Banco Central',
              style: TextStyle(color: Color(0x99F5EAD8), fontSize: 10)),
          Text(_money(data['preco']),
              style: GoogleFonts.playfairDisplay(
                  color: gold, fontSize: 22, fontWeight: FontWeight.bold)),
        ])),
        _VariationBadge(data: variation),
      ]),
    );
  }
}

class _MarketSectionTitle extends StatelessWidget {
  const _MarketSectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 16, fontWeight: FontWeight.bold, color: roast)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: coffee)),
        ]),
      );
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard(
      {required this.data,
      required this.icon,
      required this.color,
      required this.subtitle});
  final Map<String, dynamic> data;
  final IconData icon;
  final Color color;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final variation = _asMap(data['variacao']);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, color: color)),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${data['tipo'] ?? 'Café'} • ${data['fonte'] ?? ''}',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: roast)),
                  Text(subtitle,
                      style: const TextStyle(color: coffee, fontSize: 10)),
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_money(data['preco']),
                  style: GoogleFonts.playfairDisplay(
                      color: color, fontSize: 17, fontWeight: FontWeight.bold)),
              Text('${data['unidade'] ?? ''}',
                  style: const TextStyle(fontSize: 9, color: coffee)),
            ]),
          ]),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _VariationBadge(data: variation),
            Text('${data['data'] ?? ''}',
                style: const TextStyle(fontSize: 10, color: coffee)),
          ]),
        ]),
      ),
    );
  }
}

class _VariationBadge extends StatelessWidget {
  const _VariationBadge({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final positive = data['positivo'] != false;
    final color = positive ? marketGreen : marketRed;
    final percent = (data['percentual'] as num?)?.toDouble() ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .22))),
      child: Text(
          '${positive ? '▲' : '▼'} ${percent.abs().toStringAsFixed(2)}%',
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.future, required this.quotesFuture});
  final Future<List<Map<String, dynamic>>> future;
  final Future<Map<String, dynamic>> quotesFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: caramel));
        }
        if (snapshot.hasError) {
          return _LoadError(message: '${snapshot.error}');
        }
        final points = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evolução nas últimas 24h',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: roast,
                      ),
                    ),
                    const Text(
                      'Preço médio por saca de 60 kg (R\$)',
                      style: TextStyle(color: coffee, fontSize: 11),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(height: 210, child: _PriceChart(points: points)),
                    const SizedBox(height: 10),
                    const Row(
                      children: [
                        _ChartLegend(color: caramel, label: 'Arábica'),
                        SizedBox(width: 18),
                        _ChartLegend(color: marketGreen, label: 'Conilon'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>>(
              future: quotesFuture,
              builder: (context, quoteSnapshot) {
                final data = quoteSnapshot.data ?? {};
                final arabica = _asMap(data['arabica_cepea']);
                final conilon = _asMap(data['conilon_cepea']);
                final dollar = _asMap(data['dolar']);
                final arabicaPrice =
                    (arabica['preco'] as num?)?.toDouble() ?? 0;
                final conilonPrice =
                    (conilon['preco'] as num?)?.toDouble() ?? 0;
                final dollarPrice = (dollar['preco'] as num?)?.toDouble() ?? 0;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumo do mercado',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: roast,
                          ),
                        ),
                        _StatRow(
                          label: 'Arábica atual',
                          value: _money(arabicaPrice),
                          color: caramel,
                        ),
                        _StatRow(
                          label: 'Conilon atual',
                          value: _money(conilonPrice),
                          color: marketGreen,
                        ),
                        _StatRow(
                          label: 'Spread Arábica / Conilon',
                          value: _money(arabicaPrice - conilonPrice),
                          color: marketBlue,
                        ),
                        _StatRow(
                          label: 'Dólar comercial',
                          value: _money(dollarPrice),
                          color: roast,
                        ),
                        _StatRow(
                          label: 'Arábica em USD/sc',
                          value: dollarPrice == 0
                              ? '-'
                              : 'US\$ ${(arabicaPrice / dollarPrice).toStringAsFixed(2)}',
                          color: const Color(0xFF7B5EA7),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _PriceChart extends StatelessWidget {
  const _PriceChart({required this.points});
  final List<Map<String, dynamic>> points;
  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _PriceChartPainter(points), child: const SizedBox.expand());
}

class _PriceChartPainter extends CustomPainter {
  _PriceChartPainter(this.points);
  final List<Map<String, dynamic>> points;
  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const inset = 8.0;
    final chart = Rect.fromLTWH(
        inset, inset, size.width - inset * 2, size.height - inset * 2);
    final values = points
        .expand((point) => [
              (point['arabica'] as num?)?.toDouble() ?? 0,
              (point['conilon'] as num?)?.toDouble() ?? 0
            ])
        .toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final span = math.max(1.0, maxValue - minValue);
    final gridPaint = Paint()
      ..color = coffee.withValues(alpha: .11)
      ..strokeWidth = 1;
    for (var row = 0; row < 4; row++) {
      final y = chart.top + chart.height * row / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }
    void drawSeries(String key, Color color) {
      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final value = (points[i][key] as num?)?.toDouble() ?? 0;
        final x = chart.left + chart.width * i / math.max(1, points.length - 1);
        final y = chart.bottom - ((value - minValue) / span) * chart.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);
    }

    drawSeries('arabica', caramel);
    drawSeries('conilon', marketGreen);
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(width: 18, height: 3, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: coffee))
      ]);
}

class _StatRow extends StatelessWidget {
  const _StatRow(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: coffee, fontSize: 12)),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12))
      ]));
}

class _NewsTab extends StatelessWidget {
  const _NewsTab({required this.future});
  final Future<List<Map<String, dynamic>>> future;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: caramel),
          );
        }
        if (snapshot.hasError) {
          return _LoadError(message: '${snapshot.error}');
        }
        final news = snapshot.data ?? [];
        if (news.isEmpty) {
          return const Center(child: Text('Nenhuma notícia disponível.'));
        }
        return ListView(
          padding: const EdgeInsets.all(14),
          children: news.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 9),
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () async {
                  final link = Uri.tryParse('${item['link'] ?? ''}');
                  if (link != null &&
                      (link.scheme == 'https' || link.scheme == 'http')) {
                    await launchUrl(
                      link,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: caramel.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '${item['fonte'] ?? 'Notícias'}',
                              style: const TextStyle(
                                color: caramel,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${item['data'] ?? ''}',
                            style: const TextStyle(color: coffee, fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${item['titulo'] ?? ''}',
                        style: const TextStyle(
                          color: roast,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.open_in_new, color: caramel, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Ler matéria completa',
                            style: TextStyle(
                              color: caramel,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SourcesCard extends StatelessWidget {
  const _SourcesCard();
  @override
  Widget build(BuildContext context) => const Card(
      child: Padding(
          padding: EdgeInsets.all(13),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Fontes dos indicadores',
                style: TextStyle(
                    color: roast, fontWeight: FontWeight.bold, fontSize: 12)),
            SizedBox(height: 6),
            Text('• CEPEA/ESALQ — mercado físico de café',
                style: TextStyle(color: coffee, fontSize: 10)),
            Text('• Banco Central — dólar PTAX',
                style: TextStyle(color: coffee, fontSize: 10)),
            Text('• B3 e ICE/NY — contratos futuros',
                style: TextStyle(color: coffee, fontSize: 10)),
            Text('• Notícias Agrícolas — notícias do setor',
                style: TextStyle(color: coffee, fontSize: 10)),
          ])));
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Não foi possível carregar os dados. $message',
              style: const TextStyle(color: marketRed))));
}

Map<String, dynamic> _asMap(dynamic value) =>
    value is Map<String, dynamic> ? value : <String, dynamic>{};

String _money(dynamic value) {
  final amount = (value as num?)?.toDouble();
  if (amount == null) return '—';
  final pieces = amount.toStringAsFixed(2).split('.');
  final whole = pieces.first.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.');
  return 'R\$ $whole,${pieces.last}';
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.user, required this.api});
  final Map<String, dynamic> user;
  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: api.dashboard(user['id'] as int),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        return ListView(padding: const EdgeInsets.all(24), children: [
          Text('Bom dia, ${user['nome'] ?? 'cafeicultor'}',
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          const Text('Seu mercado hoje.',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: const Color(0xFF18211B),
                  borderRadius: BorderRadius.circular(22)),
              child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CAFE CONECTA',
                        style: TextStyle(
                            color: Color(0xFFD9915B), letterSpacing: 2)),
                    SizedBox(height: 12),
                    Text('Decisoes melhores\ncom conexoes melhores.',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text('Acompanhe seus lotes e negocie com confianca.',
                        style: TextStyle(color: Colors.white70))
                  ])),
          const SizedBox(height: 24),
          const Text('Resumo da operacao',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: StatCard(
                    label: 'Lotes ativos',
                    value: '${data['total_lotes'] ?? '-'}')),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard(
                    label: 'Propostas',
                    value: '${data['total_propostas'] ?? '-'}')),
            const SizedBox(width: 10),
            Expanded(
                child: StatCard(
                    label: 'Nota media',
                    value: '${data['media_avaliacao'] ?? '-'}'))
          ]),
        ]);
      },
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45F32))),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700))
          ])));
}

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key, required this.api, required this.user});
  final ApiClient api;
  final Map<String, dynamic> user;
  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  late Future<List<Map<String, dynamic>>> future;
  late Future<int> unreadMessages;
  int minimumScore = 0;

  @override
  void initState() {
    super.initState();
    future = widget.api.cafes();
    unreadMessages = widget.api.mensagensNaoLidas(widget.user['id'] as int);
  }

  void openMessages() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => MessagesPage(api: widget.api, user: widget.user),
          ),
        )
        .then((_) {
          if (mounted) {
            setState(() {
              unreadMessages =
                  widget.api.mensagensNaoLidas(widget.user['id'] as int);
            });
          }
        });
  }

  void setMinimumScore(int score) {
    setState(() {
      minimumScore = score;
      future = widget.api.cafes(scoreMinimo: score);
    });
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cafés disponíveis',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: roast,
                      ),
                    ),
                    Text(
                      'Encontre seu próximo lote',
                      style: TextStyle(color: Colors.brown.shade600),
                    ),
                  ],
                ),
              ),
              FutureBuilder<int>(
                future: unreadMessages,
                builder: (context, snapshot) {
                  final unread = snapshot.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton.filledTonal(
                        tooltip: unread == 0
                            ? 'Mensagens'
                            : '$unread mensagens recebidas',
                        onPressed: openMessages,
                        icon: const Icon(Icons.chat_bubble_outline),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: -3,
                          top: -5,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: marketRed,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: milk, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                unread > 99 ? '99+' : '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Score mínimo de qualidade',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        minimumScore == 0 ? 'Todos' : '$minimumScore+',
                        style: GoogleFonts.playfairDisplay(
                          color: caramel,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: minimumScore.toDouble(),
                    min: 0,
                    max: 95,
                    divisions: 19,
                    activeColor: caramel,
                    onChanged: (value) => setMinimumScore(value.round()),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      _ScoreChip(
                        label: 'Todos',
                        selected: minimumScore == 0,
                        onTap: () => setMinimumScore(0),
                      ),
                      _ScoreChip(
                        label: 'Bom 80+',
                        selected: minimumScore == 80,
                        onTap: () => setMinimumScore(80),
                      ),
                      _ScoreChip(
                        label: 'Excelente 90+',
                        selected: minimumScore == 90,
                        onTap: () => setMinimumScore(90),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(color: caramel),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  'Não foi possível carregar os lotes: ${snapshot.error}',
                );
              }
              final cafes = snapshot.data ?? [];
              if (cafes.isEmpty) return const EmptyState();
              return Column(
                children: cafes
                    .map(
                      (cafe) => CafeCard(
                        cafe: cafe,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CafeDetailsPage(
                              cafe: cafe,
                              api: widget.api,
                              user: widget.user,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      );
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ChoiceChip(
        label: Text(label),
        selected: selected,
        selectedColor: caramel.withValues(alpha: .2),
        onSelected: (_) => onTap(),
      );
}

class CafeCard extends StatelessWidget {
  const CafeCard({super.key, required this.cafe, required this.onTap});
  final Map<String, dynamic> cafe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final score = (cafe['score_qualidade'] as num?)?.toInt();
    final scoreColor = score == null
        ? caramel
        : score >= 90
            ? marketGreen
            : score >= 80
                ? const Color(0xFF9B7A00)
                : marketRed;
    final price = cafe['preco_saca'];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [roast, coffee]),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cafe['tipo'] ?? 'Café'} · ${cafe['classificacao'] ?? 'Sem classificação'}',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${cafe['fazenda'] ?? 'Anunciante'} · ${cafe['regiao'] ?? '-'}',
                          style: const TextStyle(color: cream, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: marketGreen.withValues(alpha: .25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ATIVO',
                          style: TextStyle(
                            color: Color(0xFF9DFFC1),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (score != null) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scoreColor,
                            border: Border.all(color: Colors.white70),
                          ),
                          child: Center(
                            child: Text(
                              '$score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
              child: Column(
                children: [
                  if (cafe['verificado'] == true)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: marketBlue.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: marketBlue.withValues(alpha: .2),
                          ),
                        ),
                        child: const Text(
                          '✓ Empresa verificada',
                          style: TextStyle(
                            color: marketBlue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  _StatRow(
                    label: 'Cidade',
                    value: '${cafe['cidade'] ?? '-'}',
                    color: roast,
                  ),
                  const Divider(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price == null ? 'Preço a consultar' : _money(price),
                        style: GoogleFonts.playfairDisplay(
                          color: marketGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${cafe['quantidade'] ?? '-'} sacas',
                        style: const TextStyle(
                          color: coffee,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver detalhes',
                          style: TextStyle(
                            color: caramel,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, color: caramel, size: 17),
                      ],
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

class CafeDetailsPage extends StatefulWidget {
  const CafeDetailsPage(
      {super.key, required this.cafe, required this.api, required this.user});
  final Map<String, dynamic> cafe;
  final ApiClient api;
  final Map<String, dynamic> user;

  @override
  State<CafeDetailsPage> createState() => _CafeDetailsPageState();
}

class _CafeDetailsPageState extends State<CafeDetailsPage> {
  final price = TextEditingController();
  final quantity = TextEditingController();
  final message = TextEditingController();
  bool loading = false;
  bool sendingMessage = false;

  Future<void> sendMessage() async {
    if (message.text.trim().isEmpty) {
      showMessage(context, 'Escreva uma mensagem antes de enviar.');
      return;
    }
    setState(() => sendingMessage = true);
    try {
      await widget.api.enviarMensagem({
        'de_usuario_id': widget.user['id'],
        'para_usuario_id': widget.cafe['usuario_id'],
        'texto': message.text.trim(),
      });
      if (mounted) {
        message.clear();
        showMessage(context, 'Mensagem enviada ao anunciante.');
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => sendingMessage = false);
    }
  }

  Future<void> sendProposal() async {
    setState(() => loading = true);
    try {
      await widget.api.criarProposta({
        'cafe_id': widget.cafe['id'],
        'de_usuario_id': widget.user['id'],
        'para_usuario_id': widget.cafe['usuario_id'],
        'preco_ofertado': double.parse(price.text.replaceAll(',', '.')),
        'quantidade': int.parse(quantity.text),
      });
      if (mounted) showMessage(context, 'Proposta enviada com sucesso.');
    } catch (error) {
      if (mounted) {
        showMessage(context, error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cafe = widget.cafe;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do lote')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.local_cafe, size: 64, color: Color(0xFFB45F32)),
          const SizedBox(height: 14),
          Text('${cafe['tipo'] ?? 'Cafe'} • ${cafe['classificacao'] ?? '-'}',
              style:
                  const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('${cafe['regiao'] ?? '-'} • ${cafe['cidade'] ?? '-'}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 17)),
          const SizedBox(height: 24),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informacoes do lote',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 14),
                        Text('Quantidade: ${cafe['quantidade'] ?? '-'} sacas'),
                        Text('Fazenda: ${cafe['fazenda'] ?? '-'}'),
                        Text(
                            'Preco por saca: ${cafe['preco_saca'] ?? 'A consultar'}'),
                        Text(
                            'Score de qualidade: ${cafe['score_qualidade'] ?? '-'}'),
                      ]))),
          const SizedBox(height: 24),
          const Text('Enviar proposta',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
              controller: quantity,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Quantidade desejada')),
          const SizedBox(height: 10),
          TextField(
              controller: price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Preco ofertado por saca')),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: loading ? null : sendProposal,
              child: Text(loading ? 'Enviando...' : 'Enviar proposta')),
          const SizedBox(height: 28),
          const Text('Falar com o anunciante',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tire duvidas ou combine os detalhes da negociacao.',
              style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          TextField(
              controller: message,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Sua mensagem',
                  alignLabelWithHint: true,
                  hintText: 'Ola, tenho interesse neste lote...')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: sendingMessage ? null : sendMessage,
              icon: const Icon(Icons.send_outlined),
              label: Text(sendingMessage ? 'Enviando...' : 'Enviar mensagem')),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.message = 'Nenhum lote publicado ainda.'});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Center(child: Text(message)),
      );
}

class NewCafePage extends StatefulWidget {
  const NewCafePage({super.key, required this.user, required this.api});
  final Map<String, dynamic> user;
  final ApiClient api;
  @override
  State<NewCafePage> createState() => _NewCafePageState();
}

class _NewCafePageState extends State<NewCafePage> {
  final tipo = TextEditingController(text: 'Arabica');
  final classificacao = TextEditingController(text: 'Especial');
  final quantidade = TextEditingController();
  final regiao = TextEditingController();
  final cidade = TextEditingController();
  final preco = TextEditingController();
  bool loading = false;
  Future<void> save() async {
    setState(() => loading = true);
    try {
      await widget.api.criarCafe({
        'usuario_id': widget.user['id'],
        'tipo': tipo.text,
        'classificacao': classificacao.text,
        'quantidade': int.parse(quantidade.text),
        'regiao': regiao.text,
        'cidade': cidade.text,
        'preco_saca': double.tryParse(preco.text)
      });
      if (mounted) {
        showMessage(context, 'Lote publicado com sucesso.');
        quantidade.clear();
        preco.clear();
      }
    } catch (e) {
      if (mounted) {
        showMessage(context, e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Novo anuncio',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Apresente seu lote para compradores',
            style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(height: 24),
        TextField(
            controller: tipo,
            decoration: const InputDecoration(labelText: 'Tipo de cafe')),
        const SizedBox(height: 12),
        TextField(
            controller: classificacao,
            decoration: const InputDecoration(labelText: 'Classificacao')),
        const SizedBox(height: 12),
        TextField(
            controller: quantidade,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Quantidade de sacas')),
        const SizedBox(height: 12),
        TextField(
            controller: regiao,
            decoration: const InputDecoration(labelText: 'Regiao')),
        const SizedBox(height: 12),
        TextField(
            controller: cidade,
            decoration: const InputDecoration(labelText: 'Cidade')),
        const SizedBox(height: 12),
        TextField(
            controller: preco,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration:
                const InputDecoration(labelText: 'Preco por saca (opcional)')),
        const SizedBox(height: 20),
        FilledButton(
            onPressed: loading ? null : save,
            child: Text(loading ? 'Publicando...' : 'Publicar lote'))
      ]);
}

class ProposalsPage extends StatefulWidget {
  const ProposalsPage({super.key, required this.api, required this.user});
  final ApiClient api;
  final Map<String, dynamic> user;

  @override
  State<ProposalsPage> createState() => _ProposalsPageState();
}

class _ProposalsPageState extends State<ProposalsPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.propostas(widget.user['id'] as int);
  }

  Future<void> updateStatus(int id, String status) async {
    try {
      await widget.api.atualizarProposta(id, status);
      if (!mounted) return;
      setState(() => future = widget.api.propostas(widget.user['id'] as int));
      showMessage(context,
          status == 'aceita' ? 'Proposta aceita.' : 'Proposta recusada.');
    } catch (error) {
      if (mounted) {
        showMessage(context, error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: caramel));
          }
          if (snapshot.hasError) {
            return _LoadError(message: '${snapshot.error}');
          }
          final proposals = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Propostas formais',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 25, fontWeight: FontWeight.bold, color: roast)),
              const SizedBox(height: 4),
              Text('Negociações registradas na plataforma.',
                  style: TextStyle(color: Colors.brown.shade600)),
              const SizedBox(height: 16),
              if (proposals.isEmpty)
                const EmptyState(message: 'Você ainda não tem propostas.')
              else
                ...proposals.map((proposal) {
                  final isRecipient =
                      proposal['para_usuario_id'] == widget.user['id'];
                  final status = '${proposal['status'] ?? 'aguardando'}';
                  final otherId = isRecipient
                      ? proposal['de_usuario_id'] as int
                      : proposal['para_usuario_id'] as int;
                  final otherName =
                      isRecipient ? proposal['de_nome'] : proposal['para_nome'];
                  final canRespond = isRecipient && status == 'aguardando';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text('$otherName',
                                    style: GoogleFonts.playfairDisplay(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: roast))),
                            _StatusBadge(status: status),
                          ]),
                          const SizedBox(height: 12),
                          _StatRow(
                              label: 'Lote',
                              value:
                                  '${proposal['cafe_tipo'] ?? 'Café'} · ${proposal['cafe_classificacao'] ?? ''}',
                              color: roast),
                          _StatRow(
                              label: 'Quantidade',
                              value: '${proposal['quantidade'] ?? '-'} sacas',
                              color: roast),
                          _StatRow(
                              label: 'Preço ofertado',
                              value: _money(proposal['preco_ofertado']),
                              color: marketGreen),
                          if ('${proposal['condicao_pagamento'] ?? ''}'
                              .isNotEmpty)
                            _StatRow(
                                label: 'Pagamento',
                                value: '${proposal['condicao_pagamento']}',
                                color: roast),
                          if ('${proposal['mensagem'] ?? ''}'.isNotEmpty)
                            Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text('“${proposal['mensagem']}”',
                                    style: TextStyle(
                                        color: Colors.brown.shade600,
                                        fontStyle: FontStyle.italic))),
                          const SizedBox(height: 12),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            if (canRespond)
                              FilledButton.tonalIcon(
                                  onPressed: () => updateStatus(
                                      proposal['id'] as int, 'aceita'),
                                  icon: const Icon(Icons.check),
                                  label: const Text('Aceitar')),
                            if (canRespond)
                              OutlinedButton.icon(
                                  onPressed: () => updateStatus(
                                      proposal['id'] as int, 'recusada'),
                                  icon: const Icon(Icons.close),
                                  label: const Text('Recusar')),
                            OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => ChatPage(
                                            api: widget.api,
                                            user: widget.user,
                                            otherUserId: otherId,
                                            otherUserName: '$otherName'))),
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: const Text('Conversar')),
                          ]),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = status == 'aceita'
        ? marketGreen
        : status == 'recusada'
            ? marketRed
            : caramel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: .25))),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key, required this.api, required this.user});
  final ApiClient api;
  final Map<String, dynamic> user;

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.alertas(widget.user['id'] as int);
  }

  Future<void> refresh() async {
    setState(() => future = widget.api.alertas(widget.user['id'] as int));
  }

  Future<void> createAlert() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateAlertDialog(api: widget.api, user: widget.user),
    );
    if (created == true && mounted) refresh();
  }

  Future<void> deleteAlert(int id) async {
    try {
      await widget.api.deletarAlerta(id);
      if (mounted) refresh();
    } catch (error) {
      if (mounted) {
        showMessage(context, error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: caramel));
          }
          if (snapshot.hasError) {
            return _LoadError(message: '${snapshot.error}');
          }
          final alerts = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(
                    child: Text('Meus alertas',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: roast))),
                IconButton.filledTonal(
                    onPressed: createAlert,
                    tooltip: 'Criar alerta',
                    icon: const Icon(Icons.add_alert_outlined)),
              ]),
              Text('Receba avisos quando lotes atenderem aos seus critérios.',
                  style: TextStyle(color: Colors.brown.shade600)),
              const SizedBox(height: 16),
              if (alerts.isEmpty)
                const EmptyState(message: 'Nenhum alerta configurado.')
              else
                ...alerts.map((alert) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                            backgroundColor: Color(0x1AC4863A),
                            child: Icon(Icons.notifications_active_outlined,
                                color: caramel)),
                        title: Text(
                            '${alert['tipo_cafe'] ?? 'Qualquer café'} · ${alert['regiao'] ?? 'Qualquer região'}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text([
                          if (alert['preco_maximo'] != null)
                            'Até ${_money(alert['preco_maximo'])}/saca',
                          if (alert['score_minimo'] != null)
                            'Score ≥ ${alert['score_minimo']}',
                        ].join(' · ').isEmpty
                            ? 'Sem limite de preço ou score'
                            : [
                                if (alert['preco_maximo'] != null)
                                  'Até ${_money(alert['preco_maximo'])}/saca',
                                if (alert['score_minimo'] != null)
                                  'Score ≥ ${alert['score_minimo']}',
                              ].join(' · ')),
                        trailing: IconButton(
                            tooltip: 'Remover alerta',
                            onPressed: () => deleteAlert(alert['id'] as int),
                            icon: const Icon(Icons.delete_outline,
                                color: marketRed)),
                      ),
                    )),
              if (alerts.isNotEmpty)
                OutlinedButton.icon(
                    onPressed: createAlert,
                    icon: const Icon(Icons.add),
                    label: const Text('Criar novo alerta')),
            ],
          );
        },
      );
}

class _CreateAlertDialog extends StatefulWidget {
  const _CreateAlertDialog({required this.api, required this.user});
  final ApiClient api;
  final Map<String, dynamic> user;

  @override
  State<_CreateAlertDialog> createState() => _CreateAlertDialogState();
}

class _CreateAlertDialogState extends State<_CreateAlertDialog> {
  final type = TextEditingController();
  final region = TextEditingController();
  final price = TextEditingController();
  final score = TextEditingController();
  bool loading = false;

  Future<void> save() async {
    setState(() => loading = true);
    try {
      await widget.api.criarAlerta({
        'usuario_id': widget.user['id'],
        'tipo_cafe': type.text.trim().isEmpty ? null : type.text.trim(),
        'regiao': region.text.trim().isEmpty ? null : region.text.trim(),
        'preco_maximo': double.tryParse(price.text.replaceAll(',', '.')),
        'score_minimo': int.tryParse(score.text),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        showMessage(context, error.toString().replaceFirst('Exception: ', ''));
      }
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Criar alerta',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold, color: roast)),
        content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: type,
              decoration: const InputDecoration(labelText: 'Tipo de café')),
          const SizedBox(height: 10),
          TextField(
              controller: region,
              decoration: const InputDecoration(labelText: 'Região')),
          const SizedBox(height: 10),
          TextField(
              controller: price,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Preço máximo por saca')),
          const SizedBox(height: 10),
          TextField(
              controller: score,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Score mínimo')),
        ])),
        actions: [
          TextButton(
              onPressed: loading ? null : () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: loading ? null : save,
              child: Text(loading ? 'Salvando...' : 'Criar alerta')),
        ],
      );
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key, required this.api, required this.user});
  final ApiClient api;
  final Map<String, dynamic> user;

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = widget.api.conversas(widget.user['id'] as int);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mensagens')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: caramel));
            }
            if (snapshot.hasError) {
              return _LoadError(message: '${snapshot.error}');
            }
            final latestByUser = <int, Map<String, dynamic>>{};
            for (final message in snapshot.data ?? []) {
              final otherId = message['interlocutor_id'] as int;
              latestByUser.putIfAbsent(otherId, () => message);
            }
            if (latestByUser.isEmpty) {
              return const EmptyState(
                  message: 'Suas conversas aparecerão aqui.');
            }
            return ListView(
              children: latestByUser.entries.map((entry) {
                final message = entry.value;
                final sender = message['de_usuario_id'] == widget.user['id'];
                return ListTile(
                  leading: CircleAvatar(
                      backgroundColor: roast,
                      foregroundColor: gold,
                      child: Text('${message['interlocutor_nome'] ?? '?'}'
                          .characters
                          .first
                          .toUpperCase())),
                  title: Text('${message['interlocutor_nome'] ?? 'Contato'}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${sender ? 'Você: ' : ''}${message['texto'] ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChatPage(
                          api: widget.api,
                          user: widget.user,
                          otherUserId: entry.key,
                          otherUserName:
                              '${message['interlocutor_nome'] ?? 'Contato'}'))),
                );
              }).toList(),
            );
          },
        ),
      );
}

class ChatPage extends StatefulWidget {
  const ChatPage(
      {super.key,
      required this.api,
      required this.user,
      required this.otherUserId,
      required this.otherUserName});
  final ApiClient api;
  final Map<String, dynamic> user;
  final int otherUserId;
  final String otherUserName;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final text = TextEditingController();
  late Future<List<Map<String, dynamic>>> future;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    future = widget.api.conversa(widget.user['id'] as int, widget.otherUserId);
  }

  Future<void> send() async {
    if (text.text.trim().isEmpty) return;
    setState(() => sending = true);
    try {
      await widget.api.enviarMensagem({
        'de_usuario_id': widget.user['id'],
        'para_usuario_id': widget.otherUserId,
        'texto': text.text.trim(),
      });
      text.clear();
      if (mounted) {
        setState(() => future =
            widget.api.conversa(widget.user['id'] as int, widget.otherUserId));
      }
    } catch (error) {
      if (mounted) {
        showMessage(context, error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.otherUserName)),
        body: Column(children: [
          Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: caramel));
              }
              if (snapshot.hasError) {
                return _LoadError(message: '${snapshot.error}');
              }
              final messages = snapshot.data ?? [];
              if (messages.isEmpty) {
                return const EmptyState(
                    message: 'Inicie a conversa sobre o lote.');
              }
              return ListView(
                  padding: const EdgeInsets.all(14),
                  children: messages.map((message) {
                    final mine = message['de_usuario_id'] == widget.user['id'];
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 10),
                        decoration: BoxDecoration(
                            color:
                                mine ? const Color(0xFFEEDCC5) : Colors.white,
                            borderRadius: BorderRadius.circular(14)),
                        child: Text('${message['texto'] ?? ''}'),
                      ),
                    );
                  }).toList());
            },
          )),
          SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(children: [
                    Expanded(
                        child: TextField(
                            controller: text,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                                hintText: 'Escreva sua mensagem'))),
                    const SizedBox(width: 8),
                    IconButton.filled(
                        onPressed: sending ? null : send,
                        tooltip: 'Enviar mensagem',
                        icon: const Icon(Icons.send)),
                  ]))),
        ]),
      );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.user, required this.onMessages});
  final Map<String, dynamic> user;
  final VoidCallback onMessages;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Seu perfil',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Card(
            child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text('${user['nome'] ?? '-'}'),
                subtitle:
                    Text('${user['email'] ?? '-'}\n${user['tipo'] ?? '-'}'))),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.forum_outlined, color: caramel),
            title: const Text('Mensagens'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onMessages,
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthPage()),
            (route) => false,
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Sair da conta'),
        ),
      ]);
}

void showMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
