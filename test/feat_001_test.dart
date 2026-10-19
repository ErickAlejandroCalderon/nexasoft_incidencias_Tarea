import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexasoft_incidencias/data/almacen_local.dart';
import 'package:nexasoft_incidencias/model/incidencia.dart';
import 'package:nexasoft_incidencias/services/gestor_incidencias.dart';
import 'package:nexasoft_incidencias/ui/pantalla_detalle.dart';
import 'package:nexasoft_incidencias/ui/pantalla_nueva.dart';
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

  group('FEAT-001: Clasificación por prioridad (Baja, Media, Alta)', () {
    test('Incidencias antiguas sin campo prioridad se abren sin fallar y asignan Media por defecto', () {
      final jsonAntiguo = {
        'id': 'INC-ANTIGUO',
        'titulo': 'Falla histórica',
        'descripcion': 'Registro previo a la clasificación',
        'cliente': 'Cliente Antiguo',
        'categoria': 'Hardware',
        'estado': 'Pendiente',
        'fecha': '2026-08-01',
      };

      final incidencia = Incidencia.desdeJson(jsonAntiguo);
      expect(incidencia.prioridad, 'Media');
      expect(incidencia.toJson()['prioridad'], 'Media');
    });

    test('Se evitan valores distintos de los tres aprobados (Baja, Media, Alta), aplicando Media', () {
      final jsonInvalido = {
        'id': 'INC-ERR',
        'titulo': 'Falla con prioridad corrupta',
        'descripcion': 'Valor no aprobado',
        'cliente': 'Test',
        'categoria': 'Redes',
        'estado': 'Pendiente',
        'fecha': '2026-08-02',
        'prioridad': 'UrgenteCritica', // No aprobado
      };

      final incidencia = Incidencia.desdeJson(jsonInvalido);
      expect(incidencia.prioridad, 'Media', reason: 'Debe caer en Media si el valor no es aprobado');

      final incDirecta = Incidencia(
        id: 'INC-ERR-2',
        titulo: 'Test',
        descripcion: 'Desc',
        cliente: 'Cliente',
        categoria: 'Software',
        estado: 'Pendiente',
        fecha: '2026-08-02',
        prioridad: 'Desconocida',
      );
      expect(incDirecta.prioridad, 'Media');
    });

    test('Crear incidencia con prioridad Alta, modificar a Baja y verificar persistencia tras reiniciar', () async {
      final almacen = AlmacenLocalPrueba([]);
      final gestor1 = GestorIncidencias(datos: almacen);
      await gestor1.iniciar();

      // 1. Crear nuevo registro con prioridad Alta
      await gestor1.crear(
        'Servidor caído',
        'El servidor principal no responde',
        'Banco Corporativo',
        'Redes',
        prioridad: 'Alta',
      );

      expect(gestor1.incidencias.length, 1);
      final nuevoId = gestor1.incidencias.first.id;
      expect(gestor1.porId(nuevoId)!.prioridad, 'Alta');

      // 2. Modificar la prioridad desde el gestor a 'Baja'
      await gestor1.cambiarPrioridad(nuevoId, 'Baja');
      expect(gestor1.porId(nuevoId)!.prioridad, 'Baja');

      // 3. Simular cierre y reinicio de la aplicación
      final gestor2 = GestorIncidencias(datos: almacen);
      await gestor2.iniciar();

      final recuperada = gestor2.porId(nuevoId);
      expect(recuperada, isNotNull);
      expect(recuperada!.id, nuevoId);
      expect(recuperada.prioridad, 'Baja', reason: 'La prioridad modificada debe persistir tras reiniciar');
    });

    testWidgets('PantallaNueva permite seleccionar prioridad y guardarla', (tester) async {
      final almacen = AlmacenLocalPrueba([]);
      final gestor = GestorIncidencias(datos: almacen);
      await gestor.iniciar();

      await tester.pumpWidget(MaterialApp(
        home: PantallaNueva(gestor: gestor),
      ));

      // Llenar campos
      await tester.enterText(find.widgetWithText(TextFormField, 'Título'), 'Falla crítica de enlace');
      await tester.enterText(find.widgetWithText(TextFormField, 'Descripción'), 'No hay enlace principal');
      await tester.enterText(find.widgetWithText(TextFormField, 'Cliente'), 'Telecom SA');

      // Seleccionar prioridad Alta en el dropdown
      // El valor inicial es Media
      expect(find.text('Media'), findsOneWidget);
      await tester.tap(find.text('Media'));
      await tester.pumpAndSettle();

      // Elegir 'Alta' en el menú desplegable
      await tester.tap(find.text('Alta').last);
      await tester.pumpAndSettle();

      // Presionar Registrar
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(gestor.incidencias.length, 1);
      expect(gestor.incidencias.first.prioridad, 'Alta');
    });

    testWidgets('PantallaDetalle muestra la prioridad y permite modificarla', (tester) async {
      final almacen = AlmacenLocalPrueba([
        Incidencia(
          id: 'INC-DET-1',
          titulo: 'Impresora rota',
          descripcion: 'Falla física',
          cliente: 'Oficina Central',
          categoria: 'Hardware',
          estado: 'Pendiente',
          fecha: '2026-10-18',
          prioridad: 'Media',
        ),
      ]);
      final gestor = GestorIncidencias(datos: almacen);
      await gestor.iniciar();

      await tester.pumpWidget(MaterialApp(
        home: PantallaDetalle(gestor: gestor, id: 'INC-DET-1'),
      ));

      // Debe mostrarse la fila de Prioridad
      expect(find.text('Prioridad'), findsWidgets);
      expect(find.text('Media'), findsWidgets);

      // Abrir dropdown de prioridad y cambiar a 'Alta'
      final dropdownPrioridad = find.byKey(const ValueKey('prioridad_Media'));
      await tester.tap(dropdownPrioridad);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alta').last);
      await tester.pumpAndSettle();

      expect(gestor.porId('INC-DET-1')!.prioridad, 'Alta');
    });
  });
}
