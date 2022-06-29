# rhsso-ora
-----
##Procedure
This section details the procedure to do a migration of Red Hat Single Sign On 7.2 to Red Hat Single Sign On 7.5, both deployed on top of Red Hat OpenShift.

##Prepare Migration
###Requirements:
- oc client installed
- unzip tool
- User logged on OCP with enough privileges to:
  - Create resources on the openshift project
  - Manage SSO 7.2 project
  - Create SSO 7.5 project
- Oracle user with all permissions on a database and SELECT ON SYS.DBA_RECYCLEBIN permissions too.
-----
###Preload Red Hat SSO 7.5 resources in openshift project:

```bash
for resource in sso75-image-stream.json sso75-https.json sso75-postgresql.json \
     sso75-postgresql-persistent.json sso75-x509-https.json \
     sso75-x509-postgresql-persistent.json
do
 oc replace -n openshift --force -f \
https://raw.githubusercontent.com/jboss-container-images/redhat-sso-7-openshift-image/sso75-cpaas-dev/templates/${resource}
done
```


###Next step consist in a backup/export of SSO 7.2:

```bash
oc login -u user -p password
oc project sso-72-project
# edit migration_export-01.sh and migration_export-02.sh, filling up APPNAME_EXPORT variable with the name of the DeploymentConfig
./migration_export-01.sh sso72-project
./migration_export-02.sh sso72-project
# You should find a file named export_all.json on the migration directory and 0 replicas of the SSO pod
```



##Deployment of Red Hat Single Sign On 7.5
###Directory structure:
```bash
rhsso-ora/
├── .credentials
├── install.sh
├── migration
│   └── empty_on_purpose
├── migration_export-01.sh
├── migration_export-02.sh
├── migration_import-01.sh
├── migration_import-02.sh
├── nb-sso7-x509-oracle-persistent.yaml
├── preparing.sh
├── README.md
├── sso_install.properties
└── sso_s2i
   ├── extensions
   │   ├── configuration
   │   │   ├── krb5.conf
   │   │   ├── oracle_driver.properties
   │   │   └── sso-http.keytab
   │   ├── deployments
   │   │   └── ExampleHelloWorld.ear
   │   ├── ext
   │   │   ├── postconfigure.sh
   │   │   ├── preconfigure.sh
   │   │   ├── sso-extension.properties
   │   │   └── sso-extensions.cli
   │   ├── install.sh
   │   └── modules
   │       └── com
   │           └── oracle
   │               └── main
   │                   └── module.xml
   └── pom.xml
```
This directory should be deployed in a Git server where OpenShift can access.

##Preparation:
There are several files in which the deployment configuration relies. Here you have the most important variables, but there are many more configurations.
- .credentials
  - GIT_CRED_*: credentials to connect to Git Server
  - SSO_ADMIN_CRED_*: credentials for configure the new SSO master access
  - SSO_DB_CRED_*: credentials for Oracle Database access
  - REG_REDHAT_IO_*: credentials for OpenShift to download SSO image
- sso_install.properties
  - APPLICATION_NAME: the base name for all resources created on new deployment
  - SOURCE_REPOSITORY_*: configuration about Git Repository where this directory is published
  - KEYCLOAKDS_*: several configurations for datasource, with connection url among others
  - *_LIMIT: configuration for limits of CPU and Memory
- sso_s2i/extensions/configuration: you can find several files for configure sync with LDAP among others
- sso_s2i/extensions/deployments: here you should copy the AGP ear file in order to be deployed
- sso_s2i/extensions/ext: configuration about HTTPS
- nb_sso7_x509_oracle-persistent.yaml: the template for the build and deployment of RH SSO with Oracle Database connection.

After filling configuration it is needed to run some of the scripts in order:

```bash
oc new-project sso-75-project
./preparing.sh sso75-project
./install.sh sso75-project
# Once it is deployed for first time you can import the backup found a file named export_all.json on the migration directory 
./migration_import-01.sh sso75-project
./migration_import-02.sh sso75-project
```

The migration should be complete, and now it is needed to update the route hostname.

