FROM microsoft/dotnet:2.1-aspnetcore-runtime AS runner

RUN mkdir ~/.gnupg \
    && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
    && apt-get update \
    && apt-get -y install gnupg2 \
    && n=0 \
    && until [ $n -ge 8 ]; do \
    apt-key adv --keyserver keys.gnupg.net --recv-key 'E19F5F87128899B192B1A2C2AD5F960A256A04AF' && break; \
    ((n++)); \
    sleep 2; \
    done \
    && echo deb http://cloud.r-project.org/bin/linux/debian stretch-cran35/ >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get -y install r-base \
    && apt-get clean

ENV R_HOME /usr/lib/R
