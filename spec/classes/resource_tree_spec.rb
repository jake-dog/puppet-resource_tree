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
  
  context 'with compress => true' do
    let(:params) { 
      {
        :collections => {
          "dynamic_content" => {
            "file" => {
              "/tmp/date_test" => {
                "content" => Time.now.day
              }
            }
          }
        }, 
        :apply => ["dynamic_content"]
      } 
    }

    it do
      should contain_file('/tmp/date_test') \
        .with_content(Time.now.day)
    end
  end
end
