flaskapp

Postgres Database has to be created before hand.
DB tables (User and Post) are not created automatically as part of this Application deployment.
Once the app is deployed in Docker, you need to execute the below command inside the Application container to create the tables.

[ec2-user@ip-172-31-37-221 ~]$ sudo docker exec d097e8271f99 flask db upgrade
INFO  [alembic.runtime.migration] Context impl PostgresqlImpl.
INFO  [alembic.runtime.migration] Will assume transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade  -> d58d1fdfa548, empty message

Where "d097e8271f99" is the container ID of the flask application.

We will use "flask-migrate" to create the database instead of db.create_all() command.
This gives us the flexibility to migrate and upgrade/update the database easily in multi-developer environmanet.
Commit your "migrations" folder along with the code. Any other developer can just run "flask db upgrade" to get
the databse set up. "flask db upgrade" gets the script to upgrade the database from the "migrations" folder committed by
previous developer. You can upgrade as well as downgrade.

Commands to be used for flask-migrate : 
    export FLASK_APP=run.py
    flask db init
    flask db migrate
    flask db upgrade

"flask db init" needs to be run only ONCE. This sets up your "migrations" folder.
Everytime you make any change to the Database schema execute "flask db migrate".
This generates the scripts for database upgrade with the new changes.
You can verify the generated scripts and if everything is fine, execute "flask db upgrade"
"flask db upgrade" changes/updates your database schema.
At the beginning of your project, you need to run all the 3 commands to set up your database.
After that if you do any changes to the schema, just execute "flask db migrate" and "flask db upgrade".

---------------------------------------------

If you are deploying the app using docker compose, then you can execute the below command.
"docker-compose exec web flask db upgrade"

----------------------------------------------

If you are deploying the app in Elastic Beanstalk, then you need to install and enable "eb CLI" and "eb ssh" to login to the EC2 instance and then
execute the below command.

sudo docker exec d097e8271f99 flask db upgrade

Where "d097e8271f99" is the container ID of the flask application.

----------------------------------------------------------------------------

Static Files:

Dynamic web applications also need static files. That’s usually where the CSS and JavaScript files are coming from. Ideally your web server is configured to serve them for you, but during development Flask can do that as well. Just create a folder called static in your package or next to your module and it will be available at /static on the application.

To generate URLs for static files, use the special 'static' endpoint name:

url_for('static', filename='style.css')
The file has to be stored on the filesystem as static/style.css.

-----------------------------------------------------------
