# CouchDB Detailed Reference Guide

Based on the laboratory exercises, here's a comprehensive table covering CouchDB concepts and operations:

## CouchDB Core Concepts

| Concept | Description | When to Use | Example |
|---------|-------------|-------------|---------|
| **Document** | JSON object with unique `_id` and `_rev` | Store any structured data | `{"_id": "item1", "product": "bread", "price": 2.2}` |
| **Database** | Container for documents | Organize related documents | Create database: `PUT /mystore` |
| **View** | MapReduce function for querying | Query and aggregate data | Map function to filter/transform docs |
| **Design Document** | Contains views, shows, lists | Group related views together | `_design/shopping` contains all shopping views |

## HTTP API Operations

| Operation | HTTP Method | URL Pattern | Purpose | Example |
|-----------|-------------|-------------|---------|---------|
| **List Databases** | GET | `/_all_dbs` | Show all databases | `curl http://server:5984/_all_dbs` |
| **Create Database** | PUT | `/{db}` | Create new database | `PUT /shopping_list` |
| **Delete Database** | DELETE | `/{db}` | Remove database | `DELETE /shopping_list` |
| **Create Document** | POST | `/{db}` | Insert document (auto ID) | `POST /shopping_list` with JSON body |
| **Create Document** | PUT | `/{db}/{id}` | Insert/update with specific ID | `PUT /shopping_list/item1` |
| **Get Document** | GET | `/{db}/{id}` | Retrieve document | `GET /shopping_list/item1` |
| **Update Document** | PUT | `/{db}/{id}` | Update existing document | Must include current `_rev` |
| **Delete Document** | DELETE | `/{db}/{id}?rev={rev}` | Remove document | Must specify revision |
| **Query View** | GET | `/{db}/_design/{ddoc}/_view/{view}` | Execute view | `GET /db/_design/shop/_view/by_store` |

## Authentication Methods

| Method | Usage | Example | When to Use |
|--------|-------|---------|-------------|
| **URL Credentials** | `http://user:pass@server` | `http://admin:ztb2020@server:5984` | Simple, not secure |
| **cURL -u Flag** | `-u 'user:pass'` | `curl -u 'admin:ztb2020' http://server` | More secure than URL |
| **Authorization Header** | `Authorization: Basic {base64}` | `Authorization: Basic YWRtaW46enRiMjAyMA==` | Most secure |

## View Types and Functions

| View Type | Map Function Purpose | Reduce Function Purpose | Example Use Case |
|-----------|---------------------|------------------------|------------------|
| **Simple List** | Filter and emit documents | None | Show all products by store |
| **Counting** | Emit 1 for each match | `_count` built-in | Count items per store |
| **Summing** | Emit numeric values | `_sum` built-in | Total prices per store |
| **Averaging** | Emit [sum, count] | Custom reduce | Average price per product |
| **Grouping** | Emit by category | Various | Group by store/product |

## MapReduce Patterns

### Pattern 1: Simple Filtering and Sorting
```javascript
// Map function for store/product/price view
function(doc) {
  if (doc.product && doc.price && doc.store) {
    emit([doc.store, doc.product], doc.price);
  }
}
```

### Pattern 2: Counting
```javascript
// Map function for counting items per store
function(doc) {
  if (doc.product && doc.store) {
    emit(doc.store, 1);
  }
}
// Reduce: _count
```

### Pattern 3: Average Calculation
```javascript
// Map function for average price per product
function(doc) {
  if (doc.product && doc.price) {
    emit(doc.product, [doc.price, 1]);
  }
}

// Reduce function for averaging
function(keys, values, rereduce) {
  var sum = 0;
  var count = 0;
  if (rereduce) {
    for (var i = 0; i < values.length; i++) {
      sum += values[i][0];
      count += values[i][1];
    }
  } else {
    for (var i = 0; i < values.length; i++) {
      sum += values[i][0];
      count += values[i][1];
    }
  }
  return [sum, count];
}
```

