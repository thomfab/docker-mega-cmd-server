# mega-cmd-server
Docker container with [MegaCmd](https://mega.io/cmd) installed and configured to start `mega-cmd-server` for background synchronisation.

## objective
This image is aimed to be used on systems where MegaCmd is not supported (for example Truenas Scale), or to synchronize multiple accounts easily by launching several containers with different user ids.

## design principles
This image launches the `mega-cmd-server` binary to provide continuous synchronisation of one or more local folders with your Mega account.

The objective is to be able to map a user and group id to a local ones so that files are created and modified with the correct attributes. The Docker `USER` directive (or parameter `--user`) was not chosen because the home directory of the user in the container is needed by megacmd and it cannot be created on the fly when launching the container.

Therefore, [gosu](https://github.com/tianon/gosu) is used and user and group ids are passed with environment variables (see usage paragraph).

`mega-cmd-server` is run with a user named `user` that is created if needed when starting the container. A check is done for user id collision (for example if passed id is 1000, then the default `ubuntu` user is deleted and a new `user` user is created).

## possible environment variables

- `PUID` and `PGID` : used to match IDs defined on the Docker host so that UNIX rights are correct when accessing the volumes 

## volumes

Define one or more volumes for the folders to be synchronized on the host.

For example: `--volume=/path/to/host/folder:/sync` and then the `/sync` folder can be used in the `mega-sync` command to create a synchronisation task.

## usage

Assuming that you have a user `johndoe` on your host, with a user id of `1234` and a primary group `johngroup` with a group id of `5678`, and you want to synchronize the host folder `/home/johndoe/photos` with the `/photos` folder on your Mega account.

### start container
Launch the container with the following command line:
```bash
$ docker run -d --name mega \
        -v "/home/johndoe/photos:/sync" \
        -e "PUID=1234" \
        -e "PGID=5678" \
        thomfab/mega-cmd-server
```

You can check that the container started with `docker logs mega`:

```
[...]
Starting with :
   user  : user
   uid   : 1234
   group : user
   gid   : 5678

.===========================================================================.
|               __  __ _____ ____    _                      _               |
|              |  \/  | ___|/ ___|  / \   ___ _ __ ___   __| |              |
|              | |\/| | \  / |  _  / _ \ / __| '_ ` _ \ / _` |              |
|              | |  | | /__\ |_| |/ ___ \ (__| | | | | | (_| |              |
|              |_|  |_|____|\____/_/   \_\___|_| |_| |_|\__,_|              |
|                                                                           |
|                                  SERVER                                   |
`===========================================================================´
```

### login
You now need to login to your Mega account (replace your Mega email and password in the command below):
```bash
$ docker exec -it mega gosu user mega-login you@yourmail.com yoursecretpassword
```
If 2FA is activated on your account, Mega will ask you to enter the OTP.

> **Please note**: when running mega commands in the container with docker exec, always prefix them with `gosu user` to run them as the same user as the `mega-cmd-server` process. Otherwise, the command you run with create a second `mega-cmd-server` as root, process in which you will not be logged and which will synchronize files with id `0`.

### synchronize
Once logged in you can use the mega commands.

List remote folders:
```bash
$ docker exec -it mega gosu user mega-ls
documents
photos
```

Synchronize the `photos` folder:
```bash
$ docker exec -it mega gosu user mega-sync /sync /photos
Added sync: /sync to /photos
```

## more advanced usage

### synchronize multiple folders
Launch with:
```bash
$ docker run -d --name mega \
        -v "/home/johndoe/photos:/sync/photos" \
        -v "/home/johndoe/documents:/sync/documents" \
        -e "PUID=1234" \
        -e "PGID=5678" \
        thomfab/mega-cmd-server
```
Synchronize:
```bash
$ docker exec -it mega gosu user mega-sync /sync/documents /documents
Added sync: /sync/documents to /photos
$ docker exec -it mega gosu user mega-sync /sync/photos /photos
Added sync: /sync/photos to /photos
```

### map the megacmd folder to keep session if container is deleted
Launch with:
```bash
$ docker run -d --name mega \
        -v "/home/johndoe/photos:/sync/photos" \
        -v "/home/johndoe/mega-session:/home/user/.megaCmd" \
        -e "PUID=1234" \
        -e "PGID=5678" \
        thomfab/mega-cmd-server
```
