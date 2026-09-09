# Registro del proceso — Avance 1

## Paso 1: Limpieza de datos

Archivos revisados (los 10 que alimentan las 15 tablas requeridas): `awards.csv`,
`award_winners.csv`, `confederations.csv`, `teams.csv`, `stadiums.csv`, `players.csv`,
`player_appearances.csv`, `matches.csv`, `goals.csv`, `tournaments.csv`.

## Verificaciones hechas sobre los 10 archivos
- Formato de fecha: ya venía unificado en ISO `AAAA-MM-DD` en todos los archivos que
  tienen columnas de fecha (`match_date`, `birth_date`, `start_date`, `end_date`). No fue
  necesario reformatear nada ahí.
- Filas mal formadas (número de columnas distinto al encabezado): 0 en los 10 archivos.
- IDs duplicados en la columna que actúa como identificador de cada archivo
  (`award_id`, `confederation_id`, `team_id`, `stadium_id`, `player_id`, `match_id`,
  `goal_id`, `tournament_id`, `key_id`): 0 duplicados.

## Cambios aplicados
**`players.csv`**
- Columna `birth_date`: 77 filas tenían el texto `"not available"` en vez de una fecha.
  Se dejaron en blanco (vacío) para que al importar en MySQL como columna `DATE` queden
  como `NULL` en vez de romper la importación o convertirse en `0000-00-00`. Sumado a
  1 fila que ya venía vacía, el archivo limpio tiene **78 registros con fecha de
  nacimiento desconocida** (jugadores sin ese dato documentado).
- Columna `player_wikipedia_link`: 14 filas tenían `"not available"`; se dejaron en
  blanco por consistencia (no es un campo requerido por la rúbrica).

**Los otros 9 archivos no necesitaron cambios** — ya estaban limpios en fechas, IDs y
estructura.

## Nota sobre `given_name = "Na"`
Al revisar coincidencias de texto tipo "na"/"n/a" para descartar basura, aparece un
jugador real: **Na Sang-ho** (Corea del Sur, `player_id P-10357`), cuyo nombre de pila
es literalmente "Na". No se tocó — no es un dato corrupto.

## Fuera de alcance
Los otros 17 CSV de la carpeta (`bookings`, `substitutions`, `squads`, `managers`,
`referees`, `group_standings`, `groups`, `host_countries`, `qualified_teams`,
`team_appearances`, `tournament_stages`, `tournament_standings`,
`manager_appearances`, `manager_appointments`, `referee_appearances`,
`referee_appointments`, `penalty_kicks`) no corresponden a ninguna de las 15 tablas
pedidas en el Avance 1, así que no se revisaron en esta pasada. Si luego se necesitan
para otro avance, se pueden limpiar con el mismo criterio.

## Al importar en phpMyAdmin
- Guarda/usa estos CSV en UTF-8 (ya lo están) para que nombres como `José`, `Ángel` o
  `Calderón` no se dañen.
- En el asistente de importación, para la columna `birth_date` de `players`, asegúrate
  de que las celdas vacías se importen como `NULL` y no como cadena vacía `''` (en el
  tipo de columna `DATE`, phpMyAdmin normalmente lo maneja bien si el CSV trae la celda
  realmente vacía, que es el caso aquí).

## Paso 2: Creación de las 15 tablas (DDL)

Script: `01_create_tablas.sql` — pensado para pegarse directo en la pestaña **SQL** de
phpMyAdmin (XAMPP). Crea la base `mundiales_db` y las 15 tablas exigidas, en el orden
que respeta las llaves foráneas.

**Motor:** InnoDB (necesario para que MySQL aplique las FOREIGN KEY; MyISAM las ignora
silenciosamente, así que no sirve para este avance).

**Decisión de diseño — llaves primarias:**
- Las tablas que ya traían un identificador natural en el CSV original lo conservan
  como PK: `award_id`, `confederation_id`, `team_id`, `stadium_id`, `player_id`,
  `match_id`, `goal_id`, `tournament_id` (todos `VARCHAR`, ej. `T-03`, `WC-1930`).
- Las tablas que **no** vienen como archivo aparte y hay que extraerlas de columnas
  repetidas en otros CSV (`region`, `country`, `city`, `federation`) usan un
  `INT AUTO_INCREMENT` como PK, porque no había un código natural único en el dataset
  original para esas entidades.
- `position` usa `position_code` (ej. `GK`, `DF`, `MF`, `FW`) como PK — sí es un código
  natural corto y único en el CSV.
- `player_appearance` y `award_winner` usan `AUTO_INCREMENT` (equivalen al `key_id`
  que traía el CSV original), porque son tablas de relación sin un identificador de
  negocio propio.

