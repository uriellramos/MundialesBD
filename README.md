# Proyecto Mundiales — Base de datos histórica de la Copa del Mundo

**Avance 1** — Modelado y carga de datos históricos de los Mundiales FIFA en una base de datos relacional.

## Integrantes

- Uriel Ramos

## Descripción del proyecto

Este primer avance construye la base del proyecto: comprender la estructura de los
datos históricos de los Mundiales de fútbol y diseñar una base de datos relacional
que los almacene correctamente. En esta etapa no se evalúan dashboards, Machine
Learning ni desarrollo web — el enfoque es la organización de los datos y la
automatización de la carga.

La carga de datos se hizo completa por **XAMPP / phpMyAdmin** (importación de CSV +
scripts SQL), sin scripts de Python, como alcance acordado para este avance.

## Tecnologías utilizadas

- **XAMPP** (Apache + MariaDB + phpMyAdmin) como entorno local de base de datos
- **MySQL / MariaDB** como motor de base de datos relacional (InnoDB, con llaves
  foráneas e integridad referencial)
- **CSV** como formato de los datos de origen (dataset histórico de Mundiales FIFA)
- **Excel** para la revisión inicial de los datos

## Estructura del repositorio

```
├── README.md                          # este archivo
├── CAMBIOS_LIMPIEZA.md                # bitácora completa del proceso (limpieza, diseño, bugs y correcciones)
├── csv_dataset/                       # CSV originales del dataset (sin modificar)
├── csv_limpios/                       # los 10 CSV que alimentan las 15 tablas, ya limpios
├── 01_create_tablas.sql               # crea la base de datos y las 15 tablas
├── 02_staging_tablas.sql              # crea 10 tablas temporales (una por CSV limpio)
├── 00_limpiar_encabezados_staging.sql # quita filas de encabezado mal importadas en las tablas staging
└── 03_poblar_tablas.sql               # puebla las 15 tablas finales desde las tablas staging
```

## Modelo de datos

15 tablas, con clave primaria, tipos de datos adecuados, relaciones por llave foránea
e integridad referencial: `award`, `award_winner`, `city`, `confederation`, `country`,
`federation`, `goal`, `matches`, `player`, `player_appearance`, `position`, `region`,
`stadium`, `team`, `tournament`.

De los 27 CSV originales del dataset, solo 10 alimentan estas 15 tablas. Cuatro
entidades (`city`, `country`, `federation`, `region`) no vienen como archivo aparte —
se extrajeron de columnas repetidas en otros CSV (ver el detalle completo del mapeo
tabla → CSV de origen y las decisiones de diseño en `CAMBIOS_LIMPIEZA.md`).

## Instrucciones para ejecutar la base de datos

1. Instalar/abrir **XAMPP** e iniciar los módulos **Apache** y **MySQL**.
2. Abrir phpMyAdmin en `http://localhost/phpmyadmin`.
3. Ir a la pestaña **SQL**, pegar el contenido completo de `01_create_tablas.sql` y
   ejecutarlo. Esto crea la base de datos `mundiales_db` y las 15 tablas finales,
   vacías.

## Instrucciones para ejecutar los scripts de carga

1. Con `mundiales_db` seleccionada, ejecutar `02_staging_tablas.sql` en la pestaña
   SQL — crea 10 tablas temporales (`stg_*`), una por cada CSV de `csv_limpios/`.
2. Ir a la pestaña **Importar** y, para cada uno de los 10 CSV de `csv_limpios/`,
   importarlo en su tabla `stg_<nombre_del_csv>` correspondiente. Configuración:
   formato CSV, columnas separadas por `,`, encerradas por `"`, y **marcar la casilla
   "La primera línea del archivo contiene los nombres de las columnas"**.
3. Ejecutar `00_limpiar_encabezados_staging.sql` — por seguridad, quita cualquier
   fila de encabezado que se haya colado como dato en alguna tabla staging.
4. Ejecutar `03_poblar_tablas.sql` — puebla las 15 tablas finales desde las tablas
   staging, respetando el orden de dependencias de llave foránea. Al final muestra
   un conteo de filas por tabla para verificar la carga. Este script se puede volver
   a correr las veces que haga falta sin generar errores de llave duplicada.

### Conteo esperado tras la carga

| Tabla | Filas | | Tabla | Filas |
|---|---|---|---|---|
| region | 11 | | player | 10.401 |
| confederation | 6 | | award | 8 |
| position | 21 | | tournament | 30 |
| country | 22 | | matches | 1.248 |
| city | 202 | | goal | 3.637 |
| federation | 87 | | player_appearance | 27.432 |
| team | 88 | | award_winner | 200 |
| stadium | 240 | | | |

## Documentación adicional

`CAMBIOS_LIMPIEZA.md` trae el registro completo del proceso: qué se limpió y por qué,
el mapeo detallado de cada tabla a su CSV de origen, las decisiones de diseño del
modelo, y los errores encontrados durante la carga junto con su corrección.
