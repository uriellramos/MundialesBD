-- =====================================================================
-- AVANCE 1 - Proyecto Mundiales
-- Script: quitar la fila de encabezado que se coló como dato en las 10
-- tablas staging (pasa cuando al importar el CSV no queda marcada la
-- casilla "La primera linea del archivo contiene los nombres de las
-- columnas"). Todas las tablas staging tienen 'key_id' como primera
-- columna, y el encabezado colado trae literalmente el texto
-- key_id = 'key_id' -- por eso el filtro funciona igual en las 10.
--
-- Correr esto en la pestana SQL de phpMyAdmin ANTES de volver a correr
-- 03_poblar_tablas.sql.
-- =====================================================================

USE mundiales_db;

DELETE FROM stg_awards             WHERE key_id = 'key_id';
DELETE FROM stg_award_winners      WHERE key_id = 'key_id';
DELETE FROM stg_confederations     WHERE key_id = 'key_id';
DELETE FROM stg_teams              WHERE key_id = 'key_id';
DELETE FROM stg_stadiums           WHERE key_id = 'key_id';
DELETE FROM stg_players            WHERE key_id = 'key_id';
DELETE FROM stg_player_appearances WHERE key_id = 'key_id';
DELETE FROM stg_matches            WHERE key_id = 'key_id';
DELETE FROM stg_goals              WHERE key_id = 'key_id';
DELETE FROM stg_tournaments        WHERE key_id = 'key_id';

-- ---------------------------------------------------------------------
-- Verificacion: estos 10 conteos deben coincidir EXACTO con esta lista.
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
