# Automatic Snapshots for Google Kubernetes Engine

This is a kubernetes cronjob that automatically snapshots all Google Compute Engine disks in a Google cloud project, excepting the disks for the stateless cluster nodes.

If a disk is related to a PVC in the k8s cluster, then the snapshots are named using the k8s PVC namespace and name.

Google snapshots are incremental, and don't need to be deleted. If you delete an earlier snapshot the block are automatically migrated to the later snapshot.  So deleting snapshots does not save space, but for convenience, rather than an infinitely long list, it is useful to purge earlier snapshots assuming that you would never need granularity. This script assumes 60 days is sufficient.

This is a fork of Alan Fullmer's project at https://gitlab.com/alan8/google-cloud-auto-snapshot.


## How it works

- Determine all Compute Engine Disks in the current project, filtering out any based on containeros images.
- Take a snapshot of all disks - snapshots prefixed autosnap-{DISK_NAME-YYYY-MM-DD-sssssssss} or autosnap-pvc-{PVC_NAMESPACE-PVC_NAME-YYYY-MM-DD-sssssssss}.
- Delete all associated snapshots prefixed with `autosnap-` that are older than 60 days.


## Installation

This is intended to be executed as a cronjob on a k8s cluster in the GCP project where the target disks reside.

Take a look at `gke-autosnap-cronjob.yaml` for an example k8s cronjob resource definition which runs snapshots every 6 hours (0,6,12,18).
Make any desired changes and apply it to your cluster via `kubectl apply -f gke-autosnap-cronjob.yaml`.


## Permissions

The `snapshotter-role.yaml` file describes a GCP role with all of the permissions this
project needs to do its job. 

The `create-snapshotter-role.sh` script can be used to create this role in a Google Cloud project:

	$ PROJECT=my-gcp-project ./create-snapshotter-role.sh

The best solution to apply this role at runtime is to use an [account assigner][1] that can provide pods
with permissions unique to their task in GCP. The example cronjob resource yaml has annotations used by this assigner.

Alternatively, the created role can be applied to your default GCE compute service account identity.
This will give any pod in your cluster the ability to use these permissions. This is not a great thing
to do-from a security POV-except in the simplest of test clusters.

[1]: https://github.com/imduffy15/k8s-gke-service-account-assigner


## Snapshot Retention

Snapshots are kept for 60 days


## Limitations, possible future enhancements
* Works for all disks in a project, can't be selective
* Only works for default project for the gcloud environment ( see  gcloud info )
* Only manages snapshots created by the script ( prefixed autosnap- )
