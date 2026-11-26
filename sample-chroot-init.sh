#!/bin/bash
case "$1" in
	start-after)
		service dockerd start
		service media-downloader start
		service samba4 start
		service sshd restart
		;;

	stop-before)
		service dockerd stop
		service media-downloader stop
		service samba4 stop
		service nfsd stop
		service sshd restart
		;;
esac
