CREATE (p0:PERSON {name: 'Person1'});
CREATE (p1:PERSON {name: 'Person2'});
CREATE (p2:PERSON {name: 'Person3'});
CREATE (p3:PERSON {name: 'Person4'});
CREATE (p4:PERSON {name: 'Person5'});
CREATE (p5:PERSON {name: 'Person6'});
CREATE (p6:PERSON {name: 'Person7'});
CREATE (p7:PERSON {name: 'Person8'});
CREATE (p8:PERSON {name: 'Person9'});
CREATE (p9:PERSON {name: 'Person10'});


CREATE (post0:POST {content: 'Post content 1 by Person3'});
CREATE (post1:POST {content: 'Post content 2 by Person6'});
CREATE (post2:POST {content: 'Post content 3 by Person3'});
CREATE (post3:POST {content: 'Post content 4 by Person5'});
CREATE (post4:POST {content: 'Post content 5 by Person5'});


MATCH (a:PERSON {name: 'Person3'}) LIMIT 1
MATCH (p:POST {content: 'Post content 1 by Person3'}) LIMIT 1
CREATE (a)-[:POSTED]->(p);
MATCH (a:PERSON {name: 'Person6'}) LIMIT 1
MATCH  (p:POST {content: 'Post content 2 by Person6'}) LIMIT 1
CREATE (a)-[:POSTED]->(p);
MATCH (a:PERSON {name: 'Person3'}) LIMIT 1
MATCH (p:POST {content: 'Post content 3 by Person3'}) LIMIT 1
CREATE (a)-[:POSTED]->(p);
MATCH (a:PERSON {name: 'Person5'}) LIMIT 1
MATCH (p:POST {content: 'Post content 4 by Person5'}) LIMIT 1
CREATE (a)-[:POSTED]->(p);
MATCH (a:PERSON {name: 'Person5'}) LIMIT 1
MATCH (p:POST {content: 'Post content 5 by Person5'})  LIMIT 1
CREATE (a)-[:POSTED]->(p);


-- Count the persons nodes first to avoid the cartisien product
MATCH (p:PERSON ) RETURN count(p);
MATCH (p:POST ) RETURN count(p);


--- Create the friend relationship
MATCH (a:PERSON) , (b:PERSON)
WHERE id(a) < id(b) AND rand() < 5
WITH a, b
LIMIT 20
MERGE  (a)-[:FREIND_WITH]-(b);

-- Count the created relationship
MATCH (a:PERSON)-[:FRIEND_WITH]-(b:PERSON)
RETURN  a.name, b.name;


-- Indexing on the name of the person for the faster look up
CREATE INDEX person_name_idx FOR (p:PERSON) ON (p.name);

-- All mutual friend of the two Person
MATCH path = ((a:PERSON {name: 'Person2'})-[:FREIND_WITH]->(b:PERSON)<-[:FREIND_WITH]-(c:PERSON {name: 'Person3'}))
RETURN path;


-- List All Friends You may know
MATCH (p:PERSON)-[:FREIND_WITH]-(friend)-[:FREIND_WITH]-(suggested)
WHERE NOT (p)-[:FREIND_WITH]-(suggested) AND p <> suggested
RETURN  DISTINCT  suggested.name  AS `Friends You May Know`
LIMIT 10

-- List all Friends You may know with the   mutual Friend
MATCH (p:PERSON)-[:FREIND_WITH]-(friend)-[:FREIND_WITH]-(suggested)
WHERE NOT (p)-[:FREIND_WITH]-(suggested) AND p <> suggested
RETURN    suggested.name  AS `Friends You May Know` , count(*)  as `mutual friends`
LIMIT 10
---

MATCH (p:PERSON {name: "Swan"})-[:FREIND_WITH]-(friend)-[:FREIND_WITH]-(suggested)
WHERE NOT (p)-[:FREIND_WITH]-(suggested) AND p <> suggested
RETURN suggested.name AS `Friend You May Know`, COUNT(*) AS mutualFriends
ORDER BY mutualFriends DESC
LIMIT 10;