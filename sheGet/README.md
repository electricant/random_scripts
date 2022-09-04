sheGet
======

I neended a download manager tyhat could be run as a cron job with a simple command-line interface.
This is the result. It even supports priorities!
This script uses sqlite for holding and retrieving the downloads. The actual download is done by wget.

* Usage:

The main script is sheget. Just run it. It will query de database and download the files.
If nothing has to be downloaded then the script will sleep for a selectable amount of time.

To add an url in the queue use 'sheget-add url [priority]'.

To print the current status of the downloads run 'sheget -l'.

* Installation:

Copy the files where you whish and use 'sheget-makedb.sh path/to/database' to create the database.
Make sure to edit the proper config options (sheget.conf).
