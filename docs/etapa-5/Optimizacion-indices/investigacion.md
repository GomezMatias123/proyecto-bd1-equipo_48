# Informe: Optimización de consultas a través de índices en SQL Server

**Proyecto:** DragabulK (Base de datos `DragabulK_TCG`)  
**Etapa:** V - Optimización de consultas mediante índices  
**Integrante:** Emiliano Tomas Gonzalez  
**Tema:** Simulación masiva e impacto del indexado en búsquedas por rangos de fechas sobre el historial de ventas  

---

## 1. Introducción

En sistemas de comercio electrónico y tiendas físicas con alto volumen de operaciones —como **DragabulK_TCG**—, las tablas transaccionales acumulan cientos de miles o millones de registros con el tiempo. Realizar consultas analíticas o reportes sobre tablas masivas sin la preparación adecuada puede degradar drásticamente el rendimiento del motor de base de datos, consumiendo excesivos recursos de I/O (lectura en disco/memoria) y CPU.

Los **índices** constituyen el mecanismo fundamental en SQL Server para acelerar la localización y recuperación de filas sin necesidad de escanear la tabla de manera completa. En este informe se analiza el comportamiento interno del motor de base de datos mediante la simulación de 1.000.000 de registros en la tabla `COMPRA_HISTORICA`, evaluando tres escenarios progresivos de optimización a través de sus respectivos planes de ejecución y métricas de rendimiento.

---

## 2. Marco teórico

### Concepto de Índice e Índices No Agrupados (Non-Clustered)

Un índice es una estructura de datos B-Tree (Árbol Balanceado) independiente de las páginas de datos de la tabla. Almacena las claves del índice de forma ordenada junto con un puntero (RID en tablas Heap o Clustered Key en tablas indexadas) hacia la fila correspondiente.

* **Table Scan (Recorrido de Tabla):** Ocurre cuando el motor debe leer la totalidad de las páginas de datos de la tabla, registro por registro, para resolver un filtro `WHERE`. Es la operación más costosa en volúmenes masivos.
* **Index Seek (Búsqueda de Índice):** Ocurre cuando el motor utiliza la estructura de árbol del índice para navegar directamente hacia las filas que cumplen la condición del filtro `WHERE`, reduciendo las lecturas a una fracción mínima.
* **Key Lookup / RID Lookup (Búsqueda de claves / Heap):** Si la consulta solicita columnas que no están incluidas dentro del índice, el motor debe realizar un salto desde el índice hacia la tabla principal por cada fila filtrada para recuperar las columnas faltantes.
* **Covering Index (Índice de Cobertura - `INCLUDE`):** Es un índice no agrupado que añade en sus hojas columnas adicionales que no forman parte de la clave de búsqueda. Al incluir todas las columnas solicitadas por la consulta en la cláusula `INCLUDE`, se logra resoluciòn total desde el índice, eliminando por completo los *Lookups*.

### Métricas de Rendimiento Evaluadas

- **Lecturas Lógicas (`Logical Reads`):** Número de páginas de datos de 8 KB leídas del caché de memoria. Es el indicador de eficiencia I/O más estable.
- **Tiempo de CPU (`CPU Time`):** Tiempo en milisegundos consumido por los procesadores para procesar la instrucción.
- **Elapsed Time (Tiempo Transcurrido):** Tiempo total percibido desde el inicio hasta el fin de la ejecución.

---

## 3. Descripción del script

El script `script-indices.sql` está estructurado en las siguientes fases:

1. **Creación e Inserción Masiva:** Crea la tabla `COMPRA_HISTORICA` e inserta 1.000.000 de registros sintéticos distribuidos aleatoriamente en un rango de 5 años (2020 a 2025) con montos y referencias de clientes de la tienda.
2. **Prueba 1 - Consulta Sin Índices:** Ejecuta una consulta por rango de fechas (`WHERE Fecha BETWEEN '2023-01-01' AND '2023-03-31'`) sobre la tabla base en estado Heap (sin índices).
3. **Prueba 2 - Índice Simple por Fecha:** Crea un índice no agrupado sobre la columna `Fecha` (`IX_COMPRA_HISTORICA_Fecha`). Ejecuta la misma consulta utilizando un *Index Hint* (`WITH(INDEX(...))`) para forzar y evidenciar la combinación `Index Seek` + `RID Lookup`.
4. **Prueba 3 - Índice de Cobertura (`INCLUDE`):** Borra el índice anterior y crea `IX_COMPRA_HISTORICA_Fecha_Cobertura` incluyendo las columnas de la lista `SELECT` (`ID_compra`, `Monto_Total`, `ID_cliente`, `ID_metodo_pago`). Ejecuta la consulta para evaluar la resolución 100% cubierta.

---

## 4. Análisis de cada escenario

### Prueba 1: Consulta sin índices (Table Scan)

La consulta debe inspeccionar la totalidad del millón de registros almacenados en el Heap para determinar cuáles cumplen con el rango de fechas solicitado.

```sql
SELECT ID_compra, Fecha, Monto_Total, ID_cliente, ID_metodo_pago
FROM COMPRA_HISTORICA
WHERE Fecha BETWEEN '2023-01-01' AND '2023-03-31';
```

**Comportamiento observado:** El plan de ejecución asigna el 100% del costo al operador **`Recorrido de tabla` (`Table Scan`)**. SQL Server resalta la advertencia en verde de *Falta índice (Missing Index)* indicando un impacto estimado de mejora superior al 77%.

