#!/bin/sh

#chip="x86"
chip="arm"

if [	$1 -a $1 = "clean" 	]
then
	make chip=$chip clean
	echo "clean $chip obj file"
elif [	$1 -a $1 = "cleanall" 	]
then
	make chip=$chip cleanall
	echo "clean all $chip obj file"
else
	echo "rm $chip hy_server"
	rm bin/$chip/hy_server
	make chip=$chip
	cd bin/$chip/
	cp ./hy_server /opt/tftpboot
	#tar -cjf /opt/tftpboot/hy_server.bz2 ./hy_server
fi

