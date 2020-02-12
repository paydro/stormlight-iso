SHELL := /bin/bash
CPIO := vendor/cpio/bin/cpio
ISO_URL := "http://archive.ubuntu.com/ubuntu/dists/bionic-updates/main/installer-amd64/current/images/netboot/mini.iso"
ISO := stormlight.iso

VM_NAME := stormlight-nuc
VB := VBoxManage

.DEFAULT_GOAL := stormlight.iso

.PHONY: install-deps
install-deps: .make.deps.cpio .make.deps.homebrew

.make.deps.cpio:
	bin/deps/cpio
	touch .make.deps.cpio

.make.deps.homebrew:
	bin/deps/homebrew
	touch .make.deps.homebrew

stormlight.iso: build/iso/initrd.gz build/iso/txt.cfg build/iso/boot/grub/grub.cfg install-deps
	bin/create-iso

build/iso/initrd.gz: config/preseed.cfg config/post-install.sh config/authorized_keys build/base.iso
	$(MAKE) clean-iso-workspace
	bin/extract-and-modify

build/iso/txt.cfg: config/txt.cfg build/base.iso
	$(MAKE) clean-iso-workspace
	bin/extract-and-modify

build/iso/boot/grub/grub.cfg: config/grub.cfg build/base.iso
	$(MAKE) clean-iso-workspace
	bin/extract-and-modify

build/base.iso:
	-mkdir build
	curl $(ISO_URL) > build/base.iso

.PHONY: vm
vm:
	bin/build-vm

vm-create:
	bin/create-vm $(VM_NAME)

.PHONY: vm-start
vm-start:
	$(VB) startvm $(VM_NAME)

.PHONY: vm-stop
vm-stop:
	-$(VB) controlvm $(VM_NAME) poweroff

.PHONY: vm-insert-iso
vm-insert-iso: stormlight.iso
	$(VB) storageattach $(VM_NAME) \
		--storagectl ide \
		--port 1 \
		--device 0 \
		--type dvddrive \
		--medium $(shell pwd)/$(ISO)

.PHONY: vm-eject-iso
vm-eject-iso:
	-$(VB) storageattach $(VM_NAME) \
		--storagectl ide \
		--port 1 \
		--device 0 \
		--type dvddrive \
		--medium none

# I found cases where virtualbox used a cached version of the ISO. Ejecting
# and inserting the ISO back into the VM works around this.
.PHONY: vm-reset-iso
vm-reset-iso: vm-eject-iso vm-insert-iso

.PHONY: vm-clean
vm-clean:
	-$(VB) unregistervm --delete $(VM_NAME)
	-$(VB) closemedium disk build/vms/stormlight-iso/disk.vdi --delete
	-rm -rf build/vms/$(VM_NAME)

.PHONY: test
test:
	vendor/bats/bin/bats tests

.PHONY: inspect-initrd
inspect-initrd:
	gunzip -c build/iso/initrd.gz | $(CPIO) -ivt

.PHONY: clean
clean: clean-iso-workspace vm-clean
	-rm -rf build stormlight.iso

.PHONY: clean-iso-workspace
clean-iso-workspace:
	-chmod -R +w build/iso
	-rm -rf build/iso

