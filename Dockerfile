FROM centos
MAINTAINER Karel Malbroukou <karel.malbroukou@gmail.com>

ADD https://releases.hashicorp.com/consul/0.6.4/consul_0.6.4_linux_amd64.zip /tmp/consul.zip
ADD https://releases.hashicorp.com/consul/0.6.4/consul_0.6.4_web_ui.zip /tmp/consul_ui.zip

RUN yum -y install unzip

RUN mkdir -p /consul/{data,etc/conf.d,ui}
ADD ./config/ /consul/etc/
ADD ./consul-run /bin/consul-run

RUN cd /bin && unzip /tmp/consul.zip && chmod +x /bin/consul && rm -f /tmp/consul.zip
RUN cd /consul && unzip /tmp/consul_ui.zip && mv static ui/static && mv index.html ui/  && rm -f /tmp/consul_ui.zip

EXPOSE 8300 8301 8301/udp 8302 8302/udp 8400 8500 53 53/udp

ENTRYPOINT [ "/bin/consul-run" ]