**Mapeo tabla → CSV de origen** (de dónde sale cada tabla):

| Tabla | CSV de origen | Nota |
|---|---|---|
| `tournament` | `tournaments.csv` | |
| `team` | `teams.csv` | trae `federation_name`/`region_name` mezclados |
| `confederation` | `confederations.csv` | |
| `federation` | *(extraída)* | valores únicos de `federation_name` en `teams.csv` |
| `region` | *(extraída)* | valores únicos de `region_name` en `teams.csv` |
| `stadium` | `stadiums.csv` | trae `city_name`/`country_name` mezclados |
| `city` | *(extraída)* | de `city_name`+`country_name` en `stadiums.csv` |
| `country` | *(extraída)* | de `country_name` en `stadiums.csv`/`matches.csv`/`tournaments.csv` |
| `player` | `players.csv` | `birth_date` ya limpio (ver Paso 1) |
| `player_appearance` | `player_appearances.csv` | trae `position_name`/`position_code` mezclados |
| `position` | *(extraída)* | de `position_name`/`position_code` en `player_appearances.csv` |
| `matches` | `matches.csv` | |
| `goal` | `goals.csv` | |
| `award` | `awards.csv` | |
| `award_winner` | `award_winners.csv` | |

**Orden de creación / carga (por dependencias de FK):**
1. `region`, `confederation`, `position` — sin dependencias
2. `country`
3. `city` (→ country), `federation`
4. `team` (→ federation, region, confederation)
5. `stadium` (→ city)
6. `player`, `award` — sin dependencias
7. `tournament` (→ country, team)
8. `matches` (→ tournament, stadium, team)
9. `goal`, `player_appearance` (→ matches, team, player, position)
10. `award_winner` (→ award, tournament, player, team)

**Nota sobre palabras reservadas:** ninguno de los 15 nombres de tabla es palabra
reservada en MySQL/MariaDB (verificado contra las listas oficiales de ambos motores).
Sin embargo, al correr el script en phpMyAdmin (MariaDB, como trae XAMPP) apareció un
error de sintaxis puntual: `REFERENCES position(position_code)` choca con la sintaxis
especial de la función `POSITION(substr IN str)` del estándar SQL, aunque `position` no
esté formalmente reservada. La corrección fue escribirla entre backticks donde se usa
como nombre de tabla — `` `position` `` — tanto en su `CREATE TABLE`/`DROP TABLE` como
en la referencia desde `player_appearance`. El resto de tablas no tuvo este problema.

**Si ya habías corrido el script antes de esta corrección:** no pasa nada, el script
completo empieza con `DROP TABLE IF EXISTS` para cada tabla, así que se puede volver a
pegar entero en la pestaña SQL y va a recrear todo limpio, sin duplicar ni dejar tablas
a medias.

### Error #1451 al hacer DROP TABLE region ("Cannot delete or update a parent row")

Este error salió al ejecutar solo el pedazo de `region` (el `DROP TABLE IF EXISTS
region;` y su comentario), sin el resto del script. Lo probé de punta a punta en un
MariaDB local (misma versión que trae XAMPP): corrí el script **completo** dos veces
seguidas sin errores y crea las 15 tablas correctamente ambas veces — el script en sí
está bien.

La causa real: el script pone `SET FOREIGN_KEY_CHECKS = 0;` una sola vez, cerca del
inicio, para poder borrar tablas "padre" (como `region`) aunque otras tablas ya
apuntaran a ellas con una FK (como `team.region_id`). Esa instrucción solo protege lo
que viene *después de ella* en la misma ejecución. Si en phpMyAdmin se pega o ejecuta
únicamente el bloque de `region` — sin haber corrido antes, en la misma sesión, el
`SET FOREIGN_KEY_CHECKS = 0;` — el chequeo de llaves foráneas sigue activo y MariaDB no
deja borrar `region` porque `team` ya la referencia.

**Solución:** pegar y ejecutar el script **completo**, de corrido, desde
`CREATE DATABASE IF NOT EXISTS mundiales_db` hasta el `SET FOREIGN_KEY_CHECKS = 1;`
final — no por partes. La forma más segura de garantizar esto en phpMyAdmin es usar la
pestaña **Importar** y subir el archivo `01_create_tablas.sql` directamente, en vez de
copiar y pegar texto (así no hay riesgo de que el copy-paste se quede corto por
accidente).

**Si la base quedó en un estado intermedio/raro** por los intentos anteriores, lo más
rápido es empezar de cero:
```sql
DROP DATABASE IF EXISTS mundiales_db;
```
y luego correr el script completo una sola vez.

