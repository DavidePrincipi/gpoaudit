$Server = $Env:LOGONSERVER.Trim('\')

#0=EMERG 1=Alert 2=CRIT 3=ERR 4=WARNING 5=NOTICE  6=INFO  7=DEBUG

$Severity = '5'

#(16-23)=LOCAL0-LOCAL7

$Facility = '10'

$Hostname = (Get-WmiObject win32_computersystem).DNSHostName.ToLower() + "." + (Get-WmiObject win32_computersystem).Domain

# Create a UDP Client Object

$UDPCLient = New-Object System.Net.Sockets.UdpClient

$UDPCLient.Connect($Server, 514)

# Calculate the priority

$Priority = ([int]$Facility * 8) + [int]$Severity

#Time format the SW syslog understands

$Timestamp = Get-Date -Format "MMM d HH:mm:ss"

# Assemble the full syslog formatted message

$FullSyslogMessage = "<{0}>{1} {2} gpoLogoff: {3}\{4}" -f $Priority, $Timestamp, $Hostname, $Env:USERDOMAIN, $Env:USERNAME

# create an ASCII Encoding object

$Encoding = [System.Text.Encoding]::ASCII

# Convert into byte array representation

$ByteSyslogMessage = $Encoding.GetBytes($FullSyslogMessage)

# Send the Message

$result = $UDPCLient.Send($ByteSyslogMessage, $ByteSyslogMessage.Length)
