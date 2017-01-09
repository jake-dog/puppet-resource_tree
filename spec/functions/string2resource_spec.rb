require 'spec_helper'

describe 'string2resource' do
  it { is_expected.to run.with_params(1,2,3).and_raise_error(ArgumentError) }

  describe 'with arrays of resources' do
    filefoo = Puppet::Resource.new(:file, "foo")
    filebar = Puppet::Resource.new(:file, "bar")
    packagebiz = Puppet::Resource.new(:package, "biz")
    
    it { is_expected.to run.with_params([ 'File[foo]', 'File[bar]' ]).and_return([filefoo, filebar]) }
    it { is_expected.to run.with_params([ 'File[foo]']).and_return([filefoo]) }
    it { is_expected.to run.with_params([ 'File[foo]', 'File[bar]', 'Package[biz]' ]).and_return([filefoo, filebar, packagebiz]) }
  end

  describe 'with individual resources' do
    filefoo = Puppet::Resource.new(:file, "foo")
    filebar = Puppet::Resource.new(:file, "bar")
    packagebiz = Puppet::Resource.new(:package, "biz")

    it { is_expected.to run.with_params('File[bar]').and_return(filebar) }
    it { is_expected.to run.with_params('Package[biz]').and_return(packagebiz) }
    it { is_expected.to run.with_params('file', 'foo').and_return(filefoo) }
    it { is_expected.to run.with_params('package', 'biz').and_return(packagebiz) }
  end
end

