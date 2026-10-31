# Informe: Manejo de transacciones en SQL Server

**Proyecto:** DragabulK (Base de datos `DragabulK_TCG`)
**Etapa:** V - Manejo de transacciones
**Tema:** Proceso de venta real con validación de stock y reposición con transacción anidada

## 1. Introducción

Una base de datos casi nunca ejecuta una sola instrucción aislada. Una venta, por ejemplo, implica registrar la cabecera de la compra, registrar su detalle y descontar el stock del producto. Si una de esas operaciones falla a mitad de camino, la base de datos queda en un estado inconsistente: habría una venta sin detalle, o un stock descontado sin venta registrada.

Las **transacciones** resuelven este problema agrupando varias instrucciones en una sola unidad de trabajo que se ejecuta **completa o no se ejecuta en absoluto**. Este informe explica qué son las transacciones, cómo se usan en T-SQL y por qué son necesarias, tomando como base el script de la Etapa V del proyecto DragabulK.

## 2. Marco teórico

## Propiedades ACID

Las transacciones garantizan cuatro propiedades conocidas como ACID:

| Propiedad | Significado | Ejemplo en DragabulK |
|---|---|---|
| **Atomicidad** | Todo o nada. | La venta y el descuento de stock se confirman juntos o se deshacen juntos. |
| **Consistencia** | La base pasa de un estado válido a otro válido. | El stock nunca queda con un valor que contradiga las reglas de negocio. |
| **Aislamiento** | Las transacciones concurrentes no se interfieren de forma indebida. | Dos clientes no pueden vender las mismas unidades simultáneamente. |
| **Durabilidad** | Una vez confirmada, la operación persiste aunque falle el servidor. | Un `COMMIT` guarda la venta en disco de forma permanente. |

### Instrucciones principales

- **`BEGIN TRANSACTION`**: inicia una transacción explícita.
- **`COMMIT TRANSACTION`**: confirma todos los cambios realizados desde el `BEGIN`.
- **`ROLLBACK TRANSACTION`**: deshace todos los cambios desde el `BEGIN`.
- **`SAVE TRANSACTION nombre`**: crea un punto de guardado dentro de la transacción, al que se puede volver sin cancelar todo.
- **`ROLLBACK TRANSACTION nombre`**: revierte únicamente hasta el punto de guardado indicado.
- **`@@TRANCOUNT`**: variable del sistema que indica cuántas transacciones están abiertas.

### Manejo de errores con TRY...CATCH

Las transacciones se combinan con `BEGIN TRY ... END TRY` y `BEGIN CATCH ... END CATCH`. Si ocurre un error dentro del bloque `TRY`, el control pasa al `CATCH`, donde se decide si hacer `ROLLBACK` o recuperar la operación. Dentro del `CATCH` se usan funciones como `ERROR_MESSAGE()` para conocer la causa.

## 3. Descripción del script

El script contiene cuatro bloques independientes:

1. **Prueba 1 - Venta exitosa:** compra 5 sobres "Pitch Black" (ID 2). Primero verifica el stock; si alcanza, inserta en `COMPRA`, inserta en `DETALLE_COMPRA`, descuenta el stock en `PRODUCTO` y confirma con `COMMIT`.
2. **Prueba 2 - Atomicidad ante error:** realiza los mismos inserts, pero provoca un error intencional (`1 / 0`) antes del descuento de stock. El `CATCH` ejecuta `ROLLBACK`, por lo que ninguno de los inserts queda guardado.
3. **Reposición con transacción anidada:** registra una reposición de 100 unidades y luego intenta insertar un teléfono y un correo de proveedor. El correo usa un proveedor inexistente (ID 99999), lo que viola una clave foránea. Se revierte solo hasta el punto de guardado `PuntoContactoProveedor`, y se confirma la reposición.
4. **Consultas de verificación:** comprueban el resultado de cada prueba con `SELECT`.

## 4. Análisis de cada escenario

### Prueba 1: venta con stock suficiente

La validación previa es el punto clave. Antes de escribir, el programa consulta el stock y decide:

```sql
IF @stock_actual_ok < @cantidad_ok
    ROLLBACK TRANSACTION;  -- no hay stock: se cancela
ELSE
    -- insertar COMPRA, DETALLE_COMPRA, descontar stock
    COMMIT TRANSACTION;
```

