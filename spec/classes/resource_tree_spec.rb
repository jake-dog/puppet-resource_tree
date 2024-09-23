require 'spec_helper'

describe 'resource_tree', type: :class do
  it { is_expected.to contain_class('resource_tree') }

  it { is_expected.to have_resource_count(0) }

  at_exit { RSpec::Puppet::Coverage.report! }

  context 'with static content' do
    let(:params) do
      {
        collections: {
          'static_content' => {
            'file' => {
              '/tmp/date_test' => {
                'content' => Time.now.day
              }
            }
          }
        },
        apply: ['static_content']
      }
    end

    it 'has a file with the current day number' do
      is_expected.to contain_file('/tmp/date_test') \
        .with_content(Time.now.day)
    end
  end

  context 'with dynamic content' do
    let(:params) do
      {
        collections: {
          'dynamic_content' => {
            'file' => {
              '/tmp/date_test' => '{ \'content\' => Time.now.day }',
            },
          },
        },
        apply: ['dynamic_content'],
      }
    end

    it 'has a file with the current day number' do
      is_expected.to contain_file('/tmp/date_test') \
        .with_content(Time.now.day)
    end
  end

  context 'with dynamic resources' do
    let(:params) do
      {
        collections: {
          'dynamic_resources' => %({
            'file' => Hash[(1..5).map {|n|
              [
                '/tmp/test-file-' + n.to_s,
                { 'content' => rand(500).to_s }
              ]
            }]
          })
        },
        apply: ['dynamic_resources'],
      }
    end

    it 'has 5 files' do
      (1..5).each do |n|
        is_expected.to contain_file('/tmp/test-file-' + n.to_s)
      end
    end

    it 'has resouce_tree resources' do
      (1..5).each do |n|
        is_expected.to contain_resource_tree__resource('file[/tmp/test-file-' + n.to_s + ']')
      end
    end
  end

  context 'with dynamic resource' do
    let(:params) do
      {
        collections: {
          'dynamic_resource' => {
            'host' => %(
              Hash[(1..5).map {|n|
                [
                  'test-node-0' + n.to_s,
                  {
                    'ip' => '192.168.1.' + n.to_s,
                    'ensure' => 'present',
                  }
                ]
              }]
            ),
          },
        },
        apply: ['dynamic_resource'],
      }
    end

    it 'has 5 hosts entries' do
      (1..5).each do |n|
        is_expected.to contain_host('test-node-0' + n.to_s) \
          .with({ 'ip' => '192.168.1.' + n.to_s, 'ensure' => 'present' })
      end
    end

    it 'has resouce_tree resources' do
      (1..5).each do |n|
        is_expected.to contain_resource_tree__resource('host[test-node-0' + n.to_s + ']')
      end
    end
  end

  context 'with dynamic resources and dependencies' do
    let(:params) do
      {
        collections: {
          'dynamic_resources' => {
            'file' => {
              '/tmp/test' => {
                'ensure' => 'directory',
                'rt_resources' => %({
                  'file' => Hash[(1..5).map {|n|
                     [
                       '/tmp/test/test-file-' + n.to_s,
                       { 'content' => rand(500).to_s },
                     ]
                   }],
                }),
              },
            },
          },
        },
        apply: ['dynamic_resources'],
      }
    end

    it 'has 5 files dependent on 1 folder' do
      (1..5).each do |n|
        is_expected.to contain_file('/tmp/test/test-file-' + n.to_s).that_requires('File[/tmp/test]')
      end
    end

    it 'has resouce_tree resources' do
      (1..5).each do |n|
        is_expected.to contain_resource_tree__resource('file[/tmp/test/test-file-' + n.to_s + ']')
      end
    end
  end

  context 'with multiple collections' do
    let(:params) do
      {
        collections: {
          'static_content1' => {
            'file' => {
              '/tmp/date_test1' => {
                'content' => Time.now.day,
              },
            },
          },
          'static_content2' => {
            'file' => {
              '/tmp/date_test2' => {
                'content' => Time.now.day,
              },
            },
          },
        },
        apply: ['static_content1', 'static_content2'],
      }
    end

    it 'has two files with the current day number' do
      is_expected.to contain_file('/tmp/date_test1') \
        .with_content(Time.now.day)
      is_expected.to contain_file('/tmp/date_test2') \
        .with_content(Time.now.day)
    end
  end

  context 'with selecting one collection from multiple' do
    let(:params) do
      {
        collections: {
          'static_content1' => {
            'file' => {
              '/tmp/date_test1' => {
                'content' => Time.now.day,
              },
            },
          },
          'static_content2' => {
            'file' => {
              '/tmp/date_test2' => {
                'content' => Time.now.day,
              },
            },
          },
        },
        apply: ['static_content1'],
      }
    end

    it 'has a file with the current day number' do
      is_expected.to contain_file('/tmp/date_test1') \
        .with_content(Time.now.day)
    end

    it 'does not have another file with current day' do
      is_expected.not_to contain_file('/tmp/date_test2')
    end
  end

  context 'with selecting none existent collection' do
    let(:params) do
      {
        collections: {
          'static_content1' => {
            'file' => {
              '/tmp/date_test1' => {
                'content' => Time.now.day,
              },
            },
          },
          'static_content2' => {
            'file' => {
              '/tmp/date_test2' => {
                'content' => Time.now.day,
              },
            },
          },
        },
        apply: ['not_a_collection'],
      }
    end

    it 'has no resources' do
      is_expected.to have_resource_count(0)
    end
  end

  context 'with inline ruby evaluation' do
    let(:params) do
      {
        collections: {
          'static_content' => {
            'file' => {
              '/tmp/date_test' => {
                'content' => 'rt_eval::Time.now.day',
              },
            },
          },
        },
        apply: ['static_content'],
      }
    end

    it 'has a file with the current day number' do
      is_expected.to contain_file('/tmp/date_test') \
        .with_content(Time.now.day)
    end
  end

  context 'with default params' do
    let(:params) do
      {
        default_params: {
          'file' => {
            'mode' => '0600',
          }
        },
        collections: {
          'static_content' => {
            'file' => {
              '/tmp/test1' => {
                'content' => 'foo',
              },
              '/tmp/test2' => {
                'content' => 'foo',
              },
              '/tmp/test3' => {
                'content' => 'foo',
              },
              '/tmp/test4' => {
                'content' => 'foo',
              },
              '/usr/local/bin/foo' => {
                'content' => 'echo bar',
                'mode'    => '0755',
                'rt_resources' => {
                  'file' => {
                    '/etc/cron.daily/run_foo' => {
                      'content' => '/bin/bash /usr/local/bin/foo',
                    },
                  },
                },
              },
            },
          },
        },
        apply: ['static_content'],
      }
    end

    it 'has files with mode=0600' do
      (1..4).each do |n|
        is_expected.to contain_file('/tmp/test' + n.to_s) \
          .with_mode('0600')
      end
    end

    it 'has resouce_tree resources' do
      (1..4).each do |n|
        is_expected.to contain_resource_tree__resource('file[/tmp/test' + n.to_s + ']')
      end
    end

    it 'has a foo executable' do
      is_expected.to contain_file('/usr/local/bin/foo') \
        .with_mode('0755')
    end

    it 'has a cron to run foo' do
      is_expected.to contain_file('/etc/cron.daily/run_foo') \
        .with_mode('0600') \
        .that_requires('File[/usr/local/bin/foo]')
    end
  end

  context 'with variable collision' do
    let(:params) do
      {
        collections: {
          'variable_collider' => {
            'file' => %({'foo' => 'bar', 'hello' => 'world'}.inject({}) {|r,(k,v)| r.merge({k => {'content' => v.to_s}}) }),
          },
        },
        apply: ['variable_collider'],
      }
    end

    it 'has two files' do
      is_expected.to contain_file('foo') \
        .with_content('bar')
      is_expected.to contain_file('hello') \
        .with_content('world')
    end
  end

  context 'with instance vars' do
    let(:params) do
      {
        collections: {
          'instance_vars' => {
            'file' => {
              '/tmp/instance_vars' => {
                'content' => 'rt_eval::@environment',
              },
            },
          },
        },
        apply: ['instance_vars'],
      }
    end

    it 'has a file with an instance var' do
      is_expected.to contain_file('/tmp/instance_vars') \
        .with_content('rp_env')  # should be default environment
    end
  end

  context 'with aliased scope functions but preserving scope var' do
    let(:params) do
      {
        collections: {
          'scoped_functions' => {
            'file' => %({'foo' => inline_template('bar'), 'hello' => scope.function_inline_template(['world'])}.inject({}) {|r,(k,v)| r.merge({k => {'content' => v.to_s}}) }),
          },
        },
        apply: ['scoped_functions'],
      }
    end

    it 'has two files' do
      is_expected.to contain_file('foo') \
        .with_content('bar')
      is_expected.to contain_file('hello') \
        .with_content('world')
    end
  end

  context 'with inline ruby scope functions and legacy scope evaluation' do
    let(:params) do
      {
        collections: {
          'rt_eval_scoping' => {
            'file' => {
              '/tmp/foo' => {
                'content' => 'rt_eval::scope.function_inline_template([\'bar\'])',
              },
              '/tmp/hello' => {
                'content' => 'rt_eval::inline_template(\'world\')',
              },
            },
          },
        },
        apply: ['rt_eval_scoping'],
      }
    end

    it 'has two files' do
      is_expected.to contain_file('/tmp/foo') \
        .with_content('bar')
      is_expected.to contain_file('/tmp/hello') \
        .with_content('world')
    end
  end

  context 'file with notify' do
    let(:params) do
      {
        collections: {
          'static_content' => {
            'file' => {
              '/tmp/date_test' => {
                'content' => Time.now.day,
                'notify' => 'Service[httpd]',
              }
            },
            'service' => {
              'httpd' => {
                'ensure' => 'running',
              },
            },
          },
        },
        apply: ['static_content'],
      }
    end

    it 'has a file' do
      is_expected.to contain_file('/tmp/date_test') \
        .with_content(Time.now.day)
    end

    it 'has a service' do
      is_expected.to contain_service('httpd')
    end

    it 'has a file notifying a service' do
      is_expected.to contain_file('/tmp/date_test') \
        .that_notifies('Service[httpd]')
    end
  end

  context 'file with multiple notifies' do
    let(:params) do
      {
        collections: {
          'static_content' => {
            'file' => {
              '/tmp/date_test' => {
                'content' => Time.now.day,
                'notify' => [
                  'Service[httpd]',
                  'Service[rsyslog]',
                  'Exec[create_test]',
                ],
              }
            },
            'service' => {
              'httpd' => {
                'ensure' => 'running'
              },
              'rsyslog' => {
                'ensure' => 'running'
              }
            },
            'exec' => {
              'create_test' => {
                'command' => '/bin/mkdir /tmp/test'
              }
            }
          }
        },
        apply: ['static_content']
      }
    end

    it 'has a file' do
      is_expected.to contain_file('/tmp/date_test') \
        .with_content(Time.now.day)
    end

    it 'has services' do
      is_expected.to contain_service('httpd')
      is_expected.to contain_service('rsyslog')
    end

    it 'has a exec' do
      is_expected.to contain_exec('create_test')
    end

    it 'has a file notifying services and exec' do
      is_expected.to contain_file('/tmp/date_test') \
        .that_notifies('Service[httpd]')
      is_expected.to contain_file('/tmp/date_test') \
        .that_notifies('Service[rsyslog]')
      is_expected.to contain_file('/tmp/date_test') \
        .that_notifies('Exec[create_test]')
    end
  end

  context 'with require' do
    let(:params) do
      {
        collections: {
          'static_content' => {
            'file' => {
              '/tmp/check_date.sh' => {
                'content' => 'date -u | logger',
                'mode'    => '0755',
              },
            },
            'cron' => {
              'run_date_check' => {
                'command'     => '/tmp/check_date.sh',
                'hour'        => '*',
                'require' => 'File[/tmp/check_date.sh]',
              },
            },
          },
        },
        apply: ['static_content'],
      }
    end

    it 'has a script' do
      is_expected.to contain_file('/tmp/check_date.sh') \
        .with_content('date -u | logger')
    end

    it 'has a cron requiring a script' do
      is_expected.to contain_cron('run_date_check').that_requires('File[/tmp/check_date.sh]')
    end
  end

  context 'with multiple require' do
    let(:params) do
      {
        collections: {
          'static_content' => {
            'file' => {
              '/tmp/check_date.sh' => {
                'content' => 'date -u > /tmp/test/date.log',
                'mode'    => '0755',
              },
              '/tmp/test' => {
                'ensure' => 'directory',
              },
            },
            'cron' => {
              'run_date_check' => {
                'command'     => '/tmp/check_date.sh',
                'hour'        => '*',
                'require' => [
                  'File[/tmp/check_date.sh]',
                  'File[/tmp/test]',
                ],
              },
            },
          },
        },
        apply: ['static_content'],
      }
    end

    it 'has a directory and script' do
      is_expected.to contain_file('/tmp/check_date.sh') \
        .with_content('date -u > /tmp/test/date.log')
      is_expected.to contain_file('/tmp/test')
    end

    it 'has a cron requiring a script' do
      is_expected.to contain_cron('run_date_check').that_requires('File[/tmp/check_date.sh]')
      is_expected.to contain_cron('run_date_check').that_requires('File[/tmp/test]')
    end
  end

  context 'with before' do
    let(:params) do
      {
        collections: {
          'static_content' => {
            'file' => {
              '/tmp/check_date.sh' => {
                'content' => 'date -u | logger',
                'mode'    => '0755',
                'before'  => 'Cron[run_date_check]',
              },
            },
            'cron' => {
              'run_date_check' => {
                'command'     => '/tmp/check_date.sh',
                'hour'        => '*',
              },
            },
          },
        },
        apply: ['static_content'],
      }
    end

    it 'has a script' do
      is_expected.to contain_file('/tmp/check_date.sh') \
        .with_content('date -u | logger')
    end

    it 'has a script before a cron' do
      is_expected.to contain_file('/tmp/check_date.sh') \
        .that_comes_before('Cron[run_date_check]')
    end
  end

  context 'service with subscribe' do
    let(:params) do
      {
        collections: {
          'static_content' => {
            'file' => {
              '/tmp/date_test' => {
                'content' => Time.now.day,
              },
            },
            'service' => {
              'httpd' => {
                'ensure' => 'running',
                'subscribe' => 'File[/tmp/date_test]',
              },
            },
          },
        },
        apply: ['static_content'],
      }
    end

    it 'has a file' do
      is_expected.to contain_file('/tmp/date_test') \
        .with_content(Time.now.day)
    end

    it 'has a service that subscribes to a file' do
      is_expected.to contain_service('httpd')
        .that_subscribes_to('File[/tmp/date_test]')
    end
  end

  context 'combining implicit/explicit require, notify, subscribe and before' do
    let(:params) do
      {
        collections: {
          'apache_server' => {
            'package' => %({
              'httpd' => {
                'ensure' => 'installed',
                'before' => 'Service[httpd]',
              },
            }),
            'file' => {
              '/etc/rsyslog.d/httpd' => {
                'content' => 'local3.info /var/log/httpd_custom.log',
                'notify' => 'Service[rsyslog]',
                'require' => 'Package[httpd]',
              },
            },
            'service' => {
              'httpd' => {
                'ensure' => 'running',
                'subscribe' => 'File[/etc/httpd/conf.d/10-myserver.conf]',
                'rt_resources' => {
                  'file' => {
                    '/etc/httpd/conf.d/10-myserver.conf' => {
                      'content' => 'rt_eval::Time.now.day.to_s',
                    },
                  },
                },
              },
              'rsyslog' => {
                'ensure' => 'running',
              },
            },
          },
        },
        apply: ['apache_server'],
      }
    end

    it 'has a package requiring a file' do
      is_expected.to contain_package('httpd') \
        .that_comes_before('Service[httpd]')
    end

    it 'has a syslog file' do
      is_expected.to contain_file('/etc/rsyslog.d/httpd') \
        .with_content('local3.info /var/log/httpd_custom.log') \
        .that_notifies('Service[rsyslog]') \
        .that_requires('Package[httpd]')
    end

    it 'has a config file' do
      is_expected.to contain_file('/etc/httpd/conf.d/10-myserver.conf') \
        .with_content(Time.now.day) \
        .that_requires('Service[httpd]')
    end

    it 'has a service that requires and subscribes to a file' do
      is_expected.to contain_service('httpd') \
        .that_subscribes_to('File[/etc/httpd/conf.d/10-myserver.conf]')
    end
  end

  context 'with default relationship metaparams' do
    let(:params) do
      {
        default_params: {
          'file' => {
            'mode' => '0600',
            'notify' => 'Service[rsyslogd]',
          }
        },
        collections: {
          'static_content' => {
            'service' => {
              'rsyslogd' => {
                'ensure' => 'running',
              }
            },
            'file' => {
              '/tmp/test1' => {
                'content' => 'foo',
              },
              '/tmp/test2' => {
                'content' => 'foo',
              },
              '/tmp/test3' => {
                'content' => 'foo',
              },
              '/tmp/test4' => {
                'content' => 'foo',
              },
              '/usr/local/bin/foo' => {
                'content' => 'echo bar',
                'notify' => [],
                'rt_resources' => {
                  'file' => {
                    '/etc/cron.daily/run_foo' => {
                      'content' => '/bin/bash /usr/local/bin/foo',
                    },
                  },
                },
              },
            },
          },
        },
        apply: ['static_content'],
      }
    end

    it 'has files with mode=0600 that notifies rsyslogd' do
      is_expected.to contain_file('/tmp/test1') \
        .with_mode('0600') \
        .that_notifies('Service[rsyslogd]')
      is_expected.to contain_file('/tmp/test2') \
        .with_mode('0600') \
        .that_notifies('Service[rsyslogd]')
      is_expected.to contain_file('/tmp/test3') \
        .with_mode('0600') \
        .that_notifies('Service[rsyslogd]')
      is_expected.to contain_file('/tmp/test4') \
        .with_mode('0600') \
        .that_notifies('Service[rsyslogd]')
    end

    it 'does not have a foo executable notifying rsyslogd' do
      is_expected.not_to contain_file('/usr/local/bin/foo') \
        .that_notifies('Service[rsyslogd]')
    end

    it 'has a rsyslogd service' do
      is_expected.to contain_service('rsyslogd')
    end

    it 'has a cron to run foo that notifies rsyslogd' do
      is_expected.to contain_file('/etc/cron.daily/run_foo') \
        .with_mode('0600') \
        .that_requires('File[/usr/local/bin/foo]') \
        .that_notifies('Service[rsyslogd]')
    end
  end
end
