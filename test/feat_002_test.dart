import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/data/almacen_local.dart';
import 'package:nexasoft_incidencias/model/incidencia.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';
import 'package:nexasoft_incidencias/ui/pantalla_principal.dart';

class AlmacenLocalPrueba extends AlmacenLocal {
  List<Incidencia> _almacen = [];

  AlmacenLocalPrueba(List<Incidencia> inicial) {
    _almacen = inicial.map((x) => Incidencia.desdeJson(x.toJson())).toList();
  }

  @override
  Future<List<Incidencia>> leer() async {
    return _almacen.map((x) => Incidencia.desdeJson(x.toJson())).toList();
  }

  @override
  Future<void> guardar(List<Incidencia> lista) async {
    _almacen = lista.map((x) => Incidencia.desdeJson(x.toJson())).toList();
  }

  @override
  Future<void> restaurarDatosDeEjemplo() async {
    _almacen = [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FEAT-002: Filtros combinables (texto, estado, prioridad)', () {
    late GestorIncidencias gestor;

    setUp(() {
      gestor = GestorIncidencias();
      gestor.incidencias = [
        Incidencia(
          id: 'INC-101',
          titulo: 'Impresora del almacén no responde',
          descripcion: 'Documentos permanecen en cola.',
          cliente: 'Almacenes del Centro',
          categoria: 'Hardware',
          estado: 'Pendiente',
          prioridad: 'Alta',
          fecha: '2026-09-28',
        ),
        Incidencia(
          id: 'INC-102',
          titulo: 'WiFi intermitente en recepción',
          descripcion: 'Cortes en recepción.',
          cliente: 'Clínica del Prado',
          categoria: 'Redes',
          estado: 'Pendiente',
          prioridad: 'Media',
          fecha: '2026-09-29',
        ),
        Incidencia(
          id: 'INC-103',
          titulo: 'Impresora térmica de tickets',
          descripcion: 'Falla al imprimir recibos.',
          cliente: 'Servicios',
          categoria: 'Hardware',
          estado: 'Resuelta',
          prioridad: 'Alta',
          fecha: '2026-09-30',
        ),
        Incidencia(
          id: 'INC-104',
          titulo: 'Configuración de VPN',
          descripcion: 'Problemas de túnel.',
          cliente: 'Servicios',
          categoria: 'Redes',
          estado: 'En proceso',
          prioridad: 'Baja',
          fecha: '2026-10-01',
        ),
      ];
    });

    test('Filtrar por estado exclusivamente', () {
      expect(gestor.filtrar(estado: 'Todos').length, 4);
      expect(gestor.filtrar(estado: 'Pendiente').length, 2);
      expect(gestor.filtrar(estado: 'En proceso').length, 1);
      expect(gestor.filtrar(estado: 'Resuelta').length, 1);
    });

    test('Filtrar por prioridad exclusivamente', () {
      expect(gestor.filtrar(prioridad: 'Todas').length, 4);
      expect(gestor.filtrar(prioridad: 'Alta').length, 2);
      expect(gestor.filtrar(prioridad: 'Media').length, 1);
      expect(gestor.filtrar(prioridad: 'Baja').length, 1);
    });

    test('Combinar texto, estado y prioridad juntos', () {
      // Buscar palabra "impresora", estado "Pendiente" y prioridad "Alta"
      final res = gestor.filtrar(
        texto: 'impresora',
        estado: 'Pendiente',
        prioridad: 'Alta',
      );
      expect(res.length, 1);
      expect(res.first.id, 'INC-101');

      // Buscar palabra "impresora", estado "Resuelta" y prioridad "Alta"
      final res2 = gestor.filtrar(
        texto: 'impresora',
        estado: 'Resuelta',
        prioridad: 'Alta',
      );
      expect(res2.length, 1);
      expect(res2.first.id, 'INC-103');

      // Búsqueda sin coincidencias combinadas (ej. "impresora" con prioridad "Baja")
      final vacio = gestor.filtrar(
        texto: 'impresora',
        prioridad: 'Baja',
      );
      expect(vacio, isEmpty);
    });

    testWidgets('Flujo en PantallaPrincipal: filtrar por palabra + Pendiente + Alta, limpiar y recuperar todos', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PantallaPrincipal(gestor: gestor),
      ));

      // Esperar a que cargue la lista
      await tester.pumpAndSettle();

      // Debe haber registros iniciales
      expect(find.textContaining('registros'), findsOneWidget);

      // 1. Ingresar texto de búsqueda
      final campoBusqueda = find.widgetWithText(TextField, 'Buscar incidencias');
      expect(campoBusqueda, findsOneWidget);
      await tester.enterText(campoBusqueda, 'impresora');
      await tester.pumpAndSettle();

      // 2. Seleccionar filtro Estado: 'Pendiente'
      final dropdownEstado = find.byKey(const ValueKey('filtro_estado_Todos'));
      await tester.tap(dropdownEstado);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pendiente').last);
      await tester.pumpAndSettle();

      // 3. Seleccionar filtro Prioridad: 'Alta'
      final dropdownPrioridad = find.byKey(const ValueKey('filtro_prioridad_Todas'));
      await tester.tap(dropdownPrioridad);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alta').last);
      await tester.pumpAndSettle();

      // 4. Presionar botón de limpiar filtros
      final botonLimpiar = find.byKey(const ValueKey('boton_limpiar_filtros'));
      expect(botonLimpiar, findsOneWidget);
      await tester.tap(botonLimpiar);
      await tester.pumpAndSettle();

      // Confirmar que el campo de texto está vacío y reaparecen los registros
      final textField = tester.widget<TextField>(campoBusqueda);
      expect(textField.controller?.text, '');
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Todas'), findsOneWidget);
    });

    testWidgets('Ante cero resultados, muestra mensaje claro con botón para restablecer filtros', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PantallaPrincipal(gestor: gestor),
      ));
      await tester.pumpAndSettle();

      // Buscar texto sin coincidencias
      final campoBusqueda = find.widgetWithText(TextField, 'Buscar incidencias');
      await tester.enterText(campoBusqueda, 'texto_que_no_existe_en_ningun_registro');
      await tester.pumpAndSettle();

      // Debe mostrarse el mensaje claro
      expect(find.text('No se encontraron incidencias con los filtros aplicados'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);

      // Presionar el botón de restablecer en el estado vacío
      final botonRestablecerVacio = find.byKey(const ValueKey('boton_restablecer_vacio'));
      expect(botonRestablecerVacio, findsOneWidget);
      await tester.tap(botonRestablecerVacio);
      await tester.pumpAndSettle();

      // Se restablece y reaparecen las incidencias
      expect(find.text('No se encontraron incidencias con los filtros aplicados'), findsNothing);
    });
  });
}
