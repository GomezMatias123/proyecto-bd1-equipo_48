## Explicacion de consulta_avanzada.sql

El codigo se basa en una consulta para filtrar a los clientes/socios que tengan gastos superiores al gasto promedio de todos los clientes.

## Seleccion de datos a mostrar

Se le seleccionan los datos que se desea traer en un SELECT una columna ID Cliente, concatenamos el apellido y nombre de la tabla Cliente en una columna Socio, hacemos un COUNT con los id de compras de cada COMPRA y usamos DISTINCT para evitar contar dos veces una misma compra.
Luego toca relacionar las tablas, en los INNER JOIN se relacionan 4 tablas (CLIENTE, SOCIO, COMPRA y DETALLE_COMPRA) se busca identificar a los clientes que son socios en estos casos de prueba todos lo son, se busca obtener las compras de cada cliente que sea socio y se busca obtener los productos, cantidades y precios de cada comopra.
Por ultimo con el having se busca filtrar para que se descarten los clientes donde su gasto total individual no supere gasto promedio de entre todos los clientes.

## Calculos a realizar

Los calculos realizados se dividen en dos partes, al traer la informacion de cada compra relacionada a un cliente sus gastos totales se realizan multiplicando la cantidad del producto y el precio unitario especifico, para el promedio hacemos uso de AVG() para calcular el promedio los totales de cada compra.

## Relacion y obtencion de datos

Hacemos valer las relaciones entre las tablas involucradas gracias a sus PK y FK, para que los datos vengan ordenados y coherentes a cada cliente.