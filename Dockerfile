FROM centos
MAINTAINER Karel Malbroukou <karel.malbroukou@gmail.com>

ADD https://dl.bintray.com/mitchellh/consul/0.5.2_linux_amd64.zip /tmp/consul.zip
ADD https://dl.bintray.com/mitchellh/consul/0.5.2_web_ui.zip /tmp/consul_ui.zip

RUN yum -y install unzip

RUN mkdir -p /consul/{data,config}
ADD ./config/ /consul/config/
ADD ./consul-run /bin/consul-run

RUN cd /bin && unzip /tmp/consul.zip && chmod +x /bin/consul && rm -f /tmp/consul.zip
RUN cd /consul && unzip /tmp/consul_ui.zip && mv dist ui && rm -f /tmp/consul_ui.zip

EXPOSE 8300 8301 8301/udp 8302 8302/udp 8400 8500 53 53/udp

ENTRYPOINT [ "/bin/consul-run" ]
