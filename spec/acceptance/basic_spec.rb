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

  def post_conditions_puppet_module
    module_path = File.join(pp_path, 'postconditions.pp')
    File.read(module_path)
  end

  before(:all) do
    apply_manifest(preconditions_puppet_module, catch_failures: true)
  end

  it 'should work with no errors' do
    apply_manifest(default_puppet_module, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(default_puppet_module, catch_changes: true)
  end

  it 'should enable etherpad-lite services' do
    apply_manifest(post_conditions_puppet_module, catch_failures: true)
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

  describe file('/opt/etherpad-lite') do
    it { should exist }
    it { should be_directory }
    it { should be_grouped_into 'eplite' }
  end

  describe file('/etc/init/etherpad-lite.conf') do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'root' }
    its(:content) { should include 'env EPUSER=eplite' }
  end

  describe file('/etc/init.d/etherpad-lite') do
    it { should be_linked_to '/lib/init/upstart-job' }
  end

  describe file('/var/log/eplite') do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'eplite' }
  end

  describe file('/opt/etherpad-lite/etherpad-lite/settings.json') do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'eplite' }
    it { should be_grouped_into 'eplite' }
    its(:content) { should include '"dbType" : "mysql"' }
  end

  describe file('/opt/etherpad-lite/etherpad-lite/src/static/custom/pad.js') do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'eplite' }
    it { should be_grouped_into 'eplite' }
    its(:content) { should include 'function customStart()' }
  end

  describe file('/etc/logrotate.d/epliteerror') do
    its(:content) { should include '/opt/etherpad-lite/eplite/error.log' }
  end

  describe file('/etc/logrotate.d/epliteaccess') do
    its(:content) { should include '/opt/etherpad-lite/eplite/access.log' }
  end

  if os[:family] == 'Ubuntu' and os[:release] == '12.04'
    describe file('/etc/apache2/conf.d/connection-tuning') do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should include '<IfModule mpm_worker_module>' }
    end
  elsif ['debian', 'ubuntu'].include?(os[:family])
    describe file('/etc/apache2/conf-available/connection-tuning.conf') do
      it { should exist }
      it { should be_file }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
      its(:content) { should include '<IfModule mpm_worker_module>' }
    end

    describe file('/etc/apache2/conf-enabled/connection-tuning.conf') do
      it { should be_linked_to '/etc/apache2/conf-available/connection-tuning.conf' }
    end
  end

  describe file('/srv/etherpad-lite/robots.txt') do
    it { should exist }
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its(:content) { should include 'User-agent: *' }
  end

  describe service('etherpad-lite') do
    it { should be_running }
    it { should be_enabled }
  end

  describe 'required packages' do
    required_packages = [
      package('abiword'),
      package('nodejs'),
      package('npm'),
      package('ssl-cert'),
    ]
    required_packages.each do |package|
      describe package do
        it { should be_installed }
      end
    end
  end

  describe 'required apache modules' do
    required_modules = [
      'proxy_module',
      'rewrite_module',
      'proxy_http_module',
      'proxy_wstunnel_module',
    ]
    required_modules.each do |modules|
      describe command('apachectl -M') do
        its(:stdout) { should include modules }
      end
    end
  end

  describe file("/opt/etherpad-lite/etherpad-lite/node_modules/ep_headings") do
    it { should exist }
    it { should be_directory }
    it { should be_owned_by 'eplite' }
  end

  describe 'required services' do
    describe port(80) do
      it { should be_listening }
    end

    describe command("curl http://localhost --insecure --location") do
      #its(:stdout) { should contain('Gerrit Code Review') }
    end

    describe port(443) do
      it { should be_listening }
    end

    describe command("curl https://localhost --insecure --location") do
      #its(:stdout) { should contain('Gerrit Code Review') }
    end
  end
end
