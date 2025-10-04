-- ============================
-- Catálogos
-- ============================

-- Tipos de reclamo
INSERT INTO gestion_reclamos.tipos_reclamo (codigo, nombre, descripcion)
VALUES
  ('FRAUDE_TARJETA', 'Fraude en tarjeta', 'Transacciones no reconocidas.'),
  ('DOBLE_COBRO', 'Doble cobro', 'Duplicidad de cargos.'),
  ('NO_ENTREGA', 'No entrega', 'Producto/servicio no recibido.'),
  ('CARGO_NO_AUTORIZADO', 'Cargo no autorizado', 'Cargo sin consentimiento.'),
  ('ERROR_MONTO', 'Error en monto', 'Monto incorrecto en transacción.')
ON CONFLICT (codigo) DO NOTHING;

-- Estados del reclamo
INSERT INTO gestion_reclamos.estados_reclamo (codigo, nombre)
VALUES
  ('ASIGNADO', 'Asignado'),
  ('PENDIENTE_DE_RASTREO', 'Pendiente de rastreo'),
  ('RASTREADO', 'Rastreado'),
  ('PENDIENTE_DE_VALIDACION', 'Pendiente de validación'),
  ('VALIDADO', 'Validado'),
  ('NOTIFICADO', 'Notificado'),
  ('CERRADO', 'Cerrado')
ON CONFLICT (codigo) DO NOTHING;

-- Tipos de revisor
INSERT INTO gestion_reclamos.tipos_revisor (codigo, nombre, descripcion)
VALUES
  ('LEGAL', 'Legal', 'Revisión por equipo legal.'),
  ('RIESGOS', 'Riesgos', 'Revisión por gestión de riesgos.'),
  ('CUMPLIMIENTO', 'Cumplimiento', 'Revisión normativa/compliance.'),
  ('IMAGEN', 'Imagen Institucional', 'Revisión de comunicaciones.')
ON CONFLICT (codigo) DO NOTHING;

-- ============================
-- Equipos y analistas
-- ============================

-- Equipos
INSERT INTO gestion_reclamos.equipos_backoffice (codigo, nombre, descripcion)
VALUES
  ('EQ_FRAUDE', 'Equipo Fraude', 'Especializado en fraude de tarjetas.'),
  ('EQ_OPERACIONES', 'Equipo Operaciones', 'Doble cobro y errores de monto.'),
  ('EQ_ATENCION', 'Equipo Atención', 'Casos de no entrega y seguimiento.')
ON CONFLICT (codigo) DO NOTHING;

-- Analistas
INSERT INTO gestion_reclamos.analistas (codigo_empleado, nombre_completo, correo, activo)
SELECT 'ANL-' || g, 'Analista ' || g, 'analista' || g || '@empresa.com', TRUE
FROM generate_series(1,10) g
ON CONFLICT (codigo_empleado) DO NOTHING;

-- Miembros de equipo (distribución simple)
INSERT INTO gestion_reclamos.miembros_equipo (id_equipo, id_analista, fecha_asignacion)
SELECT
  CASE
    WHEN g <= 4 THEN 1
    WHEN g <= 7 THEN 2
    ELSE 3
  END AS id_equipo,
  g AS id_analista,
  CURRENT_DATE
FROM generate_series(1,10) g
ON CONFLICT DO NOTHING;

-- Revisores
INSERT INTO gestion_reclamos.revisores (id_tipo_revisor, nombre_completo, correo, activo)
SELECT tr.id_tipo_revisor, 'Revisor ' || g, 'revisor' || g || '@empresa.com', TRUE
FROM gestion_reclamos.tipos_revisor tr
JOIN generate_series(1,8) g ON TRUE
ON CONFLICT DO NOTHING;

-- ============================
-- Reclamos de prueba (1000)
-- ============================

