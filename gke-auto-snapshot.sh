#!/bin/bash
# Author: Alan Fuller, Fullworks
# Modified for GKE: Josh Perry, ProdataKey
# loop through all disks within this project and create a snapshot
# ignoring stateless cluster node disks and disks representing k8s PVs
gcloud compute disks list --filter='NOT (sourceImage:* AND sourceImage~^https://www.googleapis.com/compute/v1/projects/gke-node-images/global/images/gke-.*-cos-.*$) AND NOT (description:* AND description:kubernetes.io/created-for/pv/name)' --format='value(name,zone)' | while read DISK_NAME ZONE; do
  gcloud compute disks snapshot $DISK_NAME --snapshot-names autosnap-${DISK_NAME:0:31}-$(date "+%Y-%m-%d-%s") --zone $ZONE
done

# now snapshot k8s PV disks
gcloud compute disks list --filter='description:* AND description~kubernetes.io/created-for/pvc/name' --format='value(name,zone,description)' | while read DISK_NAME ZONE DESC; do
  K8S_PVC_NS=$(echo $DESC | jq -r '."kubernetes.io/created-for/pvc/namespace"')
  K8S_PVC_NAME=$(echo $DESC | jq -r '."kubernetes.io/created-for/pvc/name"')
  NAME_LEN=$((27-${#K8S_PVC_NS})) # How much name can we keep after the NS len

  gcloud compute disks snapshot $DISK_NAME --snapshot-names autosnap-pvc-${K8S_PVC_NS}-${K8S_PVC_NAME:0:$NAME_LEN}-$(date "+%Y-%m-%d-%s") --zone $ZONE
done

#
# snapshots are incremental and dont need to be deleted, deleting snapshots will merge snapshots, so deleting doesn't lose anything
# having too many snapshots is unwiedly so this script deletes them after 60 days
#
if [[ $(uname) == "Linux" ]]; then
  from_date=$(date -d "-60 days" "+%Y-%m-%d")
else
  from_date=$(date -v -60d "+%Y-%m-%d")
fi
gcloud compute snapshots list --filter="creationTimestamp<$from_date AND name:autosnap*" --uri | while read SNAPSHOT_URI; do
   gcloud compute snapshots delete $SNAPSHOT_URI  --quiet
done
#
