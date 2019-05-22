# dysecli

**Drexel Wireless Systems Lab DYSE client**

## Command line options

* `-h`: Help
* `-c <configFile>`: Configuration file in the /mnt/dyse_config/config base directory on the grid nodes.  Modify these files predominantly to adjust the number of DYSE channels used and the center frequency of the emulation. Default=config_2x2.xml
* `-s <scenarioFile>`: RF Scenario file in the /mnt/dyse_config/scenario base directory on the grid nodes.  Modify these files predominantly to pre-load a schedule of emulated channels between different combinations of transmitters and receivers.  Make sure that the number of nodes in your scenario is consistent with whatever configuration file you use. Default = baseScenario-2.txt
* `-r`: Connect to and then reset DYSE, and disconnect.  This can be a good first step in debugging if the DYSE enters an strange state.  Look at /var/log/vre.log on the VRE in case this doesn't work. Next debug step should be to stop and restart dyse service on VRE.  Last resort should be power cycling.
* `-i`: Interactive debug mode (suggest you simultaneously look at /var/log/vre.log on VRE)


## Building dyse client
`dysecli` has already built on all grid machines and is accessible system-wide. There is no need to clone this repo onto a grid node.

If you would like to build `dysecli` on your local machine, clone this repo, change your working directory and run the following:

```
g++ dysecli.c -o dysecli
```

## Connecting Devices to the DYSE
The maximum input power to the DYSE is -20 dBm, and fixed attenuators should be used if you do not have a tight control or understanding of the radio under test.  It is recommended to measure the power levels of an unknown radio through direct connection to the spectrum analyzer to measure power levels prior to connecting it to the DYSE to make sure that you are operating within safe levels.

## DYSE server (only for system administrators)
The DYSE VSU is accessible via dwslgrid.ece.drexel.edu by logging on to dyse@dyse-vsu.maas.  Once launched by using:

`dyse_socket_ctrl`

… it should remain active to receive commands from a single instantiation (at a time) of the DYSE client from one of the DWSL grid machines (gridXX.maas).  During the emulation process, the server will place files in the /mnt/dyse_config/status directory so that the various stages of the emulation process can be monitored from any grid machine.  A file lock in this directory will prevent multiple instances of the client from running at a time.  If the DYSE server enters an unstable state, this lock file may need to be removed manually after restarting the server.

## dysecli Examples:

`dysecli -r`

Connect to, initialize, and reset the DYSE using a default 2x2 configuration.  It does not appear that resetting is needed for higher channel counts, but this can be done if needed by:

`dysecli -c config_4x4.xml -r`

`dysecli -c config_8x8.xml -r`

`dysecli -c config_16x16.xml -r`

… as needed

Typical usage would be something like the following:
`dysecli -c config_4x4.xml -s handoffScenario_noShad.txt`

`dysecli -i`

Places the DYSE in an interactive debug mode that allows channels to be input manually during emulation.  As a by-product of developing a fully automated system, it hasn't been used in a while and should only be done as a last resort.

## Configuration file
Located in /mnt/dyse_config/config

**Period** is the time resolution, in seconds, that the DYSE operates at, and **emu_time** is the total time, in seconds, of the wireless channel emulation.  Thus, the maximum number of channel samples that can be provided to the emulation system, and applied, is emu_time / period.  This total number of channel samples, is limited to be 40,000 by the DYSE library.

The VRE section of the configuration file specifies the networking parameters to connect to the emulation engine, and should not be modified under normal operation.

The configuration file defines how many of the channels of the DYSE are active during the emulation, and whether the channels are real or virtual.  Each of these channels can be associated with device files that are found in the directory specified at the top of the configuration file.  The channels are numbered starting at 0, corresponding to the front panel of the DYSE.

The configuration file would also be where real channels and virtual channels are specified.

## Device file
Located in /mnt/dyse_config/devices

**RF_center_frequency_MHz** and **Baseband_complex_sampling_rate_MHz** are self-explanatory, but please be sure to remember the capabilities of the radios under test and as part of the emulator.  When specifying a center frequency for emulation, it is best to choose one that is slightly offset from the carrier frequency of interest for your simulation.  For example, a setting of 1000 MHz (1 GHz) in the device file would work well for testing carrier frequencies at 1.01 GHz.  This is due to an apparent peculiarity with the X310 in which setting the carrier frequency to a particular setting causes an unmodulated carrier to enter into your channel.

**Fixed attenuation** specifies the amount of fixed attenuation that you want to declare as part of the emulation process.  It is not a software parameter that allows you to substitute actual attenuation that you would achieve with a physical attenuator connecting your radio to the DYSE.

For example,  if you connect a radio under test to the DYSE with a 30 dB attenuator (e.g., to keep the power levels below -20dBm), you can specify 30 dB as your "fixed attenuation".  However, if you then tell the DYSE to apply 45 dB of attenuation, it will only apply 15 dB because of the "fixed attenuation" value you specified.   If you really want the DYSE to apply 45 dB of attenuation to whatever is input to it, you can keep the attenuator in place but set "fixed attenuation" to 0.  This capability could be useful in allowing the DYSE to account for the attenuation that is present in our cabling network.

