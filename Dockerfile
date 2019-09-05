
FROM openmaptiles/postgis:2.9
ENV IMPORT_DATA_DIR=/import \
    NATURAL_EARTH_DB=/import/natural_earth_vector.sqlite

RUN apt-get update && apt-get install -y --no-install-recommends \
      wget \
      sqlite3 \
      ca-certificates 
RUN mkdir -p $IMPORT_DATA_DIR
copy ./countries.db /import/countries.db

WORKDIR /usr/src/app
COPY . /usr/src/app
CMD ["./import-country.sh"]
