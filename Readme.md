# Secure environment for SFTP user. 

## User cannot login by ssh. 
## Only upload files to a sub-directory  in the 'home' directory is possible. 
## User cannot leave this home directory. This directory this a jail. 

The script changes:
* /etc/group (Adding a new group - sftponly)
* /etc/passwd (Adding a new user)
* /home/USERNAME (Adding a new home directory)
   * Adding a new sub-directory sftp_home
* /etc/ssh/sshd_config (Changing a the end of the file the sftp behaviour)
* restart sshd if config is fine

### Call this script as root ./make_sftp_chroot.sh <NEW_USER>
