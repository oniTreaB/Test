##################################################################
#
# $Id
#
# Fhem Modul für Dimplex Wärmepumpen mit Wärmepumpenmanager mit J/L-Softwarestand und NWPM-Erweiterung
# verwendet Modbus.pm als Basismodul für die eigentliche Implementation des Protokolls.
#
# Siehe 98_ModbusAttr.pm für ausführlichere Infos zur Verwendung des Moduls 98_Modbus.pm 
#
##################################################################
#
#     This file is part of fhem.
# 
#     Fhem is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 2 of the License, or
#     (at your option) any later version.
# 
#     Fhem is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with fhem.  If not, see <http://www.gnu.org/licenses/>.
#
##############################################################################
# Changelog
# 14.09.2016 Initial Release
# 02.02.2017 ModbusTCP Enabled v1.5.x Version
#
##############################################################################

package main;
use strict;
use warnings;
sub ModbusTCPDimplexHP_Initialize($);

my %DimplexWPMParseInfo = (
	# operating_data
	'h1' 	=> {	reading => 'dimhp_temperature_outdoor',
					name => 'temperature_outdoor',
					expr => '$val/10',
					format => '%.1f',
					unpack => 's>',				
					poll => 1,
					polldelay => 600,
				},
	'h2' 	=> {	reading => 'dimhp_temperature_return',
					name => 'temperature_return',
					expr => '$val/10',
					format => '%.1f',
					unpack => 's>',					
					poll => 1,
					polldelay => 30,
				},
	'h3' 	=> {	reading => 'dimhp_temperature_dhw',
					name => 'temperature_dhw',
					expr => '$val/10',
					unpack => 's>',						
					format => '%.1f',
					poll => 1,
					polldelay => 30,
				},				
	'h5' 	=> {	reading => 'dimhp_temperature_flow',
					name => 'temperature_flow',
					expr => '$val/10',
					format => '%.1f',
					unpack => 's>',					
					poll => 1,
					polldelay => 30,
				},
	# general
	'h45' 	=> {	reading => 'dimhp_hp_typ',
					name => 'heatpump_typ',
					map => '0:undefined,1:air/water-heatpump,2:air/water-heatpump-hightemperature,3:water/water-heatpump,4:brine/waterheatpump,5:air/water-heatpump-rev,6:brine/water-heatpump-rev,7:air/water-heatpump,8:brine-or-water/water-heatpump,9:water/water-heatpump-rev,10:air/water-heatpump',
					poll => 'once',
				},
	# operating_data				
	'h53' 	=> {	reading => 'dimhp_temperature_returnset',
					name => 'temperature_returnset',
					expr => '$val/10',
					format => '%.1f',
					poll => 1,
					polldelay => 60,
				},				
	# history
	'h72' 	=> {	reading => 'dimhp_history_compressor1',
					name => 'history_compressor1',
					unpack => 'n',
					poll => 1,
					polldelay => 3600,
				},
	'h73' 	=> {	reading => 'dimhp_history_compressor2',
					name => 'history_compressor2',
					unpack => 'n',
					poll => 1,
					polldelay => 3600,					
				},
	'h74' 	=> {	reading => 'dimhp_history_ventilator',
					name => 'history_ventilator',
					unpack => 'n',
					poll => 1,
					polldelay => 3600,					
				},
	'h75' 	=> {	reading => 'dimhp_history_2heatgenerator',
					name => 'history_2heatgenerator',
					unpack => 'n',
					poll => 1,
					polldelay => 3600,					
				},
	'h76' 	=> {	reading => 'dimhp_history_circulationpump',
					name => 'history_circulationpump_M13',
					unpack => 'n',
					poll => 1,
					polldelay => 3600,					
				},
	'h77' 	=> {	reading => 'dimhp_history_dhwpump',
					name => 'history_dhwpump_M18',
					unpack => 'n',
					poll => 1,
					polldelay => 3600,					
				},
	'h78' 	=> {	reading => 'dimhp_history_flangeheater',
					name => 'history_flangeheater',
					unpack => 'n',
					poll => 1,
					polldelay => 3600,					
				},				
	# messages
	'h103'	=> {	reading => 'dimhp_messages_status',
					name => 'messages_status',
					unpack => 'n',
                    map => '0:off,1:off,2:heating,3:swimming-pool,4:domestic-hot-water,5:cooling,10:defrost,11:flow-rate-monitoring,24:mode-switching,30:block',					
					poll => 1,
				},
	'h104'	=> {	reading => 'dimhp_messages_block',
					name => 'messages_block',
					unpack => 'n',
                    map => '0:no,6:operating-limit,7:system-control,9:pump-forerun,10:minimum-time,11:line-load,12:switch-cycle-block,13:domestic-hot-water-reheating,14:regenerative,15:utility-block,16:soft-starter,17:flow-rate,18:operating-limit-heatpump,19:high-pressure,20:low-pressure,21:operating-limit-heat-source,23:system-limit,25:extern-disable,34:2nd-heat-generator,35:fault',					
					poll => 1,
				},
	'h105'	=> {	reading => 'dimhp_messages_fault',
					name => 'messages_fault',
					unpack => 'n',
                    map => '0:no,1:fault-N17.1,2:fault-N17.2,3:fault-N17.3,4:fault-N17.4,6:electronic-expansion-valve,15:fault-sensor,16:low-pressor-brine,19:!primary-circuit,21:!low-pressor-brine,22:!domestic-hot-water,23:!load-compressor,24:!coding,25:!low-pressure,26:!antifreeze,28:!high-pressure,29:temperature-difference,30:!hot-gas-thermostat,31:!flow-rate',					
					poll => 1,
				},
	'h106'	=> {	reading => 'dimhp_messages_sensor',
					name => 'messages_sensor',
					unpack => 'n',
                    map => '0:no,1:outdoor,2:return,3:domestic-hot-water,4:coding,5:flow,6:2nd-heating-circuit,7:3nd-heating-circuit,8:regenerative,9:room1,10:room2,11:heat-source-outlet,12:heat-source-inlet,14:collector,15:low-pressure,16:high-pressure,17:room-humidity1,18:room-humidity2,19:antifreeze-refrigerant,20:hot-gas,21:return,22:swimming-pool,23:flow-cooling-passive,24:return-cooling-passive,26:solar-tank',
					poll => 1,
				},
	# settings
	'h5006'	=> {	reading => 'dimhp_time_hour',
					name => 'time_hour',
					unpack => 'n',
					hint => '0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23',
					poll => 1,
					polldelay => 60,
					set => 1,
				},					
	'h5007'	=> {	reading => 'dimhp_time_minute',
					name => 'time_minute',
					unpack => 'n',
					hint => '0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59',
					poll => 1,
					polldelay => 60,
					set => 1,
				},					
	'h5008'	=> {	reading => 'dimhp_time_month',
					name => 'time_month',
					unpack => 'n',
					map => '1:january,2:february,3:march,4:april,5:may,6:june,7:july,8:august,9:september,10:october,11:november,12:december',					
					poll => 1,
					polldelay => 60,
					set => 1,
				},
	'h5009'	=> {	reading => 'dimhp_time_weekday',
					name => 'time_weekday',
					unpack => 'n',
					map => '1:monday,2:tuesday,3:wednesday,4:thursday,5:friday,6:saturday,7:sunday',
					poll => 1,
					polldelay => 60,
					set => 1,
				},
	'h5010'	=> {	reading => 'dimhp_time_day',
					name => 'time_day',
					unpack => 'n',
					hint => '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31',
					poll => 1,
					polldelay => 60,
					set => 1,
				},
	'h5011'	=> {	reading => 'dimhp_time_year',
					name => 'time_year',
					unpack => 'n',
					map => '0:2000,1:2001,2:2002,3:2003,4:2004,5:2005,6:2006,7:2007,8:2008,9:2009,10:2010,11:2011,12:2012,13:2013,14:2014,15:2015,16:2016,17:2017,18:2018,19:2019,20:2020,21:2021,22:2022,23:2023,24:2024,25:2025,26:2026,27:2027,28:2028,29:2029,30:2030,31:2031,32:2032,33:2033,34:2034,35:2035,36:2036,37:2037,38:2038,39:2039,40:2040,41:2041,42:2042,43:2043,44:2044,45:2045,46:2046,47:2047,48:2048,49:2049,50:2050,51:2051,52:2052,53:2053,54:2054,55:2055,56:2056,57:2057,58:2058,59:2059,60:2060',
					poll => 1,
					polldelay => 60,
					set => 1,
				},
	'h5015'	=> {	reading => 'dimhp_operatingmode',
					name => 'operatingmode',
					unpack => 'n',
                    map => '0:summer,1:winter,2:vacation,3:party,4:2nd-heatgenerator,5:cooling',						
					poll => 1,
					polldelay => 60,
					set => 1,
				},	
	'h5045'	=> {	reading => 'dimhp_set_dhwhys',
					name => 'set_dhwhys',
					unpack => 'n',
					hint => '3,4,5,6,7,8,9,10,11,12,13,14,15',
					poll => 1,
					polldelay => 60,
					set => 1,
				},
	'h5046'	=> {	reading => 'dimhp_settemperature_dhw',
					name => 'settemperature_dhw',
					unpack => 'n',
					hint => '35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60',
					poll => 1,
					polldelay => 60,
					set => 1,
				},
	# timeprogram
	'h5065'	=> {	reading => 'dimhp_trigger_value',
					name => 'trigger_timeprogram',
					unpack => 'n',					
					map => '0:undefined,1:1-hc-lower,2:1-hc-raise,3:2-hc-lower,4:2-hc-raise,5:3-hc-lower,6:3-hc-raise,7:dhw-block,8:thermal-disinfection,12:dhw-circulation',
					poll => 'once',
					set => 1,						
				},
	'h5066'	=> {	reading => 'dimhp_trigger_starthour1',
					name => 'starthour1',
					unpack => 'n',						
					hint => '0,1,2,3,4,5,6,7,8,9,10,11,12',
					poll => 'once',
					set => 1,
				},				
	'h5067'	=> {	reading => 'dimhp_trigger_startminute1',
					name => 'startminute1',
					unpack => 'n',
					hint => '0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59',
					poll => 'once',
					set => 1,
				},
	'h5068'	=> {	reading => 'dimhp_trigger_endhour1',
					name => 'endhour2',
					unpack => 'n',
					hint => '0,1,2,3,4,5,6,7,8,9,10,11,12',
					poll => 'once',
					set => 1,
				},
	'h5069'	=> {	reading => 'dimhp_trigger_endminute1',
					name => 'endminute1',
					unpack => 'n',
					hint => '0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59',					
					poll => 'once',
					set => 1,
				},
	'h5070'	=> {	reading => 'dimhp_trigger_starthour2',
					name => 'starthour2',
					unpack => 'n',						
					hint => '0,1,2,3,4,5,6,7,8,9,10,11,12',
					poll => 'once',
					set => 1,
				},				
	'h5071'	=> {	reading => 'dimhp_trigger_startminute2',
					name => 'startminute2',
					unpack => 'n',	
					hint => '0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59',					
					poll => 'once',
					set => 1,
				},
	'h5072'	=> {	reading => 'dimhp_trigger_endhour2',
					name => 'endhour2',
					unpack => 'n',						
					hint => '0,1,2,3,4,5,6,7,8,9,10,11,12',
					poll => 'once',
					set => 1,
				},
	'h5073'	=> {	reading => 'dimhp_trigger_endminute2',
					name => 'endminute2',
					unpack => 'n',						
					hint => '0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59',					
					poll => 'once',
					set => 1,
				},
	'h5074'	=> {	reading => 'dimhp_trigger_sunday',
					name => 'sunday',
					map => '0:yes, 1:no, 2:time1, 3:time2',				
					unpack => 'n',						
					poll => 'once',
					set => 1,
				},
	'h5075'	=> {	reading => 'dimhp_trigger_monday',
					name => 'monday',
					map => '0:yes, 1:no, 2:time1, 3:time2',				
					unpack => 'n',						
					poll => 'once',
					set => 1,
				},
	'h5076'	=> {	reading => 'dimhp_trigger_tuesday',
					name => 'tuesday',
					map => '0:yes, 1:no, 2:time1, 3:time2',				
					unpack => 'n',						
					poll => 'once',
					set => 1,
				},
	'h5077'	=> {	reading => 'dimhp_trigger_wednesday',
					name => 'wednesday',
					map => '0:yes, 1:no, 2:time1, 3:time2',				
					unpack => 'n',						
					poll => 'once',
					set => 1,
				},
	'h5078'	=> {	reading => 'dimhp_trigger_thursday',
					name => 'thursday',
					map => '0:yes, 1:no, 2:time1, 3:time2',				
					unpack => 'n',						
					poll => 'once',
					set => 1,
				},
	'h5079'	=> {	reading => 'dimhp_trigger_friday',
					name => 'friday',
					map => '0:yes, 1:no, 2:time1, 3:time2',				
					unpack => 'n',						
					poll => 'once',
					set => 1,
				},
	'h5080'	=> {	reading => 'dimhp_trigger_saturday',
					name => 'saturday',
					map => '0:yes, 1:no, 2:time1, 3:time2',				
					unpack => 'n',						
					poll => 'once',
					set => 1,
				},				
	# Wärmemenge			
	'h5096'	 => {	reading => 'dimhp_thermalenergy_heating_1-4',
					name => 'thermalenergy_heating_1-4',
					unpack => 'n',
					poll => 1,
					polldelay => 60,
				},				
	'h5097'	 => {	reading => 'dimhp_thermalenergy_heating_5-8',
					name => 'thermalenergy_heating_5-8',
					unpack => 'n',
					poll => 1,
					polldelay => 60,
				},
	'h5098'	 => {	reading => 'dimhp_thermalenergy_heating_9-12',
					name => 'thermalenergy_heating_9-12',
					unpack => 'n',
					poll => 1,
					polldelay => 60,
				},					
	'h5099'	 => {	reading => 'dimhp_thermalenergy_dhw_1-4',
					name => 'thermalenergy_dhw_1-4',
					unpack => 'n',
					poll => 1,
					polldelay => 60,
				},				
	'h5100'	 => {	reading => 'dimhp_thermalenergy_dhw_5-8',
					name => 'thermalenergy_dhw_5-8',
					unpack => 'n',
					poll => 1,
					polldelay => 60,
				},
	'h5101'	 => {	reading => 'dimhp_thermalenergy_dhw_9-12',
					name => 'thermalenergy_dhw_9-12',
					unpack => 'n',
					poll => 1,
					polldelay => 60,
				},
	'h5127'	 => {	reading => 'dimhp_energy_environment_1-4',
					name => 'energy_environment_1-4',
					poll => 1,
				},				
	'h5128'	 => {	reading => 'dimhp_energy_environment_5-8',
					name => 'energy_environment_5-8',
					poll => 1,
				},
	'h5129'	 => {	reading => 'dimhp_energy_environment_9-12',
					name => 'energy_environment_9-12',
					poll => 1,
				},
	# roomcontrol				
	'h5159'	=> {	reading => 'dimhp_room_temperature',
					name => 'room_temperature',
					expr => '$val/10',
					unpack => 's>',						
					format => '%.1f',
					poll => 'once',
				},	
	'h5160'	=> {	reading => 'dimhp_room_settemperature',
					name => 'room_settemperature',
					expr => '$val/10',
					unpack => 's>',						
					format => '%.1f',
					poll => 'once',
				},
	'h5161'	=> {	reading => 'dimhp_room_humidity',
					name => 'room_humidity',
					expr => '$val/10',
					unpack => 's>',						
					format => '%.1f',
					poll =>'once',
				},				
	'h5162'	=> {	reading => 'dimhp_room_valve',
					name => 'room_valve',
					unpack => 's>',						
					poll => 1,
				},
	'h5163'	=> {	reading => 'dimhp_room_trigger',
					name => 'room_trigger',
					min => 0,
					max => 201,	
					poll => 1,
					set => 1,					
				},
	'h5164'	=> {	reading => 'dimhp_room_release',
					name => 'Raumfreigabe',
					unpack => 's>',						
					poll => 'once',					
				},                
	'h5165'	=> {	reading => 'dimhp_room_dewpoint',
					name => 'room_dewpoint',
					expr => '$val/10',
					unpack => 's>',						
					format => '%.1f',
					poll => 'once',
				},
	# outputs
	'c41' 	=> {	reading => 'dimhp_output_compressor1',
					name => 'output_compressor1',
					map => '0:off, 1:on',
					poll => 1,
					polldelay => 30,
				},
	'c42' 	=> {	reading => 'dimhp_output_compressor2',
					name => 'output_compressor2',
					map => '0:off, 1:on',
					poll => 1,
					polldelay => 30,
				},			
	'c43' 	=> {	reading => 'dimhp_output_ventilator',
					name => 'output_ventilator',
					map => '0:off, 1:on',
					poll => 1,
					polldelay => 30,
				},
	'c44' 	=> {	reading => 'dimhp_output_2heatgenerator',
					name => 'output_2heatgenerator',
					map => '0:off, 1:on',
					poll => 1,
					polldelay => 30,
				},				
	'c45' 	=> {	reading => 'dimhp_output_circulationpump',
					name => 'output_circulationpump_M13',
					map => '0:off, 1:on',
					poll => 1,
					polldelay => 30,
				},
	'c46' 	=> {	reading => 'dimhp_output_dhwpump',
					name => 'output_dhwpump_M18',
					map => '0:off, 1:on',
					poll => 1,
					polldelay => 30,
				},	
	'c49' 	=> {	reading => 'dimhp_output_auxiliarypump',
					name => 'output_auxiliarypump_M16',
					map => '0:off, 1:on',
					poll => 1,
					polldelay => 30,
				},
	'c50' 	=> {	reading => 'dimhp_output_flangeheater',
					name => 'output_flangeheater',
					map => '0:off, 1:on',
					poll => 1,
					polldelay => 30,
				},
	# time				
	'c102'	=> {	reading => 'dimhp_timeset_hour',
					name => 'set_hour',
					hint => '0,1',				
					poll => 'once',
					set => 1,
				},
	'c103'	=> {	reading => 'dimhp_timeset_minute',
					name => 'set_minute',
					hint => '0,1',	
					poll => 'once',
					set => 1,
				},
	'c104'	=> {	reading => 'dimhp_timeset_day',
					name => 'set_day',
					hint => '0,1',	
					poll => 'once',
					set => 1,
				},
	'c105'	=> {	reading => 'dimhp_timeset_month',
					name => 'set_month',
					hint => '0,1',	
					poll => 'once',
					set => 1,
				},
	'c106'	=> {	reading => 'dimhp_timeset_year',
					name => 'set_year',
					hint => '0,1',	
					poll => 'once',
					set => 1,
				},
	'c107'	=> {	reading => 'dimhp_timeset_weekday',
					name => 'set_weekday',
					hint => '0,1',	
					poll => 'once',
					set => 1,
				},
);

