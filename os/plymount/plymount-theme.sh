#!/bin/bash
# @summary: Installs Plymouth boot animation theme.
sudo cp -r "$(dirname "$0")/xkor" /usr/share/plymouth/themes/
sudo plymouth-set-default-theme -R xkor
