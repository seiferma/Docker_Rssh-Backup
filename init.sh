#!/bin/sh

set -e

UNIX_USERS=$VOL_CFG/users
SSH_KEYS=$VOL_CFG/keys
HOMES=$VOL_HOME

if [ ! -f $UNIX_USERS/passwd ] || [ ! -f $UNIX_USERS/group ] || [ ! -f $UNIX_USERS/shadow ]; then
    echo "Initializing unix users in volume"
    mkdir -p $UNIX_USERS
    cp -f /etc/passwd $UNIX_USERS/
    cp -f /etc/group $UNIX_USERS/
    cp -f /etc/shadow $UNIX_USERS/
fi

echo "Using unix users from volume"
rm /etc/passwd
ln -s $UNIX_USERS/passwd /etc/passwd
rm /etc/group
ln -s $UNIX_USERS/group /etc/group
rm /etc/shadow
ln -s $UNIX_USERS/shadow /etc/shadow

if [ ! -f $SSH_KEYS/ssh_host_ed25519_key ] || [ ! -f $SSH_KEYS/ssh_host_rsa_key ]; then
    echo "Initializing sshd keys in volume"
    rm -f $SSH_KEYS
    mkdir -p $SSH_KEYS
    ssh-keygen -q -N "" -t ed25519 -f $SSH_KEYS/ssh_host_ed25519_key
    ssh-keygen -q -N "" -t rsa -f $SSH_KEYS/ssh_host_rsa_key
    chmod 600 $SSH_KEYS/*
fi

echo "Using sshd keys from volume"
rm -f /etc/ssh/ssh_host_*
ln -s $SSH_KEYS/ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key
ln -s $SSH_KEYS/ssh_host_ed25519_key /etc/ssh/ssh_host_ed25519_key

if [ "$1" == "sshd" ]; then
    echo "Starting ssh server"
    exec /usr/sbin/sshd -D -e

elif [ "$1" == "adduser" ]; then
    if [ -z "$2" ] || [ -z "$3" ]; then
        echo "You have to specify an username and a public key"
        exit 1
    fi
    echo "Adding new user $2"
    USERDIR=$HOMES/$2
    adduser -s $(which rssh) -h $USERDIR -D $2
    mkdir $USERDIR/.ssh
    chmod -R 750 $USERDIR
    echo $3 > $USERDIR/.ssh/authorized_keys
    sed -i -e "s/$2:!:/$2:\*:/" $UNIX_USERS/shadow

else
    echo "Executing command"
    exec "$@"
fi
