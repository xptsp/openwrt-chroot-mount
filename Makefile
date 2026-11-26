include $(TOPDIR)/rules.mk

PKG_NAME:=chroot-mount
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/chroot-mount
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Chroot Mounter
  # DEPENDS:=+bash +coreutils-tac +mount-utils
endef

define Package/chroot-mount/description
  A package that mounts a chroot environment as specified, waiting until
  each partition is ready before mounting to specified directory.
endef

define Build/Compile
	# Leave empty as the files do not need compiling
endef

define Package/chroot-mount/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/chroot_mount.init $(1)/etc/init.d/chroot_mount

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/chroot_mount.config $(1)/etc/config/chroot_mount

	$(INSTALL_DIR) $(1)/etc/hotplug.d/block
	$(INSTALL_BIN) ./files/chroot_mount.hotplug $(1)/etc/hotplug.d/block/99-chroot-uuid
endef

define Package/chroot-mount/conffiles
/etc/config/chroot_mount
endef

$(eval $(call BuildPackage,chroot-mount))
