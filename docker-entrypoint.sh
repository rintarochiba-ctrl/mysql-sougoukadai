#!/bin/bash
set -e

# Buckupディレクトリがマウントされている場合、起動時に/tmpにコピー
if [ -d "/mnt/buckup" ]; then
    echo "Buckupディレクトリから/tmpにファイルをコピーしています..."
    # ディレクトリが空でない場合のみコピー
    if [ "$(ls -A /mnt/buckup 2>/dev/null)" ]; then
        cp -r /mnt/buckup/* /tmp/ 2>/dev/null || true
        echo "コピー完了"
    else
        echo "Buckupディレクトリは空です"
    fi
fi

# 停止時の処理を定義
cleanup() {
    echo "コンテナを停止しています..."
    
    # /tmp配下のバックアップファイルをBuckupディレクトリにコピー
    if [ -d "/mnt/buckup" ]; then
        echo "/tmpからBuckupディレクトリにバックアップファイルをコピーしています..."
        # .sqlファイルのみをコピー（既存ファイルは上書き）
        find /tmp -maxdepth 1 -name "*.sql" -type f -exec cp -f {} /mnt/buckup/ \; 2>/dev/null || true
        echo "バックアップ完了"
    fi
    
    # MySQLが起動している場合のみ停止
    if [ -f /var/run/mysqld/mysqld.pid ]; then
        mysqladmin -uroot -proot shutdown || true
    fi
    exit 0
}

# シグナルをトラップ
trap cleanup SIGTERM SIGINT

# MySQLのデフォルトエントリーポイントを実行
# MySQL 8.0の公式イメージでは、/usr/local/bin/docker-entrypoint.shが存在する
if [ -f /usr/local/bin/docker-entrypoint.sh ]; then
    exec /usr/local/bin/docker-entrypoint.sh "$@"
else
    # フォールバック: 直接mysqldを起動
    exec "$@"
fi

