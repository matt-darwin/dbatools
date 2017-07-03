﻿function Remove-DbaComputerCertificate {
<#
.SYNOPSIS
Removes a computer certificate - useful for removing easily certs from remote computers

.DESCRIPTION
Removes a computer certificate from a local or remote compuer

.PARAMETER ComputerName
The target computer - defaults to localhost

.PARAMETER Credential
Allows you to login to $ComputerName using alternative credentials

.PARAMETER Store
Certificate store - defaults to LocalMachine (otherwise exceptions can be thrown on remote connections)

.PARAMETER Folder
Certificate folder
	
.PARAMETER Certificate
The target certificate object

.PARAMETER Thumbprint
The thumbprint of the certificate object 

.PARAMETER WhatIf 
Shows what would happen if the command were to run. No actions are actually performed. 

.PARAMETER Confirm 
Prompts you for confirmation before executing any changing operations within the command. 

.PARAMETER Silent 
Use this switch to disable any kind of verbose messages

.NOTES
Tags: Certificate

Website: https://dbatools.io
Copyright: (C) Chrissy LeMaire, clemaire@gmail.com
License: GNU GPL v3 https://opensource.org/licenses/GPL-3.0

.EXAMPLE
Remove-DbaComputerCertificate -ComputerName Server1 -Thumbprint C2BBE81A94FEE7A26FFF86C2DFDAF6BFD28C6C94

Removes certificate with thumbprint C2BBE81A94FEE7A26FFF86C2DFDAF6BFD28C6C94 in the LocalMachine store on Server1

.EXAMPLE
Remove-DbaComputerCertificate -ComputerName Server1 -Thumbprint C2BBE81A94FEE7A26FFF86C2DFDAF6BFD28C6C94 -Store User -Folder My

Removes certificate with thumbprint C2BBE81A94FEE7A26FFF86C2DFDAF6BFD28C6C94 in the User\My (Personal) store on Server1
#>
	[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
	param (
		[Alias("ServerInstance", "SqlServer", "SqlInstance")]
		[DbaInstanceParameter[]]$ComputerName = $env:COMPUTERNAME,
		[PSCredential][System.Management.Automation.CredentialAttribute()]$Credential,
		[parameter(ParameterSetName = "Certificate", ValueFromPipeline)]
		[System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
		[string]$Thumbprint,
		[string]$Store = "LocalMachine",
		[string]$Folder,
		[switch]$Silent
	)
	
	process {
		
		if (!$Certificate -and !$Thumbprint) {
			Write-Message -Level Warning -Message "You must specify either Certificate or Thumbprint"
			return
		}
		
		if ($Certificate) {
			$thumbprint = $Certificate.Thumbprint
		}
		
		foreach ($computer in $computername) {
			
			$scriptblock = {
				$thumbprint = $args[0]
				$Store = $args[1]
				$Folder = $args[2]
				
				Write-Verbose "Searching Cert:\$Store\$Folder for thumbprint: $thumbprint"
				$cert = Get-ChildItem "Cert:\$store\$folder" -Recurse | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }
				
				if ($cert) {
					$cert | Remove-Item
					$status = "Removed"
				}
				else {
					$status = "Certificate not found in Cert:\$Store\$Folder"
				}
				
				[pscustomobject]@{
					ComputerName = $env:COMPUTERNAME
					Thumbprint = $thumbprint
					Status = $status
				}
			}
			
			if ($PScmdlet.ShouldProcess("local", "Connecting to $computer to remove cert from Cert:\$Store\$Folder")) {
				try {
					Invoke-Command2 -ComputerName $computer -Credential $Credential -ArgumentList $thumbprint, $store, $folder -ScriptBlock $scriptblock -ErrorAction Stop
				}
				catch {
					Stop-Function -Message $_ -ErrorRecord $_ -Target $computer -Continue
				}
			}
		}
	}
}