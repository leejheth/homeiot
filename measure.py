from sensirion_shdlc_driver import ShdlcSerialPort, ShdlcConnection
from sensirion_shdlc_sensorbridge import SensorBridgePort, SensorBridgeShdlcDevice, SensorBridgeI2cProxy
from sensirion_i2c_driver import I2cConnection
from sensirion_i2c_scd import Scd4xI2cDevice

import mysql.connector 
import time
import datetime

def upload_SQL(co2, temperature, humidity, sql_credentials_all):
    sql_credentials = sql_credentials_all.splitlines()

    try:
        conn = mysql.connector.connect(
            host=sql_credentials[0],
            database=sql_credentials[1],
            user=sql_credentials[2],
            password=sql_credentials[3],
            port=sql_credentials[4]
        )
        
        cur = conn.cursor()
        tablename = sql_credentials[5]
        query = f"INSERT INTO {tablename} (CO2, temperature, humidity, time) VALUES (%s, %s, %s, %s)"
        timestamp = datetime.datetime.now()
        cur.execute(query, (co2,temperature,humidity,timestamp))
        conn.commit()
        cur.close()

    except mysql.connector.Error as e:
        print(e)
    finally:
        if conn is not None:
            conn.close()

# get MySQL database information and credentials data from text file
# .txt file format: host, database, user, password, table (at each line)
with open('conf/mysql.txt', 'r') as f:
    sql_credentials_all = f.read()

# Connect to the SensorBridge with default settings:
#  - baudrate:      460800
#  - slave address: 0
with ShdlcSerialPort(port='COM1', baudrate=460800) as port:
    bridge = SensorBridgeShdlcDevice(ShdlcConnection(port), slave_address=0)
    print("SensorBridge SN: {}".format(bridge.get_serial_number()))

    # Configure SensorBridge port 1 for SCD4x
    bridge.set_i2c_frequency(SensorBridgePort.ONE, frequency=100e3)
    bridge.set_supply_voltage(SensorBridgePort.ONE, voltage=3.3)
    bridge.switch_supply_on(SensorBridgePort.ONE)

    # Create SCD41 device
    i2c_transceiver = SensorBridgeI2cProxy(bridge, port=SensorBridgePort.ONE)
    scd41 = Scd4xI2cDevice(I2cConnection(i2c_transceiver))

    # start periodic measurement in high power mode
    scd41.start_periodic_measurement()

    # Measure every 60 seconds
    while True:
        time.sleep(60)
        co2, temperature, humidity = scd41.read_measurement()

        # upload data to MySQL database
        upload_SQL(round(co2), round(temperature), round(humidity), sql_credentials_all)

        # use default formatting for printing output:
        print(f"{co2}, {temperature}, {humidity}")
        # custom printing of attributes:
        print("{:d} ppm CO2, {:0.2f} °C ({} ticks), {:0.1f} %RH ({} ticks)".format(
            co2.co2,
            temperature.degrees_celsius, temperature.ticks,
            humidity.percent_rh, humidity.ticks))
    scd41.stop_periodic_measurement()

