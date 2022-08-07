#!/bin/bash
# shellcheck disable=SC3040
set -euo pipefail

function to_params() {
    # e.g. ${1} = '{"path": "/path/to","uri": "/hoge"}'
    # => BUCKET_PATH=/path/to, URI=/hoge

    local -r cleaning=$(echo "${1}" | tr -d '{' | tr -d '}' | tr -d '"' | tr -d ' ')

    if echo "${cleaning}" | awk -F, '{print $1}' | grep -q "^path" ; then
        BUCKET_PATH=$(echo "${cleaning}" | awk -F, '{print $1}' | sed -e 's/^\([^:]*\):\(.*\)$/\2/')
        URI=$(echo "${cleaning}" | awk -F, '{print $2}' | sed -e 's/^\([^:]*\):\(.*\)$/\2/')
    else
        BUCKET_PATH=$(echo "${cleaning}" | awk -F, '{print $2}' | sed -e 's/^\([^:]*\):\(.*\)$/\2/')
        URI=$(echo "${cleaning}" | awk -F, '{print $1}' | sed -e 's/^\([^:]*\):\(.*\)$/\2/')
    fi

    readonly BUCKET_PATH
    readonly URI
    # echo "BUCKET_PATH:${BUCKET_PATH}"  # debug_message
    # echo "URI:${URI}"  # debug_message
}

function handler() {
    # e.g. ${1} = '{"path": "/path/to","uri": "/hoge"}'

    aws s3 cp s3://"${BUCKET}${BUCKET_PATH}" . --recursive > /dev/null
    # ${BUCKET} is the bucket name in S3. It should be set to an environment variable.
    # ${BUCKET} はS3 のバケット名。環境変数に設定しておくこと。
    to_params "${1}"

    local -r result=$(find . -type f -name "aws-*" \
        | xargs jq "select(.action == \"ALLOW\" and .httpRequest.uri == \"${URI}\") | {clientIp: .httpRequest.clientIp, headers: .httpRequest.headers, coutry: .httpRequest.country}")
    echo "${result}" 1>&2;  # => clientIp, headers, coutry

    local -r clientip=$(echo "${result}" | grep "clientIp" | awk '{print $2}' | sed -e 's/\"//g' | sed -e 's/,$//g' | sort | uniq)
    echo "${clientip}" 1>&2;  # => clientIp
}