## Paso 3: Carga de datos — tablas staging + importación (sin Python)

Antes de entregarte esto lo probé de punta a punta contra un MariaDB local (misma
versión que XAMPP), cargando los 10 CSV reales y poblando las 15 tablas. En el proceso
encontré y corregí **dos bugs reales**, documentados aquí para que quede el rastro.

### Bug encontrado #1 — los CSV "limpios" tenían saltos de línea de Windows (CRLF)

Los CSV que te entregué en el Paso 1 quedaron con saltos de línea `\r\n` (Windows) en
vez de `\n` (Unix, como venían los originales) — un efecto secundario de la
herramienta con la que los regeneré, no algo que hicieras tú. Eso rompe la carga
cuando un campo va entre comillas y es el último de la fila (por ejemplo,
`city_wikipedia_link` en `stadiums.csv`, que trae comas en enlaces como
"Córdoba, Argentina"): MySQL/MariaDB pierde la sincronía y empieza a fusionar filas.
En la prueba, esto hizo que `stadiums.csv` cargara solo 5 filas de 240, y
`players.csv` solo 9.488 de 10.401 — silencioso, sin marcar error duro.

**Ya está corregido**: los 10 CSV que van en este paquete son una nueva versión con
saltos de línea `\n` (igual que el original), verificada fila por fila. Si ya habías
importado los CSV del Paso 1/2 anteriores y te dieron conteos de filas raros o bajos
en phpMyAdmin, ese era el motivo — reimporta con esta versión.

### Bug encontrado #2 — ciudades con dos enlaces de Wikipedia distintos

Algunas ciudades tienen más de un estadio, y el dataset original no siempre trae el
mismo `city_wikipedia_link` en cada fila (ej. Foxborough, EE.UU.: un estadio apunta al
wiki del estadio y el otro al wiki de la ciudad). Eso rompía la carga de `city` por
duplicado de la llave única (ciudad+país). Se corrigió agrupando por ciudad+país y
tomando un valor determinista con `MIN()` — no afecta ningún dato requerido por la
rúbrica, `city_wikipedia_link` es solo referencia.

### Cómo importar

1. Corre `02_staging_tablas.sql` en la pestaña **SQL** de phpMyAdmin (con
   `mundiales_db` seleccionada) — crea 10 tablas `stg_*`, una por CSV, con todas las
   columnas como texto.
2. Ve a la pestaña **Importar**, y para cada uno de los 10 CSV de esta carpeta:
   - Selecciona el archivo.
   - Formato: **CSV**.
   - En "Tabla destino" (o el desplegable de la parte superior de phpMyAdmin) elige la
     tabla `stg_<nombre_del_csv>` correspondiente (ej. `stadiums.csv` → `stg_stadiums`).
   - Columnas separadas con: `,` — Columnas encerradas con: `"` — Columnas escapadas
     con: *(vacío)* — Líneas terminadas con: `auto`.
   - Marca "La primera línea del archivo contiene los nombres de las columnas".
3. Corre `03_poblar_tablas.sql` en la pestaña SQL — puebla las 15 tablas finales desde
   las tablas staging, en el orden correcto de dependencias, y al final muestra un
   conteo de filas por tabla para que verifiques.

### Conteos esperados (verificados en la prueba)

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

Nota curiosa de los datos (no es un error): `country` incluye entradas históricas como
"West Germany" y "Korea, Japan" (sede compartida del Mundial 2002) — son valores reales
del dataset, no duplicados que haya que limpiar.

### Error #1452 al insertar en `matches` ("Cannot add or update a child row")

Reproduje este error exacto: pasa cuando la tabla staging `stg_teams` queda vacía (0
filas) — por ejemplo, si `teams.csv` no se importó, se importó en la tabla staging
equivocada, o un intento anterior la dejó en 0. Como el paso 7 (`team`) hace un
`INSERT ... SELECT ... FROM stg_teams`, si `stg_teams` está vacía ese `INSERT` no marca
ningún error — simplemente inserta 0 filas — y el problema solo se nota 5 pasos
después, cuando `matches` intenta apuntar a un `team_id` que nunca se creó.

**El script ya se corrigió para que esto sea mucho más fácil de detectar y de
recuperar:**
- Al principio de `03_poblar_tablas.sql` ahora se vacían primero las 15 tablas finales
  (con `TRUNCATE`, respetando el orden de llaves foráneas), así el script se puede
  volver a correr las veces que haga falta sin errores de llave duplicada — antes, si
  ya tenías datos parciales de un intento anterior, un segundo intento fallaba por
  duplicados antes de siquiera llegar al problema real.
