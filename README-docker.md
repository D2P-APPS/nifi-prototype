# Docker Images For Apache NiFi

```
$ docker search nifi | grep "^apache" | sort 
apache/nifi-minifi-cpp        Unofficial convenience binaries for NiFi        2
apache/nifi-minifi            Unofficial convenience binaries for Apache N…   7
apache/nifi-registry          Unofficial convenience binaries for Apache N…   24
apache/nifi-stateless         Apache stateless nifi                           1
apache/nifi-toolkit           Unofficial convenience binaries for NiFi        3
apache/nifi                   Unofficial convenience binaries and Docker i…   187   [OK]
```

## Starting Apache NiFi

* Start container

```bash
docker run --name nifi \
  -p 9090:9090 \
  -it --rm \
  -e NIFI_WEB_HTTP_PORT='9090' \
  apache/nifi:latest
```

* Visit web page.

```bash
xdg-open http://localhost:9090/nifi
```

## Apache NiFi Registry

* Start container

```bash
docker run --name nifi-registry \
  -p 18080:18080 \
  -d \
  apache/nifi-registry:latest
```

* Visit web page.

```bash
xdg-open http://localhost:18080/nifi-registry
```
