# Neo4j Graph Database Detailed Reference Guide

Based on the laboratory exercises, here's a comprehensive table covering Neo4j concepts and Cypher query language:

## Neo4j Core Concepts

| Concept | Description | When to Use | Example |
|---------|-------------|-------------|---------|
| **Node** | Represents entities in the graph | Store objects, people, places | `(building:BUILDING {name: "A-1"})` |
| **Relationship** | Connects nodes with direction | Model connections between entities | `(a)-[:ADJACENT_TO {floor: 1}]->(b)` |
| **Label** | Groups nodes by type/category | Classify and query similar nodes | `:BUILDING`, `:SERVICE`, `:TEACHING` |
| **Property** | Key-value pairs on nodes/relationships | Store attributes and metadata | `{name: "C-3", capacity: 100}` |
| **Path** | Sequence of connected nodes/relationships | Find routes between entities | `(start)-[*]-(end)` |

## Cypher Query Language Components

| Component | Purpose | Syntax | Example |
|-----------|---------|--------|---------|
| **MATCH** | Find patterns in graph | `MATCH (pattern)` | `MATCH (b:BUILDING)` |
| **CREATE** | Create nodes/relationships | `CREATE (pattern)` | `CREATE (b:BUILDING {name: "A-1"})` |
| **MERGE** | Create if not exists | `MERGE (pattern)` | `MERGE (b:BUILDING {name: "A-1"})` |
| **WHERE** | Filter results | `WHERE condition` | `WHERE b.name = "A-1"` |
| **RETURN** | Specify output | `RETURN variables` | `RETURN b.name, COUNT(*)` |
| **WITH** | Pass results between query parts | `WITH variables` | `WITH b, COUNT(*) as cnt` |
| **ORDER BY** | Sort results | `ORDER BY property` | `ORDER BY b.name ASC` |
| **LIMIT** | Restrict result count | `LIMIT number` | `LIMIT 10` |

## Node Creation Patterns

| Pattern Type | Syntax | Use Case | Example |
|--------------|--------|----------|---------|
| **Simple Node** | `(variable:Label)` | Basic entity | `(b:BUILDING)` |
| **Node with Properties** | `(var:Label {prop: value})` | Entity with attributes | `(b:BUILDING {name: "A-1"})` |
| **Multiple Labels** | `(var:Label1:Label2)` | Multi-type classification | `(b:BUILDING:RESEARCH:TEACHING)` |
| **Variable Node** | `(variable)` | Reference in query | `(b)` where b is defined elsewhere |

## Relationship Creation Patterns

| Pattern Type | Syntax | Use Case | Example |
|--------------|--------|----------|---------|
| **Simple Relationship** | `(a)-[:TYPE]->(b)` | Basic connection | `(a)-[:ADJACENT_TO]->(b)` |
| **With Properties** | `(a)-[:TYPE {prop: val}]->(b)` | Connection with attributes | `(a)-[:ADJACENT_TO {floor: 1}]->(b)` |
| **Bidirectional** | `(a)-[:TYPE]-(b)` | Undirected connection | `(a)-[:CONNECTED]-(b)` |
| **Variable Length** | `(a)-[:TYPE*min..max]-(b)` | Multi-hop paths | `(a)-[:ADJACENT_TO*1..3]-(b)` |

## Query Patterns for Campus Graph

### 1. Create Building Nodes
```cypher
// Create buildings with multiple labels
CREATE (s1:BUILDING:SERVICE {name: "S-1"})
CREATE (a1:BUILDING:RESEARCH:TEACHING {name: "A-1"})
CREATE (c3:BUILDING:RESEARCH:TEACHING {name: "C-3"})
```

### 2. Create Adjacency Relationships
```cypher
// Buildings connected on specific floors
MATCH (c3:BUILDING {name: "C-3"}), (c2:BUILDING {name: "C-2"})
CREATE (c3)-[:ADJACENT_TO {floor: 0}]->(c2)
CREATE (c3)-[:ADJACENT_TO {floor: 1}]->(c2)
CREATE (c3)-[:ADJACENT_TO {floor: 2}]->(c2)
```

### 3. Create Faculty Headquarters
```cypher
CREATE (hq1:HQ {name: "Faculty of Mechanical Engineering", building: "A-1"})
CREATE (hq2:HQ {name: "Admission Centre", building: "C-1"})
```

### 4. Create Classrooms and Entrances
```cypher
CREATE (room1:CLASSROOM {number: "315", building: "A-1"})
CREATE (entrance1:ENTRANCE {name: "Main Entrance A-1", building: "A-1"})
```

## Analytics Query Patterns

| Query Type | Pattern | Example | Purpose |
|------------|---------|---------|---------|
| **Isolated Nodes** | Find nodes without relationships | `MATCH (b:BUILDING) WHERE NOT (b)--() RETURN b` | Find disconnected buildings |
| **Count by Label** | Count nodes with specific label | `MATCH (s:SERVICE) RETURN COUNT(s)` | Count service facilities |
| **Path Finding** | Find connections between nodes | `MATCH path = (a)-[*]-(b) RETURN path` | Find routes between buildings |
| **Shortest Path** | Minimal hops between nodes | `MATCH path = shortestPath((a)-[*]-(b)) RETURN path` | Optimal route finding |
| **Neighbor Analysis** | Find adjacent nodes | `MATCH (a)-[:ADJACENT_TO]-(b) RETURN a, b` | Find directly connected buildings |

