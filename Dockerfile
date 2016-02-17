FROM ubuntu:14.04
MAINTAINER Peter Frey<freypa22@gmail.com>
EXPOSE 80 22 4730 5666

ENV REFRESHED 2015-11-16
ENV CUSTOMIZED 2016-02-13

RUN  echo 'net.ipv6.conf.default.disable_ipv6 = 1' > /etc/sysctl.d/20-ipv6-disable.conf; \ 
    echo 'net.ipv6.conf.all.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf; \ 
    echo 'net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.d/20-ipv6-disable.conf; \ 
    cat /etc/sysctl.d/20-ipv6-disable.conf; sysctl -p

RUN gpg --keyserver keys.gnupg.net --recv-keys F8C1CA08A57B9ED7 && \
    gpg --armor --export F8C1CA08A57B9ED7 | apt-key add - 

RUN echo "deb http://labs.consol.de/repo/stable/ubuntu $(lsb_release -sc) main" >> /etc/apt/sources.list && \
    apt-get update

# http://omdistro.org/doc/quickstart_debian_ubuntu
RUN apt-get install -y lsof vim git openssh-server tree tcpdump libevent-2.0-5 
RUN apt-get install -y xinetd  
RUN apt-get install -y omd-labs-edition

RUN a2enmod proxy_http

RUN sed -i 's|echo "on"$|echo "off"|' /opt/omd/versions/default/lib/omd/hooks/TMPFS

RUN omd create cmkfrey || true

# https://monitoring-portal.org/index.php?thread/28386-site-konfiguration-via-skript/&s=9c8d12a866a4602ba59378468f2afc0b8df77196
RUN omd config cmkfrey set DEFAULT_GUI check_mk
RUN omd config cmkfrey set THRUK_COOKIE_AUTH off
RUN omd config cmkfrey set APACHE_TCP_ADDR 0.0.0.0

# workaround for Livestatus problem "Table 'hosts' has no column 'host_comments_with_extra_info'"
# with core naemon
RUN omd config cmkfrey set CORE nagios

#TODO configure default password for omdadmin at build time? seems not to work
RUN echo 'root:xxx' | chpasswd
RUN echo 'cmkfrey:xxx' | chpasswd

#ENV OMD_DEMO /opt/omd/sites/demo
ENV OMD_SITE /opt/omd/sites/cmkfrey

# install check_mk agent to monitor self
RUN dpkg -i /opt/omd/versions/default/share/check_mk/agents/check-mk-agent_1.2.6p12-1_all.deb

#TODO add localhost to check-mk inventory at Docker build time? vs defer to initialization at runtime

ADD run_omd.sh /run_omd.sh
CMD ["/run_omd.sh"]
