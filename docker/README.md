# Apache NiFi In Docker

## Questions

* How will authentication be handled in NiFi? Sreeram says to start with username and password.
* How will authorization be handled in NiFi?
* Encryption - https://www.mtnfog.com/philter-2/apache-nifi-phi-processing/
* Secrets in flow definitions
* HTTPS
* LDAP
* Do we need to put different repositories on different disks to get better disk I/O?

## TODO

* Make any desired edits in files found under <installdir>/conf. At a minimum, we recommend editing the nifi.properties file and entering a password for the nifi.sensitive.props.key
* Desginate "Initial Admin Identity" in authorizers.xml.
* Set nifi.sensitive.props.key

## On Docker

* Should /opt/nifi/nifi-current directory be located on host so that the various directories (content_repository, etc.) be available on host?
* enable https

### On Server

* start and enable
* configuration best practices.
  * do these conflict with Marathon?
* anti-virus exclusions
* logs sent to AWS - https://www.mtnfog.com/aws/monitoring-nifi-logs-with-cloudwatch/

### On Marathon

Can NiFi run under Marathon?
Does it provide a benefit?
Are there negatives?

## Procedure

## Certificate Generation

Following information from https://mintopsblog.com/2017/11/01/apache-nifi-configuration/, this section generates the certficates needed for SSL.

* Start a throw-away container.

```bash
docker run --rm --name toolkit -d apache/nifi
```

* The tls-toolkit.sh script will be used to create the required self-signed certificate, keystore, truststore and pre-configured nifi.properties. The command creates SSL files for three servers. It also creates a client certificate and password.

When it is time to add SSH to a NiFi container, these files will be attached to the container.

If you are running these commands more than once, make sure you are not overwritting important files in the `conf` directory. You have been warned!

```bash
docker exec \
  -ti toolkit \
  /opt/nifi/nifi-toolkit-current/bin/tls-toolkit.sh \
    standalone \
    -n 'nifi[1-3].bluejay.local' \
    -C 'CN=admin,OU=NIFI'

# Copy the public certificate of the Certificate Authority.
docker cp toolkit:/opt/nifi/nifi-current/nifi-cert.pem        conf
# Copy the Base64-encoded private key of the Certificate Authority in PKCS #1 PEM format.
docker cp toolkit:/opt/nifi/nifi-current/nifi-key.key         conf

docker cp toolkit:/opt/nifi/nifi-current/nifi1.bluejay.local  conf
docker cp toolkit:/opt/nifi/nifi-current/nifi2.bluejay.local  conf
docker cp toolkit:/opt/nifi/nifi-current/nifi3.bluejay.local  conf

docker cp toolkit:/opt/nifi/nifi-current/CN=admin_OU=NIFI.p12      conf
docker cp toolkit:/opt/nifi/nifi-current/CN=admin_OU=NIFI.password conf

docker stop toolkit
```

Import the `.p12` file into your browser.

Add "127.0.0.1 nifi1.bluejay.local" to the end of your /etc/hosts file.

### Docker Network

* Define a docker network name and set some IP address for Docker to use. Add these to your .envrc file if you use `direnv`.

```bash
DOCKER_NETWORK=nifi
NIFI_HOST=10.18.0.10
NIFI_PORT=9080
ZK_HOST=10.18.0.11
```

* Create a docker network.

```bash
docker network create --subnet=10.18.0.0/16 $DOCKER_NETWORK
```

### Apache Zookeeper

* Build and start Zookeeper

```bash
docker build -t zookeeper ./zookeeper

docker run \
  --name zookeeper \
  --net $DOCKER_NETWORK \
  --ip $ZK_HOST \
  -p 2181:2181 \
  -p 2888:2888 \
  -p 3888:3888 \
  -d \
  zookeeper
```

### Apache NiFi Registry

* Start NiFi Registry. There will only ever be one registry container so we are not changing the port number.

```bash
docker run \
  --name nifi-registry \
  -p 18080:18080 \
  -d \
  apache/nifi-registry
```

* Visit the NiFi Registry.

```bash
xdg-open http://localhost:18080/nifi-registry
```

* Create a bucket. You'll use this bucket later.
  * Click on the wrench.
  * Click new bucket.
  * Enter a bucket name.
  * Click Create.

* Get the Gateway IP for the Registry container. Use this as part of the registry url when configuring NiFi.

```bash
docker inspect nifi-registry --format="{{.NetworkSettings.Networks.$DOCKER_NETWORK.Gateway}}"
```

### Apache NiFi

* Create the NiFi container. We'll eventually have more than one NiFi container so it's a good idea to change the port number. The NiFi Toolkit is included in the image. Only `docker create` is used so that we can replace property files in the container. As of Docker v1.4.0 container volumes are initialized during the `create` phase. This allows use of `docker cp` to update containers (such as changing `nifi.properties`) before starting the container.

Note: NiFi 1.0.0 no longer contains authorized-users.xml. Instead, it contains authorizations.xml and users.xml. Older articles on the internet still refer to this unused file.

