# Configuration

This playbook mainly uses two files to configure rook to work with a ceph cluster:

* k8s_rook_ceph_conf_ini_file
* k8s_rook_ceph_conf_key_ring

From these files, we draw most of the configurations. To alter default behavior, or not use the files at all, we can set the following variables:

* k8s_rook_ceph_fsid
* k8s_rook_ceph_admin_user_name
* k8s_rook_ceph_admin_secret
* k8s_rook_ceph_mon_data
* k8s_rook_ceph_monitors
* k8s_rook_rbd_pool_name

If defined, they take precedence over what is in the configuration and keyring files
