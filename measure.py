#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# (c) Copyright 2023 Sensirion AG, Switzerland
# Adapted by Jihyun Lee for SQL database upload

from sensirion_shdlc_driver import ShdlcSerialPort, ShdlcConnection
from sensirion_shdlc_sensorbridge import SensorBridgePort, SensorBridgeShdlcDevice, SensorBridgeI2cProxy
from sensirion_i2c_driver import I2cConnection
from sensirion_i2c_scd import Scd4xI2cDevice

import mysql.connector 
import time
import datetime

# get MySQL database information and credentials data from text file
# .txt file format: host, database, user, password, table (at each line)
with open('conf/mysql.txt', 'r') as f:
    sql_credentials = f.read().splitlines()

# Connect to the SensorBridge with default settings:
#  - baudrate:      460800
#  - slave address: 0
with ShdlcSerialPort(port='COM6', baudrate=460800) as port:
    bridge = SensorBridgeShdlcDevice(ShdlcConnection(port), slave_address=0)
    print("SensorBridge SN: {}".format(bridge.get_serial_number()))

    # Configure SensorBridge port 1 for SCD4x
    bridge.set_i2c_frequency(SensorBridgePort.ONE, frequency=100e3)
    bridge.set_supply_voltage(SensorBridgePort.ONE, voltage=3.3)
    bridge.switch_supply_on(SensorBridgePort.ONE)

    # Create SCD4x device
    i2c_transceiver = SensorBridgeI2cProxy(bridge, port=SensorBridgePort.ONE)
    scd4x = Scd4xI2cDevice(I2cConnection(i2c_transceiver))

    # Make sure measurement is stopped, else we can't read serial number or
    # start a new measurement
    scd4x.stop_periodic_measurement()

    print("scd4x Serial Number: {}".format(scd4x.read_serial_number()))

    # start periodic measurement in high power mode
    scd4x.start_periodic_measurement()

    # establish connection to MySQL database
    conn = mysql.connector.connect(
        host=sql_credentials[0],
        database=sql_credentials[1],
        user=sql_credentials[2],
        password=sql_credentials[3],
        port=sql_credentials[4]
    )

    cur = conn.cursor()
    tablename = sql_credentials[5]

    # Measure every 60 seconds
    try:
        while True:
            time.sleep(60)
            co2, temperature, humidity = scd4x.read_measurement()
            timestamp = datetime.datetime.now().strftime("%Y-%m-%d, %H:%M:%S")

            # print the output
            print(f"{co2}, {temperature}, {humidity}")

            # upload data to MySQL database
            query = f"INSERT INTO {tablename} (CO2, temperature, humidity, time) VALUES (%s, %s, %s, %s)"
            cur.execute(query, (f"{co2}", f"{temperature}", f"{humidity}",timestamp))
            conn.commit()
    
    except KeyboardInterrupt:
        print("Keyboard interruption detected. Exiting...")

    finally:
        scd4x.stop_periodic_measurement()
        cur.close()
        conn.close()

