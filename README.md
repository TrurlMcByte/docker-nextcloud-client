# docker-nextcloud-client
Dockerized NextCloud client


```
*Usage:.
docker run -d -v <hostdirtosync:dockerdirtosync> <environment vars> \
         trurlmcbyte/nextcloud-client

*Example :.
docker run -d \
   -v ~/mydocs:/mydocs \
   -e LOCALDIR="/mydocs" \
   -e USER="example" \
   -e PASSWORD="examplepassword" \
   -e URL="https://<owncloudserver_name>/owncloud/remote.php/webdav/mydocs" \
   -e INTERVAL="30" \
   -e HOSTUSER="myuserid" \
   --name <container name> \
   trurlmcbyte/nextcloud-client
```

# Environment vars to use:
* USER => owncloud user
* PASSWORD => owncloud user password
* LOCALDIR => local (to docker client) directory to sync (create one with -v <hostdir>:<dockerdir> )
* URL      => owncloud server URL with remote directory to sync
* INTERVAL => interval to check for changes (default 30(s)).
* HOSTUSER => user on host system so files get written by this user instead of root!
* WORK_UID => work user UID (default 82)
* WORK_GID => work user GID (default 82)
* WORK_USER =>  work user name (default "clouddata")
* WORK_USER =>   work group name (default "clouddata")
* POST_SCRIPT => script to run after each sync
* CONFDIR => directory with multiple ```.conf``` files, contained separated variables for multisync, files must have ALL variables

# Remarks
* if one of those environment variables are not available it won't work!
* naming the container (--name) is just for conveniance
* client will trust any https certificate, so you can use it with self-signed certificates as well
  so check the certificate of the server URL before yourself! (possible override with PARAMSTRING variable)
* logging is done to a file inside the container because it did show credentials via the docker logs.
  Inside the container in the log these are still shown, but can only be hidden by logging to /dev/null
  instead as far as I know :(