my %DimplexWPMDeviceInfo = (
	'h' => {defShowGet => 1,
		},
	'c' => {defShowGet => 1,
		},
	'timing' => {sendDelay => 0.2,
				commDelay => 0.2
		}
);



#####################################
sub ModbusTCPDimplexHP_Initialize($) {
	my ($hash) = @_;
	
	require "$attr{global}{modpath}/FHEM/98_Modbus.pm";
	$hash->{parseInfo}  = \%DimplexWPMParseInfo;  # defines registers, inputs, coils etc. for this Modbus Device
	$hash->{deviceInfo} = \%DimplexWPMDeviceInfo; # defines properties of the device like defaults and supported function codes
	ModbusLD_Initialize($hash); # Generic function of the Modbus module does the rest
	
	$hash->{AttrList} .= ' '.$hash->{ObjAttrList}.' '.$hash->{DevAttrList}.' poll-.* polldelay-.*';
}
1;

=pod
=begin html

<a name="ModbusTCPDimplexHP"></a>
<h3>ModbusRTUDimplexHP</h3>

=end html

=begin html_DE

<a name="ModbusTCPDimplexHP"></a>
<h3>ModbusRTUDimplexHP</h3>
<ul>
    ModbusRTUDimplexHP verwendet das Modul Modbus für die Kommunikation mit dem Wärmepumpenmanager.
    Hier wurden die wichtigsten Werte aus den Holding-Registern und Coils- definiert und werden im angegebenen Intervall abgefragt und aktualisiert.
    <br /><br />

    <b>Vorraussetzungen</b>
	<ul>
    Dieses Modul benötigt das Basismodul <a href="#Modbus">Modbus</a> für die Kommunikation, welches wiederum das Perl-Modul Device::SerialPort (sudo apt-get install libdevice-serialport-perl) oder Win32::SerialPort benötigt.
    </ul><br />
    
    <b>Physikalische Verbindung zum Wärmepumpenmanager</b>
	<ul>
    Im <a href="http://www.dimplex.de/wiki/index.php/LWPM_410">Dimplex Wiki</a> steht die Pinbelegung der RS485-Schnittstelle. Diese Schnittstelle ist nicht im Lieferumfang und ist als Zubehör erhältlich.<br />
    Man benötigt die üblichen Pins für TD und RD, sowie Ground.
    </ul><br />
    
    <b>Besonderheiten der Readings und des Reglers</b>
	<ul>
    Man kann mit diesem Modul z.B. den Betriebsmodus, die Heizkurve und die Solltemperaturen ändern.<br /><br />
    
    <b>Hinweis:</b><br />
    Es ist sehr empfehlenswert das Attribut <code>event-on-change-reading</code> auf <code>.*</code> zu setzen. Sonst werden sehr viele unnötige Events erzeugt.
    </ul><br />

    <a name="ModbusTCPDimplexHPDefine"></a>
    <b>Define</b>
	<ul>
    <code>define &lt;name&gt; ModbusRTUDimplexHP &lt;ID&gt; &lt;Interval&gt;</code><br /><br />
    Das Modul verbindet sich zum Dimplex Wärmepumpenmanager mit der angegebenen Modbus Id &lt;ID&gt; über ein bereits fertig definiertes Modbus-Device und fragt die gewünschten Werte im Abstand von &lt;Interval&gt; Sekunden ab.<br /><br />
    Beispiel:<br>
    <code>define DimplexHP ModbusRTUDimplexHP 1 60 192.168.1.100:502 TCP</code>
    </ul><br />

    <a name="ModbusTCPDimplexHPSet"></a>
    <b>Set-Kommandos</b>
	<ul>
    Die folgenden Werte können gesetzt werden:
    <ul>
    	<li>Datum und Uhrzeit<ul>
	    	<li><b>dimhp_time_hour</b>: Stunde</li>
	    	<li><b>dimhp_time_minute</b>: Minute</li>
	    	<li><b>dimhp_time_month</b>: Monat (1:january,2:february,3:march,4:april,5:may,6:june,7:july,8:august,9:september,10:october,11:november,12:december)</li>
	    	<li><b>dimhp_time_weekday</b>: Wochentag (1:monday,2:tuesday,3:wednesday,4:thursday,5:friday,6:saturday,7:sunday)</li>
	    	<li><b>dimhp_time_day</b>: Tag</li>
	    	<li><b>dimhp_time_year</b>: Jahr</li>
    	</ul></li>
    	
    	<li>Eiinstellungen<ul>
	    	<li><b>dimhp_operatingmode</b>: Betriebsmodus (0:summer,1:winter,2:vacation,3:party,4:2nd-heatgenerator,5:cooling)</li>
	    	<li><b>dimhp_heatingcurve</b>: Heizkurve</li>
	    	<li><b>dimhp_dhw_settemperature</b>: Warmwassersolltemperatur [°C]</li>
	    	<li><b>dimhp_dhwhys_settemperature</b>: Warmwasserhysterese [K]</li>
    	</ul></li>
    	
    </ul><br />
    <ul>
    	<li>Bedeutung der Readings Temperaturen<ul>
	    	<li><b>dimhp_wp_typ</b>: Wärmepumpentyp</li>
	    	<li><b>dimhp_temperature_outdoor</b>: Aussentemperatur [°C]</li>
	    	<li><b>dimhp_temperature_return</b>: Rücklauftemperatur [°C]</li>
			<li><b>dimhp_temperature_returnset</b>: Rücklaufsolltemperatur [°C]</li>	
	    	<li><b>dimhp_temperature_dhw</b>: Warmwassertemperatur [°C]</li>
	    	<li><b>dimhp_temperature_flow</b>: Vorlauftemperatur [°C]</li>
       </ul></li>
	   
    	<li>Bedeutung der Readings Zustände<ul>
	    	<li><b>dimhp_output_compressor1</b>: Verdichter 1 [on/off]</li>
	    	<li><b>dimhp_output_compressor2</b>: Verdichter 2 [on/off]</li>
	    	<li><b>dimhp_output_ventilator</b>: Ventilator [on/off]</li>
			<li><b>dimhp_output_2heatgenerator</b>: 2.Wärmeerzeuger [on/off]</li>	
	    	<li><b>dimhp_output_circulationpump</b>: Heizungspumpe M13 [on/off]</li>
	    	<li><b>dimhp_output_dhwpump</b>: Warmwasserpumpe M18 [on/off]</li>
	    	<li><b>dimhp_output_flangeheater</b>: Flanschheizung [on/off]</li>
	    	<li><b>dimhp_output_auxiliarypump</b>: Zusatzumwälzpumpe M16 [on/off]</li>			
	    </ul></li>
		
		 <li>Bedeutung der Readings Historie<ul>
	    	<li><b>dimhp_history_compressor1</b>: Verdichter 1 [h]</li>
	    	<li><b>dimhp_history_compressor2</b>: Verdichter 2 [h]</li>
	    	<li><b>dimhp_history_ventilator</b>: Ventilator [h]</li>
			<li><b>dimhp_history_2heatgenerator</b>: 2.Wärmeerzeuger [h]</li>	
	    	<li><b>dimhp_history_circulationpump</b>: Heizungspumpe M13 [h]</li>
	    	<li><b>dimhp_history_dhwpump</b>: Warmwasserpumpe M18 [h]</li>
	    	<li><b>dimhp_history_flangeheater</b>: Flanschheizung [h]</li>			
	    </ul></li>
		
		 <li>Bedeutung der Readings Meldungen<ul>
	    	<li><b>dimhp_messages_status</b>: Status</li>
	    	<li><b>dimhp_messages_block</b>: Sperre</li>
	    	<li><b>dimhp_messages_fault</b>: Störungator</li>
			<li><b>dimhp_messages_sensor</b>: Sensor</li>	
	    </ul></li>		
	   </ul>
    </ul><br />
    
    <a name="ModbusTCPDimplexHPGet"></a>
    <b>Get-Kommandos</b>
	<ul>
    Alle Readings sind auch als get-Kommando verfügbar. Intern führt ein get einen Request an den Wärmepumpenmanager aus, aktualisiert den entsprechenden Readings-Wert und gibt ihn als Ergebnis des Aufrufs zurück. Damit kann man eine zusätzliche Aktualisierung des Wertes erzwingen.
    </ul><br />
</ul>

=end html_DE
=cut
