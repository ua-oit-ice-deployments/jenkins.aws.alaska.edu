#!/bin/bash
root=$(cd "$(dirname "$(which "$0")")" && pwd)
secrets_source=$1

jobs_vol="$root/docker/volumes/jobs"
secrets_vol="$root/docker/volumes/secrets"
mkdir -p "$jobs_vol" "$secrets_vol"
if [ ! $(stat -c%u "$jobs_vol") = 1000 ] ; then
  sudo chown -R 1000 "$jobs_vol"
fi
if [ ! $(stat -c%g "$secrets_vol") = 1000 ] ; then
  sudo chown -R :1000 "$secrets_vol"
  sudo chmod 2750 "$secrets_vol"
fi

if [ -f "$secrets_source" ] ; then
  rm -rf "$secrets_vol/jenkins"
  jenkins="$(cat "$secrets_source")" docker run --rm \
    --name jenkins-secrets \
    -e jenkins \
    -v "$secrets_vol:/run/secrets" \
    docker/ecs-secrets-sidecar:latest '[{"Name":"jenkins","Keys":["*"]}]'
elif [ -d "$secrets_source" ] ; then
  rm -rf "$secrets_vol/jenkins"
  (umask 027; cp -r "$secrets_source" "$secrets_vol/jenkins")
fi

unset fail
secrets=$(grep '${' jenkins.casc.yml | sed 's,.*\${\([^:}]*\)}.*,\1,' | sort -u)
for ss in $secrets ; do
  if [ ! -e "$secrets_vol/jenkins/$ss" ] ; then
    echo "fatal: secret $secrets_vol/jenkins/$ss does not exist"
    fail=1
  fi
done
test "$fail" && exit 1

(docker build -f docker/Dockerfile -t jenkins-casc:latest .) || exit $?

exec docker run --rm \
  --name jenkins-casc \
  -p 8080:8080 \
  -e "SECRETS=/run/secrets/jenkins" \
  -v "$jobs_vol:/var/jenkins_home/jobs" \
  -v "$secrets_vol:/run/secrets:ro" \
  jenkins-casc:latest
