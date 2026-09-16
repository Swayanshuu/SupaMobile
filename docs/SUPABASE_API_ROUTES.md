# Supabase API Routes & Payload Reference

This document provides a comprehensive, field-by-field reference of every Supabase API route utilized by **SupaMobile**, including the authentication mechanism, query parameters, request bodies, and exact JSON responses returned by Supabase.

---

## Table of Contents
1. [Overview & Authentication Architecture](#overview--authentication-architecture)
2. [Supabase Management API (`api.supabase.com/v1`)](#1-supabase-management-api)
   - [List Projects](#get-projects)
   - [Retrieve Project API Keys](#get-projectsrefapi-keys)
   - [Project Infrastructure Details](#get-projectsref)
   - [Project Compute Addons](#get-projectsrefbillingaddons)
   - [API Request Counts (Time Series)](#get-projectsrefanalyticsendpointsusageapi-counts)
   - [Total API Request Aggregate](#get-projectsrefanalyticsendpointsusageapi-requests-count)
   - [Analytics & System Logs Query Engine](#get-projectsrefanalyticsendpointslogsall)
   - [Direct Database Query Runner](#post-projectsrefdatabasequery)
   - [List Edge Functions](#get-projectsreffunctions)
   - [List Function Secrets](#get-projectsrefsecrets)
3. [Supabase Project Service & REST APIs (`{ref}.supabase.co`)](#2-supabase-project-service--rest-apis)
   - [Admin Auth Users List & Total Count](#get-authv1adminusers)
   - [List Storage Buckets](#get-storagev1bucket)
   - [List Storage Objects / Folders](#post-storagev1objectlistbucketid)
   - [Table Data Fetch (PostgREST)](#get-restv1tablename)
   - [Insert Table Row (PostgREST)](#post-restv1tablename)
   - [Update Table Row (PostgREST)](#patch-restv1tablename)
   - [Delete Table Row (PostgREST)](#delete-restv1tablename)
   - [Prometheus Host Metrics](#get-customerv1privilegedmetrics)
4. [Realtime WebSocket Subscriptions](#3-realtime-websocket-subscriptions)
5. [Error Responses & Handling](#4-error-responses--handling)

---

## Overview & Authentication Architecture

SupaMobile communicates with Supabase across three distinct security contexts:

| Layer | Base URL | Auth Header | Description |
|---|---|---|---|
| **Management API** | `https://api.supabase.com/v1` | `Authorization: Bearer <PERSONAL_ACCESS_TOKEN>` | Administrative controls, project listings, analytics, SQL execution, Edge Functions. |
| **Project Service API** | `https://<ref>.supabase.co` | `Authorization: Bearer <SERVICE_ROLE_KEY>`<br>`apikey: <SERVICE_ROLE_KEY>` | Auth admin endpoints, storage bucket inspection, administrative table mutations. |
| **Project Client API** | `https://<ref>.supabase.co` | `Authorization: Bearer <ANON_KEY>`<br>`apikey: <ANON_KEY>` | Realtime WebSocket connection, public table reads. |

All keys are stored locally on the device using OS-level encrypted storage (`FlutterSecureStorage` via Android Keystore / iOS Keychain).

---

## 1. Supabase Management API

Base URL: `https://api.supabase.com/v1`  
Client Class: `ManagementApiClient` & `ManagementApi` (`lib/core/api/management_api.dart`)

---

### `GET /projects`

Retrieves all projects owned by or accessible to the account associated with the Personal Access Token (PAT).

* **Headers:**
  ```http
  Authorization: Bearer <PAT>
  Content-Type: application/json
  ```
* **Query Parameters:** None
* **SupaMobile Consumer:** `projectsProvider` (`lib/features/projects/projects_provider.dart`)
* **Response:** `200 OK`
  ```json
  [
    {
      "id": "abcdefghijklmnopqrst",
      "ref": "xypqfhlmtyurvwnzoasb",
      "name": "Production Database",
      "organization_id": "org_1234567890",
      "cloud_provider": "AWS",
      "region": "us-east-1",
      "status": "ACTIVE_HEALTHY",
      "created_at": "2024-01-15T08:30:00.000Z"
    }
  ]
  ```
* **Key Fields Used in App:**
  - `ref`: The unique project reference code used across all project-scoped requests.
  - `name`: Display name rendered on project cards and switcher drawers.
  - `region`: Cloud datacenter location.
  - `status`: Health status badge (`ACTIVE_HEALTHY`, `COMING_UP`, `INACTIVE`).

---

### `GET /projects/{ref}/api-keys`

Fetches the project's public anonymous key (`anon`) and secret administrative key (`service_role`).

* **Path Parameters:**
  - `ref` (string): Project reference identifier.
* **Headers:**
  ```http
  Authorization: Bearer <PAT>
  ```
* **SupaMobile Consumer:** `serviceRoleKeyProvider`, `anonKeyProvider` (`lib/core/providers/core_providers.dart`)
* **Response:** `200 OK`
  ```json
  [
    {
      "name": "anon",
      "api_key": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "tags": "anon"
    },
    {
      "name": "service_role",
      "api_key": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "tags": "service_role"
    }
  ]
  ```
* **How SupaMobile Uses This:**
  - Automatically extracts and caches `service_role` and `anon` in encrypted storage.
  - Enables subsequent direct project requests without requiring the user to manually copy keys.

---

### `GET /projects/{ref}`

Returns infrastructure specifications, database versions, and operational state.

* **Path Parameters:**
  - `ref` (string): Project reference identifier.
* **Headers:**
  ```http
  Authorization: Bearer <PAT>
  ```
* **SupaMobile Consumer:** `dashboardUsageProvider` (`lib/features/dashboard/dashboard_provider.dart`)
* **Response:** `200 OK`
  ```json
  {
    "id": "xypqfhlmtyurvwnzoasb",
    "name": "Production Database",
    "region": "us-east-1",
    "cloud_provider": "AWS",
    "status": "ACTIVE_HEALTHY",
    "database": {
      "host": "db.xypqfhlmtyurvwnzoasb.supabase.co",
      "version": "15.1.0.116"
    },
    "created_at": "2024-01-15T08:30:00.000Z"
  }
  ```
* **Key Fields Used in App:**
  - `cloud_provider`, `region`: Rendered in the Infrastructure card and Dashboard headers.
  - `database.version`: Postgres engine version displayed in Dashboard & Infrastructure screens.

---

### `GET /projects/{ref}/billing/addons`

Retrieves active infrastructure addons, specifically compute instance sizing (Micro, Small, Medium, etc.).

* **Path Parameters:**
  - `ref` (string): Project reference identifier.
* **Headers:**
  ```http
  Authorization: Bearer <PAT>
  ```
* **SupaMobile Consumer:** `dashboardUsageProvider` (`lib/features/dashboard/dashboard_provider.dart`)
* **Response:** `200 OK`
  ```json
  [
    {
      "type": "compute_instance",
      "variant": "ci_micro"
    }
  ]
  ```
* **How SupaMobile Uses This:**
  - Translates `ci_micro` $\rightarrow$ `t4g.nano`
  - Translates `ci_small` $\rightarrow$ `t4g.small`
  - Defaults to `Free` when no paid compute addon is active.

---

### `GET /projects/{ref}/analytics/endpoints/usage.api-counts`

Fetches time-series data points of API request volumes partitioned by subsystem.

* **Path Parameters:**
  - `ref` (string): Project reference identifier.
* **Query Parameters:**
  - `interval` (string, required): Aggregation window (`1hr`, `1day`, `7d`, `30d`).
* **Headers:**
  ```http
  Authorization: Bearer <PAT>
  ```
* **SupaMobile Consumer:** `AnalyticsApi.getApiCounts` (`lib/core/api/analytics_api.dart`)
* **Response:** `200 OK`
  ```json
  {
    "result": [
      {
        "timestamp": "2026-09-16T12:00:00Z",
        "total_requests": 1420,
        "database_requests": 950,
        "auth_requests": 210,
        "storage_requests": 180,
        "realtime_requests": 80
      },
      {
        "timestamp": "2026-09-16T13:00:00Z",
        "total_requests": 1680,
        "database_requests": 1100,
        "auth_requests": 320,
        "storage_requests": 190,
        "realtime_requests": 70
      }
    ]
  }
  ```
* **How SupaMobile Uses This:**
  - Parsed into `ApiUsagePoint` models in Dart.
  - Renders line charts and sparklines (`fl_chart`) on the interactive dashboard.
  - Aggregated dynamically to display Total, DB, Auth, Storage, and Realtime request counts.

---

### `GET /projects/{ref}/analytics/endpoints/usage.api-requests-count`

Fetches pre-aggregated total request counts across a given window.

* **Path Parameters:**
  - `ref` (string): Project reference identifier.
* **Query Parameters:**
  - `interval` (string, optional): Aggregation timeframe (`1d`, `7d`, `30d`).
* **Headers:**
  ```http
  Authorization: Bearer <PAT>
  ```
* **SupaMobile Consumer:** `AnalyticsApi.getTotalApiRequestsCount` (`lib/core/api/analytics_api.dart`)
* **Response:** `200 OK`
  ```json
  {
    "result": [
      {
        "count": 48291
      }
    ]
  }
  ```

---

### `GET /projects/{ref}/analytics/endpoints/logs.all`

Supabase's managed Logflare / BigQuery analytics endpoint. Executes SQL statements against structured log collections.

* **Path Parameters:**
  - `ref` (string): Project reference identifier.
* **Query Parameters:**
  - `sql` (string, required): SQL query executed against internal log tables.
  - `iso_timestamp_start` (ISO 8601 string, required): Query start time.
  - `iso_timestamp_end` (ISO 8601 string, required): Query end time.
* **Headers:**
  ```http
  Authorization: Bearer <PAT>
  ```
* **SupaMobile Consumer:** `ManagementApi.getLogs` (`lib/core/api/management_api.dart`) and `LogsProvider` (`lib/features/logs/logs_provider.dart`)

#### Log Collections & SQL Queries:

1. **API Gateway / PostgREST (`edge_logs`)**:
   ```sql
   SELECT 
     DATETIME(timestamp) as time,
     t.event_message as msg,
     r.method, 
     r.path, 
     rsp.status_code
   FROM edge_logs as t
   CROSS JOIN UNNEST(t.metadata) as m
   CROSS JOIN UNNEST(m.request) as r
   CROSS JOIN UNNEST(m.response) as rsp
   WHERE true [AND t.event_message LIKE '%filter%']
   ORDER BY timestamp DESC 
   LIMIT 100
   ```

2. **Postgres Database (`postgres_logs`)**:
   ```sql
   SELECT
     DATETIME(timestamp) as time,
     t.event_message as msg,
     p.error_severity,
     p.user_name,
     p.query
   FROM postgres_logs as t
   CROSS JOIN UNNEST(t.metadata) as m
   CROSS JOIN UNNEST(m.parsed) as p
   WHERE true [AND t.event_message LIKE '%filter%']
   ORDER BY timestamp DESC
   LIMIT 100
   ```

3. **Auth (`auth_logs`)**:
   ```sql
   SELECT
     DATETIME(timestamp) as time,
     t.event_message as msg,
     p.status_code,
     p.method,
     p.path
   FROM auth_logs as t
   CROSS JOIN UNNEST(t.metadata) as m
   CROSS JOIN UNNEST(m.request) as p
   WHERE true [AND t.event_message LIKE '%filter%']
   ORDER BY timestamp DESC
   LIMIT 100
   ```

4. **Storage (`storage_logs`)**:
   ```sql
   SELECT 
     DATETIME(timestamp) as time, 
     t.event_message as msg,
     r.method, 
     r.path, 
     r.status_code
   FROM storage_logs as t
   CROSS JOIN UNNEST(t.metadata) as m
   CROSS JOIN UNNEST(m.request) as r
   WHERE true [AND t.event_message LIKE '%filter%']
   ORDER BY timestamp DESC 
   LIMIT 100
   ```

5. **Edge Functions (`function_logs`)**:
   ```sql
   SELECT
     DATETIME(timestamp) as time,
     t.event_message as msg,
     m.level,
     m.function_id
   FROM function_logs as t
   CROSS JOIN UNNEST(t.metadata) as m
   WHERE true [AND t.event_message LIKE '%filter%']
   ORDER BY timestamp DESC
   LIMIT 100
   ```

* **Sample Response:** `200 OK`
  ```json
  {
    "result": [
      {
        "time": "2026-09-16 12:45:10",
        "msg": "GET /rest/v1/posts 200 OK",
        "status_code": 200,
        "method": "GET",
        "path": "/rest/v1/posts"
      }
    ]
  }
  ```

---

### `POST /projects/{ref}/database/query`

Executes arbitrary SQL queries directly against the project's PostgreSQL engine via the Management API.

* **Path Parameters:**
  - `ref` (string): Project reference identifier.
* **Headers:**
  ```http
  Authorization: Bearer <PAT>
  Content-Type: application/json
  ```
* **Request Body:**
  ```json
  {
    "query": "SELECT * FROM information_schema.tables WHERE table_schema = 'public';"
  }
  ```
* **SupaMobile Consumer:**
  - SQL Editor (`lib/features/sql/sql_editor_provider.dart`)
  - Table Catalog (`lib/features/tables/tables_provider.dart`)
  - Database Insights: Indexes, Triggers, Functions, Publications (`lib/features/database/database_insights_provider.dart`)
  - Auth Analytics: Growth & Status (`lib/features/auth_users/auth_analytics_provider.dart`)
  - Infrastructure Metrics (`lib/features/infrastructure/infrastructure_provider.dart`)

* **Sample Queries Executed by the App:**

| Feature | Query | Returned Data Structure |
|---|---|---|
| **List Tables** | `SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';` | `[{"table_name": "posts"}, {"table_name": "profiles"}]` |
| **Rename Table** | `ALTER TABLE "old_name" RENAME TO "new_name";` | `[]` |
| **Drop Table** | `DROP TABLE "table_name";` | `[]` |
| **Triggers** | `SELECT event_object_schema, event_object_table, trigger_name, event_manipulation, action_timing, action_statement FROM information_schema.triggers;` | Array of trigger metadata objects |
| **Indexes** | `SELECT schemaname, tablename, indexname, indexdef FROM pg_indexes WHERE schemaname NOT IN ('pg_catalog', 'information_schema');` | Array of index definitions |
| **Database Functions** | `SELECT n.nspname as schema_name, p.proname as function_name, pg_get_function_arguments(p.oid) as arguments, pg_get_function_result(p.oid) as result_type FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname NOT IN ('pg_catalog', 'information_schema');` | Array of function signatures & schemas |
| **Publications** | `SELECT pubname, puballtables, pubinsert, pubupdate, pubdelete FROM pg_publication;` | Array of replication publication settings |
| **Auth Providers** | `SELECT provider, count(*) as user_count FROM auth.identities GROUP BY provider;` | `[{"provider": "email", "user_count": 120}, {"provider": "google", "user_count": 45}]` |
| **User Growth (30d)** | `SELECT date_trunc('day', created_at)::date as date, count(*) as count FROM auth.users WHERE created_at > now() - interval '30 days' GROUP BY 1 ORDER BY 1;` | `[{"date": "2026-09-01", "count": 12}, ...]` |
| **User Confirmation Status** | `SELECT CASE WHEN confirmed_at IS NOT NULL THEN 'Confirmed' ELSE 'Unconfirmed' END as status, count(*) as count FROM auth.users GROUP BY 1;` | `[{"status": "Confirmed", "count": 280}, ...]` |
| **Active DB Connections** | `SELECT count(*) FROM pg_stat_activity;` | `[{"count": 7}]` |
| **Database Disk Size** | `SELECT pg_database_size(current_database());` | `[{"pg_database_size": 28419200}]` |
| **Tables Without RLS** | `SELECT count(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = false;` | `[{"count": 1}]` |

---

### `GET /projects/{ref}/functions`

Lists all deployed Supabase Edge Functions.

* **Path Parameters:**
  - `ref` (string): Project reference identifier.
* **Headers:**
  ```http
  Authorization: Bearer <PAT>
  ```
* **SupaMobile Consumer:** `edgeFunctionsProvider` (`lib/features/functions/functions_provider.dart`)
* **Response:** `200 OK`
  ```json
  [
    {
      "id": "fn_01ha123456789",
      "slug": "send-welcome-email",
      "name": "send-welcome-email",
      "status": "ACTIVE",
      "version": 3,
      "created_at": 1705300000000,
      "updated_at": 1705350000000
    }
  ]
  ```
* **How SupaMobile Uses This:**
  - Displays function name, deployment state, and last update timestamp.
  - Constructs the public execution URL: `https://<ref>.supabase.co/functions/v1/<name>`.

---

### `GET /projects/{ref}/secrets`

Lists environment secrets configured for Edge Functions.

* **Path Parameters:**
  - `ref` (string): Project reference identifier.
* **Headers:**
  ```http
  Authorization: Bearer <PAT>
  ```
* **SupaMobile Consumer:** `secretsProvider` (`lib/features/functions/functions_provider.dart`)
* **Response:** `200 OK`
  ```json
  [
    {
      "name": "STRIPE_SECRET_KEY",
      "value": "sk_test_••••••••"
    },
    {
      "name": "RESEND_API_KEY",
      "value": "re_••••••••"
    }
  ]
  ```

---

## 2. Supabase Project Service & REST APIs

Base URL: `https://<ref>.supabase.co`  
Client Classes: `ProjectApiClient` & `ProjectApi` (`lib/core/api/project_api.dart`, `lib/core/api/project_api_client.dart`)

---

### `GET /auth/v1/admin/users`

Administrative user management endpoint.

* **Headers:**
  ```http
  Authorization: Bearer <SERVICE_ROLE_KEY>
  apikey: <SERVICE_ROLE_KEY>
  Content-Type: application/json
  ```
* **Query Parameters:**
  - `page` (int, default: 1)
  - `per_page` (int, default: 50)
* **SupaMobile Consumer:** `ProjectApiClient.getAuthUsers`, `ProjectApiClient.getAuthUserCount` (`lib/core/api/project_api_client.dart`), `authUsersProvider` (`lib/features/auth_users/auth_users_provider.dart`)
* **Response Headers:**
  - `x-total-count`: Total number of users registered in `auth.users` (read by SupaMobile without fetching all rows).
* **Response Body:** `200 OK`
  ```json
  {
    "users": [
      {
        "id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
        "aud": "authenticated",
        "role": "authenticated",
        "email": "developer@example.com",
        "email_confirmed_at": "2024-01-15T09:00:00.000Z",
        "phone": "",
        "confirmed_at": "2024-01-15T09:00:00.000Z",
        "last_sign_in_at": "2026-09-16T10:15:30.000Z",
        "app_metadata": {
          "provider": "email",
          "providers": ["email"]
        },
        "user_metadata": {
          "full_name": "Jane Doe",
          "avatar_url": "https://..."
        },
        "identities": [],
        "created_at": "2024-01-15T08:55:00.000Z",
        "updated_at": "2026-09-16T10:15:30.000Z"
      }
    ]
  }
  ```
* **Key Features in SupaMobile:**
  - High-performance total user counter reading the `x-total-count` header with `per_page=1`.
  - User Directory search and modal inspection.
  - Linked profile table feature: automatically joins `auth.users.id` with `public.profiles.id` or `user_id` to render the user's custom application profile in real-time.

---

### `GET /storage/v1/bucket`

Lists all storage buckets in the project.

* **Headers:**
  ```http
  Authorization: Bearer <SERVICE_ROLE_KEY>
  apikey: <SERVICE_ROLE_KEY>
  ```
* **SupaMobile Consumer:** `storageBucketsProvider` (`lib/features/storage/storage_provider.dart`)
* **Response:** `200 OK`
  ```json
  [
    {
      "id": "avatars",
      "name": "avatars",
      "owner": "",
      "public": true,
      "file_size_limit": 5242880,
      "allowed_mime_types": ["image/png", "image/jpeg"],
      "created_at": "2024-01-16T10:00:00.000Z",
      "updated_at": "2024-01-16T10:00:00.000Z"
    }
  ]
  ```

---

### `POST /storage/v1/object/list/{bucketId}`

Lists objects and nested folders within a bucket.

* **Path Parameters:**
  - `bucketId` (string): Unique bucket identifier.
* **Headers:**
  ```http
  Authorization: Bearer <SERVICE_ROLE_KEY>
  apikey: <SERVICE_ROLE_KEY>
  Content-Type: application/json
  ```
* **Request Body:**
  ```json
  {
    "prefix": "uploads/2026/",
    "limit": 100,
    "offset": 0,
    "sortBy": {
      "column": "name",
      "order": "asc"
    }
  }
  ```
* **SupaMobile Consumer:** `storageObjectsProvider` (`lib/features/storage/storage_provider.dart`)
* **Response:** `200 OK`
  ```json
  [
    {
      "name": "folder_name",
      "id": null
    },
    {
      "name": "hero.jpg",
      "id": "7bf3b3c8-a73c-43f1-b9de-49c0dcb2b6e1",
      "updated_at": "2026-09-15T14:30:00.000Z",
      "created_at": "2026-09-15T14:30:00.000Z",
      "last_accessed_at": "2026-09-15T14:30:00.000Z",
      "metadata": {
        "eTag": "\"1234567890abcdef\"",
        "size": 482910,
        "mimetype": "image/jpeg",
        "cacheControl": "max-age=3600"
      }
    }
  ]
  ```
* **Folder vs File Distinction in SupaMobile:**
  - If `id == null`, item is rendered as a navigable folder icon with chevron.
  - If `id != null`, item is rendered as a file with size format and metadata inspector.

---

### `GET /rest/v1/{tableName}`

PostgREST data query for viewing rows in a database table.

* **Path Parameters:**
  - `tableName` (string): Name of the public table.
* **Query Parameters:**
  - `select=*`: Select all columns.
  - `limit=100`: Up to 100 rows per view.
* **Headers:**
  ```http
  Authorization: Bearer <SERVICE_ROLE_KEY>
  apikey: <SERVICE_ROLE_KEY>
  ```
* **SupaMobile Consumer:** `tableDataProvider` (`lib/features/tables/tables_provider.dart`)
* **Response:** `200 OK`
  ```json
  [
    {
      "id": 1,
      "title": "Getting started with Supabase",
      "published": true,
      "created_at": "2026-01-10T12:00:00Z"
    }
  ]
  ```
* **UI Features Enabled:**
  - Horizontal & vertical scrollable data grid.
  - Dynamic client-side sorting by tapping column headers.
  - Client-side full-text search across all cell values.
  - Long-press any cell to trigger inline editing.

---

### `POST /rest/v1/{tableName}`

Inserts a new row into the specified table.

* **Headers:**
  ```http
  Authorization: Bearer <SERVICE_ROLE_KEY>
  apikey: <SERVICE_ROLE_KEY>
  Prefer: return=representation
  Content-Type: application/json
  ```
* **Request Body:**
  ```json
  {
    "title": "New Blog Post",
    "published": false
  }
  ```
* **Response:** `201 Created` with the newly created row representation.

---

### `PATCH /rest/v1/{tableName}?{pkCol}=eq.{pkVal}`

Updates row(s) matching the primary key filter.

* **Query Parameters:**
  - `{pkCol}=eq.{pkVal}`: Target row identifier filter (e.g. `id=eq.42`).
* **Headers:**
  ```http
  Authorization: Bearer <SERVICE_ROLE_KEY>
  apikey: <SERVICE_ROLE_KEY>
  Content-Type: application/json
  ```
* **Request Body:**
  ```json
  {
    "title": "Updated Title"
  }
  ```
* **Response:** `204 No Content` or `200 OK`.

---

### `DELETE /rest/v1/{tableName}?{pkCol}=eq.{pkVal}`

Deletes row(s) matching the primary key filter.

* **Query Parameters:**
  - `{pkCol}=eq.{pkVal}`: Target row identifier filter (e.g. `id=eq.42`).
* **Headers:**
  ```http
  Authorization: Bearer <SERVICE_ROLE_KEY>
  apikey: <SERVICE_ROLE_KEY>
  ```
* **Response:** `204 No Content`.

---

### `GET /customer/v1/privileged/metrics`

Prometheus metrics endpoint providing host resource telemetry.

* **Headers:**
  ```http
  Authorization: Bearer <SERVICE_ROLE_KEY>
  apikey: <SERVICE_ROLE_KEY>
  ```
* **SupaMobile Consumer:** `ManagementApi.getHostMetrics` (`lib/core/api/management_api.dart`)
* **Response:** `200 OK` (Prometheus text exposition format)
  ```text
  # HELP node_cpu_seconds_total Seconds the CPUs spent in each mode.
  # TYPE node_cpu_seconds_total counter
  node_cpu_seconds_total{cpu="0",mode="idle"} 41829.12
  node_memory_MemTotal_bytes 1048576000
  node_memory_MemAvailable_bytes 629145600
  ```

---

## 3. Realtime WebSocket Subscriptions

Client Class: `SupabaseClient` & `RealtimeChannel` (`lib/features/realtime/realtime_console_screen.dart`)

* **WebSocket URL:** `wss://<ref>.supabase.co/realtime/v1/websocket?apikey=<ANON_KEY>&vsn=1.0.0`
* **Subscribed Channel Events:**
  1. **Postgres Database Changes:**
     ```dart
     channel.onPostgresChanges(
       event: PostgresChangeEvent.all,
       schema: 'public',
       callback: (payload) { ... }
     );
     ```
     Receives live mutations (`INSERT`, `UPDATE`, `DELETE`) occurring across any public table.
  2. **Broadcast Messages:**
     ```dart
     channel.onBroadcast(
       event: '*',
       callback: (payload) { ... }
     );
     ```
     Receives live ephemeral broadcast payloads from client applications.
* **UI Features Enabled:**
  - Live console monitor showing timestamped events, event type, and table target.
  - Channel switcher allowing developers to subscribe to any custom channel name.

---

## 4. Error Responses & Handling

SupaMobile includes centralized HTTP status handling in `ManagementApiClient` and `ProjectApi`:

| HTTP Status | Code / Exception | Action Taken by SupaMobile |
|---|---|---|
| `401 Unauthorized` | `UNAUTHORIZED: PAT is invalid or expired` | Invalidates cached PAT and prompts the user to re-enter a valid access token in settings. |
| `429 Too Many Requests` | `RATE_LIMITED: Retry after <ms>` | Inspects the `x-ratelimit-reset` header and alerts user with cooldown time. |
| `5xx Server Error` | `HTTP 500: Internal Server Error` | Logged to in-memory `AppLogger` and user notified via snackbar. |
| Network Timeout | `TimeoutException (15s)` | Management and Project API calls are protected by a strict 15-second timeout to prevent UI freezes. |
