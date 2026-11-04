# Informe: Implementación de Control de Acceso Basado en Roles (RBAC) y Seguridad Granular en SQL Server

**Proyecto:** DragabulK (Base de datos `DragabulK_TCG`)  
**Etapa:** V - Seguridad y Control de Acceso en Bases de Datos  
**Integrante:** Magno Exequiel Isler Mendiaz
**Tema:** Manejo de permisos a nivel de usuarios y roles en SQL Server


---

## 1. Introducción

En el desarrollo de sistemas transaccionales para tiendas físicas y comercio electrónico —como **DragabulK_TCG**—, garantizar la seguridad e integridad de la información es tan crítico como la optimización de las consultas. Las bases de datos que gestionan inventario, transacciones financieras y datos personales de clientes deben protegerse contra accesos no autorizados, modificaciones indebidas y brechas de seguridad.

El principio de menor privilegio establece que cada usuario u operación del sistema debe contar únicamente con los permisos mínimos necesarios para realizar su tarea. En este informe se analiza la implementación práctica del esquema de **Control de Acceso Basado en Roles (RBAC)** en SQL Server para el ecosistema **DragabulK_TCG**, evaluando el aislamiento de credenciales, la restricción de operaciones directas sobre tablas críticas y la delegación de transacciones mediante procedimientos almacenados autorizados.

---

## 2. Marco teórico

### Concepto de RBAC, Autenticación y Permisos Granulares

SQL Server maneja un modelo de seguridad jerárquico dividido en dos niveles de autenticación y autorización:

**Inicios de Sesión (`Logins`):** Entidad de seguridad a nivel de servidor que permite la autenticación del usuario en la instancia de SQL Server.
**Usuarios de Base de Datos (`Users`):** Mapeo del *Login* dentro de una base de datos específica (`DragabulK_TCG`). Define qué identidad adopta el usuario al operar sobre los objetos de dicha base de datos.
**Roles de Base de Datos (`Roles`):** Agrupaciones de usuarios que comparten los mismos privilegios. Permiten administrar la seguridad de forma centralizada y escalable sin necesidad de asignar permisos individualmente.
**Roles Fijos del Sistema:** Roles predeterminados como `db_owner` (control total) o `db_datareader` (lectura global).
**Roles Personalizados:** Roles definidos por el administrador (ej. `rol_operador_tcg`) para agrupar permisos específicos según el perfil laboral del empleado.
**Permisos Granulares (`GRANT` / `DENY`):**
  **`GRANT`:** Concede de forma explícita permisos para realizar operaciones específicas (ej. `SELECT`, `EXECUTE`) sobre tablas o procedimientos.
  **`DENY`:** Niega explícitamente un permiso. El `DENY` tiene máxima prioridad en SQL Server y anula cualquier otro permiso heredado por rol o grupo.
**Propiedad Encadenada y Procedimientos Almacenados (*Ownership Chaining*):** Mecanismo de seguridad que permite a un usuario sin permisos de `INSERT` directo en una tabla ejecutar un procedimiento almacenado que realiza la inserción, siempre y cuando ambos objetos pertenezcan al mismo esquema (`dbo`) y el usuario posea el permiso `GRANT EXECUTE` sobre el procedimiento.

---

## 3. Descripción de los scripts y configuración de seguridad

Los scripts de configuración de seguridad aplicados a la base de datos `DragabulK_TCG` están estructurados en los siguientes pasos:

1. **Creación de Entidades de Seguridad (Logins y Users):** Se crearon los accesos `usuario_admin`, `usuario_lector` y `empleado_lucas` a nivel de servidor y su correspondiente vinculación dentro de la base de datos `DragabulK_TCG`.
2. **Asignación de Roles y Restricciones Directas:**
   * Se asignó `usuario_admin` al rol de sistema `db_owner`.
   * Se concedió `GRANT SELECT` sobre `dbo.PRODUCTO` a `usuario_lector` y `empleado_lucas`.
   * Se aplicó `DENY INSERT, UPDATE, DELETE` sobre la tabla crítica `dbo.COMPRA` para los usuarios no administradores.
