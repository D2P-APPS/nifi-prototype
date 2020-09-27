#
# Do not use /tmp from cloud-init use /run/<dir>.
#
package_update: true
package_upgrade: true
package_reboot_if_required: true
packages:
  - docker
  - openssl
  - python3
runcmd:
  - echo "========================================================================"
  - echo "FORMAT EBS VOLUME"
  - mkfs.xfs /dev/nvme1n1
  - mkdir -p /data/1
  - mount /dev/nvme1n1 /data/1
  - echo /dev/nvme1n1 /data/1 xfs defaults 0 0 >> /etc/fstab
