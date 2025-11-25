# Breaking the Rules

## Add **prerequisite_course_id** to the **courses** table
### The Reason Breaking the Rules
Storing prerequired_course_id as an array (or list) helps to reduce the number and query data faster for simple read requests, which reduces response time for mobile/web applications

### The Design Principle Violating
#### Contains only a single value
The prerequired_course_id field contains an array of course IDs, meaning it contains multiple instances of the same value type. This makes it a Multivalued Field.

#### Contains only an absolute minimum amount of redundant data

### Anticipated Effects
- It would be difficult to ensure that all course IDs in the array are valid IDs
- If a prerequisite course is deleted from the COURSE table, the system must search and delete that ID A from every prerequired_course_id array in the entire table
- Any queries that need to find courses based on prerequisite courses must use array/string functions (parsing functions), reducing the flexibility of SQL

### Action Taken Summary

|  |  |
| ---- | ---- |
| Rule | Database-Oriented Business Rule |
| Specific | Field-Specific abd Relationship-Specific |
| Affected structures | The `COURSES` table |
| Action | Add `prerequired_course_id` field with type is `array`. Normalization rules are broken to optimize data read performance for simple queries. |
| Date/Performer | 2025-11-24 - Cuong Doan 