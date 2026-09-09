-- =====================================================================
-- AVANCE 1 - Proyecto Mundiales
-- Script DDL: creacion de las 15 tablas requeridas
-- Motor: MySQL (via phpMyAdmin / XAMPP)
--
-- Como usarlo:
--   1) Abre phpMyAdmin (http://localhost/phpmyadmin)
--   2) Crea (o entra a) la base de datos, por ejemplo: mundiales_db
--   3) Pestana "SQL" -> pega todo este script -> Continuar
--   El orden de creacion ya respeta las dependencias de llave foranea.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS mundiales_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE mundiales_db;

SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------
-- 1) region  (sin dependencias)
--    Se llena con los valores unicos de region_name en teams.csv
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS region;
CREATE TABLE region (
    region_id     INT AUTO_INCREMENT PRIMARY KEY,
    region_name   VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 2) confederation  (sin dependencias)
--    Viene directo de confederations.csv
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS confederation;
CREATE TABLE confederation (
    confederation_id             VARCHAR(10)  PRIMARY KEY,   -- ej. CF-1
    confederation_name           VARCHAR(150) NOT NULL,
    confederation_code           VARCHAR(10)  NOT NULL,
    confederation_wikipedia_link VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 3) position  (sin dependencias)
--    Se llena con los valores unicos de position_name/position_code
--    en player_appearances.csv
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS `position`;
CREATE TABLE `position` (
    position_code   VARCHAR(5)  PRIMARY KEY,   -- ej. GK, DF, MF, FW
    position_name   VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 4) country  (sin dependencias)
--    Se llena con los valores unicos de country_name en stadiums.csv,
--    matches.csv y tournaments.csv (host_country / winner)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS country;
CREATE TABLE country (
    country_id     INT AUTO_INCREMENT PRIMARY KEY,
    country_name   VARCHAR(150) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 5) city  (depende de country)
