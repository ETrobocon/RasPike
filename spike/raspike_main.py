# LEGO type:standard slot:5 autostart

import time
import re
import hub
import struct
from spike import Motor
from spike import DistanceSensor
from spike import ColorSensor
from spike import ForceSensor
import uasyncio
import gc

DONT_CARE=-1
UNDEFINED=-2



# シリアルポートの設定
spike_serial_port = "D"
# EV3RTとのポートマッピング
# 構成するロボットに合わせてマッピングを設定する
# EV3RTに合わせているので、モーター、センサーそれぞれ最大４種類しか使えないことに注意
# 内部的には全てSPIKEのポートに合わせていることに注意
spike_port_map = {
# EV3PORT : SPIKEPORT
    "1":"B",
    "2":"E",
    "3":"C",
    "4":"D",
    "A":"A",
    "B":"C",
    "C":"E",
    "D":"D"
}


# ここからは内部変数
# SPIKEポートセンサーのコンフィグ。センサーのCONFIGが行われた場合、これを埋めていく
# 配列の中身は 対応するコンフィグ（センサー種別),モード,通知インデックス
# モードの値で0のものがあり、raspi側から更新されないことがあるため、デフォルトを0とする
spike_port_sensor_config = {
    "A":[UNDEFINED,0,UNDEFINED],
    "B":[UNDEFINED,0,UNDEFINED],
    "C":[UNDEFINED,0,UNDEFINED],
    "D":[UNDEFINED,0,UNDEFINED],
    "E":[UNDEFINED,0,UNDEFINED],
    "F":[UNDEFINED,0,UNDEFINED],
}

numof_sensors = 0

#device objects [0]:motor object [1]:sensot object
device_objects = {
    "A":[0,0],
    "B":[0,0],
    "C":[0,0],
    "D":[0,0],
    "E":[0,0],
    "F":[0,0]
}

# ポートのステータス。0の場合は何もなし。他はリセット中などの意味を示す
# リセット処理が終わらないうちに値の更新をした場合に、前の値が取れるのを防ぐ仕組み
spike_port_status = {
    "A":0,
    "B":0,
    "C":0,
    "D":0,
    "E":0,
    "F":0

}



# 送信バッファの用意（動的に取らないようにここで取っておく)
# 最大は 1024/4 * 8 + 4 + 4
#sendData = bytearray(int(1024/4*8+4+4))
#sendData[0:3] = struct.pack('4s','RSRX')

def setLEDGPIO(port,device,value):
    print("GPIO is not supported")

def setMotorPower(port,device,value):
    
    device.run_at_speed(value)
#    getattr(hub.port,port).motor.start(speed=value)

def setMotorStop(port,device,value):
    #TODO:stop action
    device.stop()


async def resetMotorAngleTask(port,value):
    global spike_port_status
    if ( value != 0 ):
        print("motor reset")
        Motor(port).set_degrees_counted(0)
        #　リセットが終わったことを示す
        spike_port_status[port] = 0 



def resetMotorAngle(port,device,value):
    global spike_port_status
    #set_degrees_countedは呼び出しに200msecかかるため、非同期呼び出しとする
    #リセット中であることを示す
    spike_port_status[port] = 1 
    uasyncio.create_task(resetMotorAngleTask(port,value))

#    getattr(hub.port,port).motor.set_degrees_counted(value)

# センサーの数を数える（構成が変わった時だけにカウントを行う)
def calculate_sensors():
    num = 0
    global numof_sensors
    for port,elem in spike_port_sensor_config.items():
        if ( len(elem) == 3 and elem[2] >= 0 ):
            num = num+1
    numof_sensors = num
    print("Sensors=%d" %(numof_sensors))
    return num


# Sensor 

# Sensor コンフィグが呼ばれた時に実行。読み出すべきポートの設定を行う
# モードが存在しないセンサーの場合は、ここで実行するSensorのindexが決まる
def configureSensor(port,device,config):
    global spike_port_sensor_config
    spike_port_sensor_config[port] = [config,0,UNDEFINED]
    index = getSensorMapIndex(config,port,0)
    spike_port_sensor_config[port][2] = index
    print("Config: port=%s config=%d index=%d" %(port,config,index))
    calculate_sensors()
    device_objects[port][1] = getattr(hub.port,port).device
    if ( index != -1 ):
        device_objects[port][1].mode(sensor_map[index][6])


