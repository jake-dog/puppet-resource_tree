# frozen_string_literal: true

require 'spec_helper'

describe 'resource_tree::resref' do
  context 'with predefined puppet resources' do
    let :pre_condition do
      <<-PRECOND
        file { 'foo': }
        package { 'biz': }
      PRECOND
    end

    filefoo = Puppet::Resource.new(:file, "foo")
    filebar = Puppet::Resource.new(:file, "bar")
    packagebiz = Puppet::Resource.new(:package, "biz")

    it { is_expected.to run.with_params('File[foo]', 'Package[biz]').and_return([filefoo, packagebiz]) }
    it { is_expected.to run.with_params('Package[biz]').and_return([packagebiz]) }
    it { is_expected.to run.with_params('File[foo]', 'File[bar]', 'Package[biz]').and_return([filefoo, filebar, packagebiz]) }
  end

  ## Need to add tests for when the resource is already in the catalog
  context 'with undefined puppet resources' do
    filefoo = Puppet::Resource.new(:file, "foo")
    filebar = Puppet::Resource.new(:file, "bar")
    packagebiz = Puppet::Resource.new(:package, "biz")

    it { is_expected.to run.with_params('File[foo]', 'Package[biz]').and_return([filefoo, packagebiz]) }
    it { is_expected.to run.with_params('Package[biz]').and_return([packagebiz]) }
    it { is_expected.to run.with_params('File[foo]', 'File[bar]', 'Package[biz]').and_return([filefoo, filebar, packagebiz]) }
  end
end
