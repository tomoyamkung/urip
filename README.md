# urip

Client IP from URI

## Purpose / 目的

Project for retrieving client IPs from AWS WAF using AWS CLI.
When there is an access to a URI of concern, retrieve the client IP from the URI and use it as a reference for investigation.

AWS CLI を使って AWS WAF からクライアント IP を検索するためのプロジェクト。
気になる URI へのアクセスがあった場合に、URI からクライアント IP を検索して、調査の参考にする。

## Advance preparation / 事前準備

### Install the aws command / aws コマンドをインストールしておく

The installation method is optional. a Docker image is also acceptable.

インストール方法は任意。Docker イメージでも構わない。

```sh
➜  aws --version
aws-cli/2.4.29 Python/3.9.12 Darwin/19.6.0 source/x86_64 prompt/off
```

### Register a profile / プロファイルを登録しておく

Register a profile using IAM credentials.csv.
Specify this profile as an option in the shell script.

IAM の credentials.csv を使用してプロファイルを登録する。
このプロファイルをシェルスクリプトのオプションに指定する。

## execution (e.g. program) / 実行

The `usage` function is provided. The output is as follows.

`usage` 関数を用意した。出力は以下の通り。

```sh
➜  ./function.sh --help
Description:
    function.sh is a tool that looks up client IPs in AWS WAF logs.
    The behavior of this tool is as follows.

    1. Run s3 cp to copy the WAF log to your working directory
    2. Search the log by URI
    3. Output the client IP of the corresponding log

    function.sh は AWS WAF のログからクライアント IP を検索するツールです。
    このツールの挙動は以下の通りです。

    1. s3 cp を実行して、作業ディレクトリに WAF のログをコピーする
    2. ログに対して URI で検索する
    3. 該当したログのクライアント IP を出力する

Usage:
    function.sh --profile PROFILE_NAME --source S3_SOURCE uri

Options:
    --help      print this.
                これを出力します。
    --profile   Required fields. Specify the profile of the AWS account you want to search.
                必須項目です。検索したい AWS アカウントのプロファイルを指定します。
    --source    Required fields. Specify the bucket name and path where the WAF logs are stored. For example, "bucket_name /path/to".
                必須項目です。WAF のログが保管してあるバケット名とパスを指定します。例えば、"bucket_name/path/to" と指定します。
```
