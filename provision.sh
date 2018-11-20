#!/bin/sh

OCP_VERSION_TAG="v3.11.0"
OCP_PROJECT="rhpam7-workshop-reporting"
OPENSHIFT_PAM7_TEMPLATES_TAG="7.1.0.GA"

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

# Import PAM ImageStreams
oc create -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/$OPENSHIFT_PAM7_TEMPLATES_TAG/rhpam71-image-streams.yaml

# Import PostgreSQL ephemeral template
oc create -f https://raw.githubusercontent.com/openshift/origin/$OCP_VERSION_TAG/examples/db-templates/postgresql-ephemeral-template.json

# Import PAM templates
oc create -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/$OPENSHIFT_PAM7_TEMPLATES_TAG/templates/rhpam71-trial-ephemeral.yaml

# Create Secrets and Service accounts
oc process -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/$OPENSHIFT_PAM7_TEMPLATES_TAG/example-app-secret-template.yaml | oc create -f -
oc process -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/$OPENSHIFT_PAM7_TEMPLATES_TAG/example-app-secret-template.yaml -p SECRET_NAME=kieserver-app-secret | oc create -f -


# Create new application
oc new-app --template=postgresql-ephemeral \
	-p NAMESPACE=$OCP_PROJECT \
	-p POSTGRESQL_DATABASE="rhpam7_workshop_reporting" \
	-p POSTGRESQL_USER=postgres \
	-p POSTGRESQL_PASSWORD=postgres

# Create ConfigMap
oc create configmap postgresql-config-map --from-file=./contrib/provision_data.sh --from-file=./contrib/wait_for_postgres.sh --from-file=./contrib/provision_test_data.sql

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


# Create PAM app
oc new-app --template=rhpam70-trial-ephemeral \
-p APPLICATION_NAME="rhpam7-workshop" \
-p IMAGE_STREAM_NAMESPACE="openshift" \
-p KIE_ADMIN_USER="developer" \
-p KIE_SERVER_CONTROLLER_USER="kieserver" \
-p KIE_SERVER_USER="kieserver" \
-p DEFAULT_PASSWORD="developer" \
-p MAVEN_REPO_USERNAME="developer" \
-p MAVEN_REPO_PASSWORD="developer" \
-p BUSINESS_CENTRAL_MEMORY_LIMIT="2Gi" \
-e JAVA_OPTS_APPEND=-Derrai.bus.enable_sse_support=false