3. **Encapsulación y Control mediante Procedimientos Almacenados:** Se creó el procedimiento almacenado `dbo.sp_RegistrarCompraSimple` para procesar ventas de forma controlada y se otorgó permiso de ejecución (`GRANT EXECUTE`) a los usuarios operativos.
4. **Validación de Comportamiento:** Se implementó una suite de validación usando `EXECUTE AS USER` y `REVERT` para verificar en tiempo real las restricciones y excepciones de seguridad.

---

## 4. Análisis de cada escenario de prueba

### Prueba 1: Consulta del Catálogo de Productos (`SELECT` Permitido)

Se evaluó la capacidad de los usuarios con permisos restringidos para consultar el inventario de cartas y productos de **DragabulK_TCG**.

```sql
EXECUTE AS USER = 'usuario_lector';
GO
SELECT ID_producto, Edicion, Precio_actual, Tipo FROM PRODUCTO;
GO
REVERT;
```

**Comportamiento observado:** La consulta se ejecuta de manera exitosa, retornando el listado completo de productos (Booster Boxes, Sobres, Elite Trainer Boxes). Esto confirma que las lecturas sobre tablas del catálogo público del sistema están correctamente habilitadas.

### Prueba 2: Bloqueo de Inserción Directa sobre la Tabla `COMPRA` (`DENY` Activo)

Se intentó realizar una modificación directa sobre la tabla transaccional `COMPRA` utilizando la identidad de un usuario restringido.

```sql
EXECUTE AS USER = 'usuario_lector';
GO
INSERT INTO COMPRA (ID_compra, ID_empleado, ID_metodo_pago, ID_cliente) 
VALUES (10, 1, 1, 1);
GO
REVERT;
```

**Comportamiento observado:** El motor de SQL Server bloquea la operación y genera el **Error 229**:  
`Mens. 229, Nivel 14, Estado 5, Línea 6`  
`The INSERT permission was denied on the object 'COMPRA', database 'DragabulK_TCG', schema 'dbo'.`  
Esto demuestra que el mecanismo de denegación explícita e integridad de datos funciona correctamente, impidiendo modificaciones no autorizadas directas en la base de datos.

### Prueba 3: Inserción Controlada mediante Procedimiento Almacenado (`GRANT EXECUTE`)

Se ejecutó el procedimiento almacenado autorizado para registrar una nueva venta bajo la identidad del usuario restringido.

```sql
EXECUTE AS USER = 'usuario_lector';
GO
EXEC dbo.sp_RegistrarCompraSimple 
    @ID_compra = 10, 
    @ID_empleado = 1, 
    @ID_metodo_pago = 1, 
    @ID_cliente = 1;
GO
REVERT;
```

**Comportamiento observado:** La transacción se completa exitosamente. Al consultar la tabla con la cuenta administradora (`SELECT * FROM COMPRA WHERE ID_compra = 10;`), se verifica que el registro fue insertado correctamente con la fecha del sistema (`GETDATE()`). Se comprueba que la propiedad encadenada permite operar de forma segura sin exponer permisos directos de escritura sobre la tabla.

---

## 5. Matriz Comparativa de Permisos y Comportamiento

| Rol / Usuario | Objeto Afectado | Operación Intentada | Permiso Asignado | Resultado de la Operación | Código / Estado de Respuesta |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **`usuario_admin`** (`db_owner`) | Toda la Base de Datos | `INSERT`, `UPDATE`, `SELECT` | Control Total (`db_owner`) | **Exitoso** | Ejecución normal |
| **`usuario_lector`** | Tabla `dbo.PRODUCTO` | `SELECT` | `GRANT SELECT` | **Exitoso** | Filas retornadas |
| **`usuario_lector`** | Tabla `dbo.COMPRA` | `INSERT` directo | `DENY INSERT` | **Bloqueado** | **Error 229** (Permiso denegado) |
| **`usuario_lector`** | Procedimiento `sp_RegistrarCompraSimple` | `EXECUTE` | `GRANT EXECUTE` | **Exitoso** | Inserción indirecta realizada |
| **`rol_operador_tcg`** | Tabla `dbo.COMPRA` | `DELETE` / `UPDATE` | Herencia de denegación | **Bloqueado** | **Error 229** (Permiso denegado) |

