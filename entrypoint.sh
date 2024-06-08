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

# Exit script with status code and message
#
# $1 - Exit code
# $2 - Message to be dumped before exiting
function exit_with {
  prefix="::notice"
  if [[ "${1}" != "0" ]]; then
    prefix="::error"
  fi
  echo "${prefix}::$2"
  exit $1
}

# Takes absolute or relative paths and returns the absolute path value
# based on the current working directory.
#
# $1 - The path of the file that should be resolved as absolute path
#
# Examples (assuming pwd=/home/user/bruno-action)
#   absolute_path "out/bruno.log" => /home/user/bruno-action/out/bruno.log
#   absolute_path "/out/bruno.log" => /out/bruno.log
function absolute_path {
  input_path="${1}"
  origin_dir=$(pwd)
  cd "$(dirname ${input_path})" &>/dev/null || exit_with 1 "the directory of the provided path '${input_path}' does not exist"
  out_abs_path=$(pwd)
  out_filename=$(basename ${input_path})
  cd ${origin_dir}
  echo "${out_abs_path}/${out_filename}"
}

# Parse input parameters
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
  bru_args="${bru_args} --output $(absolute_path ${INPUT_OUTPUT})"
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

# Change to provided working directory
if [ -n "${INPUT_PATH}" ]; then
  cd "${INPUT_PATH}" || exit_with 1 "The provided bruno collection path '${INPUT_PATH}' does not exist"
fi

# Dump current working directory
echo "::notice::collection directory: '$(pwd)'"

# Only dump command if DRY_RUN is enabled and exit
if [ -n "${dry_run}" ]; then
  echo "::notice::bru run ${bru_args}"
  exit_with 0 "Executed in dry mode, skipped executing bruno collection"
fi

# Execute 'bru run ...' and evaluate execution status
if eval "bru run ${bru_args}"; then
  # Write outputs to the $GITHUB_OUTPUT file
  echo "success=true" >>"${GITHUB_OUTPUT}"
  exit_with 0 "bru run suceeded."
else
  bru_exit_code=$?
  # Write outputs to warning $GITHUB_OUTPUT file
  echo "success=false" >>"${GITHUB_OUTPUT}"
  exit_with ${bru_exit_code} "bru run failed failed with status: ${bru_exit_code}."
fi
