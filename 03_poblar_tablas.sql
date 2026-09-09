-- =====================================================================
-- AVANCE 1 - Proyecto Mundiales
-- Script: poblar las 15 tablas finales desde las tablas staging
--         (reemplaza lo que haria un script de Python con pandas)
--
-- Requisito previo: haber corrido 02_staging_tablas.sql y haber
-- importado los 10 CSV limpios (carpeta csv_limpios) en sus tablas
-- stg_* correspondientes, desde la pestana Importar de phpMyAdmin.
--
-- Orden de poblado: respeta las dependencias de llave foranea
-- (el mismo orden en que se crearon las tablas en 01_create_tablas.sql)
-- =====================================================================

USE mundiales_db;

-- ---------------------------------------------------------------------
-- Paso 0a: dejar las 15 tablas finales vacias antes de repoblar. Asi
-- este script se puede correr las veces que haga falta sin errores de
-- llave duplicada (no toca las tablas staging stg_*, esas quedan igual).
-- ---------------------------------------------------------------------
-- Nota: se usa DELETE FROM en vez de TRUNCATE TABLE porque en MariaDB
-- TRUNCATE puede seguir bloqueado por una llave foranea de otra tabla
-- incluso con foreign_key_checks=0 (comportamiento distinto a DELETE,
-- que si respeta el chequeo desactivado).
SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM award_winner;
DELETE FROM player_appearance;
DELETE FROM goal;
DELETE FROM matches;
DELETE FROM tournament;
DELETE FROM award;
DELETE FROM player;
DELETE FROM stadium;
DELETE FROM team;
DELETE FROM federation;
DELETE FROM city;
DELETE FROM country;
DELETE FROM `position`;
DELETE FROM confederation;
DELETE FROM region;

-- Reiniciar los contadores AUTO_INCREMENT de las tablas con llave
-- surrogate, para que cada corrida quede con los mismos IDs (mas facil
-- de revisar/comparar).
ALTER TABLE region AUTO_INCREMENT = 1;
ALTER TABLE country AUTO_INCREMENT = 1;
ALTER TABLE city AUTO_INCREMENT = 1;
ALTER TABLE federation AUTO_INCREMENT = 1;
ALTER TABLE player_appearance AUTO_INCREMENT = 1;
ALTER TABLE award_winner AUTO_INCREMENT = 1;

SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- Paso 0b: verificacion de las tablas staging ANTES de poblar. Si alguna
-- de estas da 0 (o un numero muy distinto al esperado) es que falto
-- importar ese CSV en su tabla stg_* -- soluciona eso primero, si no,
-- los INSERT de abajo van a insertar 0 filas ahi y vas a ver errores de
-- llave foranea mas adelante (ej. en matches) sin saber por que.
-- Esperado: awards=8, award_winners=200, confederations=6, teams=88,
-- stadiums=240, players=10401, player_appearances=27432, matches=1248,
-- goals=3637, tournaments=30
-- ---------------------------------------------------------------------
SELECT 'stg_awards' AS tabla_staging, COUNT(*) AS filas FROM stg_awards
UNION ALL SELECT 'stg_award_winners', COUNT(*) FROM stg_award_winners
UNION ALL SELECT 'stg_confederations', COUNT(*) FROM stg_confederations
UNION ALL SELECT 'stg_teams', COUNT(*) FROM stg_teams
UNION ALL SELECT 'stg_stadiums', COUNT(*) FROM stg_stadiums
UNION ALL SELECT 'stg_players', COUNT(*) FROM stg_players
UNION ALL SELECT 'stg_player_appearances', COUNT(*) FROM stg_player_appearances
UNION ALL SELECT 'stg_matches', COUNT(*) FROM stg_matches
UNION ALL SELECT 'stg_goals', COUNT(*) FROM stg_goals
UNION ALL SELECT 'stg_tournaments', COUNT(*) FROM stg_tournaments;

-- ---------------------------------------------------------------------
-- 1) region  <- teams.csv (region_name)
-- ---------------------------------------------------------------------
INSERT INTO region (region_name)
SELECT DISTINCT region_name
FROM stg_teams
WHERE region_name IS NOT NULL AND region_name <> '';

-- ---------------------------------------------------------------------
-- 2) confederation  <- confederations.csv
-- ---------------------------------------------------------------------
INSERT INTO confederation (confederation_id, confederation_name, confederation_code, confederation_wikipedia_link)
SELECT DISTINCT confederation_id, confederation_name, confederation_code, NULLIF(confederation_wikipedia_link, '')
FROM stg_confederations;

