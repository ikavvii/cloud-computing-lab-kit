# Exercises 1–2: actual cloud services

Docker prepares runtimes and applications. It cannot turn an offline laptop into EC2, a public PaaS, or a managed cloud database. Prepare an account and rehearse a real deployment before the exam if these tasks can be selected.

## Service models

The problem sheet's second heading has a typo: Platform as a Service is **PaaS**, not IaaS.

| Model | You handle | Provider handles | Demonstration |
|---|---|---|---|
| IaaS | OS configuration, firewall, runtime, app and data | Physical machines and virtualization | EC2 or Azure VM with your app |
| PaaS | Source code, configuration and application data | Runtime/platform maintenance and deployment infrastructure | Render, Heroku or Elastic Beanstalk deployment |
| SaaS | User data, permissions and business workflow | Entire ready-to-use product | Google Sheets/Docs in Workspace or Salesforce |

PaaS does not universally include a managed database or automatic scaling on every plan. Describe the features of the chosen service. Docker containers and CloudSim simulations are not standalone proof of these cloud service models.

## Recommended public rehearsal: Render + Neon PostgreSQL

This uses the sheet's allowance for an "other service provider". If the examiner mandates AWS/Azure/GCP, use that provider instead. Check account eligibility and displayed plan limits at signup; do not assume zero charges outside the free plan.

1. Create a **free Neon project**. In its SQL editor, run `labs/01-02-cloud-app/schema.sql`. Copy its database connection string with the supplied TLS options; keep the password private.
2. Put the app source in your own Git repository. Exclude `.env` and credentials. The kit has not pushed or published anything on your behalf.
3. In Render, create a Web Service from that repository. Choose Docker runtime and the **Free** instance type. Set the root directory to `labs/01-02-cloud-app` so Render uses that Dockerfile.
4. Add secret environment variables in Render: `DATABASE_URL` from Neon; a random `APP_PASSWORD` of at least 12 characters; and a random `SECRET_KEY` of at least 32 characters. Set `COOKIE_SECURE=true`. The app binds to Render's `PORT` automatically.
5. Deploy. Open the assigned HTTPS URL, log in and complete create/read/update/delete. The default local password is not appropriate for public deployment.
6. Observe the rows from Neon's SQL editor using `SELECT * FROM products;`. Refresh after each operation. This proves the app is using a hosted database.
7. Capture your public URL, successful deployment log, table schema, rows after creation/update and the deleted row's absence. Do not include passwords or connection strings in screenshots.

The app has parameterized SQL, form tokens, escaped HTML and a shared login suitable for this small lab. It is not a production identity or multi-tenant system. Do not enter personal data. Render free web services sleep after inactivity and have ephemeral local storage; the separate hosted database provides persistence. Allow startup time before showing it to the examiner.

Official references: [Render Docker deployment](https://render.com/docs/docker), [Render free plan](https://render.com/docs/free), [Neon free plan](https://neon.com/blog/how-to-make-the-most-of-neons-free-plan). Limits can change; the free plan selection in your own account is authoritative.

## Cloud database CRUD without the web app

Open the hosted PostgreSQL SQL editor, then use `crud.sql`. After INSERT, note the **returned id** and use that exact id for UPDATE/DELETE. The example id `1` is a placeholder, not a guarantee. Explain:

- CREATE data: `INSERT INTO products(name,price) VALUES (...) RETURNING *`.
- READ: `SELECT ... FROM products`.
- UPDATE: `UPDATE ... SET ... WHERE id=...`.
- DELETE: `DELETE ... WHERE id=...`.

`CREATE TABLE` is schema creation (DDL); the C in CRUD normally refers to inserting a record (DML).

## IaaS: EC2/Azure VM procedure

Use your course/sandbox account and the provider console. A public-cloud VM and its storage/IP may incur charges; choose the resources allowed by your lab account.

1. Provision an Ubuntu VM, note its OS, CPU, RAM and disk. Keep the login key private. Restrict SSH access to your current IP. For this lab web demo, permit the required HTTP port only to the examiner/lab network as appropriate.
2. Connect by SSH and copy the app folder to the VM. From that folder, install your runtime and database or use a hosted PostgreSQL connection. For a manual runtime demonstration, a Python virtual environment plus PostgreSQL makes responsibilities visible:

   ```bash
   sudo apt-get update
   sudo apt-get install -y python3-venv postgresql
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

3. Create a database/user with a chosen private password, or supply the Neon connection string. Set `DATABASE_URL`, `APP_PASSWORD`, `SECRET_KEY` as environment variables. Use `COOKIE_SECURE=false` only for a temporary HTTP-only lab demo; HTTPS uses true.
4. Start `gunicorn --bind 0.0.0.0:8000 --workers 1 app:app` from the app directory. Access the VM's allowed IP/port and perform CRUD. For a persistent deployment use a service manager and an HTTPS reverse proxy; these are outside the quick lab demonstration.
5. Explain the distinction: you configured the VM OS and installed/managed the runtime/database. That is the IaaS exercise. In PaaS, the platform manages that environment.
6. After grading, stop or terminate the course resources according to the lab instructions and check remaining disks/IP allocations. No cloud resources have been created by this kit.

For AWS terminology and current console flow see [EC2 Linux instance tutorial](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EC2_GetStarted.html).

## SaaS: Google Workspace

1. Open Google Sheets or Docs in the browser using an account you are allowed to use.
2. Create a small inventory sheet with synthetic product data. Demonstrate editing, filtering and version history. If collaboration is required, share only with the examiner/team designated by the lab.
3. Explain that you consume a complete hosted application, without installing its backend/runtime or operating its servers. That is SaaS consumption.

If asked specifically to **design** a SaaS app, describe tenant-aware users, authorization, per-tenant data isolation and browser delivery. Do not claim this kit's shared-login CRUD app implements those features.
