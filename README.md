# 📑 Base de Datos - Gestión de Reclamos

Este documento describe la **base de datos del sistema de gestión de reclamos**, diseñada para soportar el ciclo de vida completo de un reclamo: registro, asignación, revisión, evidencias, historial de estados y movimientos asociados.

---

## 📌 Índice

1. [Descripción general](#-descripción-general)
2. [Modelo Entidad-Relación (MER)](#-modelo-entidad-relación-mer)
   - [Imagen del MER](#imagen-del-mer)
   - [Diccionario de datos](#diccionario-de-datos)
3. [Scripts SQL](#-scripts-sql)
   - [DDL - Definición de esquema](#ddl---definición-de-esquema)
   - [DML - Carga inicial de datos](#dml---carga-inicial-de-datos)
4. [Notas de diseño](#-notas-de-diseño)

---

## 📝 Descripción general

La base de datos está implementada en **PostgreSQL** bajo el esquema `gestion_reclamos`.  
Su diseño contempla:

- **Reclamos** como entidad central, vinculados a clientes y productos externos.
- **Estados** y **historial de estados** para trazabilidad completa.
- **Asignaciones** a equipos y analistas de backoffice.
- **Revisores** y sus decisiones.
- **Evidencias** y **movimientos externos** asociados a cada reclamo.

---

## 🗂 Modelo Entidad-Relación (MER)

### Imagen del MER
> Diagrama generado con https://dbdiagram.io/

### Documentación online
> Documentación en dbdocs: https://dbdocs.io/winstonflores30/Prj-Reclamos-Core

![MER-GestiondeReclamosAbc](./docs/mer-gestion-reclamos.svg)

---

### Diccionario de datos

| Tabla                  | Descripción                                                                 |
|-------------------------|-----------------------------------------------------------------------------|
| **tipos_reclamo**       | Catálogo de tipos de reclamo (ej. fraude, cobro indebido).                  |
| **estados_reclamo**     | Catálogo de estados posibles de un reclamo.                                |
| **tipos_revisor**       | Catálogo de tipos de revisor (ej. legal, auditoría).                       |
| **reclamos**            | Entidad principal: contiene datos del reclamo, cliente, producto y estado. |
| **historial_estados**   | Registro de cambios de estado de cada reclamo.                             |
| **equipos_backoffice**  | Equipos responsables de gestionar reclamos.                                |
| **analistas**           | Analistas que pertenecen a equipos.                                        |
| **miembros_equipo**     | Relación N:M entre equipos y analistas.                                    |
| **asignaciones_reclamo**| Asignaciones de reclamos a equipos y analistas.                            |
| **revisores**           | Personas que revisan reclamos según su tipo.                               |
| **revisores_reclamo**   | Relación entre reclamos y revisores, con decisión y notas.                 |
| **evidencias_reclamo**  | Evidencias asociadas a un reclamo (archivos, metadatos).                   |
| **movimientos_reclamo** | Movimientos externos vinculados a un reclamo.                              |

---

## 🗄 Scripts SQL

### DDL - Definición de esquema
Archivo: [`scripts/schema_ddl.sql`](./scripts/schema_ddl.sql)  
Contiene la creación de todas las tablas, claves primarias, foráneas e índices.

Ejemplo:
```sql
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
```

### DML - Carga inicial de datos
Archivo: [`scripts/data_dml.sql`](./scripts/data_dml.sql)  
Incluye catálogos iniciales para pruebas y configuración.

Ejemplo:
```sql
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

```

---

## 📌 Notas de diseño

- Todas las tablas incluyen **claves primarias autoincrementales** (`SMALLSERIAL` o `BIGSERIAL`) según cardinalidad esperada.
- Se definen **índices compuestos y restricciones únicas** para garantizar integridad (ej. `miembros_equipo`, `movimientos_reclamo`).
- Se aplican **relaciones en cascada** en entidades dependientes (ej. historial, evidencias, asignaciones).
- El modelo está preparado para **auditoría y trazabilidad completa** de cada reclamo.

---