-- ---------------------------------------------------------------------
-- 3) position  <- player_appearances.csv (position_code / position_name)
-- ---------------------------------------------------------------------
INSERT INTO `position` (position_code, position_name)
SELECT DISTINCT position_code, position_name
FROM stg_player_appearances
WHERE position_code IS NOT NULL AND position_code <> '';

-- ---------------------------------------------------------------------
-- 4) country  <- valores unicos de country_name en stadiums / matches
--    y de host_country en tournaments
-- ---------------------------------------------------------------------
INSERT INTO country (country_name)
SELECT DISTINCT country_name FROM (
    SELECT country_name FROM stg_stadiums    WHERE country_name IS NOT NULL AND country_name <> ''
    UNION
    SELECT country_name FROM stg_matches     WHERE country_name IS NOT NULL AND country_name <> ''
    UNION
    SELECT host_country AS country_name FROM stg_tournaments WHERE host_country IS NOT NULL AND host_country <> ''
) AS todos_los_paises;

-- ---------------------------------------------------------------------
-- 5) city  <- stadiums.csv (city_name + country_name)
-- ---------------------------------------------------------------------
-- Nota: el dataset trae, para algunas ciudades, mas de un valor distinto de
-- city_wikipedia_link segun el estadio (ej. Foxborough, EE.UU. tiene dos
-- estadios y cada fila trae un link distinto). Se agrupa por ciudad+pais y
-- se toma un valor determinista con MIN() para no duplicar la ciudad.
INSERT INTO city (city_name, country_id, city_wikipedia_link)
SELECT s.city_name, co.country_id, MIN(NULLIF(s.city_wikipedia_link, ''))
FROM stg_stadiums s
JOIN country co ON co.country_name = s.country_name
WHERE s.city_name IS NOT NULL AND s.city_name <> ''
GROUP BY s.city_name, co.country_id;

-- ---------------------------------------------------------------------
-- 6) federation  <- teams.csv (federation_name)
-- ---------------------------------------------------------------------
INSERT INTO federation (federation_name, federation_wikipedia_link)
SELECT DISTINCT federation_name, NULLIF(federation_wikipedia_link, '')
FROM stg_teams
WHERE federation_name IS NOT NULL AND federation_name <> '';

-- ---------------------------------------------------------------------
-- 7) team  <- teams.csv
-- ---------------------------------------------------------------------
INSERT INTO team (team_id, team_name, team_code, mens_team, womens_team, federation_id, region_id, confederation_id)
SELECT DISTINCT
    t.team_id, t.team_name, t.team_code,
    CAST(t.mens_team AS UNSIGNED), CAST(t.womens_team AS UNSIGNED),
    f.federation_id, r.region_id, t.confederation_id
FROM stg_teams t
LEFT JOIN federation f ON f.federation_name = t.federation_name
LEFT JOIN region r      ON r.region_name = t.region_name;

-- ---------------------------------------------------------------------
-- 8) stadium  <- stadiums.csv
-- ---------------------------------------------------------------------
INSERT INTO stadium (stadium_id, stadium_name, city_id, stadium_capacity, stadium_wikipedia_link)
SELECT DISTINCT
    s.stadium_id, s.stadium_name, ci.city_id,
    CAST(NULLIF(s.stadium_capacity, '') AS UNSIGNED), NULLIF(s.stadium_wikipedia_link, '')
FROM stg_stadiums s
LEFT JOIN country co ON co.country_name = s.country_name
LEFT JOIN city ci     ON ci.city_name = s.city_name AND ci.country_id = co.country_id;

-- ---------------------------------------------------------------------
-- 9) player  <- players.csv (birth_date ya limpio, ver Paso 1)
-- ---------------------------------------------------------------------
INSERT INTO player (player_id, family_name, given_name, birth_date, female, player_wikipedia_link)
SELECT DISTINCT
    p.player_id, p.family_name, p.given_name,
    NULLIF(p.birth_date, ''), CAST(p.female AS UNSIGNED), NULLIF(p.player_wikipedia_link, '')
FROM stg_players p;

-- ---------------------------------------------------------------------
-- 10) award  <- awards.csv
-- ---------------------------------------------------------------------
INSERT INTO award (award_id, award_name, award_description, year_introduced)
SELECT DISTINCT award_id, award_name, NULLIF(award_description, ''), NULLIF(year_introduced, '')
FROM stg_awards;

