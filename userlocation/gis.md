# PostGIS Functions Reference

Based on the laboratory document, here are the key PostGIS functions and their usage:

## PostGIS Functions Table

| Function | Purpose | When to Use | Example Usage |
|----------|---------|-------------|---------------|
| `ST_GeomFromText` | Convert WKT (Well-Known Text) to geometry | Creating geometry from text coordinates | `ST_GeomFromText('POINT(19.938333 50.061389)', 4326)` |
| `ST_MakePoint` | Create point geometry from coordinates | Building point geometries programmatically | `ST_MakePoint(longitude, latitude)` |
| `ST_SetSRID` | Assign spatial reference system ID to geometry | Setting coordinate system for existing geometry | `ST_SetSRID(geom_column, 4326)` |
| `ST_Distance` | Calculate distance between geometries | Measuring distances on flat surfaces | `ST_Distance(geom1, geom2)` - returns in coordinate units |
| `ST_Transform` | Transform geometry to different coordinate system | Converting between coordinate systems | `ST_Transform(geom_column, target_srid)` |
| `ST_DistanceSphere` | Calculate spherical distance on Earth | Measuring distances on curved Earth surface | `ST_DistanceSphere(geom1, geom2)` - returns meters |
| `ST_SRID` | Get spatial reference system ID of geometry | Checking coordinate system of data | `ST_SRID(geom_column)` |
| `ST_Area` | Calculate area of polygon geometries | Finding area measurements | `ST_Area(polygon_geom)` - units depend on coordinate system |
| `ST_Length` | Calculate length of linear geometries | Measuring road lengths, perimeters | `ST_Length(linestring_geom)` |
| `ST_Intersects` | Test if geometries spatially intersect | Finding overlapping features | `ST_Intersects(geom1, geom2)` - returns boolean |
| `ST_Within` | Test if one geometry is within another | Finding features inside boundaries | `ST_Within(point_geom, polygon_geom)` |
| `ST_Buffer` | Create buffer zone around geometry | Creating proximity zones | `ST_Buffer(geom, distance)` - creates polygon buffer |
| `ST_DWithin` | Test if geometries are within specified distance | Finding nearby features | `ST_DWithin(geom1, geom2, distance)` |

## Data Types

| Type | Description | When to Use |
|------|-------------|-------------|
| `GEOMETRY` | Cartesian coordinate geometry | When working in flat coordinate systems, faster processing |
| `GEOGRAPHY` | Spherical coordinate geography | When working globally, automatic Earth curvature calculations |

## Coordinate Systems (SRID)

| SRID | Name | When to Use |
|------|------|-------------|
| `4326` | WGS-84 (GPS coordinates) | Global data, longitude/latitude |
| `2178` | PUWG 2000 Zone 8 | Krakow area, high precision |
| `2176` | PUWG 2000 Zone 6 | Szczecin area, high precision |
| `2180` | PUWG 92 | Entire Poland, medium precision |

## Common Spatial Query Patterns

### Joins in Spatial Queries

Spatial joins are used to combine tables based on spatial relationships rather than exact key matches:

```sql
-- Find all lamps within city boundaries
SELECT l.*, c.city_name
FROM lamps l
JOIN cities c ON ST_Within(l.geom, c.geom);

-- Find roads that intersect administrative boundaries
SELECT r.road_name, a.admin_name
FROM roads r
JOIN admin a ON ST_Intersects(r.geom, a.geom);
```

### Distance-Based Queries

```sql
-- Find all features within distance
SELECT * FROM lamps 
WHERE ST_DWithin(geom, ST_GeomFromText('POINT(19.938 50.061)', 4326), 100);

-- Calculate distance between specific points
SELECT ST_Distance(
    ST_Transform(geom1, 2178), 
    ST_Transform(geom2, 2178)
) as distance_meters;
```

### Buffer and Proximity Analysis

```sql
-- Create buffer zones and find intersections
SELECT COUNT(*) as lamp_count
FROM lamps l, roads r
WHERE r.road_name = 'Czarnowiejska'
AND ST_Within(l.geom, ST_Buffer(r.geom, 10));
```

### Area and Length Calculations

```sql
-- Calculate area in different coordinate systems
SELECT 
    ST_Area(geom) as area_degrees,  -- GEOMETRY in degrees
    ST_Area(geom::geography) as area_meters  -- GEOGRAPHY in meters
FROM admin;

-- Calculate road length within boundaries
SELECT SUM(ST_Length(ST_Intersection(r.geom, a.geom)))
FROM roads r, admin a
WHERE r.road_type = 'motorway'
AND ST_Intersects(r.geom, a.geom);
```

## Key Concepts Explained

**Coordinate Systems:** Different SRID values represent different ways to project the curved Earth onto flat coordinates. Local systems (like PUWG 2000) are more accurate for specific regions, while global systems (like WGS-84) work everywhere but with varying precision.

**GEOMETRY vs GEOGRAPHY:** GEOMETRY treats coordinates as flat Cartesian coordinates (faster, more functions), while GEOGRAPHY treats them as spherical coordinates on Earth's surface (more accurate for global calculations, slower).

**Spatial Relationships:** Functions like `ST_Within`, `ST_Intersects`, and `ST_DWithin` test spatial relationships between geometries, enabling complex geographic analysis beyond simple attribute-based joins.