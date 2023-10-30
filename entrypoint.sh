#!/bin/bash

# generate a unique machine id if not already done
[ -s /etc/machine-id ] || /usr/bin/uuidgen > /etc/machine-id

# only use ids that are greater than 1000

if [[ $PUID -lt 1000 || $PGID -lt 1000 ]]; then
    echo "Only use user and group ids that are greater than 1000"
    exit 1
fi

USER=user
USER_ID=${PUID:-1000}
GROUP=user
GROUP_ID=${PGID:-1000}
echo "Input parameters for the user for mega-cmd-server :"
echo "   user  : $USER"
echo "   uid   : $USER_ID"
echo "   group : $GROUP"
echo "   gid   : $GROUP_ID"


echo "Check if user $USER already exists (most likely the container was previsouly launched)"
EXISTING_USER=$(getent passwd $USER)
echo "   getent passwd result : $EXISTING_USER"

if [[ "x$EXISTING_USER" == "x" ]]; then
    echo "User $USER does not exist"

    echo "Check if a user with id $USER_ID exists"
    EXISTING_USER_WITH_ID=$(getent passwd $USER_ID | cut -d ":" -f 1)
    echo "   getent passwd $USER_ID result : $EXISTING_USER_WITH_ID"
    if [[ "x$EXISTING_USER_WITH_ID" != "x" ]]; then
        echo "A user with id $USER_ID exists, delete it"
        deluser $EXISTING_USER_WITH_ID
    fi

    echo "Check if a group with id $GROUP_ID exists"
    EXISTING_GROUP_WITH_ID=$(getent group $GROUP_ID | cut -d ":" -f 1)
    echo "   getent group $GROUP_ID result : $EXISTING_GROUP_WITH_ID"
    if [[ "x$EXISTING_GROUP_WITH_ID" != "x" ]]; then
        echo "A group with id $GROUP_ID exists, delete it"
        delgroup $EXISTING_GROUP_WITH_ID
    fi

    echo "Create group $GROUP with id $GROUP_ID"
    groupadd -g $GROUP_ID $GROUP
    echo "Create user $USER with id $USER_ID"
    useradd --shell /bin/bash -u $USER_ID -g $GROUP_ID -o -c "" -m $USER
else
    EXISTING_USER_ID=$(echo $EXISTING_USER | cut -d ":" -f 3)
    # check if container is start with same user id
    if [ $EXISTING_USER_ID -ne $PUID ]; then
        echo "This container was previously launched with another user id $EXISTING_USER_ID"
        exit 1
    fi
fi

echo "Starting with :"
echo "   user  : $USER"
echo "   uid   : "$(id -u $USER)
echo "   group : $GROUP"
echo "   gid   : "$(getent group $GROUP | cut -d ":" -f 3)

export HOME=/home/$USER

exec gosu $USER "$@"