# Modeを切り替えた時に実行される
def setSensorMode(port,device,mode):
    global spike_port_sensor_config
    if ( spike_port_sensor_config[port][1] == mode or spike_port_sensor_config[port][2] < 0 ):
        spike_port_sensor_config[port][1] = mode
        index = getSensorMapIndex(spike_port_sensor_config[port][0],port,mode)
        spike_port_sensor_config[port][2] = index
        print("Mode: port=%s config=%d mode=%d index=%d" %(port,spike_port_sensor_config[port][0],mode,index))
        calculate_sensors()
        if ( index != -1 ):
            device_objects[port][1].mode(sensor_map[index][6])

# Motorのconfig
def configureMotor(port,device,config):
    device_objects[port][0] = getattr(hub.port,port).motor
    configureSensor(port,device_objects[port][0],config)
        

def getColorAmbient(port,device):
    return device.get()

def getColorReflect(port,device):
    val = device.get()
#    print ("Port=%s val=%d" %(port,val))
    return val

def getColorRGB(port):
    (red,green,blue) = device.get()
    # SPIKEはセンサー値が0-1024なので、EV3RTに合わせて0-256にする（不要?)
    return (int(red/4),int(green/4),int(blue/4))

# EV3RTのカラーにマップ
color_map = {
    'black':1,
    'violet':8, #EV3にない値
    'blue':2,
    'cyan':9, #EV3にない値
    'green':3,
    'yellow':4,
    'red':5,
    'white':6
}

def getColorColor(port,device):
    val = device.get()
    if ( val == NULL or (val not in color_map)):
        return 0 # NONE
    return int(color_map[val])

def getTouchSensor(port,device):
    if (device.get()):
        return 2048
    else:
        return 0

def getMotorAngle(port,device):
    return device.get()
#    val = Motor(port).get_degrees_counted()
#    print("MA %s=%d" %(port,val))
#    return Motor(port).get_degrees_counted()





# SPIKEが受信するコマンドのフォーマット
# INDEX,[サイズ,デバッグ用文字列,コールバック関数,引数]
receive_schema = {
    "0":[4,"LEDGPIO",setLEDGPIO,"",0],
    "1":[4,"POWER_A",setMotorPower,spike_port_map['A'],0],
    "2":[4,"POWER_B",setMotorPower,spike_port_map['B'],0],
    "3":[4,"POWER_C",setMotorPower,spike_port_map['C'],0],
    "4":[4,"POWER_D",setMotorPower,spike_port_map['D'],0],
    "5":[4,"STOP_A",setMotorStop,spike_port_map['A'],0],
    "6":[4,"STOP_B",setMotorStop,spike_port_map['B'],0],
    "7":[4,"STOP_C",setMotorStop,spike_port_map["C"],0],
    "8":[4,"STOP_D",setMotorStop,spike_port_map["D"],0],
    "9":[4,"RESET_ANGLE_A",resetMotorAngle,spike_port_map['A'],0],
    "10":[4,"RESET_ANGLE_B",resetMotorAngle,spike_port_map['B'],0],
    "11":[4,"RESET_ANGLE_C",resetMotorAngle,spike_port_map['C'],0],
    "12":[4,"RESET_ANGLE_D",resetMotorAngle,spike_port_map['D'],0],
    "13":[4,"RESET_GYRO"],
    "14":[4,"COLOR_SENSOR_MODE"],
    "56":[4,"SENSOR_PORT_1 CONFIG",configureSensor,spike_port_map['1'],0],
    "57":[4,"SENSOR_PORT_2 CONFIG",configureSensor,spike_port_map['2'],0],
    "58":[4,"SENSOR_PORT_3 CONFIG",configureSensor,spike_port_map['3'],0],
    "59":[4,"SENSOR_PORT_4 CONFIG",configureSensor,spike_port_map['4'],0],
    "60":[4,"SENSOR_PORT_1 MODE",setSensorMode,spike_port_map['1'],0],
    "61":[4,"SENSOR_PORT_2 MODE",setSensorMode,spike_port_map['2'],0],
    "62":[4,"SENSOR_PORT_3 MODE",setSensorMode,spike_port_map['3'],0],
    "63":[4,"SENSOR_PORT_4 MODE",setSensorMode,spike_port_map['4'],0],
    "64":[4,"MOTOR_PORT_A CONFIG",configureMotor,spike_port_map['A'],0],
    "65":[4,"MOTOR_PORT_B CONFIG",configureMotor,spike_port_map['B'],0],
    "66":[4,"MOTOR_PORT_C CONFIG",configureMotor,spike_port_map['C'],0],
    "67":[4,"MOTOR_PORT_D CONFIG",configureMotor,spike_port_map['D'],0],
    
}