## Scenario file
Located in /mnt/dyse_config/scenario

Columns
* timeStamp(mS)  
* numTX  
* numRx 
* Gain(dB) 
* Phi(radians)
* Delay(microsecs)
* Doppler(Hz) 
* multipath1Gain(dB)
* multipath1Delay(microsecs)
* multipath2Gain(dB)
* multipath2Delay(microseconds)

It is important to realize that transmitter number (**numTX**) and receiver number (**numRX**) is given from the perspective of the DYSE.   Specifically, if you want channel 0 to be connected to an external radio receiver, you can extract the signal from the TX/RX port of DYSE channel 0, and numTX = 0.  Similarly, if channel 1 is connected to an external transmitter, you can inject the signal into the RX port of channel 1, and numRX = 1.

## Tutorial
We can illustrate operation of the DYSE with a handoff scenario from ECE-T512 (homework #3).  A mobile user moves from the coverage area of one cell to another cell, with power levels declining from the initial cell, and gradually increasing for the cell that is being traveled towards, and eventually entered.  The experiment below will look at the downlink channel being received by the mobile user due to each of the two basestations.  For purposes of simplicity, we assume that the basestations are transmitting unmodulated sinusoids on adjacent carrier frequencies.

### Physical connections
Spectrum analyzer - Mobile user
* Center frequency 1.01 GHz
* Span 500 kHz
* Connected via RF cable to DYSE port 0 - TX/RX (numTX = 0)

Signal generator 1 - BS #1
* Center frequency 1.01 GHz (modulation off)
* Amplitude -20dBm
* Connected via RF cable to DYSE port 1 - RX (numRX = 1)

Signal generator 2 - BS #2
* Center frequency 1.01005 GHz (modulation off)
* Amplitude -20 dBm
* Connected via RF cable to DYSE port 2 - RX (numRX = 2)

### Running the code:
Make sure DYSE is powered on and dyse_socket_ctrl is running on VSU

On grid machine:
	`dysecli -c config_4x4.xml -s handoffScenario-2bs-1ms-noShad.txt`

MATLAB code for generating scenario file can be found in the scenarioGenerator subdirectory.

### Configuration file - 4x4: config_4x4.xml
```
<?xml version="1.0" encoding="UTF-8"?>
<dyse>
    <!--base directory for files-->
    <dir>/home/dyse/dyse_config/devices</dir>

    <!--base directory for files-->
    <settings>
        <period>0.5</period>
        <emu_time>175.0</emu_time>
        <rt_mode>true</rt_mode>
    </settings>

    <vre>
        <device type="vre">
            <comms type="socket" protocol="tcp" service="client">
                <address>192.168.2.93</address>
                <port>49538</port>
            </comms>
        </device>
    </vre>

    <node id="0" type="real">
        <channel>0</channel>
        <radio file="rx_node.dvc"/>
    </node>

    <node id="0" type="real">
        <channel>0</channel>
        <radio file="tx_node.dvc"/>
    </node>

    <node id="1" type="real">
        <channel>1</channel>
        <radio file="rx_node.dvc"/>
    </node>

    <node id="1" type="real">
        <channel>1</channel>
        <radio file="tx_node.dvc"/>
    </node>

    <node id="2" type="real">
        <channel>2</channel>
        <radio file="rx_node.dvc"/>
    </node>

    <node id="2" type="real">
        <channel>2</channel>
        <radio file="tx_node.dvc"/>
    </node>

    <node id="3" type="real">
        <channel>3</channel>
        <radio file="rx_node.dvc"/>
    </node>

    <node id="3" type="real">
        <channel>3</channel>
        <radio file="tx_node.dvc"/>
    </node>

</dyse>
```

### Device files
rx_node.dvc
```
Device_name: 'rx'
Device_class: 'receiver'
RF_center_frequency_MHz: 1000
Baseband_complex_sampling_rate_MHz:100
fixed_attenuation: 0
```

tx_node.dvc
```
Device_name: 'tx'
Device_class: 'transmitter'
RF_center_frequency_MHz: 1000
Baseband_complex_sampling_rate_MHz:100
fixed_attenuation: 0
```

### Scenario file:
handoffScenario-2bs-1ms-noShad.txt in /mnt/dyse_config/scenario
... without shadowing

handoffScenario-2bs-1ms-Shad.txt in /mnt/dyse_config/scenario
... with shadowing


## Troubleshooting tips:
* Monitor /mnt/dyse_config/status for the current state of the emulation
* dysecli can only be run on one of the grid machines, gridXX.maas -- not on the grid server directly.
* Make sure companion server application is running on the VSU.  

* It may also be helpful to monitor the VRE with the commands (these commands can only be run from `dyse-vsu`):
```
ssh dyse@dyse-vre
tail -f /var/log/vre.log
```

* If the log doesn't respond to system commands and the DYSE socket server is running on the VSU, the VRE can be restarted by:
```
sudo service vre stop
sudo service vre start
```
