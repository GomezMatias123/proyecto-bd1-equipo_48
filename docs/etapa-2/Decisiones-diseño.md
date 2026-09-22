## Decisiones de diseño del negocio de Dragabulk.TCG 

## 1. Estrategia de herencia y especialización de clientes.
## Relación de subtipo entre CLIENTE y SOCIO.

-Modelado de la entidad Socio como un subtipo exclusivo y parcial de la entidad Cliente. 
-Una persona debe ser primero un cliente para poder acceder a una categoria de "Socio". Separar las características específicas (como las ventajas comerciales y las tasas de descuento) de los datos de identidad generales (como el documento o las vías de contacto) garantiza que la información personal no se duplique en el sistema. Además, evita tener campos vacíos en el perfil de las personas que realizan transacciones comunes sin pertenecer al programa de beneficios.

## 2. Descomposición de atributos compuestos a simplificación.

-Desglosar los elementos de identidad compuestos por múltiples conceptos jerárquicos (como los nombres y apellidos combinados) en atributos individuales e independientes.
-Para que los datos sean útiles para la base de datos, estos deben almacenarse de forma aislada. Mantener los nombres separados de los apellidos a nivel estructural permite al sistema manipularlos con mayor flexibilidad y precisión.

## 3. Aislamiento de atributos multivalorados para canales de comunicación.

-Extraer los canales de contacto que admiten múltiples valores simultáneos (como las distintas direcciones de correo electrónico y números telefónicos de una misma entidad) fuera del bloque principal de información de dicha entidad.
-Los grandes negocios corporativos o comerciales suelen operar con diferentes canales para sus distintas áreas (ventas, soporte o logística). Almacenar múltiples datos de contacto en una sola celda o como una lista de texto desorganizada impide realizar búsquedas indexadas eficientes y bloquea la automatización de comunicaciones. Al aislarlos, se permite asociar infinitas vías de localización sin alterar la consistencia de los datos base.

## 4. Creación de una instancia de intersección para relaciones múltiples. (Detalle_Compra).

-Interpolar un concepto intermedio para desglosar la relación de muchos a muchos que ocurre cuando una acción comercial involucra múltiples elementos de intercambio al mismo tiempo.
-Interpolar un concepto intermedio para desglosar la relación de muchos a muchos que ocurre cuando una acción comercial involucra múltiples elementos de intercambio al mismo tiempo.ar esta instancia intermedia permite congelar esos valores en el tiempo, asegurando que los registros históricos no sufran alteraciones si en el futuro cambian los costos comerciales vigentes.

## 5. Dirección y control en el flujo de dependencias de las relaciones.

Se definió que las acciones operativas que conectan dos conceptos trasladen siempre el control de identidad desde el lado emisor de cardinalidad uno hacia el lado receptor de cardinalidad muchos, estableciendo una dirección estricta en las dependencias de la arquitectura. Esta regla de diseño se aplica de forma mandatoria durante la fase de transformación del modelo hacia esquemas físicos, obligando a que las entidades receptoras incorporen los identificadores únicos de las entidades emisoras. 

En el contexto operativo de la organización, este mecanismo se activa y valida en tiempo real cada vez que se registra una transacción en el sistema; por ejemplo, al confirmarse una venta, el motor de la base de datos exige la coexistencia y vinculación obligatoria de un comprador registrado, un miembro del personal que gestiona la caja y un método autorizado para liquidar los saldos. Al condicionar la persistencia de los datos a estas llaves de control, el modelo restringe el comportamiento del sistema para impedir la existencia de registros huérfanos, anónimos o "fantasmas", erradicando por completo los problemas de desorganización y pérdida de historial detectados en la gestión manual previa.

## 6. Sincronización lógica de entradas y automatización del control de existencias.

-Se determinó estructurar el flujo de abastecimiento mediante una entidad intermedia denominada Reposicion_Productos, encargada de interceptar de forma dirigida la relación entre los proveedores externos y los artículos del catálogo. 
-Los atributos que describen esta logística son el campo Fecha y la Cantidad de unidades ingresantes, asi asegurando la trazabilidad de los ingresos de stock. La implementación de esta decisión de diseño conceptual resuelve el riesgo de desactualización del inventario en tiempo real; el sistema utiliza este componente como un disparador operativo que incrementa los valores de disponibilidad general del inventario, logrando una sincronización automatizada entre las órdenes de compra entrantes y las existencias físicas disponibles para la venta.

## 7. Modelado de catálogo maestro e integridad de existencias físicas
-Se estableció la entidad Producto como el catálogo maestro para administrar las propiedades comerciales y la cantidad disponible de los artículos. Los atributos como el Tipo, la Edición y el Precio_Actual se unifican aquí para evitar datos duplicados. El sistema controla el campo Stock_Disponible impidiendo que las ventas reduzcan el inventario por debajo de cero, lo que garantiza el control de las existencias reales de cartas sin necesidad de revisiones manuales.