### Prueba 2: Índice Simple por Fecha (Index Seek + RID Lookup)

Se crea un índice enfocado exclusivamente en la columna del filtro:

```sql
CREATE NONCLUSTERED INDEX IX_COMPRA_HISTORICA_Fecha 
ON COMPRA_HISTORICA (Fecha);
```

**Comportamiento observado:** El motor realiza un **`Index Seek`** para ubicar de forma inmediata los punteros de las ~49.700 filas que cumplen el rango. Sin embargo, como el índice solo almacena la columna `Fecha`, el motor debe ejecutar un **`RID Lookup (Heap)`** por cada fila para traer `Monto_Total`, `ID_cliente`, etc., uniendo ambos resultados con un operador **`Nested Loops`**. El costo dominante (99%) se desplaza a los saltos individuales a la tabla base.

### Prueba 3: Índice de Cobertura / INCLUDE (Index Seek Puro)

Se optimiza la estructura agregando el resto de las columnas consultadas a la hoja del índice:

```sql
CREATE NONCLUSTERED INDEX IX_COMPRA_HISTORICA_Fecha_Cobertura 
ON COMPRA_HISTORICA (Fecha)
INCLUDE (ID_compra, Monto_Total, ID_cliente, ID_metodo_pago);
```

**Comportamiento observado:** El plan de ejecución simplifica su árbol a un único operador **`Index Seek (NonClustered)`** con costo 100%. Desaparece la necesidad de acceder a la tabla principal (`RID Lookup`) y desaparecen los operadores de combinación (`Nested Loops`), logrando el máximo nivel de rendimiento posible para la consulta.

---

## 5. Matriz Comparativa de Resultados

*(Valores representativos obtenidos durante la suite de pruebas en SSMS)*

| Escenario de Prueba | Tiempo CPU (ms) | Tiempo Total (ms) | Lecturas Lógicas (`Logical Reads`) | Operador Principal en Plan de Ejecución |
| :--- | :---: | :---: | :---: | :--- |
| **1. Sin Índice** | ~141 ms | ~480 ms | 5.077 | Recorrido de Tabla (`Table Scan`) |
| **2. Índice Simple** | ~125 ms | ~341 ms | > 50.000 * | `Index Seek` + `RID Lookup` (Nested Loops) |
| **3. Índice de Cobertura (`INCLUDE`)** | **~16 ms** | **~118 ms** | **~165** | **`Index Seek` (Cobertura Total)** |

*\* Nota: En la Prueba 2, el elevado número de lecturas lógicas responde a las miles de operaciones de consulta individuales (Lookups) requeridas para recuperar los campos no indexados.*

---

## 6. Evidencias Gráficas

Las capturas de los planes de ejecución reales obtenidos en SQL Server Management Studio se encuentran archivadas en la carpeta de evidencias del repositorio:

* **Prueba 1 (Sin Índice - Table Scan):**  
  `proyecto-bd1-equipo_48\docs\etapa-5\Optimizacion-indices\Evidencias\Caso 1 sin indice`
* **Prueba 2 (Índice Simple - Index Seek + RID Lookup):**  
  `proyecto-bd1-equipo_48\docs\etapa-5\Optimizacion-indices\Evidencias\Caso 2 indice simple por fecha`
* **Prueba 3 (Índice de Cobertura - Index Seek Puro):**  
  `proyecto-bd1-equipo_48\docs\etapa-5\Optimizacion-indices\Evidencias\Caso 3 indice de cobertura INCLUDE`

---

## 7. Buenas prácticas y consideraciones técnicas

- **Costo de Mantenimiento (`Overhead` de Escritura):** Aunque los índices aceleran dramáticamente las lecturas (`SELECT`), ralentizan las operaciones de modificación (`INSERT`, `UPDATE`, `DELETE`), ya que SQL Server debe actualizar el B-Tree con cada cambio.
- **Uso Responsable de `INCLUDE`:** No deben incluirse todas las columnas de la tabla dentro de la cláusula `INCLUDE`, sino solo las requeridas en consultas críticas o frecuentes. Incluir columnas innecesarias infla el tamaño del índice en disco y memoria.
- **Tipos de Datos Eficientes:** Definir columnas de fecha y valores numéricos con sus tipos estrictos (`DATE`, `DATETIME2`, `DECIMAL`) permite que el árbol del índice sea más compacto, almacenando más claves por página.
- **Mantenimiento Periódico:** En ambientes de producción con alta carga transaccional, los índices sufren fragmentación. Es necesario programar tareas de reorganización (`REORGANIZE`) o reconstrucción (`REBUILD`).

---

## 8. Conclusiones

La optimización de consultas mediante índices es una exigencia indispensable para mantener la escalabilidad de la base de datos **DragabulK_TCG**. 

A través del experimento práctico se evidenció que:
1. El **Table Scan** es ineficiente en grandes volúmenes de datos debido al alto consumo de I/O de lectura.
2. Un **índice simple** ayuda en la búsqueda de filas, pero puede generar un cuello de botella por *Lookups* si la consulta solicita columnas adicionales.
3. El **índice de cobertura (`INCLUDE`)** representa la solución óptima para reportes y búsquedas frecuentes por rangos de fecha, reduciendo el consumo de lecturas lógicas y tiempos de CPU en más de un 90% en comparación con la tabla sin optimizar.