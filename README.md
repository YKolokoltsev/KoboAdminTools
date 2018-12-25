# KoboAdminTools

ABOUT

For the moment KoboToolbox is a living project with limited backward compatibility. 
At any moment the next update of the Kobo Server can bring inconsistency with
it's previous databases, update it's REST API or even leave support of it's previous mobile client. 

The KoboAdminTools is a script package created to automate routinary operations of Kobo 
Server administration and to increase the Kobo Server stability. Another, collateral 
advantage of the KoboAdminTools is to protect administrators from mechanical errors caused by the human 
factor. Irreversible operations contain automatic checklist of the most important actions that
may preceed before the changes take place. Whithin KoboAdminTools repository the best found administration 
strategies may be discussed and implemented.

Installation of the KoboAdminTools

Installation of the KoboDocker:
a) sudo apt-get install docker-compose
b) #postgres-dev, pgquarrel

1. git clone ....MyRepo ./
2. ln -s <full path to existing kobo server> kobo-server.lnk

1. git clone https://github.com/kobotoolbox/kobo-docker.git
2. ln -s docker-compose.local.yml docker-compose.yml
3. docker-compose pull
4. envfile.local.txt
5. KOBO_POSTGRES_DB_NAME=kobotoolbox
6. ports: - 2345:5432
...

Before deployment of the database on the new or updated server, first run
server with an empty database, so the server creates all tables for the 
first time.

Use import_pgdb.sh to import the old postgres database into the new
server but with a name different from 'kobotoolkit'. Therefore, at the new
server will appear two databases at the same time.

Use pgquarrel to compare squemes of the recent but empty database
with the database restored from the dump. If the postgres squeme was 
not changed in the newer version of KoboDocker, it is safe to remove
temporary database form the server and use dump_deploy.sh script.

If something in the squeme was changed, the manual database migration shell be done
based on the pgquarrel report. In this case the dump_deploy.sh cannot be used, and
mongoDB dump can be obsolete. The steps to process are the following:
....

1. Point KOBO_SERVER_ROOT_DIR to the new server folder
2. Migrate manually postgres databse
3. Drop empty kobotoolbox database and make your migrated database primary
4. Generate MongoDB based on the recovered primary database
5. Deploy user-media data and check that all is consistent
