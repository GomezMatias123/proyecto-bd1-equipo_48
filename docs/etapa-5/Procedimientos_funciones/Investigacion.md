# Procedimientos y funciones almacenadas


## 1. Definición
Son bloques de código SQL (a menudo extendidos con
lógica procedimental como bucles y condicionales) que se almacenan directamente en la base de
datos. Pensamos en ellos como subrutinas o métodos dentro de tu base de datos, que encapsulan
lógica de negocio.
**Procedimiento almacenado (Stored Procedure):** programa SQL que ejecuta una o varias operaciones. Se invoca con `EXEC`, recibe parámetros (de entrada y de salida con `OUTPUT`), pueden o no
devolver un conjunto de resultados y puede modificar datos (`INSERT`, `UPDATE`, `DELETE`).

**Función almacenada (Function):** 
Rutina que recibe parámetros y siempre devuelve un valor o una tabla. Se usa dentro de expresiones (`SELECT`, `WHERE`, etc) y **no puede modificar datos**.

## 2. Objetivo

- Comprender la diferencia entre procedimientos y funciones.
- Aplicarlos en operaciones CRUD sobre la tabla `PRODUCTO` y en cálculos de negocio sobre `COMPRA` y `DETALLE_COMPRA`.
- Comparar su eficiencia contra las operaciones directas.

## 3. Ventajas

- **Reutilizan lógica de negocio:** una regla se escribe una vez y se usa en muchos lugares.
- **Reducen código repetido:** `fn_TotalConDescuento` reutiliza `fn_TotalCompra`.
- **Mejoran la mantenibilidad:** si cambia una regla, se corrige en un solo objeto.
- **Centralizan reglas de negocio:** las validaciones no dependen de cada aplicación que acceda a la base.
- **Facilitan la seguridad:** se puede dar permiso para ejecutar el procedimiento sin dar acceso directo a la tabla.

## 4. Aplicaciones en Dragabulk.TCG

| Objeto | Tipo | Qué resuelve |
|---|---|---|
| `sp_Producto_Insertar` | Procedimiento | Alta de producto con validaciones y ID de salida |
| `sp_Producto_Modificar` | Procedimiento | Modificación de producto con validaciones |
| `sp_Producto_Eliminar` | Procedimiento | Baja de producto protegiendo el historial |
| `fn_TotalCompra` | Función | Total de una compra (`Precio_unitario × Cantidad`) |
| `fn_TotalConDescuento` | Función | Total aplicando el descuento de socio (0% si no es socio) |
| `fn_ProductosStockBajo` | Función | Productos con stock menor o igual a un umbral |

---

## 5. Implementación

### 5.1 Procedimientos

 `sp_Producto_Insertar`

Recibe edición, precio, stock y tipo, y devuelve el ID asignado mediante un parámetro `OUTPUT`. Valida antes de insertar:

| Error | Regla |
|---|---|
| 50001 | El precio debe ser mayor a 0 |
| 50002 | El stock no puede ser negativo |
| 50003 | No puede repetirse la combinación edición + tipo |

`ID_producto` no es `IDENTITY`, por lo que el tuvimos que investigar y logramos que el procedimiento calcule `MAX(ID_producto) + 1`, pero en un sistema real con concurrencia correspondería usar `IDENTITY`.

`sp_Producto_Modificar`

Recibe el ID del producto y los nuevos valores. Agrega el error **50004** (el producto no existe), que de otro modo pasaría inadvertido porque un `UPDATE` sobre un ID inexistente no da error. La validación de duplicados excluye al propio producto (`ID_producto <> @ID_producto`).

Cambiar `Precio_actual` no altera `DETALLE_COMPRA`: el historial de precios de ventas pasadas se conserva.

`sp_Producto_Eliminar`

Valida antes de borrar:

| Error | Regla |
|---|---|
| 50004 | El producto no existe |
| 50005 | Tiene ventas registradas (`DETALLE_COMPRA`) |
| 50006 | Tiene reposiciones registradas (`REPOSICION_PRODUCTOS`) |

