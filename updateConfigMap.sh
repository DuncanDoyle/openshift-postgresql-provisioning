#/bin/sh

# Replace the ConfigMap
echo "Updating ConfigMap"
oc create configmap postgresql-config-map --from-file=./contrib/wait_for_postgres.sh --from-file=./contrib/provision_data.sh --from-file=./contrib/provision_test_data.sql --dry-run -o yaml | oc replace -f -

# Rollout a new version of the pod
echo "Rolling out new version of the PostgreSQL pod."
oc rollout latest postgresql
