# Social Network Analysis with Neo4j

A modern social network implementation using Neo4j graph database to model relationships between people and their posts.

## Table of Contents
<details>
<summary>📋 Click to expand</summary>

- [Database Schema](#-database-schema)
- [Setup Instructions](#-setup-instructions)
- [Key Features](#-key-features)
- [Sample Queries](#-sample-queries)
- [Performance Optimization](#-performance-optimization)
- [Future Enhancements](#-future-enhancements)
</details>

## 🗃 Database Schema

The social network consists of two main node types and their relationships:

```
(PERSON) -[:POSTED]-> (POST)
(PERSON) -[:FRIEND_WITH]-> (PERSON)
```

<details>
<summary>📊 Schema Details</summary>

- **PERSON nodes** represent users with a `name` property
- **POST nodes** contain `content` with the post text
- **POSTED relationships** connect users to their posts
- **FRIEND_WITH relationships** represent mutual friendships between users

</details>

## 🛠 Setup Instructions

<details>
<summary>🔧 Click for setup steps</summary>

1. **Install Neo4j Desktop** from [neo4j.com/download](https://neo4j.com/download/)
2. **Create a new project** and start a database instance
3. **Run the Cypher script** provided to:
   - Create 10 person nodes
   - Create 5 post nodes
   - Establish posting relationships
   - Create random friendships between users
4. **Verify the data** with the validation queries

```cypher
// Verification queries
MATCH (p:PERSON) RETURN count(p) AS personCount;
MATCH (post:POST) RETURN count(post) AS postCount;
MATCH ()-[r:FRIEND_WITH]-() RETURN count(r) AS friendshipCount;
```

</details>

## ✨ Key Features

<details>
<summary>🌟 Explore features</summary>

### Friend Recommendations
- **People You May Know**: Suggends friends based on mutual connections
- **Mutual Friend Count**: Shows how many friends you have in common

### Social Graph Analysis
- Find all mutual friends between any two users
- Analyze the complete friendship network

### Content Relationships
- Track which users created which posts
- Easily find all posts by a specific user

</details>

## 🔍 Sample Queries

<details>
<summary>📝 Query examples</summary>

### Find Mutual Friends
```cypher
MATCH path = ((a:PERSON {name: 'Person2'})-[:FREIND_WITH]->(b:PERSON)<-[:FREIND_WITH]-(c:PERSON {name: 'Person3'}))
RETURN path;
```

### Friend Recommendations
```cypher
MATCH (p:PERSON)-[:FREIND_WITH]-(friend)-[:FREIND_WITH]-(suggested)
WHERE NOT (p)-[:FREIND_WITH]-(suggested) AND p <> suggested
RETURN suggested.name AS `Friends You May Know`, count(*) AS `mutual friends`
ORDER BY `mutual friends` DESC
LIMIT 10;
```

### User's Posts
```cypher
MATCH (p:PERSON {name: 'Person3'})-[:POSTED]->(posts)
RETURN posts.content;
```

</details>

## ⚡ Performance Optimization

<details>
<summary>🚀 Performance tips</summary>

- Created index on `PERSON(name)` for faster lookups:
  ```cypher
  CREATE INDEX person_name_idx FOR (p:PERSON) ON (p.name);
  ```
- Used `LIMIT` clauses to prevent Cartesian products
- Structured queries to minimize path traversals
- Random friendship generation avoids over-connecting the graph

</details>

## 🚀 Future Enhancements

<details>
<summary>🔮 Planned improvements</summary>

1. Add user profiles with more attributes (age, location, interests)
2. Implement post likes and comments
3. Add timestamp to posts and friendships
4. Create weighted friendships based on interaction frequency
5. Implement community detection algorithms
6. Add visualization dashboard with Neo4j Bloom

</details>

---

**📊 Current Stats** (run these to see your network size):
```cypher
MATCH (p:PERSON) RETURN count(p) AS Users;
MATCH (post:POST) RETURN count(post) AS Posts;
MATCH ()-[r:FRIEND_WITH]-() RETURN count(r) AS Friendships;
```
