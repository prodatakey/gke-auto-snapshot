#!/bin/bash
PROJECT="`gcloud config get-value project`"

gcloud iam roles create snapshotter --project $PROJECT --file snapshotter-role.yaml

gcloud iam service-accounts create snapshotter --display-name Snapshotter

gcloud projects add-iam-policy-binding $PROJECT \
    --member serviceAccount:snapshotter@$PROJECT.iam.gserviceaccount.com \
    --role projects/$PROJECT/roles/snapshotter
