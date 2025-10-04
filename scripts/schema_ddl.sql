CREATE SCHEMA IF NOT EXISTS gestion_reclamos;

-- Catálogos
CREATE TABLE IF NOT EXISTS gestion_reclamos.tipos_reclamo (
  id_tipo_reclamo SMALLSERIAL PRIMARY KEY,
  codigo VARCHAR(32) UNIQUE NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  descripcion VARCHAR(300)
);

CREATE TABLE IF NOT EXISTS gestion_reclamos.estados_reclamo (
  id_estado BIGSERIAL PRIMARY KEY,
  codigo VARCHAR(40) UNIQUE NOT NULL,
  nombre VARCHAR(120) NOT NULL
);

CREATE TABLE IF NOT EXISTS gestion_reclamos.tipos_revisor (
  id_tipo_revisor SMALLSERIAL PRIMARY KEY,
  codigo VARCHAR(32) UNIQUE NOT NULL,
  nombre VARCHAR(120) NOT NULL,
  descripcion VARCHAR(300)
);

-- Reclamos
CREATE TABLE IF NOT EXISTS gestion_reclamos.reclamos (
  id_reclamo BIGSERIAL PRIMARY KEY,
  id_cliente INT NOT NULL,
  id_producto INT NOT NULL,
  id_tipo_reclamo SMALLINT NOT NULL REFERENCES gestion_reclamos.tipos_reclamo(id_tipo_reclamo),
  id_estado_actual BIGINT NOT NULL REFERENCES gestion_reclamos.estados_reclamo(id_estado),
  fecha_apertura DATE NOT NULL,
  fecha_cierre DATE,
  canal VARCHAR(32),
  referencia_externa VARCHAR(64) UNIQUE NOT NULL,
  descripcion VARCHAR(1000),
  monto NUMERIC(10,2),
  moneda VARCHAR(3),
  fecha_actualizacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Historial de estados
CREATE TABLE IF NOT EXISTS gestion_reclamos.historial_estados (
  id_historial BIGSERIAL PRIMARY KEY,
  id_reclamo BIGINT NOT NULL REFERENCES gestion_reclamos.reclamos(id_reclamo) ON DELETE CASCADE,
  id_estado_origen BIGINT REFERENCES gestion_reclamos.estados_reclamo(id_estado),
  id_estado_destino BIGINT NOT NULL REFERENCES gestion_reclamos.estados_reclamo(id_estado),
  fecha_cambio DATE NOT NULL,
  usuario_cambio VARCHAR(120),
  nota VARCHAR(500),
  fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Equipos y analistas
CREATE TABLE IF NOT EXISTS gestion_reclamos.equipos_backoffice (
  id_equipo SMALLSERIAL PRIMARY KEY,
  codigo VARCHAR(32) UNIQUE NOT NULL,
  nombre VARCHAR(160) NOT NULL,
  descripcion VARCHAR(300)
);

CREATE TABLE IF NOT EXISTS gestion_reclamos.analistas (
  id_analista SMALLSERIAL PRIMARY KEY,
  codigo_empleado VARCHAR(32) UNIQUE,
  nombre_completo VARCHAR(160) NOT NULL,
  correo VARCHAR(160) NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS gestion_reclamos.miembros_equipo (
  id_equipo SMALLINT NOT NULL REFERENCES gestion_reclamos.equipos_backoffice(id_equipo) ON DELETE CASCADE,
  id_analista SMALLINT NOT NULL REFERENCES gestion_reclamos.analistas(id_analista) ON DELETE CASCADE,
  fecha_asignacion DATE NOT NULL,
  fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id_equipo, id_analista)
);

CREATE TABLE IF NOT EXISTS gestion_reclamos.asignaciones_reclamo (
  id_asignacion BIGSERIAL PRIMARY KEY,
  id_reclamo BIGINT NOT NULL REFERENCES gestion_reclamos.reclamos(id_reclamo) ON DELETE CASCADE,
  id_equipo SMALLINT NOT NULL REFERENCES gestion_reclamos.equipos_backoffice(id_equipo),
  id_analista SMALLINT NOT NULL REFERENCES gestion_reclamos.analistas(id_analista),
  fecha_asignacion DATE NOT NULL,
  fecha_desasignacion DATE,
  fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Revisores
CREATE TABLE IF NOT EXISTS gestion_reclamos.revisores (
  id_revisor SMALLSERIAL PRIMARY KEY,
  id_tipo_revisor SMALLINT NOT NULL REFERENCES gestion_reclamos.tipos_revisor(id_tipo_revisor),
  nombre_completo VARCHAR(160) NOT NULL,
  correo VARCHAR(160) NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS gestion_reclamos.revisores_reclamo (
  id_asignacion BIGSERIAL PRIMARY KEY,
  id_reclamo BIGINT NOT NULL REFERENCES gestion_reclamos.reclamos(id_reclamo) ON DELETE CASCADE,
  id_revisor SMALLINT NOT NULL REFERENCES gestion_reclamos.revisores(id_revisor),
  fecha_asignacion DATE NOT NULL,
  decision VARCHAR(40),
  fecha_decision DATE,
  nota VARCHAR(500),
  fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Evidencias
CREATE TABLE IF NOT EXISTS gestion_reclamos.evidencias_reclamo (
  id_evidencia BIGSERIAL PRIMARY KEY,
  id_reclamo BIGINT NOT NULL REFERENCES gestion_reclamos.reclamos(id_reclamo) ON DELETE CASCADE,
  tipo_evidencia VARCHAR(40) NOT NULL,
  url_almacenamiento VARCHAR(300),
  referencia_externa VARCHAR(120),
  metadatos JSON,
  fecha_agregado DATE NOT NULL,
  agregado_por VARCHAR(120),
  fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Movimientos externos
CREATE TABLE IF NOT EXISTS gestion_reclamos.movimientos_reclamo (
  id_movimiento BIGSERIAL PRIMARY KEY,
  id_reclamo BIGINT NOT NULL REFERENCES gestion_reclamos.reclamos(id_reclamo) ON DELETE CASCADE,
  id_movimiento_externo VARCHAR(80) NOT NULL,
  sistema_origen VARCHAR(60) NOT NULL,
  fecha_vinculo DATE NOT NULL,
  fecha_registro TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (id_reclamo, id_movimiento_externo, sistema_origen)
);