-- Reclamos
INSERT INTO gestion_reclamos.reclamos (
  id_cliente, id_producto, id_tipo_reclamo, id_estado_actual,
  fecha_apertura, fecha_cierre, canal, referencia_externa,
  descripcion, monto, moneda
)
SELECT
  100000 + (g % 500), -- id_cliente simulado
  200000 + (g % 300), -- id_producto simulado
  (SELECT id_tipo_reclamo FROM gestion_reclamos.tipos_reclamo ORDER BY id_tipo_reclamo LIMIT 1 OFFSET (g % 5)),
  (SELECT id_estado FROM gestion_reclamos.estados_reclamo ORDER BY id_estado LIMIT 1 OFFSET (g % 7)),
  CURRENT_DATE - (g % 30),
  CASE WHEN g % 7 = 0 THEN CURRENT_DATE ELSE NULL END,
  CASE WHEN g % 4 = 0 THEN 'APP'
       WHEN g % 4 = 1 THEN 'WEB'
       WHEN g % 4 = 2 THEN 'CALL_CENTER'
       ELSE 'BRANCH' END,
  'REF-' || g,
  'Descripción del reclamo ' || g,
  ROUND(10 + (g % 5000) * 1.0, 2),
  CASE WHEN g % 5 = 0 THEN 'USD' ELSE 'PEN' END
FROM generate_series(1,1000) g;

-- Historial inicial
INSERT INTO gestion_reclamos.historial_estados (
  id_reclamo, id_estado_origen, id_estado_destino,
  fecha_cambio, usuario_cambio, nota
)
SELECT r.id_reclamo, NULL, r.id_estado_actual,
       r.fecha_apertura, 'seed', 'Estado inicial'
FROM gestion_reclamos.reclamos r;

-- Asignaciones de reclamo
INSERT INTO gestion_reclamos.asignaciones_reclamo (
  id_reclamo, id_equipo, id_analista, fecha_asignacion
)
SELECT r.id_reclamo,
       CASE
         WHEN tr.codigo IN ('FRAUDE_TARJETA','CARGO_NO_AUTORIZADO') THEN 1
         WHEN tr.codigo IN ('DOBLE_COBRO','ERROR_MONTO') THEN 2
         ELSE 3
       END AS id_equipo,
       ((r.id_reclamo % 10) + 1) AS id_analista,
       r.fecha_apertura
FROM gestion_reclamos.reclamos r
JOIN gestion_reclamos.tipos_reclamo tr ON tr.id_tipo_reclamo = r.id_tipo_reclamo;

-- Evidencias (0–2 por reclamo)
INSERT INTO gestion_reclamos.evidencias_reclamo (
  id_reclamo, tipo_evidencia, url_almacenamiento,
  referencia_externa, metadatos, fecha_agregado, agregado_por
)
SELECT r.id_reclamo,
       CASE WHEN e % 2 = 0 THEN 'DOCUMENT' ELSE 'IMAGE' END,
       'https://evidencias/reclamo_' || r.id_reclamo || '_' || e || '.pdf',
       'EV-' || r.id_reclamo || '-' || e,
       json_build_object('mime', 'application/pdf', 'size_kb', 100 + e * 10),
       r.fecha_apertura,
       'seed'
FROM gestion_reclamos.reclamos r
JOIN generate_series(0,2) e ON (r.id_reclamo % 3 = e);

-- Movimientos externos (0–3 por reclamo)
INSERT INTO gestion_reclamos.movimientos_reclamo (
  id_reclamo, id_movimiento_externo, sistema_origen, fecha_vinculo
)
SELECT r.id_reclamo,
       'TX-' || r.id_reclamo || '-' || m,
       CASE WHEN r.id_reclamo % 2 = 0 THEN 'CORE_CARDS' ELSE 'TX_ENGINE' END,
       r.fecha_apertura
FROM gestion_reclamos.reclamos r
JOIN generate_series(1,3) m ON (r.id_reclamo % 4 = m);

-- Revisores asignados a reclamos sensibles
INSERT INTO gestion_reclamos.revisores_reclamo (
  id_reclamo, id_revisor, fecha_asignacion, nota
)
SELECT r.id_reclamo,
       ((r.id_reclamo % 8) + 1),
       r.fecha_apertura + 1,
       'Asignado por semilla'
FROM gestion_reclamos.reclamos r
JOIN gestion_reclamos.tipos_reclamo tr ON tr.id_tipo_reclamo = r.id_tipo_reclamo
WHERE tr.codigo IN ('FRAUDE_TARJETA','CARGO_NO_AUTORIZADO');