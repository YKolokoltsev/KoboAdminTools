# KoboAdminTools

ABOUT

For the moment KoboToolbox is a living project with limited backward compatibility. At any moment the next update of the Kobo Server can bring inconsistency with it's previous databases, update it's REST API or even leave support of it's previous mobile client.

The KoboAdminTools is a script package created to automate routine operations of Kobo Server administration and to increase it’s stability. Another, collateral advantage of the KoboAdminTools is to protect administrators from mechanical errors caused by the human factor. Irreversible operations contain automatic checklist of the most important actions that may precede before the changes take place. Within KoboAdminTools repository the best found administration strategies may be discussed and implemented.


INSTALLATION

The KoboAdminTools is just a folder with bash scripts, it does not require any specific installation. However, it is recommended to use the latest version of Pgquarrel (https://eulerto.github.io/pgquarrel/) - utility that can be used for PostgreSQL database schema comparison. After the script package download, it is required to create a `kobo-server.lnk` file in the script folder. This shell be a symbolic link to the configured KoboDocker folder, that will be the target server for all scripts.

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

- `dump_store.sh`

This script automates creation of the complete 100% self-consistent Kobo Server backup on the running server. The core idea of this script is to stop the Kobo front-end services (`nginx`, `kobocat`, `kpi`, `enketo_express`, `rabbit`) in the correct order to protect databases from any client access during the backup.

- `stop_frontend.sh`

For the case of any manual changes within active databases on the production server it is also strongly recommended to stop the frontend. This operation alone is automated with `stop_frontend.sh`.

- `import_pgdb.sh`

To compare the current main Postgres database (it’s name is `kobotoolbox`) with any other version of this database given by the dump file, it is required to install this dump on any working Postgres server. This script will install selected postgres dump onto the running production postgres server creating the new independent database with a user-specified name.

- `dump_deploy.sh`

This script deploys three dump files for postgres, mongo, and user media onto the running Kobo server. It is important that the server version
from where a dump was made coincide with the active Kobo Server. Dump deployment is associated with increased data-loss risk and some additional 
actions are proposed in the `dump_deploy.sh` script to prevent appearance of the unrecoverable state.

- `deploy_user_media.sh`

In this short script the kobocat user media archive will replace all KoboCat data files. This can be a dangerous operation, so some notifications proposed to prevent data-loss.

- `remongo.sh`

Re-create Mongo database from Postgress data can be useful if there is no valid mongo backup, or the postrges database was migrated onto the
new server.

- `functions.sh`

In this file the Kobo-specific bash functions are stored. It is possible to `source functions.sh` in the current shell session to simplify some of the lo-level operations. Please see the `functions.sh` source code to check for the functions list and their description.


COMMON RECIPES

Short guide for KoboDocker clean installation:
1. `git clone https://github.com/kobotoolbox/kobo-docker.git`
2. Check: `sdiff -s docker-compose.local.yml docker-compose.server.yml | grep image`
3. Edit *.yml files (ports, extra_hosts)
4. `ln -s docker-compose.<?>.yml docker-compose.yml`
5. Edit `envfile.<?>.txt` files, append `KOBO_POSTGRES_DB_NAME=kobotoolbox`
6. `docker-compose pull`
7. Configure ssh tunnels to these ports to have direct remote access to production server databases
8. Run the new server (better in server mode) so it fills it’s databases with the most recent clean schemes

Short migration guide from the Kobo server A to another server B (aka Server Update):
1. A: `run dump-store.sh`
2. Copy backup files from `A/backups/` to the `B/backups/`
3. B: run `import_pgdb.sh`
4. B:`pgquarrel -c pgquarrel_test.ini`

Depending on the `pgquarrel` results there are two different scenario of what to do next:

(I) The `pgquarrel` reports that there are no difference between the main B database and the imported one. In this case it is possible to try `dump-deploy.sh` on the server B. However, in this case there is no guarantee that mongo dump is safe. Also, there is no guarantee that user-media folder did not change it's structure.

(II) If there are differences, it is possible to fix them manually within the temporary database usung pure SQL generated by `pgquarrel`. However, be aware of running an SQL automatically, all changes shell be analyzed. Midification of the imported database can be made on the working server B. After migration it may be necessary to recover the mongoDB data. Use the `stop_frontend.sh` script on the server B, remove `kobotoolbox` database and rename the temporary database to `kobotoolbox`. Afterwards – generate new mongo data. Use `deploy_user_media.sh` script to deploy user data files. Be aware that no checks are found yet to control user-media folder structure changes.


LINKS

https://github.com/kobotoolbox/kobo-docker
https://www.kobowiki.org/index.php?title=KoBo_software_upgrade
https://community.kobotoolbox.org/c/kobo-developers

