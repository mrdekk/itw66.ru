#!/bin/bash

cwd=$(pwd)

docker run \
	-it \
	-e DEBUG=true \
	-p 4000:4000 \
	-v ${cwd}:/src \
	--label=mrdekk_itw66 \
	mrdekk/itw66 \
	/src/run.sh \
	--host 0.0.0.0