- Justo después, el script muestra un **conteo de las 10 tablas staging** — si alguna
  da 0 (o muy distinto de lo esperado), ahí está el problema, antes de que truene más
  adelante en un `INSERT` que no tiene nada que ver a simple vista.

**Si te vuelve a salir este error:** corre el script actualizado, revisa el primer
resultado (conteo de `stg_*`) y compáralo con la tabla de conteos esperados de arriba.
La tabla que dé 0 (o un número raro) es la que hay que reimportar desde la pestaña
Importar de phpMyAdmin — asegúrate de elegir la tabla `stg_<nombre>` correcta en el
desplegable antes de importar cada CSV.

**Causa real encontrada en este caso concreto:** al importar `teams.csv`, la primera
línea (el encabezado `key_id,team_id,team_name,...`) se coló como si fuera una fila de
datos más (`stg_teams` quedó en 89 en vez de 88). Eso no da error al poblar `team`
(inserta 88 filas válidas igual, la fila del encabezado simplemente no calza con nada
más adelante), pero deja el conteo raro. Se identificó con:
```sql
SELECT * FROM stg_teams WHERE team_id NOT IN ('T-01','T-02',...,'T-88');
```
y se corrigió con `DELETE FROM stg_teams WHERE team_id = 'team_id';`. Para que no
vuelva a pasar: en el asistente de Importar de phpMyAdmin, revisa que la casilla **"La
primera línea del archivo contiene los nombres de las columnas"** quede marcada antes
de subir cada CSV.

### Error #1701 al hacer TRUNCATE TABLE ("Cannot truncate a table referenced in a foreign key constraint")

Salió en el `Paso 0a` del script (el que deja las 15 tablas finales vacías antes de
repoblar). La causa: en MariaDB, `TRUNCATE TABLE` puede seguir bloqueado por una llave
foránea de otra tabla **aunque `SET FOREIGN_KEY_CHECKS = 0` esté activo** — a diferencia
de `DELETE`, que sí respeta ese chequeo desactivado en cualquier versión. Es un
comportamiento real de MariaDB (documentado, no un capricho de esta base de datos en
particular), y probablemente depende de la versión exacta.

**Corrección:** el `Paso 0a` de `03_poblar_tablas.sql` ahora usa `DELETE FROM` en vez de
`TRUNCATE TABLE` para las 15 tablas finales, y agrega un `ALTER TABLE ... AUTO_INCREMENT
= 1` después para las tablas con llave surrogate (`region`, `country`, `city`,
`federation`, `player_appearance`, `award_winner`), así cada corrida deja los mismos
IDs. Ya lo probé corriendo el script completo dos veces seguidas sin errores.

### El encabezado se coló en las 10 tablas staging, no solo en `stg_teams`

Después de corregir `stg_teams`, el mismo error #1452 volvió a salir en `matches` — pero
esta vez con `team` ya en 88 filas correctas. La causa: **las 10 tablas staging**
tenían el mismo problema que `stg_teams` (la fila de encabezado importada como dato),
no solo esa una. En este caso concreto era `stg_matches` la que tenía
`home_team_id = 'home_team_id'` colado, y como el `INSERT ... SELECT` de `matches` es
una sola operación por lotes, esa única fila mala hace fallar el `INSERT` completo
aunque las otras 1.248 filas sean válidas.

**Script nuevo: `00_limpiar_encabezados_staging.sql`** — borra la fila de encabezado
colada de las 10 tablas staging de una sola vez (todas comparten `key_id` como primera
columna, así que el filtro `WHERE key_id = 'key_id'` funciona igual en las 10) y al
final muestra el conteo de las 10 tablas para verificar contra la lista de conteos
esperados. Lo probé simulando el encabezado colado en las 10 tablas a la vez, y deja
todo en el número correcto.

**Orden recomendado de aquí en adelante**, cada vez que se reimporte algo en las tablas
staging: `00_limpiar_encabezados_staging.sql` primero (por si se coló algún
encabezado), después `03_poblar_tablas.sql`.

**Para que no se repita:** en el asistente de Importar de phpMyAdmin, la casilla es
**"La primera línea del archivo contiene los nombres de las columnas"** — revisarla
antes de subir cada uno de los 10 CSV.

**Siguiente paso pendiente:** importar los 10 CSV limpios como tablas de staging desde
phpMyAdmin y poblar estas 15 tablas con `INSERT INTO ... SELECT DISTINCT ...` en el
mismo orden de arriba (esto reemplaza la carga que haría un script de Python).
