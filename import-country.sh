#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

readonly COUNTRY_DB_FILE="$IMPORT_DATA_DIR/countries.db"
readonly ISO_CODE=${ISO_CODE:-JP}

function exec_psql() {
    PGCLIENTENCODING="UTF-8" PGPASSWORD=$POSTGRES_PASSWORD psql --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --dbname="$POSTGRES_DB" --username="$POSTGRES_USER"
}

function restore() {
    echo "create schema test" | exec_psql
     PGCLIENTENCODING="UTF-8" PGPASSWORD=$POSTGRES_PASSWORD psql --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --dbname="$POSTGRES_DB" --username="$POSTGRES_USER" < $COUNTRY_DB_FILE
}

function move() {
    local table=$1
    echo "create table $table
            as
            select osm_id, way as geometry, 'country'::text as class, name, tags->'name:en' as name_en,
                tags->'name:de' as name_de, tags, null::int as rank from
                test.svens_countries
                where tags->'ISO3166-1' = '$ISO_CODE'" | exec_psql
}

function import_shp() {
    local shp_file=$1
    local table_name=$2
    PGCLIENTENCODING="UTF-8" shp2pgsql -s 3857 -I -g geometry "$shp_file" "$table_name" | exec_psql | hide_inserts
}

function hide_inserts() {
    grep -v "INSERT 0 1"
}

function drop_table() {
    local table=$1
    local drop_command="DROP TABLE IF EXISTS $table;"
    echo "$drop_command" | exec_psql
}

function generalize_country() {
    local target_table_name="$1"
    local source_table_name="$2"
    local tolerance="$3"
    echo "Generalize $target_table_name with tolerance $tolerance from $source_table_name"
    echo "CREATE TABLE $target_table_name AS SELECT osm_id, name, tags, name_en, name_de, rank, class, st_makevalid(ST_Simplify(geometry, $tolerance)) AS geometry FROM $source_table_name" | exec_psql
    echo "CREATE INDEX ON $target_table_name USING gist (geometry)" | exec_psql
    echo "ANALYZE $target_table_name" | exec_psql
}

function import_country() {
    drop_table "test.svens_countries"
    restore
    local table_name="osm_country_polygon"
    drop_table "$table_name"
    move "$table_name"

    local gen8_table_name="osm_country_polygon_gen8"
    drop_table "$gen8_table_name"
    generalize_country "$gen8_table_name" "$table_name" 611

    local gen7_table_name="osm_country_polygon_gen7"
    drop_table "$gen7_table_name"
    generalize_country "$gen7_table_name" "$table_name" 611

    local gen6_table_name="osm_country_polygon_gen6"
    drop_table "$gen6_table_name"
    generalize_country "$gen6_table_name" "$table_name" 305

    local gen5_table_name="osm_country_polygon_gen5"
    drop_table "$gen5_table_name"
    generalize_country "$gen5_table_name" "$table_name" 152

    local gen4_table_name="osm_country_polygon_gen4"
    drop_table "$gen4_table_name"
    generalize_country "$gen4_table_name" "$table_name" 75

    local gen3_table_name="osm_country_polygon_gen3"
    drop_table "$gen3_table_name"
    generalize_country "$gen3_table_name" "$table_name" 75

    local gen2_table_name="osm_country_polygon_gen2"
    drop_table "$gen2_table_name"
    generalize_country "$gen2_table_name" "$table_name" 38

    local gen1_table_name="osm_country_polygon_gen1"
    drop_table "$gen1_table_name"
    generalize_country "$gen1_table_name" "$table_name" 19
}

import_country