-- ---------------------------------------------------------------------
-- 11) tournament  <- tournaments.csv
-- ---------------------------------------------------------------------
INSERT INTO tournament (tournament_id, tournament_name, year, start_date, end_date, host_country_id, winner_team_id, host_won, count_teams)
SELECT DISTINCT
    t.tournament_id, t.tournament_name, t.year,
    NULLIF(t.start_date, ''), NULLIF(t.end_date, ''),
    co.country_id, tm.team_id,
    CAST(t.host_won AS UNSIGNED), CAST(NULLIF(t.count_teams, '') AS UNSIGNED)
FROM stg_tournaments t
LEFT JOIN country co ON co.country_name = t.host_country
LEFT JOIN team tm    ON tm.team_name = t.winner;

-- ---------------------------------------------------------------------
-- 12) matches  <- matches.csv
-- ---------------------------------------------------------------------
INSERT INTO matches (match_id, tournament_id, stadium_id, match_date, match_time, stage_name, group_name,
                      home_team_id, away_team_id, home_team_score, away_team_score, extra_time,
                      penalty_shootout, home_team_score_penalties, away_team_score_penalties, result)
SELECT DISTINCT
    m.match_id, m.tournament_id, m.stadium_id, NULLIF(m.match_date, ''), NULLIF(m.match_time, ''),
    m.stage_name, m.group_name, m.home_team_id, m.away_team_id,
    CAST(NULLIF(m.home_team_score, '') AS SIGNED), CAST(NULLIF(m.away_team_score, '') AS SIGNED),
    CAST(m.extra_time AS UNSIGNED), CAST(m.penalty_shootout AS UNSIGNED),
    CAST(NULLIF(m.home_team_score_penalties, '') AS SIGNED), CAST(NULLIF(m.away_team_score_penalties, '') AS SIGNED),
    NULLIF(m.result, '')
FROM stg_matches m;

-- ---------------------------------------------------------------------
-- 13) goal  <- goals.csv
-- ---------------------------------------------------------------------
INSERT INTO goal (goal_id, match_id, team_id, player_id, minute_regulation, minute_stoppage, match_period, own_goal, penalty)
SELECT DISTINCT
    g.goal_id, g.match_id, g.team_id, g.player_id,
    CAST(NULLIF(g.minute_regulation, '') AS SIGNED), CAST(NULLIF(g.minute_stoppage, '') AS SIGNED),
    NULLIF(g.match_period, ''), CAST(g.own_goal AS UNSIGNED), CAST(g.penalty AS UNSIGNED)
FROM stg_goals g;

-- ---------------------------------------------------------------------
-- 14) player_appearance  <- player_appearances.csv
-- ---------------------------------------------------------------------
INSERT INTO player_appearance (match_id, team_id, player_id, shirt_number, position_code, starter, substitute)
SELECT DISTINCT
    pa.match_id, pa.team_id, pa.player_id,
    CAST(NULLIF(pa.shirt_number, '') AS UNSIGNED), NULLIF(pa.position_code, ''),
    CAST(pa.starter AS UNSIGNED), CAST(pa.substitute AS UNSIGNED)
FROM stg_player_appearances pa;

-- ---------------------------------------------------------------------
-- 15) award_winner  <- award_winners.csv
-- ---------------------------------------------------------------------
INSERT INTO award_winner (tournament_id, award_id, player_id, team_id, shared)
SELECT DISTINCT
    aw.tournament_id, aw.award_id, NULLIF(aw.player_id, ''), NULLIF(aw.team_id, ''), CAST(aw.shared AS UNSIGNED)
FROM stg_award_winners aw;

-- =====================================================================
-- Verificacion rapida: conteo de filas por tabla final
-- =====================================================================
SELECT 'region' AS tabla, COUNT(*) AS filas FROM region
UNION ALL SELECT 'confederation', COUNT(*) FROM confederation
UNION ALL SELECT 'position', COUNT(*) FROM `position`
UNION ALL SELECT 'country', COUNT(*) FROM country
UNION ALL SELECT 'city', COUNT(*) FROM city
UNION ALL SELECT 'federation', COUNT(*) FROM federation
UNION ALL SELECT 'team', COUNT(*) FROM team
UNION ALL SELECT 'stadium', COUNT(*) FROM stadium
UNION ALL SELECT 'player', COUNT(*) FROM player
UNION ALL SELECT 'award', COUNT(*) FROM award
UNION ALL SELECT 'tournament', COUNT(*) FROM tournament
UNION ALL SELECT 'matches', COUNT(*) FROM matches
UNION ALL SELECT 'goal', COUNT(*) FROM goal
UNION ALL SELECT 'player_appearance', COUNT(*) FROM player_appearance
UNION ALL SELECT 'award_winner', COUNT(*) FROM award_winner;
