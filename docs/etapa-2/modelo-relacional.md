# Dragabulk — Esquema Relacional

Documento generado a partir del archivo ERDPlus proporcionado.

## Tablas

### `CLIENTE`

| Campo | Tipo | PK | FK | Opcional |
|---|---|:---:|:---:|:---:|
| `ID_cliente` | `INT` | Sí |  | No |
| `dni` | `INT` |  |  | No |
| `Nombre` | `VARCHAR(n)` |  |  | No |
| `Apellido` | `VARCHAR(n)` |  |  | No |

### `EMPLEADO`

| Campo | Tipo | PK | FK | Opcional |
|---|---|:---:|:---:|:---:|
| `ID_empleado` | `INT` | Sí |  | No |
| `Apellido` | `VARCHAR(n)` |  |  | No |
| `Nombre` | `VARCHAR(n)` |  |  | No |

### `PROVEEDOR`

| Campo | Tipo | PK | FK | Opcional |
|---|---|:---:|:---:|:---:|
| `ID_proveedor` | `INT` | Sí |  | No |
| `Nombre` | `VARCHAR(n)` |  |  | No |
| `Tiempos de entrega` | `INT` |  |  | No |
| `fk_EMPLEADO` | `None` |  | Sí | No |

### `PRODUCTO`

| Campo | Tipo | PK | FK | Opcional |
|---|---|:---:|:---:|:---:|
| `ID_producto` | `INT` | Sí |  | No |
| `Edicion` | `VARCHAR(n)` |  |  | No |
| `Precio_actual` | `INT` |  |  | No |
| `Stock disponible` | `INT` |  |  | No |
| `Tipo` | `VARCHAR(n)` |  |  | No |

### `COMPRA`

| Campo | Tipo | PK | FK | Opcional |
|---|---|:---:|:---:|:---:|
| `ID_compra` | `INT` | Sí |  | No |
| `fk_EMPLEADO` | `None` |  | Sí | No |
| `fk_METODODEPAGO` | `None` |  | Sí | No |
| `fk_CLIENTE` | `None` |  | Sí | No |

### `DETALLE_COMPRA`

| Campo | Tipo | PK | FK | Opcional |
|---|---|:---:|:---:|:---:|
| `Precio unitario` | `INT` |  |  | No |
| `fk_COMPRA` | `None` | Sí | Sí | No |
| `fk_PRODUCTO` | `None` | Sí | Sí | No |
| `Cantidad` | `INT` |  |  | No |

### `METODODEPAGO`

| Campo | Tipo | PK | FK | Opcional |
|---|---|:---:|:---:|:---:|
| `ID_metodo_pago` | `INT` | Sí |  | No |
| `nombre` | `VARCHAR(n)` |  |  | No |

### `SOCIO`

| Campo | Tipo | PK | FK | Opcional |
|---|---|:---:|:---:|:---:|
| `Descuento` | `INT` |  |  | No |
| `Beneficio` | `INT` |  |  | No |
| `fk_CLIENTE` | `None` | Sí | Sí | No |

### `REPOSICION_PRODUCTOS`

| Campo | Tipo | PK | FK | Opcional |
|---|---|:---:|:---:|:---:|
| `Fecha` | `DATE` |  |  | No |
| `Cantidad` | `INT` |  |  | No |
| `ID_reposicion` | `INT` | Sí |  | No |
| `fk_PROVEEDOR` | `None` |  | Sí | No |
| `fk_PRODUCTO` | `None` |  | Sí | No |

### `PROVEEDOR_TELEFONO`

| Campo | Tipo | PK | FK | Opcional |
|---|---|:---:|:---:|:---:|
| `Telefono` | `INT` | Sí |  | No |
| `fk_PROVEEDOR` | `None` |  | Sí | No |

### `PROVEEDOR_EMAIL`

| Campo | Tipo | PK | FK | Opcional |
|---|---|:---:|:---:|:---:|
| `Email` | `VARCHAR(n)` | Sí |  | No |
| `fk_PROVEEDOR` | `None` |  | Sí | No |

### `telefono_empleado`

| Campo | Tipo | PK | FK | Opcional |
|---|---|:---:|:---:|:---:|
| `telefono` | `INT` | Sí |  | No |
| `fk_EMPLEADO` | `None` |  | Sí | No |

### `Telefono_cliente`

| Campo | Tipo | PK | FK | Opcional |
|---|---|:---:|:---:|:---:|
| `Telefono` | `INT` | Sí |  | No |
| `fk_CLIENTE` | `None` |  | Sí | No |

### `Email_cliente`

| Campo | Tipo | PK | FK | Opcional |
|---|---|:---:|:---:|:---:|
| `email` | `INT` | Sí |  | No |
| `fk_CLIENTE` | `None` |  | Sí | No |

## Relaciones

- **EMPLEADO → PROVEEDOR**: ``ID_empleado``
- **EMPLEADO → COMPRA**: ``ID_empleado``
- **METODODEPAGO → COMPRA**: ``ID_metodo_pago``
- **CLIENTE → COMPRA**: ``ID_cliente``
- **COMPRA → DETALLE_COMPRA**: ``ID_compra``
- **PRODUCTO → DETALLE_COMPRA**: ``ID_producto``
- **CLIENTE → SOCIO**: ``ID_cliente``
- **PROVEEDOR → REPOSICION_PRODUCTOS**: ``ID_proveedor``
- **PRODUCTO → REPOSICION_PRODUCTOS**: ``ID_producto``
- **PROVEEDOR → PROVEEDOR_TELEFONO**: ``ID_proveedor``
- **PROVEEDOR → PROVEEDOR_EMAIL**: ``ID_proveedor``
- **EMPLEADO → telefono_empleado**: ``ID_empleado``
- **CLIENTE → Telefono_cliente**: ``ID_cliente``
- **CLIENTE → Email_cliente**: ``ID_cliente``

## Claves foráneas por tabla

### `PROVEEDOR`

- `fk_EMPLEADO` → **EMPLEADO** (`ID_empleado`)

### `COMPRA`

- `fk_EMPLEADO` → **EMPLEADO** (`ID_empleado`)
- `fk_METODODEPAGO` → **METODODEPAGO** (`ID_metodo_pago`)
- `fk_CLIENTE` → **CLIENTE** (`ID_cliente`)

### `DETALLE_COMPRA`

- `fk_COMPRA` → **COMPRA** (`ID_compra`)
- `fk_PRODUCTO` → **PRODUCTO** (`ID_producto`)

### `SOCIO`

- `fk_CLIENTE` → **CLIENTE** (`ID_cliente`)

### `REPOSICION_PRODUCTOS`

- `fk_PROVEEDOR` → **PROVEEDOR** (`ID_proveedor`)
- `fk_PRODUCTO` → **PRODUCTO** (`ID_producto`)

### `PROVEEDOR_TELEFONO`

- `fk_PROVEEDOR` → **PROVEEDOR** (`ID_proveedor`)

### `PROVEEDOR_EMAIL`

- `fk_PROVEEDOR` → **PROVEEDOR** (`ID_proveedor`)

### `telefono_empleado`

- `fk_EMPLEADO` → **EMPLEADO** (`ID_empleado`)

### `Telefono_cliente`

- `fk_CLIENTE` → **CLIENTE** (`ID_cliente`)

### `Email_cliente`

- `fk_CLIENTE` → **CLIENTE** (`ID_cliente`)
