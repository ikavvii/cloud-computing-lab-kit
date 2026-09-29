# Exam command sheet

Commands marked **host** run in PowerShell/terminal in the kit folder. Commands marked **container** run after `docker compose exec bigdata bash`. Paths beginning `/workspace` and `/lab` are Linux/HDFS paths, not Windows paths.

## Start here

```powershell
# HOST: only once after copying the exported kit (checks archive hash)
.\lab.ps1 import
docker compose up -d --no-build --pull never --wait bigdata
docker compose exec bigdata bash
```

```bash
# CONTAINER: show actual installation and processes
java -version
hadoop version
pig -version
jps
hdfs dfs -ls /
yarn node -list
```

HDFS console: <http://localhost:9870>. YARN console: <http://localhost:8088>. Job history: <http://localhost:19888>. Dockerfile and XML configs show download, environment variables, filesystem and YARN configuration. No SSH daemon is needed because the entrypoint starts the five daemons directly. JobHistoryServer lets Pig retrieve counters after a YARN job finishes.

## 3. CloudSim

```powershell
# HOST
docker compose run --rm --no-deps --pull never cloudsim minmin
docker compose run --rm --no-deps --pull never cloudsim roundrobin
```

Edit `labs/03-cloudsim/MinMinScheduling.java`. Both commands compile your current source, then run a real CloudSim simulation. Inspect `RESULT` and `SUMMARY` lines.

Explain Min-Min:

1. Estimate finish time for each remaining task on each VM: `VM available time + task length / VM MIPS`.
2. Choose the task/VM pair with the smallest finish time.
3. Bind that task to that VM and update the VM's available time.
4. Repeat until every task is assigned; submit tasks in this chosen order.

This is a **custom broker-level assignment policy**. `CloudletSchedulerSpaceShared` controls the execution queue inside each VM. `VmSchedulerTimeShared` shares host processing capacity between VMs. They are different scheduling levels.

Assumptions: independent single-core tasks, known instruction lengths, one task at a time per VM, no transfer delay, all VMs can be created. Time is simulation time, not wall-clock execution time. Min-Min can disadvantage long jobs; do not claim it always beats round-robin. This fixture is a comparison, not a proof: its ideal Min-Min makespan is 16 seconds versus 15 for round-robin, before simulator event effects. Change lengths/speeds to study other workloads.

## 4. Weather MapReduce

```bash
# CONTAINER: short route; threshold is optional
bash /workspace/labs/04-weather/run.sh 25

# Manual route
cd /workspace/labs/04-weather
mkdir -p /tmp/weather-exam
javac -cp "$(hadoop classpath --glob)" -d /tmp/weather-exam Weather.java
jar cf /tmp/weather.jar -C /tmp/weather-exam .
hdfs dfs -mkdir -p /lab/exam-weather
hdfs dfs -put -f weather.csv /lab/exam-weather/input.csv
# Choose a NEW output directory every run.
hadoop jar /tmp/weather.jar Weather /lab/exam-weather/input.csv /lab/exam-weather/output1 25
hdfs dfs -cat '/lab/exam-weather/output1/part-*'
```

Mapper: parse ISO date and Celsius temperature; emit `(date, temperature)`. Shuffle: group by date. Reducer: calculate the daily maximum and classify `>=25` as **Shiny Day**, otherwise **Cool Day**. Keep the problem sheet's exact label. Header/invalid rows are counted separately; invalid dates, missing temperatures and NaN are rejected.

The sheet does not specify how to combine repeated dates. This solution states a daily-maximum rule. If the examiner gives one record per date, there is no ambiguity. If the required rule is average/minimum/per-record classification, change the reducer accordingly. The parser expects two unquoted CSV fields, not NOAA fixed-width data.

Expected temperatures/classes: `25 Shiny`, `18.5 Cool`, `30 Shiny`, `-2 Cool`, `24.99 Cool`, `25.01 Shiny`.

## 5. Pig inventory audit

```bash
# CONTAINER
bash /workspace/labs/05-pig/run.sh Electronics 3.0

# Manual route
cd /workspace/labs/05-pig
hdfs dfs -mkdir -p /lab/catalog
hdfs dfs -put -f products.csv reviews.csv /lab/catalog/
pig -x mapreduce -param PRODUCTS=/lab/catalog/products.csv \
  -param REVIEWS=/lab/catalog/reviews.csv -param CATEGORY=Electronics \
  -param THRESHOLD=3.0 -param OUTPUT=/lab/catalog/flagged1 inventory.pig
hdfs dfs -cat '/lab/catalog/flagged1/part-*'
```

Flow: `LOAD → TRIM/FILTER/DISTINCT → category FILTER → LEFT OUTER JOIN → GROUP product_id → AVG/COUNT → FILTER → STORE`.

