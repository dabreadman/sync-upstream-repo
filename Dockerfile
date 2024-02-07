FROM registry.access.redhat.com/ubi9/ubi-minimal:9.3-1552

RUN microdnf -y install bash git && microdnf clean all

RUN useradd -d /home/ci ci

ADD entrypoint.sh /home/ci/

RUN chmod 555 /home/ci/*.sh 

ENTRYPOINT ["/home/ci/entrypoint.sh"]
