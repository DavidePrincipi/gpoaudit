#
# Copyright (C) 2018 Nethesis S.r.l.
# http://www.nethesis.it - nethserver@nethesis.it
#
# This script is part of NethServer.
#
# NethServer is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License,
# or any later version.
#
# NethServer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with NethServer.  If not, see COPYING.
#

Param(
  [string]$server,
  [string]$port,
  [string]$tag,
  [string]$severity,
  [string]$facility,
  [Parameter(Position=1)] [string]$message
)

if(!$server) {
    $server = $Env:LOGONSERVER.Trim('\')
}

if(!$port) {
    $port = '514'
}

if(!$tag) {
    $tag = 'syslogger'
}

#0=EMERG 1=Alert 2=CRIT 3=ERR 4=WARNING 5=NOTICE  6=INFO  7=DEBUG
if(!$severity) {
    $severity = '5'
}

#(16-23)=LOCAL0-LOCAL7
if(!$facility) {
    $facility = '16'
}

if($message) {
    foreach($var in Get-ChildItem Env:) {
        $message = $message.Replace("%" + $var.name + "%", $var.value)
    }
} else {
    $message = "default message text"
}

$hostname = (Get-WmiObject win32_computersystem).DNSHostName.ToLower() + "." + (Get-WmiObject win32_computersystem).Domain
$priority = ([int]$facility * 8) + [int]$severity
$timestamp = Get-Date -Format o
$structuredData = 'timeQuality tzKnown="1" isSynced="1"' # See Syslog Protocol RFC5424

$Encoding = [System.Text.Encoding]::ASCII
$payload = $Encoding.GetBytes("<${priority}>1 ${timestamp} ${hostname} ${tag} ${PID} - [${structuredData}] ${message}")

$UDPCLient = New-Object System.Net.Sockets.UdpClient
$UDPCLient.Connect($server, $port)
$result = $UDPCLient.Send($payload, $payload.Length)