---

## 6. Evidencias Gráficas

Las capturas de pantalla que respaldan la ejecución de las pruebas reales en SQL Server Management Studio se encuentran archivadas en la carpeta de evidencias del repositorio:

**Evidencia de Correcta Carga de Datos:**
  `proyecto-bd1-equipo_48\docs\etapa-5\Seguridad_funciones\Evidencias\01-Prueba de lectura correcta.jpeg`
**Evidencia de Distincion de permisos de usuarios:**
  `proyecto-bd1-equipo_48\docs\etapa-5\Seguridad_funciones\Evidencias\02-Distincion en los permisos de usuarios.jpeg`
**Evidencia Error 229 (Inserción directa denegada):**  
  `proyecto-bd1-equipo_48\docs\etapa-5\Seguridad_funciones\Evidencias\03-Prueba de insercion directa.jpeg`
**Evidencia Ejecución Exitosa (Inserción vía SP):**  
  `proyecto-bd1-equipo_48\docs\etapa-5\Seguridad_funciones\Evidencias\04-Prueba de Procedimiento Almacenado.jpeg`
**Evidencia Fallo por ser rol empleado:**
  `proyecto-bd1-equipo_48\docs\etapa-5\Seguridad_funciones\Evidencias\05-Fallo al insertar por ser usuario_empleado.jpeg`
**Evidencia Fallo por ser rol empleado:**
  `proyecto-bd1-equipo_48\docs\etapa-5\Seguridad_funciones\Evidencias\06-Valido por ser usuario_supervisor.jpeg`
**Evidencia Verificación de Roles y Permisos en SSMS:**  
  `proyecto-bd1-equipo_48\docs\etapa-5\Seguridad_funciones\Evidencias\07-Distincion en comportamiento y permisos para cada usuario.jpeg`

---

## 7. Buenas prácticas y consideraciones de seguridad

- **Principio de Menor Privilegio:** Ningún usuario de la aplicación debe conectarse como `sa` o `db_owner`. Las aplicaciones cliente deben utilizar cuentas con permisos acotados estrictamente a las tareas de su módulo.
- **Uso de Procedimientos Almacenados como Capa de Abstracción:** Denegar el acceso directo a las tablas transaccionales e intermediar las operaciones a través de procedimientos almacenados previene ataques de inyección SQL (SQLi) y fuerza la validación de reglas de negocio en el motor.
- **Administración Basada en Roles (RBAC):** Asignar permisos a roles en lugar de a usuarios individuales facilita la rotación de personal y simplifica las auditorías de seguridad en la empresa.
- **Gestión Segura de Contraseñas:** Las credenciales de los *Logins* de producción deben cumplir con políticas de complejidad y ser gestionadas mediante variables de entorno o bóvedas de claves (Key Vaults), evitando incluirlas en texto plano en el código fuente.

---

## 8. Conclusiones

La implementación del esquema de seguridad y control de acceso en la base de datos **DragabulK_TCG** asegura la protección de los datos transaccionales del negocio.

A través del trabajo práctico realizado se concluye que:
1. La segregación de funciones mediante **roles y permisos granulares** previene modificaciones no autorizadas en tablas críticas como `COMPRA`.
2. El uso del comando `DENY` proporciona una barrera de seguridad infranqueable frente a intentos de omisión de restricciones de la aplicación.
3. La combinación de `DENY` en tablas directas con `GRANT EXECUTE` en **procedimientos almacenados** permite a los usuarios operativos realizar sus tareas comerciales sin comprometer la estructura de la base de datos ni los registros históricos.