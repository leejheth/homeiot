.ONESHELL:
.PHONY: setup

DIR           := $(shell basename `pwd`)
ENV           := iot-env

setup:
	. $(shell conda info --base)/etc/profile.d/conda.sh && \
	conda env remove -y -n $(ENV) && \
	conda create -y -n $(ENV) python=3.9 && \
	conda activate $(ENV) && \
	python -m pip install -r requirements.txt && \
	echo 'PYTHONPATH=$(PWD):$$PYTHONPATH' > .env && \
	echo 'Home IoT project setup successful.' && \
	echo 'To activate your conda environment, run `conda activate $(ENV)`.'
