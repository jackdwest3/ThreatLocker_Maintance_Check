# ThreatLocker_Maintance_Check
Maintenance script to check and install ThreatLocker on computers.

This Syncro MSP script has the following platform/environmetn varible assigned at runtime:

Variable Name - $OrgName
Variable Type - platform
Value - {{customer_business_name_or_customer_full_name}}

Variable Name - $ClientKey
Variable Type - platform
Value - {{customer_custom_field_threatlocker_token}}

Variable Name - $DeviceName
Variable Type - platform
Value - {{asset_name}}

File Type - PowerShell
Run as - System
Max Script Run Time - 10 (minutes)
