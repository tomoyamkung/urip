#!/bin/bash
# shellcheck disable=SC3040
set -euo pipefail


function usage() {
    cat <<EOF 1>&2
Description:
    $(basename "${0}") is a tool that looks up client IPs in AWS WAF logs.
    The behavior of this tool is as follows.

    1. Run s3 cp to copy the WAF log to your working directory
    2. Search the log by URI
    3. Output the client IP of the corresponding log

    $(basename "${0}") は AWS WAF のログからクライアント IP を検索するツールです。
    このツールの挙動は以下の通りです。

    1. s3 cp を実行して、作業ディレクトリに WAF のログをコピーする
    2. ログに対して URI で検索する
    3. 該当したログのクライアント IP を出力する

Usage:
    $(basename "${0}") --profile PROFILE_NAME --source S3_SOURCE uri

Options:
    --help      print this.
                これを出力します。
    --profile   Required fields. Specify the profile of the AWS account you want to search.
                必須項目です。検索したい AWS アカウントのプロファイルを指定します。
    --source    Required fields. Specify the bucket name and path where the WAF logs are stored. For example, "bucket_name /path/to".
                必須項目です。WAF のログが保管してあるバケット名とパスを指定します。例えば、"bucket_name/path/to" と指定します。
EOF
}


while (( $# > 0 ))
do
    case $1 in
        --help)
            usage
            exit 1
            ;;
        --profile)
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "'option' requires an argument." 1>&2
                exit 2
            else
                PROFILE="${2}"
                echo "PROFILE:${PROFILE}"
                shift
            fi
            ;;
        --source)
            if [[ -z "$2" ]] || [[ "$2" =~ ^-+ ]]; then
                echo "'option' requires an argument." 1>&2
                exit 3
            else
                SOURCE="${2}"
                echo "SOURCE:${SOURCE}"
                shift
            fi
            ;;
        -*)
            usage
            exit 1
            ;;
        *)
            URI="${1}"
            echo "URI:${URI}"
            ;;
    esac
    shift
done


WORK_DIR=".work"
if [ -d ${WORK_DIR} ]; then
    rm -fr ${WORK_DIR}
fi
mkdir -p ${WORK_DIR}

cd ${WORK_DIR}
aws s3 --profile "${PROFILE}" cp s3://"${SOURCE}" . --recursive > /dev/null

# schellcheck disable=SC2038
find . -type f -name "aws-*" \
    | xargs jq "select(.action == \"ALLOW\" and .httpRequest.uri == \"${URI}\") | {clientIp: .httpRequest.clientIp, headers: .httpRequest.headers, coutry: .httpRequest.country}"

(cd - && rm -fr ${WORK_DIR}) > /dev/null
exit 0
