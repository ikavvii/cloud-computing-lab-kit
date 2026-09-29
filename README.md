# Cloud Computing Lab Kit

A portable Docker environment for the six exercises in your problem sheet. Build and rehearse before the exam; carry the exported folder to the college PC. You edit ordinary Java, Pig, SQL and Python files on the host.

**Start with [the exam cheatsheet](docs/EXAM-CHEATSHEET.md).** See [validation status](docs/VALIDATION.md) before relying on the kit.

**Already have the exported folder containing `images.tar`? Run `.\lab.ps1 import`, then the required lab command. Skip the build instructions below.** Local exercises need no package downloads after import.

## What is included

| Exercise | Environment and deliverable |
|---|---|
| 1. IaaS / PaaS / SaaS | [Cloud walkthrough](docs/CLOUD-EXERCISES.md); reusable dynamic application; service-model explanation |
| 2. Dynamic site + free cloud database CRUD | Flask + PostgreSQL application, SQL, local practice containers, Render + Neon deployment instructions |
| 3. CloudSim custom scheduling | CloudSim **7.0.1**, Java 21, custom **Min-Min** broker policy and round-robin comparison |
| 4. Hadoop weather MapReduce | Hadoop **3.4.3**, Java 11, real single-node HDFS + YARN, Java mapper/reducer |
| 5. Pig product audit | Pig **0.18.0**, explicit schemas, cleaning, left join, aggregation, missing reviews, HDFS output |
| 6. Hive sales | Official Hive **4.2.1** image, exact dataset, all requested queries |

These are multiple containers managed as one kit. Different Java/runtime requirements are isolated. Hadoop 3.5.0 is available; this kit deliberately uses the 3.4.3 maintenance line for the Pig/Java 11 combination. Versions are pinned for rehearsal consistency rather than using floating `latest` tags. Base OS/JDK image tags can receive updates at build time; the exported images preserve the exact built binaries.

## First setup on your laptop (internet required)

Use Docker Desktop in **Linux containers** mode. Allocate roughly 6 GB to Docker if available. Allow several GB of downloads and around 15–20 GB of free disk for layers, builds and the exported archive; actual size depends on Docker's cache. Run one heavy lab at a time on an 8 GB PC; 16 GB RAM is more comfortable. No Windows Java, Hadoop, Python or Maven installation is needed.

In PowerShell, in this folder:

```powershell
.\lab.ps1 build
.\lab.ps1 smoke
.\lab.ps1 export
```

If PowerShell blocks local scripts, use this invocation for the individual command (it does not change machine policy):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\lab.ps1 build
```

`smoke` executes the real engines and validates the results; it stops Hadoop before Hive to reduce RAM usage. It also tests the web app against PostgreSQL. It creates sample inputs/output and retains HDFS/database data. Do not run it in the middle of your own jobs.

The Hadoop/Pig build downloads official archives in eight parallel connections and caches completed chunks in Docker's build cache. If internet drops, rerun the build; completed chunks are reused. The assembled Hadoop archive is checked with SHA-512 and Pig with its published GPG signature. Keep the build cache until preparation finishes.

## Carry to college (no package downloads needed)

Copy **the whole `artifacts/exam-pack` folder** to a USB drive, then to the lab PC's local disk. Use exFAT/NTFS if `images.tar` exceeds FAT32's 4 GB per-file limit. Keep the folder's structure intact.

On the lab PC, open PowerShell inside that folder:

```powershell
.\lab.ps1 import     # verifies SHA-256, then docker load
.\lab.ps1 cloudsim
.\lab.ps1 weather
.\lab.ps1 pig
.\lab.ps1 stop       # free memory before switching to Hive
.\lab.ps1 hive
.\lab.ps1 stop
.\lab.ps1 web
.\lab.ps1 stop
```

The commands use local images and prohibit pulls. The engine and Docker Compose must already be installed and usable by your lab login. A local image archive cannot install Docker or enable virtualization. The images are intended for x86-64 Linux containers; verify the target PC architecture. Public-cloud tasks still need internet and your cloud accounts.

Keep `images.tar` and its checksum until import is complete. The small source ZIP alone does not contain the installed software and cannot replace this archive.

Linux lab PCs can use the direct Docker Compose commands in the cheatsheet. Import with `sha256sum -c images.tar.sha256` and `docker load -i images.tar`.

## Files and results

- `labs/03-cloudsim/MinMinScheduling.java`: edit cloudlet lengths/VM speeds and custom scheduling policy.
- `labs/04-weather/Weather.java`: edit parser or reducer for the examiner's actual dataset.
- `labs/05-pig/inventory.pig`: edit schemas, category, threshold and HDFS paths.
- `labs/06-hive/sales.hql`: typed table, load, discount and timestamp queries.
- `labs/01-02-cloud-app/`: independently deployable web app and CRUD SQL.
- `artifacts/`: captured program outputs; HDFS output paths are also printed.

Hadoop/Pig and CloudSim mount host source files, so editing those labs needs no image rebuild. Hive mounts its SQL and dataset read-only. Web source is copied into its image: rebuild `web` after editing it.

HDFS and local PostgreSQL use named volumes. `stop` retains them. Hive uses an embedded practice metastore in the container: stop/start retains it, removing/recreating the container loses it. Re-run `sales.hql` to restore the sample. Image export carries software and source, **not** container changes, named volumes, credentials or your `.env`.

## Scope

This is a small isolated teaching environment, not a production cluster. Ports bind to localhost. It does not impersonate AWS/Azure/GCP, create paid cloud resources, or replace the need to demonstrate installation commands if those are part of the grading. The web app uses one shared practice login; it is not a multi-tenant SaaS. Use Google Workspace to demonstrate consumption of SaaS.

Rehearse the underlying commands, input assumptions, code and expected output. Installation readiness is helpful only if you can adapt the programs to the actual exam problem.

## Official references checked on 2026-09-28

- [Hadoop releases](https://hadoop.apache.org/releases.html) and [single-node setup](https://hadoop.apache.org/docs/r3.4.3/hadoop-project-dist/hadoop-common/SingleCluster.html).
- [Pig releases and Hadoop 3 support](https://pig.apache.org/releases.html), [Pig Latin](https://pig.apache.org/docs/r0.17.0/basic.html).
- [Hive releases](https://hive.apache.org/general/downloads/), [official Docker quickstart](https://hive.apache.org/development/quickstart/), [types and NULL](https://hive.apache.org/docs/latest/language/languagemanual-types/).
- [CloudSim 7.0.1](https://github.com/Cloudslab/cloudsim/releases/tag/7.0.1); build uses commit `9a414ff15df0caa2978efb5bcd6e6180fa58bb66`. Its bundled upstream documentation/license is retained in the image.
- [Render free-service limitations](https://render.com/docs/free), [Neon free plan](https://neon.com/blog/how-to-make-the-most-of-neons-free-plan).