**Resultado esperado:** la compra aparece en `COMPRA`, su detalle en `DETALLE_COMPRA` y el stock de "Pitch Black" disminuye en 5 unidades.

**Observación:** la validación y el descuento ocurren en pasos separados. En un sistema con muchos usuarios simultáneos, otra venta podría consumir el stock entre la consulta y el `UPDATE`. Para evitarlo se pueden usar niveles de aislamiento más estrictos (como `REPEATABLE READ`) o bloqueos explícitos (`WITH (UPDLOCK, HOLDLOCK)`).

### Prueba 2: atomicidad

Los inserts se ejecutan dentro de la transacción, pero el error de división por cero interrumpe el flujo. El `CATCH` ejecuta `ROLLBACK`, y el motor deshace los inserts ya realizados.

**Resultado esperado:** las consultas de verificación devuelven 0 filas para la compra fallida y el detalle fallido, y el stock permanece igual al de la Prueba 1.

Este caso demuestra la **atomicidad**: aunque dos de tres pasos se hayan completado, el sistema no deja datos parciales.

### Reposición con transacción anidada

Este bloque introduce el concepto de **punto de guardado**:

1. Se inserta la reposición (100 unidades). Este dato debe conservarse.
2. Se crea el punto de guardado con `SAVE TRANSACTION PuntoContactoProveedor`.
3. Se insertan el teléfono y el correo. El correo falla por la clave foránea.
4. El `CATCH` ejecuta `ROLLBACK TRANSACTION PuntoContactoProveedor`, que deshace solo lo posterior al punto de guardado: el teléfono y el correo fallidos.
5. Se ejecuta `COMMIT TRANSACTION`, que confirma la reposición.

**Resultado esperado:** la reposición queda en `REPOSICION_PRODUCTOS`, pero el teléfono nuevo no aparece en `PROVEEDOR_TELEFONO`.

**Nota técnica:** un `ROLLBACK` con nombre de punto de guardado no cierra la transacción externa; por eso el `COMMIT` posterior es necesario. Si se hiciera un `ROLLBACK` sin nombre, se cancelaría toda la transacción, incluida la reposición.

## 5. ¿Para qué sirven las transacciones en este proyecto?

- **Integridad de datos:** evitan ventas sin detalle o stock descontado sin venta.
- **Control de inventario:** la validación de stock impide vender más de lo disponible.
- **Recuperación ante errores:** permiten revertir operaciones sin intervención manual.
- **Flexibilidad:** los puntos de guardado permiten conservar parte del trabajo cuando solo una subparte falla.
- **Confiabilidad para el negocio:** el historial de ventas y reposiciones refleja solo operaciones completas y válidas.

## 6. Buenas prácticas y limitaciones detectadas

- **Generación de IDs:** el script calcula el siguiente ID con `MAX(ID) + 1`. Esto funciona en pruebas de un solo usuario, pero bajo concurrencia dos sesiones pueden obtener el mismo ID. Lo recomendable es usar columnas `IDENTITY` o `SEQUENCE`.
- **Bloqueos al validar stock:** para una venta real con varios usuarios, conviene bloquear la fila del producto durante la validación.
- **Manejo de errores:** es recomendable registrar los errores en una tabla de auditoría, además de imprimirlos.
- **Variables entre lotes:** las variables declaradas no sobreviven al separador `GO`, por lo que las consultas de verificación vuelven a calcular los valores necesarios.
- **Transacciones cortas:** conviene mantener las transacciones lo más breves posible para no bloquear recursos por mucho tiempo.

## 7. Conclusiones

Las transacciones son el mecanismo que permite que una base de datos sea confiable. En el proyecto DragabulK, el script demuestra tres usos fundamentales: confirmar operaciones completas (venta exitosa), deshacer operaciones parciales ante un error (atomicidad) y conservar una parte del trabajo mediante puntos de guardado (transacción anidada).

Además, el análisis muestra que una implementación real debe considerar la concurrencia, la generación segura de identificadores y el control de bloqueos. Con estos ajustes, el proceso de venta y reposición cumple con las propiedades ACID y protege la coherencia del inventario.