def getUltrasonic(port,device):
    return device.get()
#    return DistanceSensor(port).get_distance_cm()

def undefined(port,device):
    print("Notsupported:")

# SPIKEが送信するコマンドのフォーマット
# [コンフィグ,ポート,mode,デバッグ用文字列,コールバック,INDEX]
# ポート：PORT1-4 -> 0-3
# コンフィグ:sensor_type_tの値
# モード: -1　は関係なし
# COLOR_SENSOR
# 	DRI_COL_REFLECT = 0,
#	DRI_COL_AMBIENT = 1,
#	DRI_COL_COLOR   = 2,
#	DRI_COL_RGBRAW  = 4,
sensor_map = [
    # 0:NONE_SENSOR
    [0],
    # 1: ULTRASONIC_SENSOR mode 0:normal 2:listen
    [1,DONT_CARE,0,"ULTRASONIC",getUltrasonic,22,0],
    [1,DONT_CARE,2,"ULTRASONIC_LISTEN",undefined,23,0],

    # 2: GYRO_SENSOR  
    [2,DONT_CARE,DONT_CARE,"GYRO_SENSOR",undefined,7,0],

    # TODO:Support Multi config
    # 3: TOUCH_SENSOR
    [3,DONT_CARE,DONT_CARE,"TOUCH_SENSOR",getTouchSensor,28,0],

    # 4: COLOR_SENSOR
    [4,DONT_CARE,1,"COLOR_AMBIENT",getColorAmbient,1,0],
    [4,DONT_CARE,2,"COLOR_COLOR",getColorColor,2,0],
    [4,DONT_CARE,0,"COLOR_REFLECT",getColorReflect,3,1],
    [4,DONT_CARE,4,"COLOR_RGB",getColorRGB,4,0],

    # 20: Motor : RASPIKE用に作成したもの
    [20,spike_port_map['A'],DONT_CARE,"MOTOR_A",getMotorAngle,64,2],
    [20,spike_port_map['B'],DONT_CARE,"MOTOR_B",getMotorAngle,65,2],
    [20,spike_port_map['C'],DONT_CARE,"MOTOR_C",getMotorAngle,66,2],
    [20,spike_port_map['D'],DONT_CARE,"MOTOR_D",getMotorAngle,67,2],
    
]

# ポートとモードから使用するsensor_mapのインデックスを求める
def getSensorMapIndex(type,port,mode):
#    if ( port not in sensor_map ):
#        return
    for index,elem in enumerate(sensor_map):
        # Check Sensor Type
        if ( type != elem[0]):
            continue
        # Check Port
        if ( elem[1] == DONT_CARE or elem[1] == port ):
            if ( int(elem[2]) == DONT_CARE  or elem[2] == mode ):
                return index

    return -1


#sender_receiver = {
#    "4" : [4,0,4,1,"COLOR_AMBIENT",getColorAmbient,]
#}

#receive_schema["4"][2](receive_schema["4"][3],30)
#motor = Motor('A')
#motor.start_at_power(30)




def wait_serial_ready():
    while True:
        reply = ser.read(1000)
        print(reply)
        if reply == b'':
            break

def stop():
    r_motor.brake()
    l_motor.brake()


def wait_read2(ser,size):
    while True:
        buf = ser.read(size)
        if ( buf == b'' or buf == None):
#            await uasyncio.sleep_ms(0)
            continue
        return buf



async def wait_read(ser,size):
    while True:
        buf = ser.read(size)
        if ( buf == b'' or buf == None):
#            await uasyncio.sleep_ms(0)
            continue
        return buf


    cur_size = 0
    ret = bytearray()
    while True:
        buf = ser.read(size-cur_size)
        if ( buf == b'' or buf == None):
            await uasyncio.sleep_ms(0)
            continue

        ret=ret+buf
        cur_size = len(ret)
        if ( cur_size == size ):
            return ret


async def wait_cmd():
# ヘッダバイト(1st bitが1)であれば読み直す
    while True:
        numcom = 0
        success = 0
        fail = 0
        val = 0
        while True:
            val = int.from_bytes(wait_read2(ser,1),'big')
