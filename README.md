# Import Land from OpenStreetMapData into PostGIS
This is a Docker image to import and simplify land polygons from [OpenStreetMapData](http://osmdata.openstreetmap.de/) using *shp2pgsql* into a PostGIS database.
The Shapefiles are already baked into the container to make distribution and execution easier.

## Usage

Provide the database credentials and run `import-water`.

```bash
docker run --rm \
    -e POSTGRES_USER="osm" \
    -e POSTGRES_PASSWORD="osm" \
    -e POSTGRES_HOST="127.0.0.1" \
    -e POSTGRES_DB="osm" \
    -e POSTGRES_PORT="5432" \
    mapcreatorio/import-land
```
## Version of OpenStreetMapData
**2019-08-05**
