# /bin/bash
mkdir traces 2> /dev/null
mkdir expectations 2> /dev/null

trace=$(echo "$TRACE_FILES")
if [ -z "${trace}" ]; then
  echo "export TRACE_FILES=\"~/pogger/traces\"" >> ~/.bashrc
fi

expectation=$(echo $EXPECTATION_FILES)
if [ -z "${expectation}" ]; then
  echo "export EXPECTATION_FILES=\"~/pogger/expectations\"" >> ~/.bashrc
fi

source ~/.bashrc
