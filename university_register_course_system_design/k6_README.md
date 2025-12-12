# K6 Scripts for Course Registration System

This directory contains K6 scripts for:
1. **Data Insertion**: Insert students and courses via API
2. **Load Testing**: Test concurrent registration scenarios

## Scripts Overview

- **`insert_data.js`**: Inserts 200 students and 2 courses via API endpoints
- **`test_without_transaction.js`**: Load tests concurrent registration with capacity constraints

## Prerequisites

1. **Install K6**: 
   - **Windows**: Download from [k6.io](https://k6.io/docs/getting-started/installation/) or use `choco install k6`
   - **macOS**: `brew install k6`
   - **Linux**: Follow [official installation guide](https://k6.io/docs/getting-started/installation/)

2. **Start the API**: Make sure the API is running
   ```
   docker-compose up -d
   ```

## Inserting Data via API

### Insert 200 Students and 2 Courses

```
k6 run insert_data.js
```

## Running the Load Test

### Basic Test (200 students, course CS101)

```
k6 run test_without_transaction.js
```
