#!/bin/sh

OCP_VERSION_TAG="v3.11.0"
OCP_PROJECT="rhpam7-workshop-reporting"

echo "Enter your registry.redhat.io username: " 
read  REGISTRY_REDHAT_IO_USERNAME
echo "Enter your registry.redhat.io password: "
read -s REGISTRY_REDHAT_IO_PASSWORD
echo "Enter password again."
read -s CHECK_PASSWORD

if [ "$REGISTRY_REDHAT_IO_PASSWORD" != "$CHECK_PASSWORD" ]
then
	echo  "Passwords don't match."
fi

oc new-project rhpam7-workshop-reporting

# Configure secrets 
oc create secret docker-registry red-hat-container-registry \
  --docker-server=https://registry.redhat.io \
  --docker-username="$REGISTRY_REDHAT_IO_USERNAME" \
  --docker-password="$REGISTRY_REDHAT_IO_PASSWORD" \
  --docker-email="ddoyle@redhat.com"
  
oc secrets link builder red-hat-container-registry --for=pull

# Import RHEL7-based ImageStreams.
oc create -f https://raw.githubusercontent.com/openshift/origin/$OCP_VERSION_TAG/examples/image-streams/image-streams-rhel7.json

# Import PostgreSQL ephemeral template
oc create -f https://raw.githubusercontent.com/openshift/origin/$OCP_VERSION_TAG/examples/db-templates/postgresql-ephemeral-template.json

# Create new application
oc new-app --template=postgresql-ephemeral \
	-p NAMESPACE=$OCP_PROJECT \
	-p POSTGRESQL_DATABASE="rhpam7_workshop_reporting" \
	-p POSTGRESQL_USER=postgres \
	-p POSTGRESQL_PASSWORD=postgres


# Create ConfigMap
oc create configmap postgresql-config-map --from-file=./contrib/provision_data.sh --from-file=./contrib/wait_for_postgres.sh

# Attach ConfigMap as Volume
oc volume dc/postgresql --name=postgresql-config-volume --add -m /tmp/config-files -t configmap --configmap-name=postgresql-config-map

# Create Post Deployment LifeCycle hook.
oc set deployment-hook dc/postgresql --post \
	-c postgresql \
	-e POSTGRESQL_HOSTNAME=postgresql \
	-e POSTGRESQL_USER=postgres \
	-e POSTGRESQL_PASSWORD=postgres \
	--volumes=postgresql-config-volume \
	--failure-policy=abort \
	-- /bin/bash /tmp/config-files/wait_for_postgres.sh /tmp/config-files/provision_data.sh
