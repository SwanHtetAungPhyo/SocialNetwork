# CouchDB emit() and rereduce Detailed Explanation

## Understanding emit() Function

### What emit() Does
The `emit()` function is the core of CouchDB's MapReduce system. It's used in map functions to output key-value pairs that will be indexed and potentially reduced.

**Syntax:** `emit(key, value)`

### How emit() Works Internally

```javascript
function(doc) {
  // CouchDB calls this function for EVERY document in the database
  // If you call emit(), it creates an index entry
  emit(key, value);
  // You can call emit() multiple times per document
}
```

### Key Design Principles

| Aspect | Explanation | Example |
|--------|-------------|---------|
| **Key determines grouping** | Documents with same key are grouped together | `emit("Lidl", 1)` - all Lidl items grouped |
| **Key determines sorting** | Results sorted by key | `emit([store, product], price)` - sorted by store, then product |
| **Value is what gets reduced** | The value parameter is passed to reduce function | `emit(store, price)` - prices get summed/averaged |
| **Multiple emits allowed** | One document can emit multiple key-value pairs | Tag system, multiple categories |

### emit() Key Patterns

#### 1. Simple Key (String/Number)
```javascript
function(doc) {
  if (doc.store) {
    emit(doc.store, 1); // Key: store name, Value: 1 for counting
  }
}
// Results: {"Lidl": [1,1,1], "Biedronka": [1,1]}
```

#### 2. Compound Key (Array)
```javascript
function(doc) {
  if (doc.store && doc.product) {
    emit([doc.store, doc.product], doc.price);
  }
}
// Results sorted by: ["Auchan", "moon rocket"], ["Biedronka", "bread"], ["Lidl", "tomato"]
```

#### 3. Date-based Key
```javascript
function(doc) {
  if (doc.timestamp) {
    var date = new Date(doc.timestamp);
    emit([date.getFullYear(), date.getMonth(), date.getDate()], doc.amount);
  }
}
// Groups by year/month/day for time-series analysis
```

#### 4. Multiple Emits per Document
```javascript
function(doc) {
  if (doc.tags) {
    for (var i = 0; i < doc.tags.length; i++) {
      emit(doc.tags[i], 1); // Each tag gets counted
    }
  }
}
// Document with tags ["food", "dairy"] emits twice
```

### emit() Value Patterns

#### 1. Simple Values
```javascript
emit(doc.category, 1);              // For counting
emit(doc.category, doc.price);      // For summing
emit(doc.category, doc);            // Emit whole document
```

#### 2. Complex Values for Averaging
```javascript
emit(doc.product, [doc.price, 1]);  // [sum, count] for average calculation
```

#### 3. Object Values
```javascript
emit(doc.store, {
  product: doc.product,
  price: doc.price,
  quantity: doc.quantity
});
```

## Understanding rereduce

### What is rereduce?

Reduce functions are called multiple times in CouchDB's distributed architecture. The `rereduce` parameter tells you whether you're reducing:
- **Initial reduction** (`rereduce = false`): Working with raw emitted values
- **Re-reduction** (`rereduce = true`): Working with results from previous reduce operations

### Why rereduce Exists

```
Documents: [doc1, doc2, doc3, doc4, doc5, doc6]
           ↓
Map Phase: emit() creates key-value pairs
           ↓
Step 1: Reduce groups 1-3 → result1
Step 2: Reduce groups 4-6 → result2  (rereduce = false)
           ↓
Step 3: Reduce [result1, result2] → final  (rereduce = true)
```

### rereduce Examples

#### Example 1: Simple Counting
```javascript
// Map function
function(doc) {
  if (doc.store) {
    emit(doc.store, 1);
  }
}

// Reduce function
function(keys, values, rereduce) {
  // This works for both rereduce=true and rereduce=false
  // because we're always just summing numbers
  return sum(values);
}

// Step 1 (rereduce=false): values = [1, 1, 1] → result = 3
// Step 2 (rereduce=false): values = [1, 1] → result = 2  
// Step 3 (rereduce=true):  values = [3, 2] → result = 5
```

