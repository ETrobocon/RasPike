# main Task

class MainTask

  def log(msg)
    @logger.write(msg)
  end

  def initialize
    @logger = EV3RT::Serial.new(EV3RT::SIO_PORT_UART)
    msg = "main task new\r\n"
    log(msg)
  end

  def execute
    colorSensor = EV3RT::ColorSensor.new(EV3RT::PORT_1)
    ultrasonicSensor = EV3RT::SonarSensor.new(EV3RT::PORT_3)
    touchSensor0 = EV3RT::TouchSensor.new(EV3RT::PORT_3)
    touchSensor1 = EV3RT::TouchSensor.new(EV3RT::PORT_4)

    leftMotor = EV3RT::Motor.new(EV3RT::PORT_A, EV3RT::LARGE_MOTOR)
    rightMotor = EV3RT::Motor.new(EV3RT::PORT_B, EV3RT::LARGE_MOTOR)
    armMotor = EV3RT::TailMotor.new(EV3RT::PORT_C, EV3RT::LARGE_MOTOR)
    leftMotor.stop
    rightMotor.stop

    count = 0
    flag = true
    while flag
      log("count:#{count}\r\n")
      case count
      when 0..200
        leftMotor.power = 5
        rightMotor.power = 5
      when 201..400
        leftMotor.power = -5
        rightMotor.power = -5
      when 401..600
        leftMotor.stop
        rightMotor.stop
        armMotor.power = 4
      when 601..800
        leftMotor.stop
        rightMotor.stop
        armMotor.power = -4
      else
	flag=false
      end
      count+=1
      EV3RT::Task.sleep(20)
    end
    log("mruby end\r\n")
  end
end

MainTask.new.execute