--    Se llena con city_name + country_name de stadiums.csv
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS city;
CREATE TABLE city (
    city_id             INT AUTO_INCREMENT PRIMARY KEY,
    city_name           VARCHAR(150) NOT NULL,
    country_id          INT NOT NULL,
    city_wikipedia_link VARCHAR(255) NULL,
    UNIQUE KEY uq_city_country (city_name, country_id),
    CONSTRAINT fk_city_country
        FOREIGN KEY (country_id) REFERENCES country(country_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 6) federation  (sin dependencias directas)
--    Se llena con los valores unicos de federation_name en teams.csv
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS federation;
CREATE TABLE federation (
    federation_id             INT AUTO_INCREMENT PRIMARY KEY,
    federation_name           VARCHAR(150) NOT NULL UNIQUE,
    federation_wikipedia_link VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 7) team  (depende de federation, region, confederation)
--    Viene de teams.csv
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS team;
CREATE TABLE team (
    team_id            VARCHAR(10)  PRIMARY KEY,   -- ej. T-03
    team_name          VARCHAR(150) NOT NULL,
    team_code          VARCHAR(10)  NULL,
    mens_team          TINYINT(1)   NOT NULL DEFAULT 0,
    womens_team        TINYINT(1)   NOT NULL DEFAULT 0,
    federation_id      INT NULL,
    region_id          INT NULL,
    confederation_id   VARCHAR(10) NULL,
    CONSTRAINT fk_team_federation
        FOREIGN KEY (federation_id) REFERENCES federation(federation_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_team_region
        FOREIGN KEY (region_id) REFERENCES region(region_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_team_confederation
        FOREIGN KEY (confederation_id) REFERENCES confederation(confederation_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 8) stadium  (depende de city)
--    Viene de stadiums.csv
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS stadium;
CREATE TABLE stadium (
    stadium_id             VARCHAR(10)  PRIMARY KEY,  -- ej. S-001
    stadium_name           VARCHAR(150) NOT NULL,
    city_id                INT NULL,
    stadium_capacity       INT NULL,
    stadium_wikipedia_link VARCHAR(255) NULL,
    CONSTRAINT fk_stadium_city
        FOREIGN KEY (city_id) REFERENCES city(city_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 9) player  (sin dependencias)
--    Viene de players.csv (birth_date ya limpio: NULL cuando no se conoce)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS player;
CREATE TABLE player (
    player_id             VARCHAR(10)  PRIMARY KEY,  -- ej. P-56486
    family_name           VARCHAR(100) NOT NULL,
    given_name             VARCHAR(100) NOT NULL,
    birth_date             DATE NULL,
    female                 TINYINT(1) NOT NULL DEFAULT 0,
    player_wikipedia_link VARCHAR(255) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 10) award  (sin dependencias)
--     Viene de awards.csv
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS award;
CREATE TABLE award (
    award_id           VARCHAR(10)  PRIMARY KEY,   -- ej. A-1
    award_name         VARCHAR(100) NOT NULL,
    award_description  VARCHAR(255) NULL,
    year_introduced     YEAR NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 11) tournament  (depende de country y team)
--     Viene de tournaments.csv
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS tournament;
CREATE TABLE tournament (
    tournament_id     VARCHAR(10)  PRIMARY KEY,   -- ej. WC-1930
    tournament_name   VARCHAR(150) NOT NULL,
    year               YEAR NOT NULL,
    start_date         DATE NULL,
    end_date           DATE NULL,
    host_country_id   INT NULL,
    winner_team_id    VARCHAR(10) NULL,
    host_won           TINYINT(1) NOT NULL DEFAULT 0,
    count_teams        INT NULL,
    CONSTRAINT fk_tournament_country
        FOREIGN KEY (host_country_id) REFERENCES country(country_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_tournament_winner
        FOREIGN KEY (winner_team_id) REFERENCES team(team_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 12) matches  (depende de tournament, stadium, team)
--     Viene de matches.csv
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS matches;
CREATE TABLE matches (
    match_id                    VARCHAR(15)  PRIMARY KEY,  -- ej. M-1930-01
    tournament_id               VARCHAR(10)  NOT NULL,
    stadium_id                  VARCHAR(10)  NULL,
    match_date                  DATE NULL,
    match_time                  TIME NULL,
    stage_name                  VARCHAR(50) NULL,
    group_name                  VARCHAR(50) NULL,
    home_team_id                VARCHAR(10) NOT NULL,
    away_team_id                VARCHAR(10) NOT NULL,
    home_team_score              INT NULL,
    away_team_score              INT NULL,
    extra_time                   TINYINT(1) NOT NULL DEFAULT 0,
    penalty_shootout             TINYINT(1) NOT NULL DEFAULT 0,
    home_team_score_penalties   INT NULL,
    away_team_score_penalties   INT NULL,
    result                        VARCHAR(50) NULL,
    CONSTRAINT fk_matches_tournament
        FOREIGN KEY (tournament_id) REFERENCES tournament(tournament_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_matches_stadium
        FOREIGN KEY (stadium_id) REFERENCES stadium(stadium_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_matches_home_team
        FOREIGN KEY (home_team_id) REFERENCES team(team_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_matches_away_team
        FOREIGN KEY (away_team_id) REFERENCES team(team_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 13) goal  (depende de matches, team, player)
--     Viene de goals.csv
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS goal;
CREATE TABLE goal (
    goal_id            VARCHAR(10)  PRIMARY KEY,  -- ej. G-0001
    match_id           VARCHAR(15)  NOT NULL,
    team_id            VARCHAR(10)  NOT NULL,
    player_id          VARCHAR(10)  NOT NULL,
    minute_regulation  INT NULL,
    minute_stoppage    INT NULL,
    match_period       VARCHAR(50) NULL,
    own_goal           TINYINT(1) NOT NULL DEFAULT 0,
    penalty            TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_goal_match
        FOREIGN KEY (match_id) REFERENCES matches(match_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_goal_team
        FOREIGN KEY (team_id) REFERENCES team(team_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_goal_player
        FOREIGN KEY (player_id) REFERENCES player(player_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 14) player_appearance  (depende de matches, team, player, position)
--     Viene de player_appearances.csv
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS player_appearance;
CREATE TABLE player_appearance (
    player_appearance_id  INT AUTO_INCREMENT PRIMARY KEY,  -- key_id del csv
    match_id               VARCHAR(15) NOT NULL,
    team_id                 VARCHAR(10) NOT NULL,
    player_id               VARCHAR(10) NOT NULL,
    shirt_number            INT NULL,
    position_code           VARCHAR(5) NULL,
    starter                 TINYINT(1) NOT NULL DEFAULT 0,
    substitute               TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_appearance_match
        FOREIGN KEY (match_id) REFERENCES matches(match_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_appearance_team
        FOREIGN KEY (team_id) REFERENCES team(team_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_appearance_player
        FOREIGN KEY (player_id) REFERENCES player(player_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_appearance_position
        FOREIGN KEY (position_code) REFERENCES `position`(position_code)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- 15) award_winner  (depende de award, tournament, player, team)
--     Viene de award_winners.csv
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS award_winner;
CREATE TABLE award_winner (
    award_winner_id  INT AUTO_INCREMENT PRIMARY KEY,  -- key_id del csv
    tournament_id     VARCHAR(10) NOT NULL,
    award_id          VARCHAR(10) NOT NULL,
    player_id         VARCHAR(10) NULL,
    team_id           VARCHAR(10) NULL,
    shared            TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_awardwinner_tournament
        FOREIGN KEY (tournament_id) REFERENCES tournament(tournament_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_awardwinner_award
        FOREIGN KEY (award_id) REFERENCES award(award_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_awardwinner_player
        FOREIGN KEY (player_id) REFERENCES player(player_id)
        ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_awardwinner_team
        FOREIGN KEY (team_id) REFERENCES team(team_id)
        ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- Fin del script. Siguiente paso: importar los CSV limpios como tablas
-- de staging y poblar estas 15 tablas con INSERT ... SELECT DISTINCT
-- respetando este mismo orden (region -> ... -> award_winner).
-- =====================================================================
