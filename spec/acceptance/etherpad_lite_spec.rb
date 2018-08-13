require 'puppet-openstack_infra_spec_helper/spec_helper_acceptance'

describe 'puppet-etherpad_lite:: manifest', :if => ['debian', 'ubuntu'].include?(os[:family]) do
  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def preconditions_puppet_module
    module_path = File.join(pp_path, 'preconditions.pp')
    File.read(module_path)
  end

  before(:all) do
    apply_manifest(preconditions_puppet_module, catch_failures: true)
  end

  def init_puppet_module
    module_path = File.join(pp_path, 'etherpad_lite.pp')
    File.read(module_path)
  end

  it 'should work with no errors' do
    apply_manifest(init_puppet_module, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(init_puppet_module, catch_changes: true)
  end

  describe 'required files' do
    describe file('/opt/etherpad-lite/') do
      it { should be_directory }
      it { should be_grouped_into 'eplite' }
    end

    # check service file installed
    describe file('/etc/systemd/system/etherpad-lite.service') do
      it { should be_file }
    end

    # check git got all the source
    describe file('/opt/etherpad-lite/etherpad-lite/bin/installDeps.sh') do
      it { should be_file }
    end

    # check npm modules installed
    describe file('/home/eplite/.npm') do
      it { should be_directory }
    end
  end

  describe 'required services' do
    describe 'ports are open and services are reachable' do
      describe port(80) do
        it { should be_listening }
      end

      describe command('curl -L -k http://localhost --verbose') do
        its(:stdout) { should contain('randomPadName()') }
      end
    end
  end

end
