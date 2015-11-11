require 'spec_helper_acceptance'

describe 'puppet-etherpad module' do
  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def preconditions_puppet_module
    module_path = File.join(pp_path, 'preconditions.pp')
    File.read(module_path)
  end

  def default_puppet_module
    module_path = File.join(pp_path, 'default.pp')
    File.read(module_path)
  end

  before(:all) do
    apply_manifest(preconditions_puppet_module, catch_failures: true)
  end

  it 'should work with no errors' do
    apply_manifest(default_puppet_module, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(default_puppet_module, catch_failures: true)
  end

  describe user ('eplite') do
    it { should exist }
    it { should belong_to_group 'eplite' }
    it { should have_home_directory '/var/log/eplite' }
    it { should have_login_shell '/usr/sbin/nologin' }
  end

  describe group('eplite') do
    it { should exist }
  end

end
