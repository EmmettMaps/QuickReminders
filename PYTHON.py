import pandas as pd, geopandas as gpd
from shapely.geometry import Point
import duckdb, boto3
# quick OSM pull
from pyrosm import OSM

# --- read csv, build geometry ---
df = pd.read_csv("transactions.csv")
gdf = gpd.GeoDataFrame(
        df,
        geometry=[Point(xy) for xy in zip(df.lon, df.lat)],
        crs=4326)

# --- spatial join to county polygons ---
counties = gpd.read_file("counties.gpkg")[["geoid", "geometry"]]
gdf = gpd.sjoin(gdf, counties, predicate="within", how="left")

# --- aggregate & write parquet ---
out = gdf.groupby("geoid").agg(bookings=("id", "count")).reset_index()
out.to_parquet("s3://airbnb-demo/bookings_by_county.parquet", index=False)

#----------- Other libraries I like ----------------------#
import arcpy
import os
import zipfile
import pandas as pd
from census import Census
from arcgis.gis import GIS

#-----------tips and tricks ---------------------------
Read remote CSV directly	------ pd.read_csv("https://…")
DuckDB from Python	----------- duckdb.sql("SELECT …").df()
Parquet → Redshift (copy) --------	cursor.execute("COPY tbl FROM 's3://…' IAM_ROLE … FORMAT PARQUET")
Distance filter -------------	gdf.buffer(5000).unary_union or gpd.GeoSeries.distance()
Graph DB hand‑wave-------------	g.V().has('district','geoid','34021').in('WITHIN')
