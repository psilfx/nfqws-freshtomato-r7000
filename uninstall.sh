#!/bin/bash

APP_BASE_DIR=$(jq -r .basedir /opt/etc/zapret.config.json)
FILE_BIN="/opt/bin/$(jq -r .binary /opt/etc/zapret.config.json)"
FILE_CFG="/opt/etc/zapret.config.json"
FILE_CTL="/opt/etc/zapret_ctl"

sh /opt/etc/zapret_ctl stop

echo ""
echo "Удаляем бинарник... $FILE_BIN"
if [ -f "$FILE_BIN" ]; then
	rm "$FILE_BIN"
	echo "Файл был удалён... $FILE_BIN"
fi
echo "Удаляем файл конфига... $FILE_CFG"
if [ -f "$FILE_CFG" ]; then
	rm "$FILE_CFG"
	echo "Файл был удалён... $FILE_CFG"
fi
echo "Удаляем менеджер комманд... $FILE_CTL"
if [ -f "$FILE_CTL" ]; then
	rm "$FILE_CTL"
	echo "Файл был удалён... $FILE_CTL"
fi
echo ""
echo "Удаляем алиасы..."
sed -i '/alias zapret_ctl=/d' /opt/etc/profile
sed -i '/zapret_ctl start/d' /opt/etc/profile
echo ""
read -p "Удалить папку $APP_BASE_DIR?(y/n): " delete_app_dir
if [ "$delete_app_dir" = "y" -o "$delete_app_dir" = "Y" -o "$delete_app_dir" = "Д" -o "$delete_app_dir" = "д" ]; then
	rm -rf "$APP_BASE_DIR"
	echo "Папка была удалена..."
else 
	echo "Оставляем папку..."
fi
echo ""
echo "$FILE_BIN"
echo "$FILE_CFG"
echo "$FILE_CTL"
echo ""
echo "Файлы были удалены."
echo ""
exit 0