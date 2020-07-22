# RoboClaw with Simulink for Raspberry Pi

## Overview
This model makes it possible to control the RoboClaw using Raspberry Pi on Simulink. This model can be controlled duty and speed. And also it can be logged counts of encoder and battery voltage.

The RoboClaw is a motor controller manufactured and sold by BASICMICRO.

## Requires
* Simulink Support Package for Raspberry Pi Hardware

## Compatibility
Created with
* MATLAB R2020a
* Raspberry Pi 3B+ / 4B
* BASICMICRO RoboClaw 2x15A
* Pololu 131:1 Metal Gearmotor 37Dx73L mm 12V with 64 CPR Encoder (Helical Pinion)

## License
This program is managed under the MIT License, but **roboclaw.h** in the "*include folder*" and **roboclaw.c** in the "*src*" folder are **copyrighted by Mr. Bartosz Meglicki**. These need to be managed under **MPL License 2.0**.\
Reference : [ bmegli/roboclaw ](https://github.com/bmegli/roboclaw)
