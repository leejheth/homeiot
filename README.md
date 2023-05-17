# homeIoT
Home IoT data collection and upload

Collect CO2, humidity, temperature data using Sensirion SCD41 sensor and upload the data to AWS RDS database (MySQL engine).

This repository is under development and more features will follow.

## Installation
Prerequisite: [conda](https://docs.conda.io/projects/conda/en/stable/user-guide/install/index.html)
Clone the repository to your work directory.
```
git clone git@github.com:leejheth/homeIoT.git
cd homeIoT
```

Set up the environment. This will create a new conda environment and install all dependencies in it.
```
make setup
```

Activate the newly create environment.
```
conda activate iot-env
```

Start measurement and data streaming.
```
python measure.py
```

## References
* [SCD4x CO2 sensors](https://developer.sensirion.com/sensirion-products/scd4x-co2-sensors/)
* [Amazon RDS](https://aws.amazon.com/rds/)
