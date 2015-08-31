define core::windows::feature(
  $ensure           = installed,
  $restart          = true,
  $subfeatures      = false,
  $management_tools = false,
  $timeout          = 300,
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
              onlyif   => "if ((Get-WindowsFeature ${feature_name}) | where { \$_.Installed -eq \$true}) { exit 1 }",
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
              onlyif   => "if ((Get-WindowsFeature ${feature_name}) | where { \$_.Installed -eq \$true}) { exit 1 }",
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
              onlyif   => "if ((Get-WindowsFeature ${feature_name}) | where { \$_.Installed -eq \$false}) { exit 1 }",
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
              onlyif   => "if ((Get-WindowsFeature ${feature_name}) | where { \$_.Installed -eq \$false}) { exit 1 }",
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
              command  => "Install-WindowsFeature -Name ${feature_name} ${subfeatures_option} ${tools_option}",
              onlyif   => "if ((Get-WindowsFeature ${feature_name}) | where { \$_.InstallState -eq 'Installed'}) { exit 1 }",
              provider => powershell,
              timeout  => $timeout,
              notify   => Reboot['now'],
            }
          }
          else
          {
            exec {"core-windows-feature-${feature_name}":
              command  => "Install-WindowsFeature -Name ${feature_name} ${subfeatures_option} ${tools_option}",
              onlyif   => "if ((Get-WindowsFeature ${feature_name}) | where { \$_.InstallState -eq 'Installed'}) { exit 1 }",
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
              onlyif   => "if ((Get-WindowsFeature ${feature_name}) | where { \$_.InstallState -ne 'Installed'}) { exit 1 }",
              provider => powershell,
              timeout  => $timeout,
              notify   => Reboot['now'],
            }
          }
          else
          {
            exec {"core-windows-feature-${feature_name}":
              command  => "Uninstall-WindowsFeature -Name ${feature_name}",
              onlyif   => "if ((Get-WindowsFeature ${feature_name}) | where { \$_.InstallState -ne 'Installed'}) { exit 1 }",
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
class iis (
  $ensure  = installed,
  $restart = false,
)
{
  case $ensure
  {
    installed:
    {
      core::windows::feature { 'Web-Server,Web-WebServer,Web-Common-Http,Web-App-Dev,Web-CGI,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Mgmt-Tools,Web-Mgmt-Console':
        ensure  => present,
        restart => $restart,
      }
    }
    default:
    {
      fail("Unsupported ensure \"${ensure}\"")
    }
  }
}