```bash
docker run -d \
  -e AUTH=tls \
  -e KEYSTORE_PATH=/opt/certs/keystore.jks \
  -e KEYSTORE_TYPE=JKS \
  -e KEYSTORE_PASSWORD=vtzmH55SP7j1jb6XrNlBMzaIwnUJUgrYg0Rt3iT6MXs \
  -e TRUSTSTORE_PATH=/opt/certs/truststore.jks \
  -e TRUSTSTORE_PASSWORD=ZZw0gW70EWGv0rO9/CWreRFWCf2cD9eSoiUfEDP7BbQ \
  -e TRUSTSTORE_TYPE=JKS \
  -e INITIAL_ADMIN_IDENTITY="CN=admin, OU=NIFI" \
  -e NIFI_WEB_PROXY_CONTEXT_PATH=/nifi \
  -e NIFI_WEB_PROXY_HOST=nifi1.bluejay.local \
  --hostname nifi1.bluejay.local \
  --ip $NIFI_HOST \
  --name nifi \
  --net $DOCKER_NETWORK \
  -p 8443:8443 \
  -v $(pwd)/conf/nifi1.bluejay.local:/opt/certs:ro \
  -v /data/projects/nifi-shared:/opt/nifi/nifi-current/ls-target \
  apache/nifi

  -v $(pwd)/conf/authorized-users.xml:/opt/nifi/nifi-current/conf/authorized-users.xml \

docker inspect nifi --format="{{.NetworkSettings.Networks.$DOCKER_NETWORK.Gateway}}"

nifi.security.needClientAuth=true

curl -vvvv https://nifi1.bluejay.local:8443/nifi

docker run --name nifi \
  -d \
  apache/nifi:latest


docker start nifi

docker logs -f nifi
```

* Logs inside the container are located at `/opt/nifi/nifi-current/logs`. The files are:
  * nifi-app.log
  * nifi-bootstrap.log - contains the start command and parameters.
  * nifi-user.log

* Copy new configuration files to the container.

```bash
docker cp login-identity-providers.xml nifi:/opt/nifi/nifi-current/conf/login-identity-providers.xml
docker cp authorizers.xml              nifi:/opt/nifi/nifi-current/conf/authorizers.xml
```

* Start NiFi.

```
docker start nifi
```

* Using the docker gateway IP address that you found earlier, create an entry in your `/etc/hosts` file.

```
10.18.0.1 nifi.bluejay.local
```

* Visit NiFi

```
xdg-open http://localhost:$NIFI_PORT/nifi
```

* Add the docker-based registry.
  * Click on the Hamburger menu.
  * Select Controller Settings.
  * Click the Plus sign.
  * Enter "Docker-based Registry" for the name.
  * Enter something like http://10.18.0.1:18080 for the URL. Use the IP from the `docker inspect` command that you ran earlier.

* Later you can add a Process Group, then version control it using the registry.

## Miscellaneous

* Display the current user using the NiFi Toolkit

```bash
docker exec -ti nifi  /opt/nifi/nifi-toolkit-current/bin/cli.sh nifi current-user
```

docker exec -ti docker_nifi_1 /opt/nifi/nifi-toolkit-current/bin/cli.sh nifi current-user

## References

* Clustering
  * https://pierrevillard.com/2016/08/13/apache-nifi-1-0-0-cluster-setup/
  * Three Part Series
    * https://mintopsblog.com/2017/11/01/apache-nifi-configuration/
    * https://mintopsblog.com/2017/11/02/apache-nifi-policies/
    * https://mintopsblog.com/2017/11/12/apache-nifi-cluster-configuration/
* Docker
  * https://github.com/dprophet/nifi/blob/master/nifi-docker/dockerhub/CONFIGURATION.md
  * https://www.nifi.rocks/official-nifi-docker-image/
  * https://www.nifi.rocks/apache-nifi-docker-compose-cluster/
  * https://dzone.com/articles/setting-apache-nifi-on-docker-containers
  * https://www.bmtrealitystudios.com/dockerising-nifi/ - use --chown=nifi:nifi when copying flow.xml.gz files.
  * https://dzone.com/articles/quick-tip-using-git-with-nifi-registry-in-docker
  * https://blog.mescrocker.co.uk/nifi-setting-up-in-docker/ - bootstrap.conf example
* Documentation
  * https://nifi.apache.org/docs/nifi-docs/
  * https://nifi.apache.org/docs/nifi-docs/components/nifi-docs/html/administration-guide.html
  * https://nifi.apache.org/docs/nifi-docs/html/toolkit-guide.html
* Download
  * https://nifi.apache.org/download.html
* Load Balancing
  * https://pierrevillard.com/2017/02/10/haproxy-load-balancing-in-front-of-apache-nifi/
* References
  * https://www.mtnfog.com/category/nifi/
  * https://cloudacademy.com/blog/moving-data-to-s3-with-apache-nifi/
* SSL
  * https://www.batchiq.com/nifi-configuring-ssl-auth.html
  * https://bryanbende.com/development/2016/08/17/apache-nifi-1-0-0-authorization-and-multi-tenancy
  * https://github.com/icalvete/puppet-nifi

### How to get the keystore password and open keystore.

* Get the keystore password.

```bash
docker exec -ti nifi cat conf/nifi.properties | grep -i nifi.security.keystorePasswd | cut -d'=' -f2
```

* Open the keystore. Use the password from the previous command.

```bash
docker exec -ti nifi keytool -v -list --keystore conf/keystore.jks
```
