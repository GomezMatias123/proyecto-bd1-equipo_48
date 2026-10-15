## Explicacion de comprobante_venta

El codigo se divide principalmente en tres partes, la seleccion de datos a mostrar, los calculos a realizar y por ultimo la relacion y de donde obtenemos los datos.

## Seleccion de datos a mostrar

Un ejemplo de como funciona esta seccion se da en COMPRA.ID_compra AS [Nro Comprobante].

Donde COMPRA es la tabla de la cual se obtiene ID_compra, y Nro Comprobante es la forma en la que se llamara a la columna

Es similar el caso de   CONCAT(CLIENTE.apellido, ', ', CLIENTE.nombre) AS [Comprador / Cliente], donde ademas se realiza una concatenacion del nombre y apellido del cliente, obteniendo es resultado "Apellido, Nombre", y  FORMAT(GETDATE(), 'dd/MM/yyyy') AS [Fecha Emisión] en el cual en lugar de obtener el dato a traves de tablas, se obtiene directamente por medio de las herramientas del  lenguaje.

## Calculos a realizar

Seguido de lo anterior, calculamos un subtotal por cada fila, utilizando la cantidad * precio unitario para lograrlo

Utilizamos Sum() para sumar cada subtotal, over() para realiza el calculo en un conjunto especifico, con partition by dividiendo las filas segun ID_compra

## Relacion y obtencion de datos

Establecemos compra como tabla de partida a traves from, y relacionamos las tablas si se cumple la condicion estipulada por ejemplo  COMPRA.ID_compra = DETALLE_COMPRA.ID_compra