#            print ("Head=%x" %(head))
            if (val & 0x80 ):
                # Found Header
#                print("Header Found")
                break
            
        # Get ID
        while True:

            idx = (val & 0x7f)
            
            val = int.from_bytes(wait_read2(ser,1),'big')
            if ( val & 0x80 ):
                print ("data1 broken")
                fail = fail + 1
                continue
            data1 = val

            val = int.from_bytes(wait_read2(ser,1),'big')
            if ( val & 0x80 ):
                print ("data2 broken")
                fail = fail + 1
                continue
            data2 = val
            ret_id = idx
            ret_data = (((data1&0x3f)<<7) | data2)
            # check +/-
            if ( data1 & 0x40 ):
                ret_data = ret_data*(-1)

            return (ret_id ,ret_data)



async def receiver():

    print(" -- start")
    start_flag = True
    previous_send_time = 0;
    value = 0
    cmd_id = 0
    if True:
        while True:
            await uasyncio.sleep_ms(0)
            #SKIP until header is "RSTX"
#            (cmd_id,value) = await wait_cmd()

            # ヘッダバイト(1st bitが1)であれば読み直す
            
            cmd = 0
            while True:
                cmd = int.from_bytes(await wait_read(ser,1),'big')
#                   print ("Head=%x" %(head))
                if (cmd & 0x80 ):
                    # Found Header
#                print("Header Found")
                    break
            
                # Get ID
            while True:
                data1 = int.from_bytes(await wait_read(ser,1),'big')
                if ( data1 & 0x80 ):
                    cmd = data1
                    print ("data1 broken")
                    continue
                idx = (cmd & 0x7f)

                data2 = int.from_bytes(await wait_read(ser,1),'big')
                if ( data2 & 0x80 ):
                    cmd = data2
                    print ("data2 broken")
                    continue

                cmd_id = idx
                value = (((data1&0x1f)<<7) | data2)
            # check +/-
                if ( data1 & 0x20 ):
                    value = value*(-1)
                
                break
           
#            print('cmd=%d,value=%d' %(cmd_id,value))
            if ( value < -2048 or value > 2048):
                print("Value is invalid")
                continue

            if ( str(cmd_id) not in receive_schema):
                continue
            
            action = receive_schema[str(cmd_id)]
            if ( len(action) > 2 and action[3] != "" ):
             # do action
                action[2](action[3],device_objects[action[3]][0],value)
            else:
                continue



                             

async def notifySensorValues():
    print("Start Sensors")
    while True:
        # 次の更新タイミング  ここでは10msec
        next_time = time.ticks_us() + 20*1000
#        numof_sensors = calculate_sensors()
#        print("Collect Sensors num=%d" %(numof_sensors))
        if ( True ):
            for port,elem in spike_port_sensor_config.items():
#                print("config port=%s config=%d index=%d" %(port,elem[0],elem[2]))
                if ( len(elem) == 3 and int(elem[2]) >= 0):
                    send_elem = sensor_map[int(elem[2])]
                    cmd_id = send_elem[5]
                    # Call Sensor Action and Get Value
                    val = send_elem[4](port,device_objects[port][1])
                    # Pack Data
                    if ( isinstance(val,tuple) ):
                        for i,d in val:
                            sendData = "@{:0=4}:{:0=6}".format(int(send_elem[5]+i*4),val)
                            #print(sendData)
                            ser.write(sendData)
                    else :
#                        print("Val=%s port=%s" %(val,port))
                        sendData = "@{:0=4}:{:0=6}".format(int(cmd_id),val[0])
                        #print(sendData)
                        ser.write(sendData)

        time_diff = next_time - time.ticks_us()
#        print("timediff={}".format(time_diff))
        if ( time_diff < 0 ):
            time_diff = 0

        await uasyncio.sleep_ms(int(time_diff/1000))


async def main_task():
    gc.collect()
    uasyncio.create_task(notifySensorValues())
    uasyncio.create_task(receiver())
    await uasyncio.sleep(120)
    print ("Time Over")



if True:

    print(" -- serial init -- ")
    ser = getattr(hub.port,spike_serial_port)

    ser.mode(hub.port.MODE_FULL_DUPLEX)
    time.sleep(1)
    ser.baud(115200)

    for x in dir(ser):
        print(x)



    wait_serial_ready()

    uasyncio.run(main_task())

