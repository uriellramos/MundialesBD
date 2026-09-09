-- =====================================================================
-- AVANCE 1 - Proyecto Mundiales
-- Script: tablas STAGING (una por cada CSV limpio, columnas tal cual
-- vienen en el archivo, todas como texto). Sirven de escala antes de
-- poblar las 15 tablas finales con 03_poblar_tablas.sql
--
-- Como usarlo:
--   1) Pega este script en la pestana SQL de phpMyAdmin (con mundiales_db
--      ya seleccionada) para crear las tablas staging vacias.
--   2) Ve a la pestana Importar y sube cada CSV limpio a su tabla staging
--      correspondiente (mismo nombre que el CSV, con prefijo stg_).
-- =====================================================================

USE mundiales_db;

SET FOREIGN_KEY_CHECKS = 0;

-- Origen: awards.csv
DROP TABLE IF EXISTS stg_awards;
CREATE TABLE stg_awards (
    key_id VARCHAR(150) NULL,
    award_id VARCHAR(150) NULL,
    award_name VARCHAR(150) NULL,
    award_description VARCHAR(150) NULL,
    year_introduced VARCHAR(150) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Origen: award_winners.csv
DROP TABLE IF EXISTS stg_award_winners;
CREATE TABLE stg_award_winners (
    key_id VARCHAR(150) NULL,
    tournament_id VARCHAR(150) NULL,
    tournament_name VARCHAR(150) NULL,
    award_id VARCHAR(150) NULL,
    award_name VARCHAR(150) NULL,
    shared VARCHAR(150) NULL,
    player_id VARCHAR(150) NULL,
    family_name VARCHAR(150) NULL,
    given_name VARCHAR(150) NULL,
    team_id VARCHAR(150) NULL,
    team_name VARCHAR(150) NULL,
    team_code VARCHAR(150) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Origen: confederations.csv
DROP TABLE IF EXISTS stg_confederations;
CREATE TABLE stg_confederations (
    key_id VARCHAR(150) NULL,
    confederation_id VARCHAR(150) NULL,
    confederation_name VARCHAR(150) NULL,
    confederation_code VARCHAR(150) NULL,
    confederation_wikipedia_link VARCHAR(150) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Origen: teams.csv
DROP TABLE IF EXISTS stg_teams;
CREATE TABLE stg_teams (
    key_id VARCHAR(150) NULL,
    team_id VARCHAR(150) NULL,
    team_name VARCHAR(150) NULL,
    team_code VARCHAR(150) NULL,
    mens_team VARCHAR(150) NULL,
    womens_team VARCHAR(150) NULL,
    federation_name VARCHAR(150) NULL,
    region_name VARCHAR(150) NULL,
    confederation_id VARCHAR(150) NULL,
    confederation_name VARCHAR(150) NULL,
    confederation_code VARCHAR(150) NULL,
    mens_team_wikipedia_link VARCHAR(150) NULL,
    womens_team_wikipedia_link VARCHAR(150) NULL,
    federation_wikipedia_link VARCHAR(150) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Origen: stadiums.csv
DROP TABLE IF EXISTS stg_stadiums;
CREATE TABLE stg_stadiums (
    key_id VARCHAR(150) NULL,
    stadium_id VARCHAR(150) NULL,
    stadium_name VARCHAR(150) NULL,
    city_name VARCHAR(150) NULL,
    country_name VARCHAR(150) NULL,
    stadium_capacity VARCHAR(150) NULL,
    stadium_wikipedia_link VARCHAR(150) NULL,
    city_wikipedia_link VARCHAR(150) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Origen: players.csv
DROP TABLE IF EXISTS stg_players;
CREATE TABLE stg_players (
    key_id VARCHAR(150) NULL,
    player_id VARCHAR(150) NULL,
    family_name VARCHAR(150) NULL,
    given_name VARCHAR(150) NULL,
    birth_date VARCHAR(150) NULL,
    female VARCHAR(150) NULL,
    goal_keeper VARCHAR(150) NULL,
    defender VARCHAR(150) NULL,
    midfielder VARCHAR(150) NULL,
    forward VARCHAR(150) NULL,
    count_tournaments VARCHAR(150) NULL,
    list_tournaments VARCHAR(150) NULL,
    player_wikipedia_link VARCHAR(150) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Origen: player_appearances.csv
DROP TABLE IF EXISTS stg_player_appearances;
CREATE TABLE stg_player_appearances (
    key_id VARCHAR(150) NULL,
    tournament_id VARCHAR(150) NULL,
    tournament_name VARCHAR(150) NULL,
    match_id VARCHAR(150) NULL,
    match_name VARCHAR(150) NULL,
    match_date VARCHAR(150) NULL,
    stage_name VARCHAR(150) NULL,
    group_name VARCHAR(150) NULL,
    team_id VARCHAR(150) NULL,
    team_name VARCHAR(150) NULL,
    team_code VARCHAR(150) NULL,
    home_team VARCHAR(150) NULL,
    away_team VARCHAR(150) NULL,
    player_id VARCHAR(150) NULL,
    family_name VARCHAR(150) NULL,
    given_name VARCHAR(150) NULL,
    shirt_number VARCHAR(150) NULL,
    position_name VARCHAR(150) NULL,
    position_code VARCHAR(150) NULL,
    starter VARCHAR(150) NULL,
    substitute VARCHAR(150) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Origen: matches.csv
DROP TABLE IF EXISTS stg_matches;
CREATE TABLE stg_matches (
    key_id VARCHAR(150) NULL,
    tournament_id VARCHAR(150) NULL,
    tournament_name VARCHAR(150) NULL,
    match_id VARCHAR(150) NULL,
    match_name VARCHAR(150) NULL,
    stage_name VARCHAR(150) NULL,
    group_name VARCHAR(150) NULL,
    group_stage VARCHAR(150) NULL,
    knockout_stage VARCHAR(150) NULL,
    replayed VARCHAR(150) NULL,
    replay VARCHAR(150) NULL,
    match_date VARCHAR(150) NULL,
    match_time VARCHAR(150) NULL,
    stadium_id VARCHAR(150) NULL,
    stadium_name VARCHAR(150) NULL,
    city_name VARCHAR(150) NULL,
    country_name VARCHAR(150) NULL,
    home_team_id VARCHAR(150) NULL,
    home_team_name VARCHAR(150) NULL,
    home_team_code VARCHAR(150) NULL,
    away_team_id VARCHAR(150) NULL,
    away_team_name VARCHAR(150) NULL,
    away_team_code VARCHAR(150) NULL,
    score VARCHAR(150) NULL,
    home_team_score VARCHAR(150) NULL,
    away_team_score VARCHAR(150) NULL,
    home_team_score_margin VARCHAR(150) NULL,
    away_team_score_margin VARCHAR(150) NULL,
    extra_time VARCHAR(150) NULL,
    penalty_shootout VARCHAR(150) NULL,
    score_penalties VARCHAR(150) NULL,
    home_team_score_penalties VARCHAR(150) NULL,
    away_team_score_penalties VARCHAR(150) NULL,
    result VARCHAR(150) NULL,
    home_team_win VARCHAR(150) NULL,
    away_team_win VARCHAR(150) NULL,
    draw VARCHAR(150) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Origen: goals.csv
DROP TABLE IF EXISTS stg_goals;
CREATE TABLE stg_goals (
    key_id VARCHAR(150) NULL,
    goal_id VARCHAR(150) NULL,
    tournament_id VARCHAR(150) NULL,
    tournament_name VARCHAR(150) NULL,
    match_id VARCHAR(150) NULL,
    match_name VARCHAR(150) NULL,
    match_date VARCHAR(150) NULL,
    stage_name VARCHAR(150) NULL,
    group_name VARCHAR(150) NULL,
    team_id VARCHAR(150) NULL,
    team_name VARCHAR(150) NULL,
    team_code VARCHAR(150) NULL,
    home_team VARCHAR(150) NULL,
    away_team VARCHAR(150) NULL,
    player_id VARCHAR(150) NULL,
    family_name VARCHAR(150) NULL,
    given_name VARCHAR(150) NULL,
    shirt_number VARCHAR(150) NULL,
    player_team_id VARCHAR(150) NULL,
    player_team_name VARCHAR(150) NULL,
    player_team_code VARCHAR(150) NULL,
    minute_label VARCHAR(150) NULL,
    minute_regulation VARCHAR(150) NULL,
    minute_stoppage VARCHAR(150) NULL,
    match_period VARCHAR(150) NULL,
    own_goal VARCHAR(150) NULL,
    penalty VARCHAR(150) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Origen: tournaments.csv
DROP TABLE IF EXISTS stg_tournaments;
CREATE TABLE stg_tournaments (
    key_id VARCHAR(150) NULL,
    tournament_id VARCHAR(150) NULL,
    tournament_name VARCHAR(150) NULL,
    year VARCHAR(150) NULL,
    start_date VARCHAR(150) NULL,
    end_date VARCHAR(150) NULL,
    host_country VARCHAR(150) NULL,
    winner VARCHAR(150) NULL,
    host_won VARCHAR(150) NULL,
    count_teams VARCHAR(150) NULL,
    group_stage VARCHAR(150) NULL,
    second_group_stage VARCHAR(150) NULL,
    final_round VARCHAR(150) NULL,
    round_of_16 VARCHAR(150) NULL,
    quarter_finals VARCHAR(150) NULL,
    semi_finals VARCHAR(150) NULL,
    third_place_match VARCHAR(150) NULL,
    final VARCHAR(150) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
