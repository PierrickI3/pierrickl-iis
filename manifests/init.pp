define core::windows::feature(
  $ensure           = installed,
  $restart          = true,
  $subfeatures      = false,
  $management_tools = false,
  $source           = 'f:',
  $timeout          = 600,
)
{
  validate_re($ensure, ['^(present|installed|absent|uninstalled)$'])

  if (is_array($name))
  {
    $feature_name = join($name, ',')
  }
  else
  {
    $feature_name = $name
  }

  case $::operatingsystemrelease
  {
    '6.1.7601', '2008 R2' : # Windows 7, 2008R2
    {
      case $ensure
      {
        'present', 'installed':
        {
          $subfeatures_option = $subfeatures ? { true => '-IncludeAllSubFeature',   default => '' }
          if ($management_tools)
          {
            warn('Automatic inclusion of Management tools is not supported on Windows 7 and 2008 R2')
          }

          if ($restart)
          {
            exec {"core-windows-feature-${feature_name}":
              command  => "Add-WindowsFeature -Name ${feature_name} ${subfeatures_option}",
              provider => powershell,
              timeout  => $timeout,
              notify   => Reboot['now'],
              require  => Exec['chocolatey-install'],
            }
          }
          else
          {
            exec {"core-windows-feature-${feature_name}":
              command  => "Add-WindowsFeature -Name ${feature_name} ${subfeatures_option}",
              provider => powershell,
              timeout  => $timeout,
              require  => Exec['chocolatey-install'],
            }
          }
        }
        'absent', 'uninstalled':
        {
          if ($restart)
          {
            exec {"core-windows-feature-${feature_name}":
              command  => "Remove-WindowsFeature -Name ${feature_name}",
              provider => powershell,
              timeout  => $timeout,
              notify   => Reboot['now'],
              require  => Exec['chocolatey-install'],
            }
          }
          else
          {
            exec {"core-windows-feature-${feature_name}":
              command  => "Remove-WindowsFeature -Name ${feature_name}",
              provider => powershell,
              timeout  => $timeout,
              require  => Exec['chocolatey-install'],
            }
          }
        }
        default: { fail("Unsupported ensure parameter: ${ensure}") }
      }
    }
    default:      # Windows 8, 8.1, 2012, 2012R2
    {
      case $ensure
      {
        'present', 'installed':
        {
          $subfeatures_option = $subfeatures      ? { true => '-IncludeAllSubFeature',   default => '' }
          $tools_option       = $management_tools ? { true => '-IncludeManagementTools', default => '' }

          if ($restart)
          {
            exec {"core-windows-feature-${feature_name}":
              command  => "Install-WindowsFeature -Name ${feature_name} ${subfeatures_option} ${tools_option} -Source ${source}\\sources\\SxS",
              provider => powershell,
              timeout  => $timeout,
              notify   => Reboot['now'],
            }
          }
          else
          {
            exec {"core-windows-feature-${feature_name}":
              command  => "Install-WindowsFeature -Name ${feature_name} ${subfeatures_option} ${tools_option} -Source ${source}\\sources\\SxS",
              provider => powershell,
              timeout  => $timeout,
            }
          }
        }
        'absent', 'uninstalled':
        {
          if ($restart)
          {
            exec {"core-windows-feature-${feature_name}":
              command  => "Uninstall-WindowsFeature -Name ${feature_name}",
              provider => powershell,
              timeout  => $timeout,
              notify   => Reboot['now'],
            }
          }
          else
          {
            exec {"core-windows-feature-${feature_name}":
              command  => "Uninstall-WindowsFeature -Name ${feature_name}",
              provider => powershell,
              timeout  => $timeout,
            }
          }
        }
        default: { fail("Unsupported ensure parameter: ${ensure}") }
      }
    }
  }
}

# == Class: iis
#
# Enables IIS
#
# === Parameters
#
# [ensure]
#   installed. No other values are currently supported.
#
# [restart]
#   Set to true if restart should occur after the feature is installed. Default is false.
#
# === Examples
#
#  class {'iis':
#   ensure  => installed,
#   restart => true,
#  }
#
# === Authors
#
# Pierrick Lozach <pierrick.lozach@inin.com>
#
# === Copyright
#
# Copyright 2015, Interactive Intelligence Inc.
#
class installiis (
  $ensure  = installed,
  $restart = false,
)
{
  case $ensure
  {
    installed:
    {
      # Mount Windows ISO
      $mountdriveletter = 'f:'
      $daascache        = 'C:/daas-cache'

      debug('Mounting Windows ISO')
      exec {'mount-windows-iso':
        command => "cmd.exe /c imdisk -a -f \"${daascache}\\${::windows_latest_version}\" -m ${mountdriveletter}",
        path    => $::path,
        cwd     => $::system32,
        creates => "${mountdriveletter}/Installs/ServerComponents/Dialer_${versiontouse}.msi",
        timeout => 30,
      }

      # Install Features
      core::windows::feature { 'Web-Server,Web-WebServer,Web-Common-Http,Web-App-Dev,Web-Net-Ext,Web-Net-Ext45,Web-AppInit,Web-ASP,Web-Asp-Net,Web-Asp-Net45,Web-CGI,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Includes,Web-WebSockets,Web-Mgmt-Tools,Web-Mgmt-Console,NET-HTTP-Activation,NET-Non-HTTP-Activ,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs,AS-WAS-Support,AS-HTTP-Activation,AS-MSMQ-Activation,AS-Named-Pipes,AS-TCP-Activation,NET-WCF-Services45,NET-WCF-HTTP-Activation45,NET-WCF-MSMQ-Activation45,NET-WCF-Pipe-Activation45,NET-WCF-TCP-Activation45,NET-WCF-TCP-PortSharing45':
        ensure   => present,
        source   => $mountdriveletter,
        restart  => $restart,
        requires => Exec['mount-windows-iso'],
      }

      # Unmount Windows ISO
      exec {'unmount-windows-iso':
        command => "imdisk -d -m ${mountdriveletter}",
        path    => $::path,
        cwd     => $::system32,
        timeout => 30,
        requires => Core::Windows::Feature['Web-Server,Web-WebServer,Web-Common-Http,Web-App-Dev,Web-Net-Ext,Web-Net-Ext45,Web-AppInit,Web-ASP,Web-Asp-Net,Web-Asp-Net45,Web-CGI,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Includes,Web-WebSockets,Web-Mgmt-Tools,Web-Mgmt-Console,NET-HTTP-Activation,NET-Non-HTTP-Activ,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs,AS-WAS-Support,AS-HTTP-Activation,AS-MSMQ-Activation,AS-Named-Pipes,AS-TCP-Activation,NET-WCF-Services45,NET-WCF-HTTP-Activation45,NET-WCF-MSMQ-Activation45,NET-WCF-Pipe-Activation45,NET-WCF-TCP-Activation45,NET-WCF-TCP-PortSharing45'],
      }
    }
    default:
    {
      fail("Unsupported ensure \"${ensure}\"")
    }
  }
}
