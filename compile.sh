#!/usr/bin/env bash

# compile and install VMware Tools

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -d vmware-tools-distrib ]]; then
  echo $0: Error: Directory not found: vmware-tools-distrib >&2
  exit 3
fi

if hash vmware-uninstall-tools.pl >/dev/null 2>&1; then
  sudo vmware-uninstall-tools.pl
fi


VMWARE_INSTALL_OPTIONS="--clobber-kkernel-modules=pvscsi,vmblock,vmci,vmhgfs,vmmemctl,vmsync,vmxnet,vmxnet3,vsock"
ANSWERS="--default"

# The number of answers required changes between tools versions
# future work is to come up with simple defaults for each tools version
# or figure out how to discover number of answers required via some other mechanism
if [[ -n "$1" ]]; then
  if [[ -f "$1" ]]; then
    if  [[ `grep "/usr/lib/vmware-tools" "$1"` ]]; then
      #echo "Passed file has some valid answers for vmware-tools"
      ANSWERS=$(cat "$1")
    else
      echo "Passed file but invalid answer file for vmware-tools"
    fi
  elif [[ "$1" == *"yes"* ]] && [[ "$1" == *"/usr/lib/vmware-tools"* ]]; then
    #echo "Some valid answers were passed"
    ANSWERS="$1"
  else
    #echo "Overriding default force options using supplied force options"
    VMWARE_INSTALL_OPTIONS="$1"
  fi
fi

pushd vmware-tools-distrib >/dev/null

if hash systemctl >/dev/null 2>&1; then
  echo "Creating empty init dirs for backwards compatibility"
  for x in {0..6}; do mkdir -p /etc/init.d/rc${x}.d; done
  sudo cp $SCRIPT_DIR/patches/vmware-tools.service /etc/systemd/system/
  sudo systemctl enable vmware-tools.service
  echo "Added and enabled VMware Tools systemd service"
fi

if sudo ./vmware-install.pl --help 2>&1 | grep -q 'force-install'; then
    VMWARE_INSTALL_OPTIONS="--force-install ${VMWARE_INSTALL_OPTIONS}"
fi

sudo ./vmware-install.pl ${ANSWERS} ${VMWARE_INSTALL_OPTIONS}

popd >/dev/null