#### Example 2: Average Calculation (Complex)
```javascript
// Map function - emit [sum, count] pairs
function(doc) {
  if (doc.product && doc.price) {
    emit(doc.product, [doc.price, 1]);
  }
}

// Reduce function - must handle rereduce properly
function(keys, values, rereduce) {
  var totalSum = 0;
  var totalCount = 0;
  
  if (rereduce) {
    // values contains results from previous reduce operations
    // Each value is [sum, count] from previous reductions
    for (var i = 0; i < values.length; i++) {
      totalSum += values[i][0];    // Sum of sums
      totalCount += values[i][1];  // Sum of counts
    }
  } else {
    // values contains raw emitted values
    // Each value is [price, 1] from map function
    for (var i = 0; i < values.length; i++) {
      totalSum += values[i][0];    // Sum of prices
      totalCount += values[i][1];  // Sum of 1s
    }
  }
  
  return [totalSum, totalCount];
}

// To get final average: totalSum / totalCount
```

### rereduce Scenarios Breakdown

#### Scenario 1: First Reduction (rereduce = false)
```javascript
// Input from map: 
// emit("bread", [2.2, 1])
// emit("bread", [2.0, 1]) 
// emit("bread", [2.5, 1])

// values = [[2.2, 1], [2.0, 1], [2.5, 1]]
// rereduce = false
// result = [6.7, 3]  // sum=6.7, count=3
```

#### Scenario 2: Re-reduction (rereduce = true)
```javascript
// Input from previous reductions:
// Previous result 1: [6.7, 3]
// Previous result 2: [4.1, 2]

// values = [[6.7, 3], [4.1, 2]]
// rereduce = true  
// result = [10.8, 5]  // total sum=10.8, total count=5
// Average = 10.8/5 = 2.16
```

### Common rereduce Mistakes

#### ❌ Wrong: Not handling rereduce
```javascript
function(keys, values, rereduce) {
  var sum = 0;
  for (var i = 0; i < values.length; i++) {
    sum += values[i][0]; // Assumes values[i] is always [price, 1]
  }
  return sum; // Breaks when rereduce=true
}
```

#### ✅ Correct: Proper rereduce handling
```javascript
function(keys, values, rereduce) {
  var sum = 0;
  var count = 0;
  
  for (var i = 0; i < values.length; i++) {
    if (rereduce) {
      // values[i] is [sum, count] from previous reduce
      sum += values[i][0];
      count += values[i][1];
    } else {
      // values[i] is [price, 1] from map
      sum += values[i][0];  
      count += values[i][1];
    }
  }
  return [sum, count];
}
```

### Built-in Reduce Functions

CouchDB provides built-in reduce functions that handle rereduce automatically:

| Function | Purpose | Use Case |
|----------|---------|----------|
| `_count` | Count documents | `emit(category, 1)` |
| `_sum` | Sum numeric values | `emit(category, amount)` |
| `_stats` | Statistical summary | `emit(category, value)` → {sum, count, min, max, sumsqr} |

### Advanced emit() Techniques

#### 1. Conditional Emit
```javascript
function(doc) {
  if (doc.status === 'active' && doc.price > 10) {
    emit([doc.category, doc.subcategory], doc.price);
  }
  // No emit() = document not included in view
}
```

#### 2. Emit for Different Query Patterns
```javascript
function(doc) {
  if (doc.product && doc.store && doc.price) {
    // Enable querying by store
    emit(['by_store', doc.store], {product: doc.product, price: doc.price});
    
    // Enable querying by product
    emit(['by_product', doc.product], {store: doc.store, price: doc.price});
    
    // Enable querying by price range
    emit(['by_price', doc.price], {store: doc.store, product: doc.product});
  }
}
```

#### 3. Hierarchical Keys
```javascript
function(doc) {
  if (doc.timestamp && doc.amount) {
    var date = new Date(doc.timestamp);
    emit([date.getFullYear(), date.getMonth(), date.getDate(), date.getHours()], doc.amount);
  }
}

// Query examples:
// ?group_level=1  → group by year
// ?group_level=2  → group by year/month  
// ?group_level=3  → group by year/month/day
// ?group_level=4  → group by year/month/day/hour
```

This comprehensive understanding of `emit()` and `rereduce` enables you to build powerful, efficient views in CouchDB that can handle complex aggregations and queries.