#!/bin/bash

GROUPNAME=sftponly


if test "`echo $1`" = ""
then
        echo "No username is given. Call this script like:  make_sftp_chrott.sh <username>"
        exit 1
else
        NEW_USER=$1
fi


if ! test "`whoami`" = "root"
then
        echo "You need to be root. Call this script like: sudo make_sftp_chrott.sh <username>"
        exit 1
fi


if  test  "`dpkg -l | grep openssh-sftp-server`" = ""
then
        echo "Installing openssh-sftp-server..."
        apt-get --assume-yes  install openssh-sftp-server
fi

if test "`cat /etc/groups | grep $GROUPNAME`" == ""
then
        echo "Adding group $GROUPNAME"
        groupadd $GROUPNAME
else
        echo "Group $GROUPNAME already exists."
fi

if ! test "`cat /etc/passwd | grep $NEW_USER`" = ""
then
        echo "User $NEW_USER exists. Will change..."
        usermod -G $GROUPNAME -s /bin/false $NEW_USER
else
        echo "Adding $NEW_USER..."
        useradd -g $GROUPNAME -s /bin/false -m -d /home/$NEW_USER $NEW_USER

        echo "Enter a password for $NEW_USER"
        passwd $NEW_USER
fi


echo "Important /home/$NEW_USER have to be owned by root in a chroot environment"
echo "Only the subfolder sftp_home belongs to $NEW_USER"
echo

if ! test -e /home/$NEW_USER
then
        mkdir /home/$NEW_USER
fi

chown root: /home/$NEW_USER
chmod 755 /home/$NEW_USER

mkdir /home/$NEW_USER/sftp_home

chmod 755 /home/$NEW_USER/sftp_home

chown $NEW_USER:$GROUPNAME /home/$NEW_USER/sftp_home

for I in .gnupg .cache
do

        if ! test -e  /home/$NEW_USER/$I
        then
                mkdir /home/$NEW_USER/$I
                chmod 700 /home/$NEW_USER/$I
                chown $NEW_USER:$GROUPNAME  /home/$NEW_USER/$I
        fi
done



/usr/sbin/sshd -t
SSHDTEST=$?

if test "`echo $SSHDTEST`" = "0"
then
        echo "Restarting sshd..."
        systemctl restart sshd
fi






if test -e /home/$NEW_USER
then
        ls -la /home/$NEW_USER
fi

echo

cp /etc/ssh/sshd_config /etc/ssh/sshd_config_`date +"%s"`

TMPX=/tmp/sshd.$$

X=`cat /etc/ssh/sshd_config | grep "/usr/lib/openssh/sftp-server"`
Y=`cat /etc/ssh/sshd_config | grep "^Match Group $GROUPNAME"`

if ! test "`echo $X `" = ""
then
        cat /etc/ssh/sshd_config | grep -v "/usr/lib/openssh/sftp-server" > $TMPX
        echo "Subsystem sftp internal-sftp" >> $TMPX
        echo "" >> $TMPX
        mv -f $TMPX /etc/ssh/sshd_config
fi

if  test "`echo $Y `" = ""
then
        cat /etc/ssh/sshd_config > $TMPX
        cat  >> $TMPX <<_EOF_
Match Group $GROUPNAME
   ChrootDirectory %h
   ForceCommand internal-sftp
   AllowTcpForwarding no
   X11Forwarding no
_EOF_

        echo "" >> $TMPX
        mv -f $TMPX /etc/ssh/sshd_config
fi
