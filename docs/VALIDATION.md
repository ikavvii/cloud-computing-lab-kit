# Validation status

Checked 2026-09-29 on this Windows laptop with Docker Desktop using Linux x86-64 containers. The college PC remains a separate environment to verify.

- Docker Compose configuration: passed parsing.
- PowerShell launcher: passed syntax parsing.
- Python sources: passed compilation.
- Shell scripts, LF line endings and Hadoop XML: passed syntax/format checks.
- Flask image: built successfully; web and PostgreSQL 18.1 containers healthy.
- Real PostgreSQL integration: passed create/read/update/delete, login, CSRF rejection, invalid-price rejection and HTML-escaping checks. Test records were removed by the test's own cleanup.
- Local login page: inspected in the browser; rendered correctly.
- All three custom images built successfully; official Hive and PostgreSQL images downloaded.
- Hadoop 3.4.3: real HDFS/YARN weather MapReduce passed all six sample dates; an additional dataset passed repeated-date maximum, exact threshold, negative temperature and invalid-row checks. HDFS outputs survived container recreation. All five daemons start, including JobHistoryServer.
- CloudSim 7.0.1: both policies completed all six cloudlets with the expected bindings. Observed makespan: Min-Min 16 seconds, round-robin 15 seconds for this fixture. Min-Min is not guaranteed to win every workload.
- Hive 4.2.1: actual table creation, CSV load and every requested query passed. Eight records, two NULL amounts, correct decimal discounts and year/month values. Invalid SQL returns a nonzero exit status. The included wrapper handles this version's JLine terminal/file-reader behavior.
- Pig 0.18.0: six real YARN/MapReduce jobs passed. Flagged P002 with average 2/count 2, P004 with no reviews, and P006 with no valid reviews. Both missing averages are NULL and review counts are zero. The image includes the Collections 3 dependency required by Pig's intermediate-record reader.
- Public cloud deployment, provider accounts and cloud CRUD: not performed.
- Portable archive: 3,260,529,664 bytes (3.26 GB / 3.04 GiB). SHA-256 verification and `docker load` passed through Windows PowerShell. Archive inspection confirmed all five expected image tags and their layers; imported image IDs match the tested builds. Credentials, caches and logs are excluded from the source package.
- Exported launcher: CloudSim compiled and completed all six tasks through standard Windows PowerShell from the actual exam-pack directory, using the imported image on the isolated network.
- Fresh offline rehearsal: **passed the complete `smoke` command** from a separate source copy, empty HDFS/PostgreSQL volumes, a fresh Hive metastore, and a Docker network with `internal: true` (no external internet routing). All commands prohibited image pulls. Real engine outputs and all PostgreSQL integration checks passed. Duration on this laptop: 15.6 minutes, with archive import running concurrently for part of the test; this is not a benchmark for the college PC.
- Target college PC: not yet tested.

Run `./lab.ps1 smoke` after building/importing. Successful checks must produce the actual engine outputs in `artifacts` and the final `PASS` messages. Source/syntax checks alone do not verify a working lab.

The exported pack includes the verified sample result files in `artifacts`. Its image archive contains installed software, not HDFS/PostgreSQL volumes or the Hive metastore. Exercises recreate their sample data on first use. The small source ZIP contains no Docker images; carry the complete exam-pack folder for offline use.