## Query Parameters

| Parameter | Purpose | Example | Effect |
|-----------|---------|---------|---------|
| `key` | Match exact key | `?key="Lidl"` | Only documents with key "Lidl" |
| `keys` | Match multiple keys | `?keys=["Lidl","Biedronka"]` | Documents matching any listed key |
| `startkey` | Range start | `?startkey="A"` | Keys >= "A" |
| `endkey` | Range end | `?endkey="M"` | Keys <= "M" |
| `group` | Group by key | `?group=true` | Group reduce results |
| `group_level` | Group by key prefix | `?group_level=1` | Group by first part of compound key |
| `include_docs` | Include full documents | `?include_docs=true` | Return documents, not just key/value |
| `descending` | Reverse order | `?descending=true` | Sort in reverse |
| `limit` | Limit results | `?limit=10` | Return max 10 results |
| `skip` | Skip results | `?skip=5` | Skip first 5 results |

## Document Structure Requirements

| Field | Required | Purpose | Example |
|-------|----------|---------|---------|
| `_id` | Auto-generated if missing | Unique document identifier | `"_id": "item_001"` |
| `_rev` | Auto-generated, required for updates | Revision tracking | `"_rev": "1-abc123"` |
| Custom fields | As needed | Application data | `"product": "bread"` |

## Error Handling

| HTTP Code | Meaning | Common Causes | Solution |
|-----------|---------|---------------|----------|
| 201 | Created | Successful document creation | Continue normally |
| 400 | Bad Request | Invalid JSON, missing fields | Check JSON syntax |
| 401 | Unauthorized | Wrong credentials | Verify username/password |
| 404 | Not Found | Database/document doesn't exist | Create database first |
| 409 | Conflict | Document revision mismatch | Get latest `_rev` and retry |
| 412 | Precondition Failed | Missing or wrong `_rev` | Include correct revision |

## Lab Exercise Solutions

### Exercise 2: Store/Product/Price View
```javascript
// Design Document: _design/shopping
// View: by_store_product
{
  "map": "function(doc) { if (doc.product && doc.price && doc.store) { emit([doc.store, doc.product], doc.price); } }"
}
```
**URL:** `GET /yourdb/_design/shopping/_view/by_store_product`

### Exercise 3: Count Items per Store
```javascript
// View: count_by_store
{
  "map": "function(doc) { if (doc.product && doc.store) { emit(doc.store, 1); } }",
  "reduce": "_count"
}
```
**URL:** `GET /yourdb/_design/shopping/_view/count_by_store?group=true`

### Exercise 4: Average Price per Product
```javascript
// View: avg_price_by_product
{
  "map": "function(doc) { if (doc.product && doc.price) { emit(doc.product, [doc.price, 1]); } }",
  "reduce": "function(keys, values, rereduce) { var sum = 0; var count = 0; if (rereduce) { for (var i = 0; i < values.length; i++) { sum += values[i][0]; count += values[i][1]; } } else { for (var i = 0; i < values.length; i++) { sum += values[i][0]; count += values[i][1]; } } return [sum, count]; }"
}
```

### Exercise 5: All Items at Lidl
**URL:** `GET /yourdb/_design/shopping/_view/by_store_product?startkey=["Lidl"]&endkey=["Lidl",{}]`

### Exercise 6: Count Items at Biedronka
**URL:** `GET /yourdb/_design/shopping/_view/count_by_store?key="Biedronka"`

## Best Practices

| Practice | Reason | Example |
|----------|--------|---------|
| **Validate in Map** | Avoid runtime errors | `if (doc.field && doc.field2)` |
| **Use Compound Keys** | Enable complex queries | `emit([store, product], price)` |
| **Handle Rereduce** | Ensure correct aggregation | Check `rereduce` parameter |
| **Index Strategically** | Optimize query performance | Create views for common queries |
| **Use Built-in Reduces** | Better performance | `_count`, `_sum`, `_stats` |