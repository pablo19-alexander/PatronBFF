import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// =========================================================================
// CONFIGURACION DE RED
// =========================================================================
// Si pruebas en EMULADOR Android: usa 10.0.2.2 (puente al host).
// Si pruebas en CELULAR FISICO: usa la IP Wi-Fi de tu computador.
//   Tu IP detectada hoy: 192.168.1.53  (cambia si tu red cambia)
// =========================================================================

class ApiConfig {
  static String get host {
    if (!kIsWeb && Platform.isAndroid) {
      // return '10.0.2.2'; // <-- descomenta si usas emulador Android
      return '192.168.1.53'; // celular fisico en la misma Wi-Fi
    }
    return '192.168.1.53';
  }

  static String get perfilUrl => 'http://$host:8001/perfil';
  static String get restaurantesUrl => 'http://$host:8002/restaurantes';
  static String get pedidosUrl => 'http://$host:8003/pedidos';
  static String get bffUrl => 'http://$host:8000/home';

  static const Duration timeout = Duration(seconds: 5);
}

void main() => runApp(const TallerApp());

class TallerApp extends StatelessWidget {
  const TallerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taller 4 - Cliente Movil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E2761)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

enum LoadState { idle, loading, success, error }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LoadState _state = LoadState.idle;
  String _modoUsado = '';
  int _elapsedMs = 0;
  String _errorMsg = '';
  Map<String, dynamic>? _data;

  Future<void> _cargaDirecta() async {
    setState(() {
      _state = LoadState.loading;
      _modoUsado = 'Carga Directa (3 peticiones)';
      _data = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final results = await Future.wait([
        http.get(Uri.parse(ApiConfig.perfilUrl)).timeout(ApiConfig.timeout),
        http.get(Uri.parse(ApiConfig.restaurantesUrl)).timeout(ApiConfig.timeout),
        http.get(Uri.parse(ApiConfig.pedidosUrl)).timeout(ApiConfig.timeout),
      ]);
      stopwatch.stop();

      for (final r in results) {
        if (r.statusCode != 200) {
          throw HttpException('HTTP ${r.statusCode}');
        }
      }

      final perfil = jsonDecode(results[0].body) as Map<String, dynamic>;
      final restaurantes = jsonDecode(results[1].body) as Map<String, dynamic>;
      final pedidos = jsonDecode(results[2].body) as Map<String, dynamic>;

      setState(() {
        _state = LoadState.success;
        _elapsedMs = stopwatch.elapsedMilliseconds;
        _data = {
          'perfil': perfil,
          'restaurantes': restaurantes['restaurantes'],
          'pedidos': pedidos,
        };
      });
    } on TimeoutException {
      _onError('La conexion tardo demasiado. Revisa tu red.');
    } on http.ClientException catch (e) {
      _onError('No fue posible contactar al servidor.\n(${e.message})');
    } catch (e) {
      _onError('Algo salio mal. Intenta nuevamente.\n($e)');
    }
  }

  Future<void> _cargaBff() async {
    setState(() {
      _state = LoadState.loading;
      _modoUsado = 'Carga BFF (1 peticion)';
      _data = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final res = await http.get(Uri.parse(ApiConfig.bffUrl)).timeout(ApiConfig.timeout);
      stopwatch.stop();

      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode}');
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      setState(() {
        _state = LoadState.success;
        _elapsedMs = stopwatch.elapsedMilliseconds;
        _data = body;
      });
    } on TimeoutException {
      _onError('La conexion tardo demasiado. Revisa tu red.');
    } on http.ClientException catch (e) {
      _onError('No fue posible contactar al servidor.\n(${e.message})');
    } catch (e) {
      _onError('Algo salio mal. Intenta nuevamente.\n($e)');
    }
  }

  void _onError(String msg) {
    setState(() {
      _state = LoadState.error;
      _errorMsg = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2761),
        foregroundColor: Colors.white,
        title: const Text('Taller 4 - BFF vs Carga Directa'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBotones(),
              const SizedBox(height: 16),
              if (_modoUsado.isNotEmpty) _buildResumen(),
              const SizedBox(height: 12),
              Expanded(child: _buildContenido()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotones() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _state == LoadState.loading ? null : _cargaDirecta,
            icon: const Icon(Icons.warning_amber_rounded),
            label: const Text('Carga Directa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9534F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _state == LoadState.loading ? null : _cargaBff,
            icon: const Icon(Icons.bolt),
            label: const Text('Carga BFF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B57),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumen() {
    if (_state != LoadState.success) return const SizedBox.shrink();
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Color(0xFF1E2761)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_modoUsado, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Tiempo: $_elapsedMs ms',
                      style: const TextStyle(fontSize: 18, color: Color(0xFF1E2761))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenido() {
    switch (_state) {
      case LoadState.idle:
        return const _MensajeCentral(
          icono: Icons.touch_app,
          titulo: 'Selecciona un modo de carga',
          subtitulo: 'Compara el tiempo entre llamar 3 microservicios o 1 BFF.',
        );
      case LoadState.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando datos...'),
            ],
          ),
        );
      case LoadState.error:
        return _PantallaError(
          mensaje: _errorMsg,
          onReintentar: () {
            if (_modoUsado.contains('BFF')) {
              _cargaBff();
            } else {
              _cargaDirecta();
            }
          },
        );
      case LoadState.success:
        return _ContenidoExitoso(data: _data!);
    }
  }
}

class _MensajeCentral extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  const _MensajeCentral({required this.icono, required this.titulo, required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(subtitulo,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }
}

class _PantallaError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const _PantallaError({required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.signal_wifi_connected_no_internet_4,
                size: 80, color: Color(0xFFD9534F)),
            const SizedBox(height: 16),
            const Text(
              '¡Ups! La señal se perdió',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Estamos intentando reconectar...\n\n$mensaje',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E2761),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContenidoExitoso extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ContenidoExitoso({required this.data});

  @override
  Widget build(BuildContext context) {
    final perfil = data['perfil'] as Map<String, dynamic>;
    final restaurantes = (data['restaurantes'] as List).cast<dynamic>();
    final pedidos = data['pedidos'] as Map<String, dynamic>;

    return ListView(
      children: [
        _Seccion(
          titulo: 'Perfil',
          icono: Icons.person,
          color: const Color(0xFF1E2761),
          hijos: [
            Text('${perfil['nombre']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('${perfil['email']}'),
            Text('${perfil['ciudad']} · ${perfil['rol']}'),
          ],
        ),
        _Seccion(
          titulo: 'Restaurantes',
          icono: Icons.restaurant,
          color: const Color(0xFF2E8B57),
          hijos: restaurantes.map<Widget>((r) {
            final rest = r as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Text(rest['nombre'])),
                  Text('⭐ ${rest['rating']}'),
                  const SizedBox(width: 10),
                  Text('${rest['tiempo_entrega_min']} min'),
                ],
              ),
            );
          }).toList(),
        ),
        _Seccion(
          titulo: 'Pedidos activos',
          icono: Icons.shopping_bag_outlined,
          color: const Color(0xFFCC7700),
          hijos: [
            ...((pedidos['pedidos_activos'] as List).map<Widget>((p) {
              final ped = p as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${ped['id']} - ${ped['restaurante']} (${ped['estado']}) \$${ped['total']}'),
              );
            })),
            const SizedBox(height: 6),
            Text('Total pedidos del mes: ${pedidos['total_pedidos_mes']}',
                style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final List<Widget> hijos;
  const _Seccion({required this.titulo, required this.icono, required this.color, required this.hijos});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(backgroundColor: color, child: Icon(icono, color: Colors.white, size: 18)),
              const SizedBox(width: 10),
              Text(titulo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 10),
            ...hijos,
          ],
        ),
      ),
    );
  }
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => message;
}
