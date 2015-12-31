class resolvconf (
										$resolvers = [ '8.8.8.8', '8.8.4.4' ],
										$domain=undef,
										$searchlist=undef ,
										$rotate=true,
										$timeout=1,
										$attempts=1,
										$ignoreifconf=true,
										$disableimmutable=true,
								) inherits params {

	validate_array($resolvers)
	validate_bool($rotate)

	$resolverlistsize=size($resolvers)

	Exec {
		path => '/usr/sbin:/usr/bin:/sbin:/bin',
	}

  # packed needed in order to get MAXNS from resolv.h file in facter fact
  package {  'glibc-headers':
    name   => $glibcheaders,
    ensure => present,
  }

  if ( ($::eyp_resolvconf_maxns) and ($resolverlistsize > $::eyp_resolvconf_maxns) )
	{
		notify { 'resolvconf limits':
			message => "more resolvers configured (${resolverlistsize}) that system's limit (${local_maxns})"
		}
	}

	if ($disableimmutable)
	{
		e2fs_immutable { $resolvconf::params::resolvfile:
			ensure => 'absent',
			before => File[$resolvconf::params::resolvfile],
		}
	}

	file { $resolvconf::params::resolvfile:
		ensure  => present,
		owner   => "root",
		group   => "root",
		mode    => 0644,
		content => template("resolvconf/resolvconf.erb"),
		notify  => $resolvconf::params::notifyresolv,
	}

	exec { 'update resolvconf':
		command     => 'resolvconf -u',
		refreshonly => true,
	}

	if($ignoreifconf and $resolvconfd)
	{
		file { '/etc/resolvconf/interface-order':
			ensure  => 'present',
			owner   => 'root',
			group   => 'root',
			mode    => '0644',
			content => "lo\n",
			notify  => Exec['update resolvconf interface-order'],
		}

		exec { 'update resolvconf interface-order':
			command     => 'resolvconf -u',
			refreshonly => true,
		}

	}

}