## Sample Analytics Queries

### 1. Buildings Not Connected Directly
```cypher
MATCH (b:BUILDING)
WHERE NOT EXISTS {
  MATCH (b)-[:ADJACENT_TO]-(:BUILDING)
}
RETURN b.name as isolated_buildings
```

### 2. Count Service Facilities
```cypher
MATCH (s:SERVICE)
RETURN COUNT(s) as service_count
```

### 3. Count Faculty Headquarters
```cypher
MATCH (hq:HQ)
RETURN COUNT(hq) as hq_count
```

### 4. A-1 Building Connections
```cypher
MATCH (a1:BUILDING {name: "A-1"})-[r:ADJACENT_TO]-(connected:BUILDING)
RETURN connected.name as connected_building, r.floor as floor
ORDER BY connected.name, r.floor
```

### 5. Path from Admission Centre to Faculty HQ
```cypher
MATCH (admission:HQ {name: "Admission Centre"})
MATCH (mech:HQ {name: "Faculty of Mechanical Engineering"})
MATCH path = shortestPath((admission)-[:LOCATED_IN|ADJACENT_TO*]-(mech))
WHERE NONE(rel IN relationships(path) WHERE type(rel) = "ENTRANCE_TO")
RETURN path
```

### 6. Shortest Path C-3 to A-0 Entrance
```cypher
MATCH (c3:BUILDING {name: "C-3"})
MATCH (a0_entrance:ENTRANCE {building: "A-0"})
MATCH path = shortestPath((c3)-[*]-(a0_entrance))
RETURN length(path) as path_length, path
```

### 7. Buildings with 3+ Adjacent Buildings
```cypher
MATCH (b:BUILDING)-[:ADJACENT_TO]-(adjacent:BUILDING)
WITH b, COUNT(DISTINCT adjacent) as adjacent_count
WHERE adjacent_count >= 3
RETURN b.name as building, adjacent_count
ORDER BY adjacent_count DESC
```

## Advanced Query Patterns

| Pattern | Syntax | Use Case | Example |
|---------|--------|----------|---------|
| **Conditional Creation** | `MERGE` with `ON CREATE` | Create only if new | `MERGE (b:BUILDING {name: "A-1"}) ON CREATE SET b.created = timestamp()` |
| **Aggregation** | `COUNT`, `SUM`, `AVG` | Statistical analysis | `MATCH (b:BUILDING) RETURN COUNT(b), AVG(b.capacity)` |
| **Pattern Matching** | Complex MATCH patterns | Multi-hop relationships | `MATCH (a)-[:TYPE1]->(b)-[:TYPE2]->(c)` |
| **Optional Matching** | `OPTIONAL MATCH` | Handle missing relationships | `OPTIONAL MATCH (b)-[:HAS_ENTRANCE]-(e)` |
| **Union Queries** | `UNION` | Combine result sets | `MATCH (b:BUILDING) RETURN b.name UNION MATCH (e:ENTRANCE) RETURN e.name` |

## Property and Label Management

| Operation | Syntax | Purpose | Example |
|-----------|--------|---------|---------|
| **Add Label** | `SET n:NewLabel` | Classify existing node | `MATCH (b {name: "A-1"}) SET b:RESEARCH` |
| **Remove Label** | `REMOVE n:Label` | Unclassify node | `MATCH (b:BUILDING) REMOVE b:OLD_LABEL` |
| **Set Property** | `SET n.prop = value` | Add/update attribute | `SET b.capacity = 200` |
| **Remove Property** | `REMOVE n.prop` | Delete attribute | `REMOVE b.old_property` |

## Query Optimization Tips

| Technique | Purpose | Example | When to Use |
|-----------|---------|---------|-------------|
| **Index Creation** | Speed up lookups | `CREATE INDEX FOR (b:BUILDING) ON (b.name)` | Frequent property searches |
| **Label Filtering** | Reduce search space | `MATCH (b:BUILDING)` vs `MATCH (b)` | When node type is known |
| **Limit Early** | Reduce processing | `MATCH (b:BUILDING) RETURN b LIMIT 10` | Large result sets |
| **Use EXPLAIN** | Analyze query plan | `EXPLAIN MATCH (b:BUILDING) RETURN b` | Performance tuning |
| **Parameterized Queries** | Avoid query compilation | `MATCH (b {name: $building_name})` | Repeated similar queries |

## Common Graph Patterns

| Pattern Name | Description | Use Case | Cypher Example |
|--------------|-------------|----------|----------------|
| **Star Pattern** | Central node with many connections | Hub buildings, main entrances | `(center)-[:CONNECTS_TO]-(spoke)` |
| **Chain Pattern** | Linear sequence of connections | Building corridors, sequential floors | `(a)-[:NEXT]->(b)-[:NEXT]->(c)` |
| **Tree Pattern** | Hierarchical relationships | Organizational structure, building hierarchy | `(parent)-[:CONTAINS*]->(child)` |
| **Mesh Pattern** | Highly interconnected nodes | Campus layout, transportation network | `(a)-[:ADJACENT_TO]-(b), (b)-[:ADJACENT_TO]-(c)` |

This comprehensive guide covers all aspects needed to work with Neo4j for the campus graph database laboratory exercises, from basic node/relationship creation to complex path-finding analytics.