# Development

## Getting started

### 1. Create your `.env.development` file

Copy the example file and fill in your own values:

```bash
cp .env.development.example .env.development
```

Open `.env.development` and set values for each variable. The HTTP Basic Auth credentials protect the web interface locally — choose any values you like.

### 2. Generate Secret Key Base

Run this once to generate the secret key base:

```bash
bin/rails secret
```
The output should look like this:

```bash
4ecab9b8565c76e4208d4ed3effae46e36bee10f7c105e85e6c13d374b6aaaf0ef83d6ac0cb8e065160616ddf6e1606b7bfee6277ab386dae4e8320400369e89
```

Copy this value and replace the example value for `SECRET_KEY_BASE` in `.env.development`.

### 3. Generate Active Record Encryption keys

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

### 4. Set up the database and start the server

```bash
bin/setup --skip-server   # installs gems and prepares the database
bin/rails db:seed         # creates the initial Tenant record
bin/dev                   # starts the server
```

Open `http://localhost:3000` and log in using the Basic Auth credentials you chose in step 1. Then go to **Settings** and enter your SerpApi key — that's the one secret that lives in the database rather than in `.env.development`.
