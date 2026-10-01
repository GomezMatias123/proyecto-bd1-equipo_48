INSERT INTO CLIENTE (ID_cliente, dni, nombre, apellido)
    VALUES(1, 45020845, 'MAGNO', 'ISLER'),
    (2, 23045689, 'MAURICIO', 'TADIO'),
    (3, 56047839, 'ALBERTO', 'TADEO'),
    (4, 67839402, 'GERONIMO', 'SILVIO'),
    (5, 12378094, 'SALOMON', 'MARTIRIO'),
    (6, 34253455, 'LUCAS', 'GUILERA'),
    (7, 32657849, 'JULIAN', 'LOVISOLO'),
    (8, 24568309, 'MARIANO', 'AGUILAR');

INSERT INTO EMPLEADO (ID_empleado, apellido, nombre, dni)
    VALUES(1, 'RAMBAUDI', 'LUCRECIA', 33675983),
    (2, 'TROIA', 'FACUNDO', 32564798),
    (3, 'QUIÑONES', 'MARTINA', 34782903),
    (4, 'MARTINEZ', 'MARTIN', 46987392),
    (5, 'QUITO', 'ESTEBAN', 34526780),
    (6, 'GOMEZ', 'LAUTARO', 53627831),
    (7, 'RIOS', 'ENZO', 54634261),
    (8, 'FRANCO', 'GERONIMO', 23451436);

INSERT INTO PROVEEDOR (ID_proveedor, nombre, tiempos_de_entrega, ID_empleado)
    VALUES(1, 'Deevir', 5, 1),
    (2, 'Pokev TCG', 7, 2),
    (3, 'Arcadia TCG', 3, 3),
    (4, 'Pokestage', 10, 4),
    (5, 'Pokeargentum', 2, 5),
    (6, 'Sunset TCG', 8, 6),
    (7, 'Tateti', 4, 7),
    (8, 'Inivictvs', 6, 8);

-- Casos de prueba para PRODUCTO
INSERT INTO PRODUCTO (ID_producto, Edicion, Precio_actual, Stock_disponible, Tipo)
    VALUES(1, 'Pitch Black', 450000, 3, 'Booster Box'),
    (2, 'Pitch Black', 17000, 50, 'Sobres'),
    (3, '30th Anniversary', 280000, 10, 'Elite Trainer Box'),
    (4, '30th Anniversary', 23000, 20, 'Sobres'),
    (5, 'Chaos Rissing', 210000, 5, 'Elite Trainer Box'),
    (6, 'Chaos Rissing', 17000, 50, 'Sobres'),
    (7, 'Chaoss Rissing', 450000, 5, 'Booster Box'),
    (8, 'Perfect Order', 16000, 75, 'Sobres');

-- Casos de prueba para METODODEPAGO
INSERT INTO METODODEPAGO (ID_metodo_pago, nombre)
    VALUES(1, 'Efectivo'),
    (2, 'Tarjeta de Crédito'),
    (3, 'Tarjeta de Débito'),
    (4, 'Transferencia Bancaria'),
    (5, 'MercadoPago'),
    (6, 'PayPal'),
    (7, 'Criptomonedas'),
    (8, 'Cheque');

-- Casos de prueba para COMPRA
INSERT INTO COMPRA (ID_compra, ID_empleado, ID_metodo_pago, ID_cliente)
    VALUES(1, 1, 1, 1),
    (2, 2, 2, 2),
    (3, 3, 3, 3),
    (4, 4, 4, 4),
    (5, 5, 5, 1),
    (6, 6, 6, 2),
    (7, 7, 7, 3),
    (8, 8, 8, 4);

-- Casos de prueba para DETALLE_COMPRA
-- Casos de prueba para DETALLE_COMPRA con precios unitarios correctos
INSERT INTO DETALLE_COMPRA (Precio_unitario, Cantidad, ID_compra, ID_producto)
    VALUES(450000, 1, 1, 1), 
    (17000, 3, 2, 2),  
    (280000, 2, 3, 3), 
    (23000, 4, 4, 4),  
    (210000, 1, 5, 5),
    (17000, 6, 6, 6),  
    (450000, 1, 7, 7),
    (16000, 5, 8, 8);  

-- Casos de prueba para SOCIO
INSERT INTO SOCIO (Descuento, Beneficio, ID_cliente)
VALUES
(10, 'Descuento en compras', 1),
(15, 'Envío gratuito', 2),
(20, 'Acceso a eventos exclusivos', 3),
(5, 'Puntos de fidelidad', 4),
(25, 'Descuento en productos seleccionados', 5),
(30, 'Acceso anticipado a promociones', 6),
(12, 'Regalos exclusivos', 7),
(18, 'Descuento en envíos', 8);

-- Casos de prueba para REPOSICION_PRODUCTOS
INSERT INTO REPOSICION_PRODUCTOS (Fecha, Cantidad, ID_reposicion, ID_proveedor, ID_producto)
VALUES
('2023-10-01', 100, 1, 1, 1),
('2023-10-02', 50, 2, 2, 2),
('2023-10-03', 200, 3, 3, 3),
('2023-10-04', 150, 4, 4, 4),
('2023-10-05', 120, 5, 5, 5),
('2023-10-06', 80, 6, 6, 6),
('2023-10-07', 60, 7, 7, 7),
('2023-10-08', 90, 8, 8, 8);

-- Casos de prueba para PROVEEDOR_TELEFONO
INSERT INTO PROVEEDOR_TELEFONO (Telefono, ID_proveedor)
VALUES
('123456789', 1),
('987654321', 2),
('456123789', 3),
('789456123', 4),
('321654987', 5),
('654987321', 6),
('147258369', 7),
('369258147', 8);

-- Casos de prueba para PROVEEDOR_EMAIL
INSERT INTO PROVEEDOR_EMAIL (Email, ID_proveedor)
VALUES
('contacto@deevir.com', 1),
('info@pokevtcg.com', 2),
('ventas@arcadiatcg.com', 3),
('soporte@pokestage.com', 4),
('contacto@pokeargentum.com', 5),
('info@sunsettcg.com', 6),
('ventas@tateti.com', 7),
('soporte@inivictvs.com', 8);

-- Casos de prueba para telefono_empleado
INSERT INTO telefono_empleado (telefono, ID_empleado)
VALUES
('3794482917', 1),
('3794593826', 2),
('3794174839', 3),
('3795265748', 4),
('3624839264', 5),
('3794927415', 6),
('3795316582', 7),
('3795748291', 8);

-- Casos de prueba para Telefono_cliente
INSERT INTO Telefono_cliente (Telefono, ID_cliente)
VALUES
('911529374', 1),
('3794681493', 2),
('3777394857', 3),
('3795716482', 4),
('3624845293', 5),
('3794672184', 6),
('3794918273', 7),
('911384756', 8);

-- Casos de prueba para Email_cliente
INSERT INTO Email_cliente (email, ID_cliente)
VALUES
('juan.perez@email.com', 1),
('ana.gomez@email.com', 2),
('carlos.lopez@email.com', 3),
('maria.rodriguez@email.com', 4),
('salomon.martirio@email.com', 5),
('lucas.guilera@email.com', 6),
('julian.lovisolo@email.com', 7),
('mariano.aguilar@email.com', 8);