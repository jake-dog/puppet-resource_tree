require 'spec_helper'

describe 'resource_tree', :type => :class do
  #let(:default_facts) do
  #  {
  #    :concat_basedir => '/dne',
  #    :ipaddress      => '10.10.10.10'
  #  }
  #end
  
  #it { should compile }
  it { should contain_class('resource_tree')}
  
  it { should have_resource_count(0) }
  
  at_exit { RSpec::Puppet::Coverage.report! }
  
  context 'with static content' do
    let(:params) { 
      {
        :collections => {
          "static_content" => {
            "file" => {
              "/tmp/date_test" => {
                "content" => Time.now.day
              }
            }
          }
        }, 
        :apply => ["static_content"]
      }
    }

    it 'should contain a file with the current day number' do
      should contain_file('/tmp/date_test') \
        .with_content(Time.now.day)
    end
  end
  
  context 'with dynamic content' do
    let(:params) {
      {
        :collections => {
          "dynamic_content" => {
            "file" => {
              "/tmp/date_test" => "{ 'content' => Time.now.day }"
            }
          }
        },
        :apply => ["dynamic_content"]
      }
    }

    it 'should contain a file with the current day number' do
      should contain_file('/tmp/date_test') \
        .with_content(Time.now.day)
    end
  end
  
  context 'with dynamic resources' do
    let(:params) {
      {
        :collections => {
          "dynamic_resources" => %q({
              'file' => Hash[(1..5).map {|n|
                [
                  "/tmp/test-file-" + n.to_s,
                  { "content" => rand(500).to_s }
                ]
              }]
            })
        },
        :apply => ["dynamic_resources"]
      }
    }

    it 'should contain 5 files' do
      #Puppet::Util::Log.level = :debug
      #Puppet::Util::Log.newdestination(:console)
      
      should contain_file('/tmp/test-file-1')
      should contain_file('/tmp/test-file-2')
      should contain_file('/tmp/test-file-3')
      should contain_file('/tmp/test-file-4')
      should contain_file('/tmp/test-file-5')
    end
  end
  
  context 'with dynamic resource' do
    let(:params) {
      {
        :collections => {
          "dynamic_resource" => {
            "host" => %q(
              Hash[(1..5).map {|n|
                [
                  "test-node-0" + n.to_s,
                  {"ip" => "192.168.1." + n.to_s, "ensure" => "present" }
                ]
              }]
            )
          }
        },
        :apply => ["dynamic_resource"]
      }
    }

    it 'should contain 5 hosts entries' do
      should contain_host('test-node-01') \
        .with({ 'ip' => '192.168.1.1', 'ensure' => 'present' })
      should contain_host('test-node-02') \
        .with({ 'ip' => '192.168.1.2', 'ensure' => 'present' })
      should contain_host('test-node-03') \
        .with({ 'ip' => '192.168.1.3', 'ensure' => 'present' })
      should contain_host('test-node-04') \
        .with({ 'ip' => '192.168.1.4', 'ensure' => 'present' })
      should contain_host('test-node-05') \
        .with({ 'ip' => '192.168.1.5', 'ensure' => 'present' })
    end
  end
  
  context 'with dynamic resources and dependencies' do
    let(:params) {
      {
        :collections => {
          "dynamic_resources" => {
            'file' => {
              '/tmp/test' => {
                'ensure' => 'directory',
                'rt_resources' => %q({
                  'file' => Hash[(1..5).map {|n|
                     [
                       "/tmp/test/test-file-" + n.to_s,
                       { "content" => rand(500).to_s }
                     ]
                   }]
                })
              }
            }
          }
        },
        :apply => ["dynamic_resources"]
      }
    }

    it 'should contain 5 files dependent on 1 folder' do
      should contain_file('/tmp/test/test-file-1').that_requires('File[/tmp/test]')
      should contain_file('/tmp/test/test-file-2').that_requires('File[/tmp/test]')
      should contain_file('/tmp/test/test-file-3').that_requires('File[/tmp/test]')
      should contain_file('/tmp/test/test-file-4').that_requires('File[/tmp/test]')
      should contain_file('/tmp/test/test-file-5').that_requires('File[/tmp/test]')
    end
  end
  
  context 'with multiple collections' do
    let(:params) {
      {
        :collections => {
          "static_content1" => {
            "file" => {
              "/tmp/date_test1" => {
                "content" => Time.now.day
              }
            }
          },
          "static_content2" => {
            "file" => {
              "/tmp/date_test2" => {
                "content" => Time.now.day
              }
            }
          }
        },
        :apply => ["static_content1", "static_content2"]
      }
    }

    it 'should contain two files with the current day number' do
      should contain_file('/tmp/date_test1') \
        .with_content(Time.now.day)
      should contain_file('/tmp/date_test2') \
        .with_content(Time.now.day)
    end
  end
  
  context 'with selecting one collection from multiple' do
    let(:params) {
      {
        :collections => {
          "static_content1" => {
            "file" => {
              "/tmp/date_test1" => {
                "content" => Time.now.day
              }
            }
          },
          "static_content2" => {
            "file" => {
              "/tmp/date_test2" => {
                "content" => Time.now.day
              }
            }
          }
        },
        :apply => ["static_content1"]
      }
    }

    it 'should contain a file with the current day number' do
      should contain_file('/tmp/date_test1') \
        .with_content(Time.now.day)
    end
    
    it 'should not contain another file with current day' do
      not contain_file('/tmp/date_test2')
    end
  end
  
  context 'with selecting none existent collection' do
    let(:params) {
      {
        :collections => {
          "static_content1" => {
            "file" => {
              "/tmp/date_test1" => {
                "content" => Time.now.day
              }
            }
          },
          "static_content2" => {
            "file" => {
              "/tmp/date_test2" => {
                "content" => Time.now.day
              }
            }
          }
        },
        :apply => ["not_a_collection"]
      }
    }

    it 'should have no resources' do
      should have_resource_count(0)
    end
  end
  
  context 'with inline ruby evaluation' do
    let(:params) {
      {
        :collections => {
          "static_content" => {
            "file" => {
              "/tmp/date_test" => {
                "content" => "rt_eval::Time.now.day"
              }
            }
          }
        },
        :apply => ["static_content"]
      }
    }

    it 'should contain a file with the current day number' do
      should contain_file('/tmp/date_test') \
        .with_content(Time.now.day)
    end
  end
  
  context 'file with notify' do
    let(:params) {
      {
        :collections => {
          "static_content" => {
            "file" => {
              "/tmp/date_test" => {
              "content" => "rt_eval::scope.function_notice([scope.lookupvar('all_notify')]);Time.now.day",
                "rt_notify" => {
                  "service" => "httpd"
                }
              }
            },
            "service" => {
              "httpd" => {
                "ensure" => "running"
              }
            }
          }
        },
        :apply => ["static_content"]
      }
  }

    it 'should have a file' do
      Puppet::Util::Log.level = :debug
      Puppet::Util::Log.newdestination(:console)
      should contain_file('/tmp/date_test') \
        .with_content(Time.now.day)
    end
    
    it 'should have a service' do
      should contain_service('httpd')
    end
    
    it 'should have a file notifying a service' do
      should contain_file('/tmp/date_test') \
        .that_notifies('Service[httpd]')
    end
  end
  
  context 'file with multiple notifies' do
    let(:params) {
      {
        :collections => {
          "static_content" => {
            "file" => {
              "/tmp/date_test" => {
                "content" => Time.now.day,
                "rt_notify" => {
                  "service" => [ "httpd", "rsyslog" ],
                  "exec"    => "create_test"
                }
              }
            },
            "service" => {
              "httpd" => {
                "ensure" => "running"
              },
              "rsyslog" => {
                "ensure" => "running"
              }
            },
            "exec" => {
              "create_test" => {
                "command" => "/bin/mkdir /tmp/test"
              }
            }
          }
        },
        :apply => ["static_content"]
      }
    }

    it 'should have a file' do
      should contain_file('/tmp/date_test') \
        .with_content(Time.now.day)
    end
    
    it 'should have services' do
      should contain_service('httpd')
      should contain_service('rsyslog')
    end
    
    it 'should have a exec' do
      should contain_exec('create_test')
    end
    
    it 'should have a file notifying services and exec' do
      should contain_file('/tmp/date_test') \
        .that_notifies('Service[httpd]')
      should contain_file('/tmp/date_test') \
        .that_notifies('Service[rsyslog]')
      should contain_file('/tmp/date_test') \
        .that_notifies('Exec[create_test]')
    end
  end
  
  context 'with requires' do
    let(:params) {
      {
        :collections => {
          "static_content" => {
            "file" => {
              "/tmp/check_date.sh" => {
                "content" => "date -u | logger",
                "mode"    => "0755"
              }
            },
            "cron" => {
              "run_date_check" => {
                "command"     => "/tmp/check_date.sh",
                "hour"        => "*",
                "rt_requires" => "file-/tmp/check_date.sh"
              }
            }
          }
        },
        :apply => ["static_content"]
      }
    }

    it 'should contain a script' do
      Puppet::Util::Log.level = :debug
      Puppet::Util::Log.newdestination(:console)
      should contain_file('/tmp/check_date.sh') \
        .with_content("date -u | logger")
    end
    
    it 'should have a cron requiring a script' do
      should contain_cron('run_date_check').that_requires('File[/tmp/check_date.sh]')
    end
  end
  
  context 'with multiple requires' do
    let(:params) {
      {
        :collections => {
          "static_content" => {
            "file" => {
              "/tmp/check_date.sh" => {
                "content" => "date -u > /tmp/test/date.log",
                "mode"    => "0755"
              },
              "/tmp/test" => {
                "ensure" => "directory",
              }
            },
            "cron" => {
              "run_date_check" => {
                "command"     => "/tmp/check_date.sh",
                "hour"        => "*",
                "rt_requires" => [ "file-/tmp/check_date.sh", "file-/tmp/test" ]
              }
            }
          }
        },
        :apply => ["static_content"]
      }
    }

    it 'should contain a directory and script' do
      should contain_file('/tmp/check_date.sh') \
        .with_content("date -u > /tmp/test/date.log")
      should contain_file('/tmp/test')
    end
    
    it 'should have a cron requiring a script' do
      should contain_cron('run_date_check').that_requires('File[/tmp/check_date.sh]')
      should contain_cron('run_date_check').that_requires('File[/tmp/test]')
    end
  end

  context 'with default params' do
    let(:params) {
      {
        :default_params => {
          "file" => {
            "mode" => '0600'
          }
        },
        :collections => {
          "static_content" => {
            "file" => {
              "/tmp/test1" => {
                "content" => "foo"
              },
              "/tmp/test2" => {
                "content" => "foo"
              },
              "/tmp/test3" => {
                "content" => "foo"
              },
              "/tmp/test4" => {
                "content" => "foo"
              },
              "/usr/local/bin/foo" => {
                "content" => "echo bar",
                "mode"    => '0755',
                "rt_resources" => {
                  "file" => {
                    "/etc/cron.daily/run_foo" => {
                      "content" => "/bin/bash /usr/local/bin/foo"
                    }
                  }
                }
              }
            }
          }
        },
        :apply => ["static_content"]
      }
    }

    it 'should contain files with mode=0600' do
      should contain_file('/tmp/test1') \
        .with_mode('0600')
      should contain_file('/tmp/test2') \
        .with_mode('0600')
      should contain_file('/tmp/test3') \
        .with_mode('0600')
      should contain_file('/tmp/test4') \
        .with_mode('0600')
    end

    it 'should contain a foo executable' do
      should contain_file('/usr/local/bin/foo') \
        .with_mode('0755')
    end

    it 'should contain a cron to run foo' do
      should contain_file('/etc/cron.daily/run_foo') \
        .with_mode('0600')
    end
  end

  context 'with variable collision' do
    let(:params) {
      {
        :collections => {
          "variable_collider" => {
            "file" => %({"foo" => "bar", "hello" => "world"}.inject({}) {|r,(k,v)| r.merge({k => {"content" => v.to_s}}) })
          }
        },
        :apply => ["variable_collider"]
      }
    }

    it 'should contain two files' do
      should contain_file('foo') \
        .with_content("bar")
      should contain_file('hello') \
        .with_content("world")
    end
  end

  context 'with aliased scope functions but preserving scope var' do
    let(:params) {
      {
        :collections => {
          "scoped_functions" => {
            "file" => %({"foo" => hiera('foo'), "hello" => scope.function_hiera(["hello"])}.inject({}) {|r,(k,v)| r.merge({k => {"content" => v.to_s}}) })
          }
        },
        :apply => ["scoped_functions"]
      }
    }

    it 'should contain two files' do
      Puppet::Parser::Scope.any_instance.expects(:function_hiera)
        .with(["foo"])
        .returns("bar")
      Puppet::Parser::Scope.any_instance.expects(:function_hiera)
        .with(["hello"])
        .returns("world")
      should contain_file('foo') \
        .with_content("bar")
      should contain_file('hello') \
        .with_content("world")
    end
  end
end
