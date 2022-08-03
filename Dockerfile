FROM public.ecr.aws/lambda/python:2.7
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    PYENV_SHELL="bash" \
    PY_VERSION="2.7.8" \
    PY_VERSION_MINOR="2.7"

COPY Pipfile ${LAMBDA_TASK_ROOT}
COPY Pipfile.lock ${LAMBDA_TASK_ROOT}

RUN yum updateinfo -y && yum update -y

RUN yum install -y links pcre2 yum-utils zip openssl binutils python27-pip python27-setuptools python27-backports.x86_64
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

RUN which python
RUN python --version

RUN which pip
RUN pip install --upgrade setuptools pip pipenv==2021.5.29 
    #backports.weakref backports.functools_lru_cache backports.shutil_get_terminal_size
RUN which pipenv
#pipenv run pip install -r <(pipenv lock -r) --target ${LAMBDA_TASK_ROOT}
RUN pipenv lock --keep-outdated --requirements > requirements.txt
RUN pip install -r requirements.txt --target ${LAMBDA_TASK_ROOT}
# RUN pipenv lock
# RUN pipenv install --deploy --ignore-pipfile --system
# RUN mkdir -p /tmp/usr
RUN cd /tmp/
RUN yumdownloader -x \*i686 --archlist=x86_64 clamav clamav-lib clamav-update json-c
# RUN yumdownloader --archlist=x86_64 pcre2
RUN rpm2cpio clamav-0*.rpm | cpio -idmv
RUN rpm2cpio clamav-lib*.rpm | cpio -idmv
RUN rpm2cpio clamav-update*.rpm | cpio -idmv
RUN rpm2cpio json-c*.rpm | cpio -idmv
RUN mkdir -p ${LAMBDA_TASK_ROOT}/bin
RUN cp usr/bin/clamscan usr/bin/freshclam usr/lib64/* ${LAMBDA_TASK_ROOT}/bin/.

# RUN rpm2cpio pcre*.rpm | cpio -idmv
RUN cd ${LAMBDA_TASK_ROOT}
RUN echo "DatabaseMirror database.clamav.net" > ${LAMBDA_TASK_ROOT}/bin/freshclam.conf
RUN mkdir -p /tmp/clamav_defs

COPY update.py ${LAMBDA_TASK_ROOT}
COPY clamav.py ${LAMBDA_TASK_ROOT}
COPY common.py ${LAMBDA_TASK_ROOT}
COPY scan.py ${LAMBDA_TASK_ROOT}
COPY scan_bucket.py ${LAMBDA_TASK_ROOT}
COPY metrics.py ${LAMBDA_TASK_ROOT}

COPY display_infected.py ${LAMBDA_TASK_ROOT}

# ENTRYPOINT [ "pipenv","run", "python", "-m", "awslambdaric" ]
CMD ["update.lambda_handler"]
