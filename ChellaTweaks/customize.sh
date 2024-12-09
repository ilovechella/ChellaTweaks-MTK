set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive $MODPATH/tweaks 0 0 0755 0755

# Install toast app
ui_print " 📲 Install Toast app"
pm install $MODPATH/Toast.apk
ui_print " "

find $MODPATH/* -maxdepth 0 \
    ! -name 'module.prop' \
    ! -name 'service.sh' \
    ! -name 'uninstall.sh' \
    ! -name 'tweaks' \
    -exec rm -rf {} \;

# Check rewrite directory
if [ ! -e /storage/emulated/0/ChellaTweaks ]; then
  mkdir /storage/emulated/0/ChellaTweaks
fi

# Check applist file
if [ ! -e /storage/emulated/0/ChellaTweaks/meowlist.txt ]; then
  cp -f $MODPATH/tweaks/meowlist.txt /storage/emulated/0/ChellaTweaks
fi

nohup am start -a android.intent.action.VIEW -d https://t.me/chellaprojects >/dev/null 2>&1 &