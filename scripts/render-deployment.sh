#!/bin/bash
set -euo pipefail

function ensureVariables {
  # search for occurences of ${SOME_THING} in deployment yaml files
  local varnames=$(grep -r '${[A-Z0-9_]\+}' -o -h deployment/ | sort | uniq | cut -f2 -d { | cut -f1 -d })
  echo "Checking environment variables"
  for varname in $varnames; do
    if [[ -z ${!varname+x} ]]; then
      echo "Environment variable $varname is not set, aborting."
      return 1
    elif [[ -z ${!varname} ]]; then
      echo "Environment variable $varname is empty, aborting."
      return 1
    else
      echo "Environment variable $varname is set."
    fi
  done
}

ensureVariables

echo -n "Cleaning up ... "
for d in rendered rendered-secrets-tmp; do
  rm -rf ./${d}/ && mkdir -p ./${d}/
done
echo "done"

echo -n "Rendering deployment manifests ... "
for f in ./deployment/*.yaml
do
  filename=$(basename "${f}")
  if [[ "${filename}" != "${filename#_prerendered-}" ]]
  then
    # prerendered files are not to be templated/rendered by envsubst
    cp "${f}" "./rendered/${filename#_prerendered-}"
  else
    envsubst < "${f}" > "./rendered/${filename}"
  fi
done
echo "done"
echo "Apply the Deployment manifests with 'kubectl apply -f ./rendered'"
