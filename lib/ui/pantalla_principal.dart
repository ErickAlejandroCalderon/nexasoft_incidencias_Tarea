import 'package:flutter/material.dart';
import '../model/incidencia.dart';
import '../services/gestor_incidencias.dart';
import 'pantalla_detalle.dart';
import 'pantalla_nueva.dart';

class PantallaPrincipal extends StatefulWidget {
  final GestorIncidencias? gestor;
  const PantallaPrincipal({super.key, this.gestor});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  late final GestorIncidencias g;
  final TextEditingController _busquedaController = TextEditingController();
  bool cargando = true;
  String? error;
  String busqueda = '';
  String filtroEstado = 'Todos';
  String filtroPrioridad = 'Todas';

  static const List<String> opcionesEstado = [
    'Todos',
    'Pendiente',
    'En proceso',
    'Resuelta',
  ];
  static const List<String> opcionesPrioridad = [
    'Todas',
    'Baja',
    'Media',
    'Alta',
  ];

  @override
  void initState() {
    super.initState();
    g = widget.gestor ?? GestorIncidencias();
    cargar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void restablecerFiltros() {
    setState(() {
      _busquedaController.clear();
      busqueda = '';
      filtroEstado = 'Todos';
      filtroPrioridad = 'Todas';
    });
  }

  Future<void> cargar() async {
    setState(() {
      cargando = true;
      error = null;
    });
    try {
      if (g.incidencias.isEmpty) {
        await g.iniciar();
      }
    } catch (e) {
      error = 'No se pudieron cargar las incidencias: $e';
    }
    if (mounted) setState(() => cargando = false);
  }

  Color colorEstado(String estado) {
    if (estado == 'Resuelta') return const Color(0xFF147D64);
    if (estado == 'En proceso') return const Color(0xFFB56B13);
    return const Color(0xFFAC4052);
  }

  Color colorPrioridad(String prioridad) {
    if (prioridad == 'Alta') return const Color(0xFFC53030);
    if (prioridad == 'Media') return const Color(0xFFB7791F);
    return const Color(0xFF2B6CB0);
  }

  Widget resumen(String etiqueta, String valor, IconData icono) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icono, size: 19, color: const Color(0xFF174C83)),
              const SizedBox(height: 4),
              Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(etiqueta, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> abrirDetalle(Incidencia item) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => PantallaDetalle(gestor: g, id: item.id)),
    );
    if (mounted) setState(() {});
  }

  Future<void> abrirFormulario() async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PantallaNueva(gestor: g)),
    );
    if (guardado == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incidencia registrada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = g.filtrar(
      texto: busqueda,
      estado: filtroEstado,
      prioridad: filtroPrioridad,
    );
    final bool hayFiltrosActivos = busqueda.trim().isNotEmpty ||
        filtroEstado != 'Todos' ||
        filtroPrioridad != 'Todas';

    return Scaffold(
      appBar: AppBar(
        title: const Text('NexaSoft | Incidencias'),
        actions: [
          IconButton(
            tooltip: 'Restablecer datos de demostración',
            onPressed: () async {
              final aceptar = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Restablecer demostración'),
                  content: const Text('Se descartarán los cambios locales y se cargarán las incidencias iniciales.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restablecer')),
                  ],
                ),
              );
              if (aceptar != true) return;
              try {
                await g.reiniciarDemo();
                if (mounted) setState(() {});
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al reiniciar: $e')));
                }
              }
            },
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      floatingActionButton: cargando || error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: abrirFormulario,
              label: const Text('Nueva incidencia'),
              icon: const Icon(Icons.add),
            ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: cargar, child: const Text('Reintentar')),
                  ]),
                ))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                          child: Row(children: [
                            resumen('Pendientes', '${g.contar('Pendiente')}', Icons.pending_actions),
                            resumen('En proceso', '${g.contar('En proceso')}', Icons.build_outlined),
                            resumen('Resueltas', '${g.contar('Resuelta')}', Icons.check_circle_outline),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
                          child: TextField(
                            controller: _busquedaController,
                            decoration: InputDecoration(
                              labelText: 'Buscar incidencias',
                              hintText: 'Ejemplo: WiFi, correo, pantalla',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: busqueda.isNotEmpty
                                  ? IconButton(
                                      tooltip: 'Borrar búsqueda',
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _busquedaController.clear();
                                        setState(() => busqueda = '');
                                      },
                                    )
                                  : null,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (texto) => setState(() => busqueda = texto),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  key: ValueKey('filtro_estado_$filtroEstado'),
                                  value: filtroEstado,
                                  decoration: const InputDecoration(
                                    labelText: 'Filtrar por estado',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: opcionesEstado
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (v) => setState(() => filtroEstado = v ?? 'Todos'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  key: ValueKey('filtro_prioridad_$filtroPrioridad'),
                                  value: filtroPrioridad,
                                  decoration: const InputDecoration(
                                    labelText: 'Filtrar por prioridad',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: opcionesPrioridad
                                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                                      .toList(),
                                  onChanged: (v) => setState(() => filtroPrioridad = v ?? 'Todas'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${items.length} registros', style: const TextStyle(color: Colors.black54)),
                              TextButton.icon(
                                key: const ValueKey('boton_limpiar_filtros'),
                                onPressed: hayFiltrosActivos ? restablecerFiltros : null,
                                icon: const Icon(Icons.filter_alt_off, size: 16),
                                label: const Text('Limpiar filtros'),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: items.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.search_off, size: 48, color: Colors.black38),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'No se encontraron incidencias con los filtros aplicados',
                                          style: TextStyle(fontSize: 16, color: Colors.black54),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        OutlinedButton.icon(
                                          key: const ValueKey('boton_restablecer_vacio'),
                                          onPressed: restablecerFiltros,
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Restablecer filtros'),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(left: 12, right: 12, bottom: 100),
                                  itemCount: items.length,
                                  itemBuilder: (context, i) {
                                    final item = items[i];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        title: Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${item.id}  ·  ${item.cliente}'),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                spacing: 8,
                                                children: [
                                                  Text(item.estado, style: TextStyle(
                                                    color: colorEstado(item.estado), fontWeight: FontWeight.bold,
                                                  )),
                                                  const Text('·', style: TextStyle(color: Colors.black45)),
                                                  Text('Prioridad: ${item.prioridad}', style: TextStyle(
                                                    color: colorPrioridad(item.prioridad), fontWeight: FontWeight.w600,
                                                  )),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () => abrirDetalle(item),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
