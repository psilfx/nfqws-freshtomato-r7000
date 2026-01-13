#!/bin/bash

BASE_DIR=$(pwd)
PROC_ARCH=$(uname -m)
NFQWS_BINARY_FILE="nfqws"
HOSTS_USER="$BASE_DIR/hosts/zapret-hosts-user.txt"
HOSTS_USER_EXCLUDE="$BASE_DIR/hosts/zapret-hosts-user-exclude.txt"
CONFIG_FILE="zapret.config.json"
OPKG_INSTALL="jq"

echo "$PROC_ARCH"
echo "$BASE_DIR"

read -p "Хотите продолжить?(y/n): " continue
#Проверяем ввод пользователя
install=0
if [ "$continue" = "y" -o "$continue" = "Y" -o "$continue" = "Д" -o "$continue" = "д" ]; then
	install=1
fi
if [ $install -eq 0 ]; then
	echo ""
	echo "Отменено пользователем...выходим..."
	exit 0
fi
echo ""
echo "Устанавливаем пакеты..."
echo ""
opkg update
opkg install "$OPKG_INSTALL"
#Создаём список интерфейсов
interfaces=$(ls /sys/class/net/)
icount=0
for iface in $interfaces; do
    icount=$((icount + 1))
    echo "$icount. $iface"
done
#Выбор пользовательского интерфейса
echo ""
read -p "Выбор интерфейса: " lan_interface
selected_interface="none"
icount=0
for iface in $interfaces; do
    icount=$((icount + 1))
    if [ "$icount" = "$lan_interface" ]; then
		selected_interface="$iface"
		break
	fi
done
if [ "$selected_interface" = "none" ]; then
	echo ""
	echo "Ничего не выбрано...повторите попытку..."
	exit 0
fi
echo ""
echo "Сетевой интерфейс: $selected_interface"
echo ""
echo "Создаём файл конфига..."
if [ -f "$CONFIG_FILE" ]; then
	rm "$BASE_DIR/$CONFIG_FILE"
	echo "Старый конфиг был удалён..."
fi
cat > "$CONFIG_FILE" << EOF
{
    "interface": "$selected_interface",
    "basedir": "$BASE_DIR",
	"arch": "$PROC_ARCH",
	"huser": "$HOSTS_USER",
	"strategy": "--dpi-desync=split2 --dpi-desync-split-seqovl=1 --dpi-desync-split-pos=2 --wssize=1:6",
	"binary": "$NFQWS_BINARY_FILE",
	"huserexclude": "$HOSTS_USER_EXCLUDE"
}
EOF
if [ ! -f "$CONFIG_FILE" ]; then
	echo "Ошибка...$BASE_DIR/$CONFIG_FILE"
fi
echo "Запись в $BASE_DIR/$CONFIG_FILE успешно..."
#Копируем нужные файлы в систему
echo ""
echo "Работаем с файлами..."
mkdir -p /opt/bin /opt/etc
if [ ! -f "$BASE_DIR/install/binaries/$PROC_ARCH/$NFQWS_BINARY_FILE" ]; then
	echo "Не найден бинарник $NFQWS_BINARY_FILE"
	exit 0
fi
#Копируем главный бинарь
if [ ! -f "/opt/bin/$NFQWS_BINARY_FILE" ]; then
	echo "Копируем бинарник в /opt/bin/$NFQWS_BINARY_FILE..."
	cp "$BASE_DIR/install/binaries/$PROC_ARCH/$NFQWS_BINARY_FILE" "/opt/bin/"
	chmod +x "/opt/bin/$NFQWS_BINARY_FILE"
else
	echo "Бинарник уже существует /opt/bin/$NFQWS_BINARY_FILE..."
fi
#Копируем конфиг
if [ -f "/opt/etc/$CONFIG_FILE" ]; then
	echo "Конфиг уже существует в /opt/etc/$CONFIG_FILE...перезапишем..."
	rm "/opt/etc/$CONFIG_FILE"
fi
mv "$BASE_DIR/$CONFIG_FILE" "/opt/etc/"
echo "Копируем новый файл в /opt/etc/$CONFIG_FILE..."
#Копируем службу
if [ ! -f "/opt/etc/zapret_ctl" ]; then
	echo "Служба успешно установлена..."
	cp "$BASE_DIR/install/zapret_ctl" "/opt/etc/"
	chmod +x "/opt/etc/zapret_ctl"
else
	echo "Служба уже установлена..."
fi
echo ""
echo "Применяем алиасы..."
echo "alias zapret_ctl='sh /opt/etc/zapret_ctl'" >> "/opt/etc/profile"
echo "zapret_ctl start" >> "/opt/etc/profile"
alias zapret_ctl="sh /opt/etc/zapret_ctl"
echo ""
echo "========================================"
echo "Zapret доступен по команде: zapret_ctl { start | stop | restart | help }"
echo "========================================"
exit 0