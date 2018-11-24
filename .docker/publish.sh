#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." > /dev/null && pwd)"
IMAGE_PREFIX=${IMAGE_PREFIX:-"riemannio/"}

function getVersion {
	local path=$ROOT_DIR
	[ -z "$1" ] || path="$ROOT_DIR/tools/$1"
	cat $path/Rakefile.rb | grep s.version | grep -oE '[0-9.]{5,}'
}

function getPackageList {
	echo -n "riemann-tools:`getVersion`"
	[ -z "$1" ] || echo -n " $1:`getVersion $1`"
}

function dockerfile {
	local packages=`getPackageList $1`
	sed "s/^ARG RUBY_GEMS=.*/ARG RUBY_GEMS=\"$packages\"/" < $ROOT_DIR/.docker/Dockerfile.tmpl
}

# Need to log in before we can push.
[ -z "$DOCKER_USER" ] && echo "DOCKER_USER is not set" && exit 1
[ -z "$DOCKER_PASS" ] && echo "DOCKER_PASS is not set" && exit 1
docker login -u $DOCKER_USER -p $DOCKER_PASS

tool=${EXTRA_TOOL:-""}
version=`getVersion $tool`
name=${IMAGE_PREFIX}riemann-tools${tool/riemann/}

echo "==> Publishing $name:$version and :latest"
dockerfile $tool | docker build --cache-from $name:latest -f - -t $name:$version -t $name:latest $ROOT_DIR/.docker
docker push $name:$version
docker push $name:latest
