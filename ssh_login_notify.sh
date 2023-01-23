#!/bin/sh
#
# Script taken from:
#  https://askubuntu.com/questions/179889/how-do-i-set-up-an-email-alert-when-a-ssh-login-is-successful#448602
#
# You can put the file in /usr/local/bin or in /etc/ssh/ for example. Don't
# forget to run chmod +x login-notify.sh to make it executable. And give 
# ownership to root with sudo chown root:root login-notify.sh, so that nobody 
# can mess with the script.
#
# Once you have that, you can add the following line to /etc/pam.d/sshd
# (with the correct /path/to/login-notify.sh of course):
#     session optional pam_exec.so seteuid /path/to/login-notify.sh
#

# Change these two lines:
sender="sender-address@example.com"
recepient="notify-address@example.org"

if [ "$PAM_TYPE" != "close_session" ]; then
    host="`hostname`"
    subject="SSH Login: $PAM_USER from $PAM_RHOST on $host"
    # Message to send, e.g. the current environment variables.
    message="`env`"
    echo "$message" | mailx -r "$sender" -s "$subject" "$recepient"
fi
