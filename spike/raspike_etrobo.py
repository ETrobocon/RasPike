# LEGO type:standard slot:2 autostart
import time
import hub
import uasyncio
from uasyncio import Event
import gc
from hub import Image, display

DONT_CARE = -1
UNDEFINED = -2

print("Start")

# Port Map
port_map = {
    "motor_A": "A",
    "motor_B": "B",
    "motor_C": "E",
    "color_sensor": "C",
    "ultrasonic_sensor": "F",
    "spike_serial_port": "D",
}


# Device objects

hub.display.show(hub.Image.ALL_CLOCKS,delay=400,clear=True,wait=False,loop=True,fade=0)

while True:
    motor_A = getattr(hub.port, port_map["motor_A"]).motor
    motor_B = getattr(hub.port, port_map["motor_B"]).motor
    motor_C = getattr(hub.port, port_map["motor_C"]).motor
    color_sensor = getattr(hub.port, port_map["color_sensor"]).device
    ultrasonic_sensor = getattr(hub.port, port_map["ultrasonic_sensor"]).device
    motor_rot_A = getattr(hub.port, port_map["motor_A"]).device
    motor_rot_B = getattr(hub.port, port_map["motor_B"]).device
    motor_rot_C = getattr(hub.port, port_map["motor_C"]).device
    touch_sensor = hub.button.connect

    if (
        motor_A is None
        or motor_B is None
        or motor_C is None
        or color_sensor is None
        or ultrasonic_sensor is None
    ):
        continue
    break

# モーターの回転を逆にして指定したい場合、以下に-1を設定してください
invert_A = 1
invert_B = 1
invert_C = -1

color_sensor_mode = 0
ultrasonic_sensor_mode = 0

motor_rot_A.mode(2)
motor_rot_B.mode(2)
motor_rot_C.mode(2)

# シリアルポートの設定
spike_serial_port = port_map["spike_serial_port"]


def wait_serial_ready():
    while True:
        reply = ser.read(1000)
        print(reply)
        if reply == b"":
            break


async def wait_read(ser, size):
    while True:
        buf = ser.read(size)
        if buf == b"" or buf is None:
            await uasyncio.sleep_ms(0)
            continue
        #        print("Val=%d" %(int.from_bytes(buf,'big')))
        return buf


num_command = 0
num_fail = 0
prev_time = time.ticks_us()
count = 0
sum_time = 0


async def receiver():
    global num_command, num_fail, count, sum_time, prev_time

    print(" -- start")
    value = 0
    cmd_id = 0

    global color_sensor_mode,ultrasonic_sensor_mode
    if True:
        while True:
            await uasyncio.sleep_ms(0)

            # ヘッダバイト(1st bitが1)であれば読み直す
            cmd = 0
            while True:
                cmd = int.from_bytes(await wait_read(ser, 1), "big")
                if cmd & 0x80:
                    # Found Header
                    #                print("Header Found")
                    break

                # Get ID
            while True:
                data1 = int.from_bytes(await wait_read(ser, 1), "big")
                num_command = num_command + 1
                if data1 & 0x80:
                    cmd = data1
                    num_fail = num_fail + 1
                    print ("data1 broken")
                    continue
                idx = cmd & 0x7F

                data2 = int.from_bytes(await wait_read(ser, 1), "big")
                if data2 & 0x80:
                    cmd = data2
                    num_fail = num_fail + 1
                    print ("data2 broken")
                    continue

                cmd_id = idx
                value = ((data1 & 0x1F) << 7) | data2
                # check +/-
                if data1 & 0x20:
                    value = value * (-1)

                break

            #  print('cmd=%d,value=%d' %(cmd_id,value))
            if value < -2048 or value > 2048:
                #                print("Value is invalid")
                num_fail = num_fail + 1
                continue

            # 高速化のために、motorスピードを優先して判定する
            if cmd_id == 1:
                motor_A.pwm(invert_A * value)
            elif cmd_id == 2:
                motor_B.pwm(invert_B * value)
            elif cmd_id == 3:
                motor_C.pwm(invert_C * value)
            #    count = count + 1
            #    now = time.ticks_us()
            #    sum_time = sum_time + (now - prev_time)
            #    prev_time = now
            elif cmd_id == 5:
                if value == 1:
                    motor_A.brake()
                else:
                    motor_A.float()
            elif cmd_id == 6:
                if value == 1:
                    motor_B.brake()
                else:
                    motor_B.float()
            elif cmd_id == 7:
                if value == 1:
                    motor_C.brake()
                else:
                    motor_C.float()
            elif cmd_id == 9:
                motor_A.preset(0)
            elif cmd_id == 10:
                motor_B.preset(0)
            elif cmd_id == 11:
                motor_C.preset(0)
            elif cmd_id == 61:
                # Port2 Color Sensor
                # Color Sensor Mode
                # 切り替えの間カラーセンサーの取得がされると不安定になるため、modeは一時的に0にする
                color_sensor_mode = 0
                if value == 1:
                    # Ambient
                    color_sensor.mode(2)
                elif value == 2:
                    # Color
                    color_sensor.mode(0)
                elif value == 3:
                    # Reflect
                    color_sensor.mode(1)
                elif value == 4:
                    # RGB
                    #print("Set RGB")
                    color_sensor.mode(5)
                #ダミーリード
                cv = color_sensor.get()
                color_sensor_mode = value
            elif cmd_id == 62:
                # Port3 Ultra Sonic Sensor
                led = b''+chr(9)+chr(9)+chr(9)+chr(9)
                ultrasonic_sensor.mode(5,led)
                if value == 1:
                    print("Ultrasonic Sensor")
                    ultrasonic_sensor.mode(0)
                elif value == 2:
                    print("Ultrasonic Sensor:Listen")
                    ultrasonic_sensor.mode(3)
                # 設定のまでのWait
                ultrasonic_sensor_mode = value