Output columns: product id, name, category, price, average rating, valid review count. Expected flagged ids: **P002** (average 2, count 2), **P004** (missing reviews), **P006** (no valid reviews). Missing average appears as an empty field. P005 equals the threshold and is **not** flagged because the condition is `<3`, not `<=3`.

`AVG` ignores null values; all-null reviews produce null. `COUNT(flat.rating)` counts non-null ratings, so an unmatched left-join row has count zero. Clean reviews **before** joining so a post-join filter does not remove products without reviews.

Assumptions: ratings are 1–5; product ids identify one consistent product; exact duplicate rows are removed. Conflicting catalog rows with the same id need an explicit resolution rule; do not silently use this script on such data. No quoted/embedded delimiters in these teaching datasets.

## 6. Hive sales

```powershell
# HOST: stop Hadoop first on low-memory machines
docker compose stop bigdata
docker compose up -d --no-build --pull never --wait --wait-timeout 420 hive
docker compose exec -T hive bash /workspace/beeline.sh -u jdbc:hive2://localhost:10000/default -n hive -f /workspace/sales.hql
docker compose exec hive beeline -u jdbc:hive2://localhost:10000/default -n hive
```

```sql
-- Inside Beeline after the host batch command created/loaded the table.
USE cloud_lab;
SELECT * FROM sales;
SELECT sale_id, amount,
       CAST(amount * CAST(0.9 AS DECIMAL(2,1)) AS DECIMAL(12,2)) AS discounted_amount,
       YEAR(sale_ts) AS sale_year, MONTH(sale_ts) AS sale_month
FROM sales;
!quit
```

Or host: `docker compose exec -T hive bash /workspace/beeline.sh -u jdbc:hive2://localhost:10000/default -n hive -f /workspace/sales.hql`. The wrapper supplies a terminal and reads SQL files through Beeline's batch parser, avoiding Hive 4.2's file-reader issue. Java preview/native-access flags are configured in Compose for its JLine terminal library. For interactive practice, type or paste SQL statements from `sales.hql` at the Beeline prompt.

| sale_id | amount | discounted_amount | year | month |
|---|---:|---:|---:|---:|
| 5001 | 500.00 | 450.00 | 2024 | 1 |
| 5002 | NULL | NULL | 2024 | 1 |
| 5003 | 1200.50 | 1080.45 | 2024 | 2 |
| 5004 | 750.25 | 675.23 | 2024 | 2 |
| 5005 | NULL | NULL | 2024 | 3 |
| 5006 | 2100.75 | 1890.68 | 2024 | 3 |
| 5007 | 850.00 | 765.00 | 2024 | 4 |
| 5008 | 450.50 | 405.45 | 2024 | 4 |

`DECIMAL(12,2)` stores money without binary floating-point approximation. Blank CSV amounts are null because of `NULL DEFINED AS ''`. `skip.header.line.count=1` ignores the header at read time; it does not physically strip the file. `LOAD ... LOCAL` reads the file on the Hive server/container. The external table is appropriate for raw CSV in Hive 4. A missing amount is unknown, not necessarily zero; use `COALESCE(amount,0)` only if the examiner wants zero substitution.

## 1–2. Cloud service models and dynamic CRUD

See [the cloud walkthrough](CLOUD-EXERCISES.md). Local practice:

```powershell
.\lab.ps1 web
```

Open <http://localhost:8000>, password `practice-only-change-me` for the default local setup. Add a product, read the list, update its price, delete it. Cloud proof requires the public HTTPS URL plus the provider's actual hosted database records. A local container is not itself a public-cloud service.

## Fast troubleshooting

| Symptom | Fix |
|---|---|
| Cannot connect to Docker engine | Open Docker Desktop; use Linux containers; wait for engine readiness |
| Docker Hub DNS/timeout during build | Check internet/VPN/proxy/Docker networking; retry build; do this before the exam |
| Image missing with `--pull never` | Import the exported `images.tar` first |
| Port already allocated | Stop the conflicting service or change the left/host port in compose.yaml |
| `FileAlreadyExistsException` / Pig output exists | Choose a new HDFS output directory; helper scripts do this automatically |
| Container exits / exit 137 | More Docker RAM or stop other heavy labs; inspect `docker compose logs --tail 80 SERVICE` |
| Pig never launches tasks | `yarn node -list`; check the YARN console and bigdata logs |
| CRLF / `bash\r` errors | Save shell files with LF line endings |
| Hive schema/table disappeared | Container was recreated; re-run `sales.hql` |
| Beeline says `Unable to create a terminal` | Use the bundled `beeline.sh` for batch commands; keep the Hive Java flags in Compose |
| Local web login does not persist | Local HTTP needs `COOKIE_SECURE=false`; cloud HTTPS should use true |
| Host source edit not visible | Keep the complete folder layout; rebuild web source changes |

Stop without deleting data: `docker compose --profile '*' stop`. Do not use `down -v` unless you intend to erase the kit's HDFS/PostgreSQL volumes.
