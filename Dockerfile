FROM python:3.7-slim as python
# TODO switch to alpine

ENV BLAST_VERSION="2.15.0"   \
    BLASTDB="/usr/src/db"

# Copy executables
WORKDIR /usr/src/

RUN set -exu                                                                                                                \
  # Install linux tools                                                                                                     \
  && apt-get update                                                                                                         \
  && apt-get install -y wget procps                                                                                                 \
  && rm -rf /var/lib/apt/lists/*                                                                                            \
  # Install blast                                                                                                           \
  && wget -q ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/$BLAST_VERSION/ncbi-blast-$BLAST_VERSION+-x64-linux.tar.gz \
  && tar xzf ncbi-blast-$BLAST_VERSION+-x64-linux.tar.gz                                                                    \
  && cp ncbi-blast-$BLAST_VERSION+/bin/blastn /usr/local/bin/blastn                                                         \
  && cp ncbi-blast-$BLAST_VERSION+/bin/makeblastdb /usr/local/bin/makeblastdb                                               \
  && rm -rf /usr/src/deps                                                                                                   \
  # Install python requirements                                                                                             \
  && cd /usr/src/                                                                                                           \
  && pip install --upgrade pip                                                                                              \
  && pip install --no-cache-dir MobileElementFinder

CMD ["/bin/bash"]
