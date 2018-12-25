# KoboAdminTools

ABOUT

For the moment KoboToolbox is a living project with limited backward compatibility. At any moment the next update of the Kobo Server can bring inconsistency with it's previous databases, update it's REST API or even leave support of it's previous mobile client.

The KoboAdminTools is a script package created to automate routine operations of Kobo Server administration and to increase it’s stability. Another, collateral advantage of the KoboAdminTools is to protect administrators from mechanical errors caused by the human factor. Irreversible operations contain automatic checklist of the most important actions that may precede before the changes take place. Within KoboAdminTools repository the best found administration strategies may be discussed and implemented.
Installation of the KoboAdminTools
The KoboAdminTools is just a folder with bash scripts, it does not require any specific installation. However, it is recommended to use the latest version of the Pgquarrel (https://eulerto.github.io/pgquarrel/) utility that can be used for PostgreSQL database schema comparison. After the script package download, it is required to create a kobo-server.lnk file in the script folder. This shell be a symbolic link to the configured KoboDocker folder, that will be the target server for all scripts.

```
git clone https://github.com/YKolokoltsev/KoboAdminTools.git ./
ln -s <path_to_kobo-docker> kobo-server.lnk
mkdir pgquarrel && cd pgquarrel
sudo apt-get install postgresql-server-dev-all (Ubuntu)
git clone https://github.com/eulerto/pgquarrel.git ./
cmake .
make
ppath=`pwd` && sudo ln -s ${ppath}/pgquarrel /usr/local/bin/pgquarrel
```


REFERENCE

`- dump-store.sh`

This script automates creation of the complete 100% self-consistent Kobo Server backup on the running server. The core idea of this script is to stop the Kobo front-end services (“nginx”, "kobocat" "kpi" "enketo_express" "rabbit") in the correct order to protect databases from any client access during the backup.

`- stop-frontend.sh`

For the case of any manual changes within active databases on the production server it is also strongly recommended to stop the frontend. This operation alone is automated with ‘stop-frontend.sh’.

- `import-pgdb.sh`

To compare the current main Postgres database (it’s name is ‘kobotoolbox’) with any other version of this database given by the dump file, it is required to install this dump on one of the working Postgres server. This script will install any postgres dump onto the running production database making the new independent database with a user-specified name.

- `dump-deploy.sh`

This script deploys three dump files for postgres, mongo, and user media onto the running Kobo server. Taking in account that this operation is associated with increased data-loss risk, here some additional actions are proposed to prevent appearance of the unrecoverable state.

- `import-user-media.sh`

In this short script the kobocat user media archive will replace all KoboCat data files. This can be a dangerous operation, so some notifications were made to prevent data-loss.
- functions.sh
In this file some common bash functions are stored. It is possible to ‘source’ this script in the current shell session to simplify some of the lo-level routine operations. Please see the functions.sh source code to check for the functions list and their description.


COMMON RECIPES

Short guide for KoboDocker clean installation:
1. git clone https://github.com/kobotoolbox/kobo-docker.git
2. ln -s docker-compose.local.yml docker-compose.yml
3. docker-compose pull
4. Edit: envfile.local.txt, envfile.server.txt
5. Put ‘KOBO_POSTGRES_DB_NAME=kobotoolbox’ into both environment files
6. Edit the *.yml files to map all three database ports to the local host
7. Configure ssh tunnels to these ports to have direct remote access to production server databases
8. Run the new server in local mode so that it fills it’s databases with the most recent clean schemes

Short migration guide from the Kobo server A to another server B:
1. A: run dump-store.sh
2. Copy postreg dump from A/backups/postgres to the B/backups/postgres
3. B: run dump-deploy.sh
4. B: run pgquarrel

Depending on the pgquarrel results there are two different scenario of what to do next:
(I) The pgquarrel reports that there are no difference between the main database and the imported one. In this case it is possible to safely use the dump-deploy.sh on the server B.
(II) If there are differences, it is possible to fix them manually within the temporary database usung pure SQL. That will not require to shot down the server B, because all required actions shell not affect active kobotoolbox database. After migration it may be necessary to recover the mongoDB data. Use the stop-frontend.sh script on the server B, remove kobotoolbox database and rename the temporary database to kobotoolbox. Afterwards – generate new mongoDB data. Use import-user-media.sh script to deploy user data files.
