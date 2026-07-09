#!/system/bin/sh
if ! applypatch -c EMMC:/dev/block/recovery:15151104:fa27e1523834b91caeb823c1f2f6663e267d7024; then
  applypatch  EMMC:/dev/block/boot:7403520:d5a4a73b4c3650f700194bbef68311c3d3791aab EMMC:/dev/block/recovery 844ce5de2694a67651d744b634395175f698d36e 15149056 d5a4a73b4c3650f700194bbef68311c3d3791aab:/system/recovery-from-boot.p && installed=1 && log -t recovery "Installing new recovery image: succeeded" || log -t recovery "Installing new recovery image: failed"
  [ -n "$installed" ] && dd if=/system/recovery-sig of=/dev/block/recovery bs=1 seek=15149056 && sync && log -t recovery "Install new recovery signature: succeeded" || log -t recovery "Installing new recovery signature: failed"
else
  log -t recovery "Recovery image already installed"
fi
