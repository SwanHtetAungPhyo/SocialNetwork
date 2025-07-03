# Critical Database Concepts - Simplified

## 🔴 **CRITICAL - Must Master**

### 1. PostgreSQL Execution Plan Types

**When PostgreSQL chooses each:**

- **Sequential Scan**: When result is >20-30% of table OR no useful index
- **Index Scan**: Highly selective queries (<1% of table), exact matches
- **Bitmap Index Scan**: Medium selectivity (1-20% of table), multiple conditions

**Key Rule**: More rows expected = more likely to use sequential scan

**Example**:
- `WHERE id = 1` → Index Scan (1 row)
- `WHERE category_id = 5` (5000/50000 rows) → Bitmap Scan
- `WHERE status IN (1,2,3,4,5)` (25000/50000 rows) → Sequential Scan

### 2. PostGIS Coordinate Systems

**Two Types:**
- **Geometry**: Flat earth, fast calculations, units depend on coordinate system
- **Geography**: Round earth, slower, always returns meters

**Common Systems:**
- **EPSG:4326**: Lat/lon degrees (WGS84)
- **EPSG:3857**: Web Mercator, meters
- **EPSG:2180**: Poland national grid, meters

**Quick Rules:**
```sql
-- Distance in degrees (useless)
ST_Distance(geom1, geom2)  

-- Distance in meters (spherical)
ST_Distance(geom1::geography, geom2::geography)

-- Distance in meters (planar, need same projection)
ST_Distance(ST_Transform(geom1, 3857), ST_Transform(geom2, 3857))
```

### 3. CouchDB Map-Reduce Structure

**Map Function** - Creates key-value pairs:
```javascript
function(doc) {
    if (doc.field_exists) {
        emit(doc.key, doc.value);
    }
}
```

**Reduce Function** - Aggregates values:
```javascript
function(keys, values, rereduce) {
    if (rereduce) {
        // Handle pre-reduced values
        return sum_of_values;
    } else {
        // Handle raw document values  
        return sum_of_values;
    }
}
```

**Output Format**: Always key-value pairs, sorted by key

### 4. Neo4j Basic Cypher

**Essential Patterns:**
```cypher
// Find nodes
MATCH (n:Label {property: value})

// Create relationships  
CREATE (a)-[:RELATIONSHIP]->(b)

// Path patterns
MATCH (a)-[:REL*1..3]-(b)  // 1 to 3 hops
MATCH path = shortestPath((a)-[:REL*]-(b))

// Conditional matching
MATCH (n:Person)
WHERE EXISTS((n)-[:FRIENDS_WITH]-())

// Left join equivalent
OPTIONAL MATCH (n)-[:REL]-(m)
```

## 🟡 **IMPORTANT - Should Know**

### 1. B-tree Index Capabilities

**Works with**: `=, <, >, <=, >=, BETWEEN, IN, LIKE 'prefix%'`
**Doesn't work with**: `LIKE '%suffix'`, `!=`, functions on columns

### 2. Spatial Function Units

- **ST_Distance(geometry, geometry)**: Units of coordinate system
- **ST_Distance(geography, geography)**: Always meters
- **ST_DistanceSphere()**: Always meters, requires lat/lon input
- **ST_DWithin()**: Uses same units as input coordinate system

### 3. Graph Traversal Performance

- **Depth matters**: `*1..2` faster than `*1..5`
- **Direction matters**: `->` faster than `-` (undirected)
- **Start from indexed properties**: `WHERE n.id = 123` then traverse

### 4. Document Database HTTP APIs

**CouchDB URL Pattern**:
`http://host:port/database/_design/design_doc/_view/view_name`

**Common Parameters**:
- `?key="exact_key"` - Single key
- `?startkey="a"&endkey="z"` - Key range
- `?reduce=false` - Skip reduce function
- `?include_docs=true` - Include full documents

That's it - focus on these patterns and you'll handle 90% of the exam questions.