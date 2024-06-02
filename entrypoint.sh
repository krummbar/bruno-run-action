#!/bin/bash
bru_args=''
dry_run="${BRUNO_ACTION_DRY_RUN}"
echo "::debug::INPUT_PATH='${INPUT_PATH}'"
echo "::debug::INPUT_FILENAME='${INPUT_FILENAME}'"
echo "::debug::INPUT_RECURSIVE='${INPUT_RECURSIVE}'"
echo "::debug::INPUT_ENV='${INPUT_ENV}'"
echo "::debug::INPUT_ENVVARS='${INPUT_ENVVARS}'"
echo "::debug::INPUT_OUTPUT='${INPUT_OUTPUT}'"
echo "::debug::INPUT_OUTPUTFORMAT='${INPUT_OUTPUTFORMAT}'"
echo "::debug::INPUT_INSECURE='${INPUT_INSECURE}'"
echo "::debug::INPUT_TESTSONLY='${INPUT_TESTSONLY}'"
echo "::debug::INPUT_BAIL='${INPUT_BAIL}'"
echo "::debug::DRY_RUN='${dry_run}'"

# Parse input parameters
# Change to provided working directory
if [ -n "${INPUT_PATH}" ]; then
  cd "${INPUT_PATH}" || exit 1
fi
if [ -n "${INPUT_FILENAME}" ]; then
  bru_args="${INPUT_FILENAME}"
fi

if [ -n "${INPUT_RECURSIVE}" ]; then
  bru_args="${bru_args} -r"
fi

if [ -n "${INPUT_ENV}" ]; then
  bru_args="${bru_args} --env ${INPUT_ENV}"
fi

if [ -n "${INPUT_OUTPUT}" ]; then
  bru_args="${bru_args} --output ${INPUT_OUTPUT}"
fi

if [ -n "${INPUT_OUTPUTFORMAT}" ]; then
  bru_args="${bru_args} --format ${INPUT_OUTPUTFORMAT}"
fi

if [ -n "${INPUT_INSECURE}" ]; then
  bru_args="${bru_args} --insecure"
fi

if [ -n "${INPUT_TESTSONLY}" ]; then
  bru_args="${bru_args} --tests-only"
fi

if [ -n "${INPUT_BAIL}" ]; then
  bru_args="${bru_args} --bail"
fi

# Assign --env-var key=value if provided
# Key value pairs must be separated by line breaks
if [ -n "${INPUT_ENVVARS}" ]; then
  while read -r env_var; do
    bru_args="${bru_args} --env-var ${env_var}"
  done < <(echo -e "${INPUT_ENVVARS}")
fi

# Dump current working directory
echo "::notice::collection directory: '$(pwd)'"

# Only dump command if DRY_RUN is enabled and exit
if [ -n "${dry_run}" ]; then
  echo "::notice::bru run ${bru_args}"
  exit 0
fi

# Execute 'bru run ...' and evaluate execution status
if eval "bru run ${bru_args}"; then
  echo "::notice::bru run succeeded."
  # Write outputs to the $GITHUB_OUTPUT file
  echo "success=true" >>"${GITHUB_OUTPUT}"
  exit 0
else
  echo "::warning::bru run failed with status: $?"
  # Write outputs to the $GITHUB_OUTPUT file
  echo "success=false" >>"${GITHUB_OUTPUT}"
  exit 1
fi