async def send_data(cmd, val):
    sendData = "@{:0=4}:{:0=6}".format(cmd, int(val))
#    print(sendData)
    ser.write(sendData)
    #高速で送るとパケットが落ちるため、0.5msec休ませる
    await uasyncio.sleep(0.0005)    

async def notifySensorValues():
    print("Start Sensors")
    global ser
    touch_sensor_value = -1
    while True:
        # 次の更新タイミング  ここでは10msec
        next_time = time.ticks_us() + 10 * 1000

        # カラーセンサーの切り替えがあった場合、タイミングによってはget()がNoneになったり、
        # RGBではない値が取れたりするので、その場合は次の周期で通知する
        if color_sensor_mode == 1:
            color_val = color_sensor.get()
            if color_val is not None:
            # ambient
                await send_data(1, color_val[0])
        elif color_sensor_mode == 2:
            color_val = color_sensor.get()
            if color_val is not None:
                # color
                # TODO:Convert to EV3 Value
                await send_data(2, color_val[0])
        elif color_sensor_mode == 3:
            color_val = color_sensor.get()
            if color_val is not None:
            # Reflect
                await send_data(3, color_val[0])
        elif color_sensor_mode == 4:
            color_val = color_sensor.get()
            if color_val[0] is not None and len(color_val) == 4 and color_val[2] is not None:
                r = color_val[0]
                g = color_val[1]
                b = color_val[2]
                await send_data(4, r / 4)
                await send_data(5, g / 4)
                await send_data(6, b / 4)

        # 超音波センサー
        if ultrasonic_sensor_mode == 1:
            val = ultrasonic_sensor.get()[0]
            if val is None:
                val = -1
#            print("Val=%d" %(int(val)))
            await send_data(22, val)
        elif ultrasonic_sensor_mode == 2:
           await send_data(23, ultrasonic_sensor.get())

        # モーター出力
        await send_data(64, motor_rot_A.get()[0] * invert_A)
        await send_data(65, motor_rot_B.get()[0] * invert_B)
        await send_data(66, motor_rot_C.get()[0] * invert_C)

        #タッチセンサー
        val = touch_sensor.is_pressed()
        if touch_sensor_value != val :
            touch_sensor_value = val
            sendVal = 0
            if touch_sensor_value:
                # Touchセンサーは加圧のアナログ値で、2048以上をタッチとして扱うため2048とする
                sendVal = 2048
            await send_data(28,sendVal)

        time_diff = next_time - time.ticks_us()
        #        print("timediff={}".format(time_diff))
        if time_diff < 0:
            time_diff = 0
        await uasyncio.sleep_ms(int(time_diff / 1000))


def stop_all():
    motor_A.pwm(0)
    motor_B.pwm(0)
    motor_C.pwm(0)


async def main_task():
    gc.collect()
    uasyncio.create_task(notifySensorValues())
    uasyncio.create_task(receiver())
    await uasyncio.sleep(10*60)
    global num_command, num_fail, count, sum_time, count
    stop_all()
    while True:
        print("Time Over command=%d fail=%d" % (num_command, num_fail))
        time.sleep(1)


#    print ("period = %dmsec num=%d" %((sVum_time/count)/1000,count))


if True:

    image = Image("99999:90090:99090:90090:99090")
    display.show(image)

    print(" -- serial init -- ")
    ser = getattr(hub.port, spike_serial_port)

    ser.mode(hub.port.MODE_FULL_DUPLEX)
    time.sleep(1)
    ser.baud(115200)

    wait_serial_ready()

    uasyncio.run(main_task())
