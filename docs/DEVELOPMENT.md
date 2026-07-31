# Development

## Getting started

### 1. Create your `.env.development` file

Copy the example file and fill in your own values:

```bash
cp .env.development.example .env.development
```

Open `.env.development` and set values for each variable. The HTTP Basic Auth credentials protect the web interface locally — choose any values you like. Leave the `AR_ENCRYPTION_*` keys blank for now; you will generate them in the next step.

### 2. Generate Active Record Encryption keys

Run this once to generate encryption keys for the database:

```bash
bin/rails db:encryption:init
```

The output looks like:

```
active_record_encryption:
  primary_key: <value>
  deterministic_key: <value>
  key_derivation_salt: <value>
```

Copy the three values into the matching lines in your `.env.development`. Generate them once and keep them stable — rotating them makes existing encrypted database values (e.g. a stored SerpApi key) unreadable.

### 3. Set up the database and start the server

```bash
bin/setup --skip-server   # installs gems and prepares the database
bin/rails db:seed         # creates the initial Tenant record
bin/dev                   # starts the server
```

Open `http://localhost:3000` and log in using the Basic Auth credentials you chose in step 1. Then go to **Settings** and enter your SerpApi key — that's the one secret that lives in the database rather than in `.env.development`.
