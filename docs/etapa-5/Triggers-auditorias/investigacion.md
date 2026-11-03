##  Triggers y Auditorias  -  Informe

## Alumno: Fernandez Fabio Javier

## DEFINICION

**Triggers:** Los triggers procedimientos los cuales se ejecutan al realizar un evento sobre una tabla (INSERT, UPDATE, DELETE). Se utilizan para obtener una mejor trazabilidad del proyecto, como tambien para realizar auditorias entre otras funciones ya que proporcionan informacion util del estado de la tabla antes de ser modificado, el quien lo modifico o incluso sirven para evitar ciertos sucesos a traves de los mismos. Estos mismos funcionan como reglas que pueden ser activadas o desactivadas a traves de **"DISABLE/ENABLE TRIGGER -NombreTrigger- ON -NombreTabla-/DATABASE"**

**Auditorias:** En el contexto de base de datos una auditoria es el proceso sistemático de registrar y examinar los eventos que ocurren dentro de una base de datos. Esto permite llevar un registro en caso de necesitar consultar datos pasado, revisar quien hizo modificaciones y cuando lo hizo y sobre todo que se modificó.


## Ventajas

Los triggers son herramientas extremadamente utilies y versatiles, poseen numerosas ventajas, entre ellas:

- **Trazabilidad del proyecto:** Pudiendo seguir el rastro de modificaciones hechos a la base de datos, asi como el cuando y quien los modifico
- **Incremento en la seguridad del proyecto:** al poder controlar los eventos que suceden y poder acceder a valores anteriores, se obtiene una base de datos mucho mas robusta y resistente a errores en torno a la actualizacion/borrado de datos
- **Control sobre los eventos:** A traves de comandos como **RAISERROR** se pueden evitar la activacion de otros procesos, como drop_table
- **Capacidad de recuperacion de datos:** Al tenerlos almacenados en la tabla de auditoria correspondiente, siempre se podran recuperar los valores anteriores de la tabla

## ¿Como lo implementamos la base de datos?

La implementacion de estos conceptos se hizo a traves de **auditorias**, las cuales se consiguieron utilizando el comando **CREATE TRIGGER** con la configuracion **ON -NombreTabla- UPDATE AS**, asi mismo tambien se implementaron las correspondientes tablas asociadas a las auditorias (AuditoriaProveedor, AuditoriaSocio, etc).

Especificamente se eligieron las siguientes tablas para el uso de triggers de auditoria:

-Cliente -- AuditoriaCliente
-Proveedor -- AuditoriaProveedor
-Socio -- AuditoriaSocio
-Empleado -- AuditoriaEmpleado
-Producto -- AuditoriaProducto

Ya que consideramos que son las mas suceptibles a cambios a lo largo del tiempo, mientras que aquellas que no fueron tomadas en cuenta se debio a que no consideramos que fuera eficiente o necesario aplicar dichos triggers.

Asi mismo tambien se añadio un capa mas de seguridad a traves del uso de un trigger que evita el comando **DROP_TABLE** en las tablas de la base de datos. Esto mismo se logro utilizando el comando **CREATE TRIGGER** pero en lugar de aplicarlo a una sola tabla, lo hicimos valido para la base de datos en su totalidad, esto fue posible cambiando **ON -NombreTabla- UPDATE AS** por **ON DATABASE FOR DROP_TABLE AS**. 
Utilizamos el **RISERROR** para forzar un error que lance el mensaje **"No es posible borrar tablas sin autorizacion"** junto con **ROLLBACK** para que no tome en cuenta el intento de borrar la tabla. Este trigger recibe el nombre de **"trg_impedir_borrar_tablas"** . Como se puede ver en la **evidencia 06-trigger-DISABLE-EvitarDropTable** al utilizar el comando antes mencionado se puede borrar una tabla de ser necesario.


## Usos especificos

**TABLA     |  TABLA AUDITORIA  |      CAMBIO REALIZADO                             | NOMBRE DEL TRIGGER**

**CLIENTE   - AuditoriaCliente:** Se cambió el nombre del cliente.                  **Trigger:** tgr_Cliente_Auditoria
**SOCIO     - AuditoriaSocio:** Se cambiaron el beneficio y el descuento del socio. **Trigger:** tgr_Socio_Auditoria
**EMPLEADO  - AuditoriaEmpleado:** Se cambio el nombre del empleado.                **Trigger:** tgr_Empleado_Auditoria
**PRODUCTO  - AuditoriaProducto:** Se cambiaron el precio y stock del producto      **Trigger:** tgr_Producto_Auditoria
**PROVEEDOR - AuditoriaProveedor:** Se cambio el tiempo de entrega del proveedor    **Trigger:** tgr_Proveedor_Auditoria

**NOMBRE DEL TRIGGER                    | QUE REALIZA**
**Trigger:** trg_impedir_borrar_tablas    Evita que se elimine una tabla midiante DROP_TABLE



## CONCLUSIONES

Los triggers han demostrado ser una herramienta util y eficiente para el manejo, trazado y cuidado de la base de datos. Nos resulta una forma muy flexible y recomendamos su uso. Si bien los resultados han sido considerablemente positivos en torno a la creacion de auditorias y al control de eventos, hemos de recalcar que en casos como las distintas tablas que utilizar como clave primaria datos suceptibles a cambios como por ejemplo "telefono_empleado" se imposibilita cambiar dicha clave debido a que si utilizamos id_empleado para realizar un JOIN, esto modificaria todos los numeros asociados a ese empleado, necesitando una tercera clave exclusivamente para este trigger, sin embargo, estos obstaculos son facilimente sorteables mediante otros metodos, como directamente eliminar el dato desactualizado. Como conclusion queremos recalcar la amplia variedad de situaciones y eventos en los que los trigger nos permiten actuar, permitiendo salvar datos que de otra forma no se podrian conocer, o incluso evitar el uso de ciertos eventos a traves de su uso.


