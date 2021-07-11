#!/bin/sh

echo  $DB_SERVER
echo  $DB_PORT
echo  $DB_USERNAME
echo  $DATABASE_NAME
echo  $DB_PASSWORD
echo  $EMAIL_USER
echo  $EMAIL_PASS
echo  $SECRET_KEY
echo  $SQLALCHEMY_TRACK_MODIFICATIONS
echo  $MAIL_SERVER
echo  $MAIL_PORT
echo  $MAIL_USE_TLS
echo  $FLASK_APP

ls -lrt
flask db upgrade
gunicorn --bind 0.0.0.0:5000 run:app 
