require 'spec_helper'

describe 'resref' do
  describe 'with puppet resource strings' do
    filefoo = Puppet::Resource.new(:file, "foo")
    filebar = Puppet::Resource.new(:file, "bar")
    packagebiz = Puppet::Resource.new(:package, "biz")

    it { is_expected.to run.with_params([ 'File[foo]', 'File[bar]' ]).and_return([filefoo, filebar]) }
    it { is_expected.to run.with_params([ 'File[foo]']).and_return([filefoo]) }
    it { is_expected.to run.with_params([ 'File[foo]', 'File[bar]', 'Package[biz]' ]).and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params([ 'File[foo]', 'File[bar]'], [ 'Package[biz]' ]).and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params([ 'File[foo]' ], [ 'Package[biz]' ]).and_return([filefoo, packagebiz]) }
    it { is_expected.to run.with_params('File[foo]', 'Package[biz]').and_return([filefoo, packagebiz]) }
    it { is_expected.to run.with_params('Package[biz]').and_return([packagebiz]) }
    it { is_expected.to run.with_params('File[foo]', 'File[bar]', [ 'Package[biz]' ]).and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params([ 'File[foo]', 'File[bar]' ], 'Package[biz]').and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params([ 'File[foo]', 'File[bar]', 'Package[biz]' ]).and_return([filefoo, filebar, packagebiz]) }
  end

  describe 'with resource_tree ref strings' do
    filefoo = Puppet::Resource.new(:file, "foo")
    filebar = Puppet::Resource.new(:file, "bar")
    packagebiz = Puppet::Resource.new(:package, "biz")

    it { is_expected.to run.with_params([ 'file-foo', 'file-bar' ]).and_return([filefoo, filebar]) }
    it { is_expected.to run.with_params([ 'file-foo']).and_return([filefoo]) }
    it { is_expected.to run.with_params([ 'file-foo', 'file-bar', 'package-biz' ]).and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params([ 'file-foo', 'file-bar'], [ 'package-biz' ]).and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params([ 'file-foo' ], [ 'package-biz' ]).and_return([filefoo, packagebiz]) }
    it { is_expected.to run.with_params([ 'file-foo' ], [ 'package-biz' ]).and_return([filefoo, packagebiz]) }
    it { is_expected.to run.with_params('file-foo', 'package-biz').and_return([filefoo, packagebiz]) }
    it { is_expected.to run.with_params('package-biz').and_return([packagebiz]) }
    it { is_expected.to run.with_params('file-foo', 'file-bar', [ 'package-biz' ]).and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params([ 'file-foo', 'file-bar' ], 'package-biz').and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params([ 'file-foo', 'file-bar', 'package-biz' ]).and_return([filefoo, filebar, packagebiz]) }
  end

  describe 'with resource type:title hash' do
    filefoo = Puppet::Resource.new(:file, "foo")
    filebar = Puppet::Resource.new(:file, "bar")
    packagebiz = Puppet::Resource.new(:package, "biz")

    it { is_expected.to run.with_params({ 'file' => ['foo', 'bar'] }).and_return([filefoo, filebar]) }
    it { is_expected.to run.with_params({ 'file' => 'foo' }).and_return([filefoo]) }
    it { is_expected.to run.with_params({ 'file' => ['foo', 'bar'], 'package' => 'biz' }).and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params({ 'file' => ['foo', 'bar'] }, { 'package' => 'biz' }).and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params({ 'file' => 'foo' }, { 'package' => 'biz' }).and_return([filefoo, packagebiz]) }
    it { is_expected.to run.with_params({ 'file' => 'foo', 'package' => 'biz' }).and_return([filefoo, packagebiz]) }
    it { is_expected.to run.with_params({ 'file' => [ 'foo' ]}, { 'package' => [ 'biz' ]}).and_return([filefoo, packagebiz]) }
    it { is_expected.to run.with_params({ 'package' => 'biz' }).and_return([packagebiz]) }
    it { is_expected.to run.with_params({ 'file' => ['foo', 'bar'] }, { 'package' => [ 'biz' ]}).and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params({ 'file' => 'foo' }, { 'file' => 'bar', 'package' => [ 'biz' ]}).and_return([filefoo, filebar, packagebiz]) }
  end

  describe 'with a mixture of resource tree refs, hashes, and puppet resource strings' do
    filefoo = Puppet::Resource.new(:file, "foo")
    filebar = Puppet::Resource.new(:file, "bar")
    packagebiz = Puppet::Resource.new(:package, "biz")

    it { is_expected.to run.with_params( 'File[foo]', 'file-bar' ).and_return([filefoo, filebar]) }
    it { is_expected.to run.with_params([ 'File[foo]' ], [ 'file-bar' ]).and_return([filefoo, filebar]) }
    it { is_expected.to run.with_params([ 'File[foo]', 'file-bar' ]).and_return([filefoo, filebar]) }
    it { is_expected.to run.with_params({ 'file' => ['foo'] }, 'file-bar' ).and_return([filefoo, filebar]) }
    it { is_expected.to run.with_params({ 'file' => 'foo' }, 'File[bar]' ).and_return([filefoo, filebar]) }
    it { is_expected.to run.with_params({ 'file' => ['foo', 'bar'] }, 'package-biz' ).and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params({ 'file' => ['foo', 'bar'] }, [ 'package-biz' ]).and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params({ 'file' => ['foo', 'bar'] }, 'package[biz]' ).and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params({ 'file' => ['foo', 'bar'] }, [ 'package[biz]' ]).and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params({ 'file' => ['foo'] }, 'file-bar', 'package[biz]' ).and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params({ 'file' => ['foo'] }, [ 'file-bar' ], [ 'package[biz]' ]).and_return([filefoo, filebar, packagebiz]) }
    it { is_expected.to run.with_params({ 'file' => 'foo' }, [ 'file-bar', 'package[biz]' ]).and_return([filefoo, filebar, packagebiz]) }
  end

  ## Need to add tests for when the resource is already in the catalog
end