### 5.4 Funciones

- **`fn_TotalCompra(@ID_compra)`**: Realiza la operacion `Precio_unitario × Cantidad` del detalle. Devuelve 0 si la compra no tiene detalle.
- **`fn_TotalConDescuento(@ID_compra)`**: Llama a `fn_TotalCompra` y aplica el descuento del cliente si es socio. Usa `100.0` para evitar división entera.
- **`fn_ProductosStockBajo(@umbral)`**: Función de tabla en línea, se usa en el `FROM` como si fuera una tabla.
---

## 6. Demostración de uso

### 6.1 Procedimientos CRUD

| Prueba | Resultado | Evidencia |
|---|---|---|
| Insertar producto válido | Se crea con ID 9 | `01_insertar_ok` |
| Modificar el producto 9 | Precio 460000, stock 6 | `02_modificar_ok` |
| Insertar y eliminar un producto temporal | Existe antes del DELETE, 0 filas después | `03_eliminar_ok` |
| Casos de error (precio negativo, producto inexistente, producto con ventas) | Errores 50001, 50004 y 50005 | `04_errores_procedimientos` |

### 6.2 Dos lotes de datos

| Lote | Método | IDs | Evidencia |
|---|---|---|---|
| 1 | `INSERT` directos | 10 a 12 | `05_lote1_insert_directo` |
| 2 | Invocando `sp_Producto_Insertar` | 13 a 15 | `06_lote2_procedimiento` |

En el lote 1 los IDs se indican a mano y no se valida nada. En el lote 2 el procedimiento asigna el ID y aplica las validaciones.

### 6.3 UPDATE y DELETE mediante procedimientos

| Operación | Producto | Cambio |
|---|---|---|
| `sp_Producto_Modificar` | 11 | Precio de 16500 a 18000 |
| `sp_Producto_Modificar` | 14 | Stock de 70 a 120 |
| `sp_Producto_Eliminar` | 12 y 15 | Eliminados |

Evidencia: `07_update_delete_antes_despues`.

### 6.4 Funciones

| Compra | Total | Total con descuento |
|---|---|---|
| 1 | 484000 | 435600.00 |
| 2 | 119000 | 101150.00 |
| 3 | 583000 | 466400.00 |
| 4 | 92000 | 87400.00 |
| 5 | 258000 | 232200.00 |
| 6 | 102000 | 86700.00 |
| 7 | 450000 | 360000.00 |
| 8 | 80000 | 76000.00 |

Evidencia: `08_funciones_totales`. Además, `fn_ProductosStockBajo(5)` devuelve los productos 1, 5, 7 y 13 (`09_funcion_stock_bajo`).

---

## 7. Comparación de eficiencia

Se repite cada operación en un bucle para que la diferencia sea medible. Ambas pruebas parten de la misma tabla, porque las filas de la primera se eliminan antes de correr la segunda y los resultados numericos pueden variar cada vez que se ejecuta la prueba pero mantienen el margen de diferencia similar cada vez que se realiza.

### 7.1 INSERT directo vs. procedimiento (1000 operaciones)

| Método | Tiempo total | 
|---|---|---|
| `INSERT` directo | 111 ms |
| `sp_Producto_Insertar` | 443 ms | 

Evidencia: `10_eficiencia_insert`.

### 7.2 Función vs. consulta directa (5000 operaciones)

| Método | Tiempo total | Por operación |
|---|---|---|
| `fn_TotalCompra(3)` | 70 ms |
| Consulta directa equivalente | 32 ms | ms |

Evidencia: `11_eficiencia_funcion`.

### 7.3 Conclusiones

- Las operaciones directas son más rápidas en 
bruto, aunque La diferencia es de **fracciones de milisegundo por operación** lo que es irrelevante para el volumen de una tienda física. Sin embargo, el
procedimiento hace más trabajo: valida precio, stock y duplicados, y devuelve el ID. El `INSERT` directo no conlleva los mismos controles o condiciones. 
Por lo que ese costo extra agrega **integridad en los datos**.