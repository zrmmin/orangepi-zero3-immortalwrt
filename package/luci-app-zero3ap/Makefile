#
# Copyright (C) 2026
#
# This is free software, licensed under the Apache License, Version 2.0.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-zero3ap
PKG_VERSION:=1.0
PKG_RELEASE:=1
PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=zrm

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-zero3ap
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Manage Orange Pi Zero3 onboard AP (UWE5622)
  PKGARCH:=all
  DEPENDS:=+wpad-openssl +hostapd-common
endef

define Package/luci-app-zero3ap/description
 LuCI page to manage the standalone hostapd AP for the Orange Pi Zero3 onboard
 UWE5622 (Cdtech 20U5622) Wi-Fi. It deliberately bypasses netifd/wifi-scripts,
 whose nl80211 auto-detection hangs the sprdwl fullmac driver. Settings are
 stored in UCI (/etc/config/zero3ap) and applied by regenerating the hostapd
 config and restarting the service.
endef

# Mark the UCI config as a conffile so user settings survive sysupgrade
define Package/luci-app-zero3ap/conffiles
/etc/config/zero3ap
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/luci-app-zero3ap/install
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/zero3ap
	$(INSTALL_DATA) ./htdocs/luci-static/resources/view/zero3ap/settings.js \
		$(1)/www/luci-static/resources/view/zero3ap/settings.js
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) ./root/usr/share/luci/menu.d/luci-app-zero3ap.json \
		$(1)/usr/share/luci/menu.d/luci-app-zero3ap.json
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) ./root/usr/share/rpcd/acl.d/luci-app-zero3ap.json \
		$(1)/usr/share/rpcd/acl.d/luci-app-zero3ap.json
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./root/etc/config/zero3ap $(1)/etc/config/zero3ap
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./root/etc/init.d/zero3-ap $(1)/etc/init.d/zero3-ap
endef

$(eval $(call BuildPackage,luci-app-zero3ap))
